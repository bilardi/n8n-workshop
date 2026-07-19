#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///
"""Pre-generate n8n user invitations and export email + invite link to a CSV.

Logs in as the instance owner through the internal REST API, then sends all
invitations in a single request: this stays under the 10-per-5-minutes IP rate
limit that n8n enforces on the invite endpoint, and returns one invite link per
user (links are valid 90 days and single-use).

Usage:
    uv run invite_users.py                                  # user00..user59 @pandle.net
    uv run invite_users.py --start 0 --end 59 --domain pandle.net

Configuration is read from a .env file next to this script (see .env.example):
    N8N_BASE_URL, N8N_OWNER_EMAIL, N8N_OWNER_PASSWORD
"""

from __future__ import annotations

import argparse
import csv
import http.cookiejar
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import cast

SCRIPT_DIR: Path = Path(__file__).resolve().parent
REPO_ROOT: Path = SCRIPT_DIR.parents[2]  # scripts/adepts/invitations -> ... -> repo root
DEFAULT_ENV_FILE: Path = SCRIPT_DIR / ".env"
DEFAULT_OUTPUT: Path = REPO_ROOT / "tmp" / "invitations" / "invites.csv"
DEFAULT_BASE_URL: str = "http://localhost:5678"
CSV_COLUMNS: list[str] = ["email", "link"]
HTTP_TOO_MANY_REQUESTS: int = 429


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


def build_emails(start: int, end: int, domain: str) -> list[str]:
    """Return user<NN>@<domain> for NN in [start, end], zero-padded to two digits."""
    return [f"user{number:02d}@{domain}" for number in range(start, end + 1)]


def _post_json(opener: urllib.request.OpenerDirector, url: str, payload: object) -> object:
    """POST a JSON payload and return the parsed JSON response (None if empty)."""
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url, data=data, method="POST")
    request.add_header("Content-Type", "application/json")
    with opener.open(request) as response:
        body = response.read().decode("utf-8")
    return json.loads(body) if body else None


def login(opener: urllib.request.OpenerDirector, base_url: str, email: str, password: str) -> None:
    """Authenticate the owner; the session cookie is stored in the opener's cookie jar."""
    payload = {"emailOrLdapLoginId": email, "password": password}
    _post_json(opener, f"{base_url}/rest/login", payload)


def invite_users(
    opener: urllib.request.OpenerDirector,
    base_url: str,
    emails: list[str],
    role: str,
) -> list[dict[str, str]]:
    """Send all invitations in one request and return [{email, link}] rows."""
    payload = [{"email": email, "role": role} for email in emails]
    result = _post_json(opener, f"{base_url}/rest/invitations", payload)
    return _parse_invitations(result)


def _parse_invitations(result: object) -> list[dict[str, str]]:
    """Extract [{email, link}] from the REST response, unwrapping the {data} envelope."""
    payload: object = result
    if isinstance(payload, dict):
        payload = cast("dict[str, object]", payload).get("data")
    rows: list[dict[str, str]] = []
    if not isinstance(payload, list):
        return rows
    for raw in cast("list[object]", payload):
        if not isinstance(raw, dict):
            continue
        user = cast("dict[str, object]", raw).get("user")
        if not isinstance(user, dict):
            continue
        fields = cast("dict[str, object]", user)
        email = fields.get("email")
        link = fields.get("inviteAcceptUrl")
        if isinstance(email, str) and isinstance(link, str):
            rows.append({"email": email, "link": link})
    return rows


def write_csv(rows: list[dict[str, str]], output: Path) -> None:
    """Write rows to a CSV with an email,link header, creating parent folders."""
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Pre-generate n8n invitations to a CSV.")
    parser.add_argument("--start", type=int, default=0, help="first user number (default: 0)")
    parser.add_argument("--end", type=int, default=59, help="last user number (default: 59)")
    parser.add_argument("--domain", default="pandle.net", help="email domain (default: pandle.net)")
    parser.add_argument("--role", default="global:member", help="role (default: global:member)")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="output CSV path")
    parser.add_argument("--env-file", type=Path, default=DEFAULT_ENV_FILE, help="path to .env")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    load_env(args.env_file)

    base_url = os.environ.get("N8N_BASE_URL", DEFAULT_BASE_URL).rstrip("/")
    email = os.environ.get("N8N_OWNER_EMAIL")
    password = os.environ.get("N8N_OWNER_PASSWORD")
    if not email or not password:
        print(
            "error: set N8N_OWNER_EMAIL and N8N_OWNER_PASSWORD (see .env.example)", file=sys.stderr
        )
        return 1

    emails = build_emails(args.start, args.end, args.domain)
    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))

    try:
        login(opener, base_url, email, password)
        rows = invite_users(opener, base_url, emails, args.role)
    except urllib.error.HTTPError as error:
        if error.code == HTTP_TOO_MANY_REQUESTS:
            print("error: rate limited (429), wait 5 minutes and retry", file=sys.stderr)
        else:
            print(f"error: HTTP {error.code} from n8n ({error.reason})", file=sys.stderr)
        return 1
    except urllib.error.URLError as error:
        print(f"error: cannot reach n8n at {base_url} ({error.reason})", file=sys.stderr)
        return 1

    if not rows:
        print(
            "warning: no invite links returned; SMTP may be configured, so links were emailed",
            file=sys.stderr,
        )

    write_csv(rows, args.output)
    print(f"wrote {len(rows)} invites to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
