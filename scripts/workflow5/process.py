#!/usr/bin/env python3
"""
Scan WORKSPACE_PATH one file at a time, logging each file to processed.csv.

Usage:
    python3 process.py --path /home/node/.n8n-files/workspace --interval 5

Creates in workflow5/ (same folder as this script):
  pid.txt        - PID of the process (removed on completion)
  processed.csv  - cumulative log: timestamp, dirname, path

On completion calls scripts/workflow6/monitor.py and sends a summary via Telegram
if the environment variables TELEGRAM_TOKEN and TELEGRAM_CHAT_ID are set.
"""

import argparse
import csv
import json
import os
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime

WORKFLOW_DIR: str = os.path.dirname(os.path.abspath(__file__))
SCRIPTS_DIR: str = os.path.dirname(WORKFLOW_DIR)
DATA_DIR: str = "/tmp/workflow5"
PID_FILE: str = os.path.join(DATA_DIR, "pid.txt")
CSV_FILE: str = os.path.join(DATA_DIR, "processed.csv")
CSV_COLUMNS: list[str] = ["timestamp", "dirname", "path"]


# -- Helpers ------------------------------------------------------------------


def write_csv(row: dict[str, str]) -> None:
    """Append a row to processed.csv, creating the header if needed."""
    file_exists = os.path.isfile(CSV_FILE)
    with open(CSV_FILE, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        if not file_exists:
            writer.writeheader()
        writer.writerow(row)


# -- Telegram notification ----------------------------------------------------


def build_summary(base: str) -> str:
    """Call monitor.py --format md and return the formatted message."""
    script = os.path.join(SCRIPTS_DIR, "workflow6", "monitor.py")
    out = subprocess.run(
        ["python3", script, "--path", base, "--data", DATA_DIR, "--format", "md"],
        capture_output=True,
        text=True,
    )
    return out.stdout.strip() or "done"


def send_telegram(text: str) -> None:
    """Send a Telegram message if TELEGRAM_TOKEN and TELEGRAM_CHAT_ID are set."""
    token = os.environ.get("TELEGRAM_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")
    if not token or not chat_id:
        return
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    data = urllib.parse.urlencode({"chat_id": chat_id, "text": text}).encode()
    try:
        urllib.request.urlopen(url, data, timeout=10)
    except Exception:
        pass


# -- Main logic ---------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Scan workspace and log files.")
    parser.add_argument("--path", required=True, help="Folder to scan (WORKSPACE_PATH)")
    parser.add_argument(
        "--interval", type=int, default=5, help="Seconds between file processing (default: 5)"
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if not os.path.isdir(args.path):
        print(json.dumps({"error": f"Folder not found: {args.path}"}))
        sys.exit(1)

    os.makedirs(DATA_DIR, exist_ok=True)

    # Write PID on startup
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    fatal_error: str | None = None
    try:
        files: list[str] = []
        base: str = args.path
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames.sort()
            for name in sorted(filenames):
                files.append(os.path.join(dirpath, name))

        if not files:
            # Empty workspace: write a single row for "."
            write_csv(
                {
                    "timestamp": datetime.now().isoformat(),
                    "dirname": args.path,
                    "path": ".",
                }
            )
        else:
            # Process one file at a time
            for i, file_path in enumerate(files):
                rel_dir = os.path.relpath(os.path.dirname(file_path), args.path)
                write_csv(
                    {
                        "timestamp": datetime.now().isoformat(),
                        "dirname": rel_dir,
                        "path": file_path,
                    }
                )
                if i < len(files) - 1:
                    time.sleep(args.interval)

    except Exception as e:
        fatal_error = str(e)

    finally:
        if os.path.isfile(PID_FILE):
            os.remove(PID_FILE)
        text = build_summary(args.path)
        if fatal_error:
            text = f"aborted: {fatal_error}\n\n{text}"
        send_telegram(text)
