#!/usr/bin/env python3
"""
Monitor process.py execution and return aggregate statistics.

Usage:
    python3 monitor.py --path /home/node/.n8n-files/workspace --data /home/node/.n8n-files/scripts/workflow5
    python3 monitor.py --path /home/node/.n8n-files/workspace --data /home/node/.n8n-files/scripts/workflow5 --column path

Prints JSON to stdout with:
  running          - bool: process.py is still active
  total_files      - int: total files in WORKSPACE_PATH
  processed_total  - int: total rows in processed.csv
  per_folder       - dict: for each aggregation key { "processed": N, "present": M }
                     union of processed.csv (by --column) and recursive physical count
"""

from __future__ import annotations

import argparse
import csv
import json
import os
from typing import Any


def is_process_running(pid: int) -> bool:
    """Return True if the process with the given PID is active."""
    try:
        os.kill(pid, 0)
        return True
    except (ProcessLookupError, PermissionError):
        return False


def read_pid(data_dir: str) -> int | None:
    """Read the PID from pid.txt, return None if missing or invalid."""
    try:
        with open(os.path.join(data_dir, "pid.txt")) as f:
            return int(f.read().strip())
    except Exception:
        return None


def count_files_per_folder(base: str) -> dict[str, int]:
    """Count files in each subfolder of base, recursively."""
    result: dict[str, int] = {}
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames.sort()
        rel = os.path.relpath(dirpath, base)
        if rel == ".":
            continue
        if filenames:
            result[rel] = len(filenames)
    return result


def count_total_files(base: str) -> int:
    """Count all files in base, recursively."""
    total = 0
    for _dirpath, _dirnames, filenames in os.walk(base):
        total += len(filenames)
    return total


def read_csv(data_dir: str, column: str) -> tuple[int, dict[str, int]]:
    """Read processed.csv and return (total_rows, count_by_column)."""
    total = 0
    by_column: dict[str, int] = {}
    try:
        csv_file = os.path.join(data_dir, "processed.csv")
        with open(csv_file, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                total += 1
                key = row.get(column) or "unknown"
                by_column[key] = by_column.get(key, 0) + 1
    except FileNotFoundError:
        pass
    return total, by_column


def format_markdown(data: dict[str, Any]) -> str:
    """Format monitor data as a Markdown message for Telegram."""
    status = "🔄 *scansione in corso*" if data["running"] else "✅ *scansione completata*"
    lines = [
        status,
        "",
        f"📊 File totali: {data['total_files']}",
        f"📋 Processati: {data['processed_total']}",
    ]
    for folder, stat in sorted(data.get("per_folder", {}).items()):
        lines.append(f"📁 {folder}: {stat['processed']} processati / {stat['present']} presenti")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Monitor process.py and return stats.")
    parser.add_argument("--path", required=True, help="Folder being monitored (WORKSPACE_PATH)")
    parser.add_argument(
        "--data",
        required=True,
        help="Folder containing pid.txt and processed.csv (e.g. workflow5/)",
    )
    parser.add_argument(
        "--column", default="dirname", help="CSV column to aggregate by (default: dirname)"
    )
    parser.add_argument(
        "--format", choices=["json", "md"], default="json", help="Output format (default: json)"
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    base = args.path

    pid = read_pid(args.data)
    running = is_process_running(pid) if pid else False

    total_csv, by_column = read_csv(args.data, args.column)
    present_per_folder = count_files_per_folder(base)
    total_files = count_total_files(base)

    # Merge both sources: keys from both dicts
    all_keys = set(by_column) | set(present_per_folder)
    per_folder = {
        key: {
            "processed": by_column.get(key, 0),
            "present": present_per_folder.get(key, 0),
        }
        for key in sorted(all_keys)
    }

    data = {
        "running": running,
        "total_files": total_files,
        "processed_total": total_csv,
        "per_folder": per_folder,
    }

    if args.format == "md":
        print(format_markdown(data))
    else:
        print(json.dumps(data, ensure_ascii=False))
