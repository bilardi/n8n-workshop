#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///
"""Import all workflows from a JSON export into an n8n account via the REST API.

Logs in as a regular member through the internal REST API, then creates each
workflow from the export file in that member's personal project. Works remotely
over HTTPS, without shell access to the container.

The export file may be a single workflow object or an array (as produced by
`n8n export:workflow --all`). Only name, nodes, connections and settings are
sent: read-only and reference fields (id, active, tags, ...) are dropped, so the
workflows are created fresh (new ids, inactive, no credentials linked).

Usage:
    uv run import_workflows.py                          # downloads/all-workflows.json
    uv run import_workflows.py --input path/to/file.json

Configuration is read from a .env file next to this script (see .env.example):
    N8N_BASE_URL, N8N_EMAIL, N8N_PASSWORD
"""

from __future__ import annotations

import argparse
import http.cookiejar
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import cast

SCRIPT_DIR: Path = Path(__file__).resolve().parent
REPO_ROOT: Path = SCRIPT_DIR.parents[2]  # scripts/adepts/workflows -> ... -> repo root
DEFAULT_ENV_FILE: Path = SCRIPT_DIR / ".env"
DEFAULT_INPUT: Path = REPO_ROOT / "downloads" / "all-workflows.json"
DEFAULT_BASE_URL: str = "http://localhost:5678"
WORKFLOW_FIELDS: tuple[str, ...] = ("name", "nodes", "connections", "settings")
REQUIRED_FIELDS: tuple[str, ...] = ("name", "nodes", "connections")


def load_env(env_file: Path) -> None:
    """Load KEY=VALUE lines from a .env file into the environment without overriding."""
    if not env_file.is_file():
        return
    for raw in env_file.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def _post_json(opener: urllib.request.OpenerDirector, url: str, payload: object) -> object:
    """POST a JSON payload and return the parsed JSON response (None if empty)."""
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=data, method="POST")
    request.add_header("Content-Type", "application/json")
    with opener.open(request) as response:
        body = response.read().decode("utf-8")
    return json.loads(body) if body else None


def login(opener: urllib.request.OpenerDirector, base_url: str, email: str, password: str) -> None:
    """Authenticate the member; the session cookie is stored in the opener's cookie jar."""
    payload = {"emailOrLdapLoginId": email, "password": password}
    _post_json(opener, f"{base_url}/rest/login", payload)


def read_workflows(path: Path) -> list[dict[str, object]]:
    """Read the export file and return a list of workflow objects."""
    raw: object = json.loads(path.read_text(encoding="utf-8"))
    candidates = cast("list[object]", raw) if isinstance(raw, list) else [raw]
    workflows: list[dict[str, object]] = []
    for item in candidates:
        if isinstance(item, dict):
            workflows.append(cast("dict[str, object]", item))
    return workflows


def import_workflow(
    opener: urllib.request.OpenerDirector,
    base_url: str,
    workflow: dict[str, object],
) -> tuple[str, bool, str]:
    """Create one workflow and return (name, ok, detail)."""
    name = str(workflow.get("name", "<unnamed>"))
    payload = {field: workflow[field] for field in WORKFLOW_FIELDS if field in workflow}
    if any(field not in payload for field in REQUIRED_FIELDS):
        return (name, False, "missing required fields (name/nodes/connections)")
    try:
        _post_json(opener, f"{base_url}/rest/workflows", payload)
    except urllib.error.HTTPError as error:
        return (name, False, f"HTTP {error.code} {error.reason}")
    return (name, True, "created")


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Import n8n workflows from a JSON export.")
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT, help="export file path")
    parser.add_argument("--env-file", type=Path, default=DEFAULT_ENV_FILE, help="path to .env")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    load_env(args.env_file)

    base_url = os.environ.get("N8N_BASE_URL", DEFAULT_BASE_URL).rstrip("/")
    email = os.environ.get("N8N_EMAIL")
    password = os.environ.get("N8N_PASSWORD")
    if not email or not password:
        print("error: set N8N_EMAIL and N8N_PASSWORD (see .env.example)", file=sys.stderr)
        return 1

    input_path: Path = args.input
    if not input_path.is_file():
        print(f"error: input file not found: {input_path}", file=sys.stderr)
        return 1
    workflows = read_workflows(input_path)
    if not workflows:
        print(f"warning: no workflows found in {input_path}", file=sys.stderr)
        return 0

    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    try:
        login(opener, base_url, email, password)
    except urllib.error.HTTPError as error:
        print(f"error: login failed (HTTP {error.code} {error.reason})", file=sys.stderr)
        return 1
    except urllib.error.URLError as error:
        print(f"error: cannot reach n8n at {base_url} ({error.reason})", file=sys.stderr)
        return 1

    imported = 0
    for workflow in workflows:
        name, ok, detail = import_workflow(opener, base_url, workflow)
        if ok:
            imported += 1
            print(f"[ok] {name}")
        else:
            print(f"[fail] {name}: {detail}")

    print(f"imported {imported}/{len(workflows)} workflows")
    return 0 if imported == len(workflows) else 1


if __name__ == "__main__":
    raise SystemExit(main())
