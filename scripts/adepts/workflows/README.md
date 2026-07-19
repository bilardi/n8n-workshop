# n8n workflow import via API

Script to load all workflows from an export file (e.g. `downloads/all-workflows.json`) into an n8n account, using the REST API. Useful to populate your own account remotely, without shell access to the container.

## Why the API instead of the CLI

The official `n8n import:workflow` command needs shell access to the container (`docker exec` or SSM on the server). This script uses the REST API over HTTPS instead, so it runs from any machine pointing at the instance URL.

Differences from the CLI:

- it creates workflows with **new ids** (originals are not preserved), **inactive**, without tags or linked credentials
- it sends only `name`, `nodes`, `connections`, `settings`: the other export fields (id, active, tags, ...) are dropped

For a faithful backup/restore (preserved ids, active state) the CLI is preferable: see the [download guide](../../../guides/download/english.md).

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (the script is self-contained, PEP 723)
- a reachable n8n instance and the credentials of a **member** user (workflows land in their personal project)

## Configuration

```sh
cp .env.example .env
```

Then fill `.env`:

- `N8N_BASE_URL`: URL of the n8n instance, no trailing slash
- `N8N_EMAIL`: member email
- `N8N_PASSWORD`: member password

The `.env` file is gitignored: it is never committed.

## Usage

```sh
# default: downloads/all-workflows.json
uv run import_workflows.py

# custom input file
uv run import_workflows.py --input path/to/file.json
```

Available arguments:

- `--input`: path to the export file (default `downloads/all-workflows.json` in the repo root)
- `--env-file`: path to the `.env` file (default: next to the script)

## Output

Log to screen: one `[ok]` / `[fail]` line per workflow and a final `imported X/Y workflows` summary. The exit code is `0` only if every workflow is imported.

## Operational notes

- Workflows are created in the personal project of the member set in `.env`
- The export file holds no credentials: after the import they must be recreated and reassigned to the nodes (see the [download guide](../../../guides/download/english.md))
- Re-running the script creates **copies** of the workflows (new ids each time): run it once to avoid duplicates
