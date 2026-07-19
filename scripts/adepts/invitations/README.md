# n8n invitation pre-generation

Script to create a batch of n8n users ahead of time and save the `email,link` invite pairs to a CSV. Handy for workshops: generate the links beforehand and hand them out on the day, without hitting the invite rate limit.

## Why it is needed

The n8n invite endpoint (Settings > Users > Invite) has a limit of **10 requests every 5 minutes per IP**, not configurable (hardcoded in the source). Inviting people one at a time during the workshop hits the limit quickly and returns `429 Too Many Requests`.

The script works around it in two ways:

- it sends all invitations in a **single request** (the endpoint accepts an array of emails): 1 request instead of N, so the limit is never reached
- the generated links stay valid for **90 days** and are **single-use**: prepare them once, use them when needed

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (the script is self-contained, PEP 723)
- a reachable n8n instance and the owner credentials
- SMTP not configured on the instance: only then does n8n return the links in the interface and in the REST response; if SMTP is active the links are emailed and do not appear in the CSV

## Configuration

```sh
cp .env.example .env
```

Then fill `.env`:

- `N8N_BASE_URL`: URL of the n8n instance, no trailing slash
- `N8N_OWNER_EMAIL`: owner email
- `N8N_OWNER_PASSWORD`: owner password

The `.env` file is gitignored: it is never committed.

## Usage

```sh
# default: user00..user59 @pandle.net
uv run invite_users.py

# custom range and domain
uv run invite_users.py --start 0 --end 59 --domain pandle.net
```

Available arguments:

- `--start` / `--end`: range of user numbers (default 0 and 59), zero-padded to two digits (`user00` ... `user59`)
- `--domain`: email domain (default `pandle.net`)
- `--role`: assigned role (default `global:member`)
- `--output`: CSV path (default `tmp/invitations/invites.csv` in the repo root)
- `--env-file`: path to the `.env` file (default: next to the script)

## Output

A CSV with header `email,link`, one user per row. Default path: `tmp/invitations/invites.csv`.

The CSV holds live JWTs (the invite links): it lives under `tmp/`, gitignored, and must not be shared or committed.

## Operational notes

- Run the script **only once**: re-running it regenerates new links for the still-pending users, creating duplicates
- Each link is for one person: once someone sets a password that link can no longer be reused
- If you get a `429`, you still hit the limit (10/5 min): wait 5 minutes and retry
