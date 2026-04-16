# n8n Guide - Docker Installation
## For those installing n8n on their own computer

---

## Table of Contents

1. [Installation](#installation)
2. [Part 5: Workflow 2 - polling and commands](#part-5-full-workflow-with-polling-and-commands)
3. [Process monitoring with Python](#process-monitoring-with-python)

---

## Installation

To install n8n with Docker (Windows, Linux, macOS), configure the `.env`, backup and restore, see the full guide:

> **[Docker installation guide](../../scripts/docker_installer/english.md)**

The guide also covers installation without Docker via npm.

---

## Telegram Bot for Notifications

> **Before continuing:** complete [Parts 1-4 of the introduction](../intro/english.md) (Telegram bot, credentials, Chat ID, test workflow). If you're starting from scratch, start there.

For credential configuration and security notes, see [intro/english.md](../intro/english.md#configuring-telegram-credentials).

### Part 5: Workflow 2 - polling and commands

Create a new workflow. Copy Nodes B, C and D from Workflow 1 (select them - Ctrl+C - new workflow - Ctrl+V): they're already configured and will be reused in the `/status` branch.

This workflow runs in the background, checks every minute for bot messages and responds to commands.

**Workflow structure:**

```
[Node 1: Schedule Trigger]
  ↓
[Node 2: HTTP Request]
  ↓
[Node 3: Code: filter recent]
  ↓
[Node 4: Switch]
  ├── /status    → [Node B] → [Node C] → [Node D]
  ├── no message → (no action)
  └── fallback   → [Node 5: IF regex]
                       ├── Yes → [Node 6: Telegram]
                       └── No → (no action)
```

> [Workflow diagram](../../mermaid/english/workflow2.mermaid) | [Sequence diagram](../../mermaid/english/workflow.basic.mermaid)

#### Node 1 - Schedule Trigger

- Interval: 1 minute

#### Node 2 - HTTP Request (getUpdates)

- Method: `GET`
- URL: `https://api.telegram.org/bot{{ $env.TELEGRAM_TOKEN }}/getUpdates`

> The Telegram node with "Get Updates" would require a public HTTPS webhook and doesn't work locally.

> If `TELEGRAM_TOKEN` is not yet in the `.env` file, add it now and restart: `docker compose down && docker compose up -d`

#### Node 3 - Code, extract the latest recent message

- Mode: **Run Once for All Items**

Choose the language you prefer
- Javascript:
```javascript
const results = $input.first().json.result;
if (!results || results.length === 0) return [];

const oneMinuteAgo = Math.floor(Date.now() / 1000) - 60;
const recent = results.filter(u =>
  u.message && u.message.date > oneMinuteAgo
);

if (recent.length === 0) return [];
return [{ json: recent[recent.length - 1] }];
```
- Python:
```python
import time

results = _items[0]["json"]["result"]
if not results:
    return []

one_minute_ago = int(time.time()) - 60
recent = [u for u in results if u.get("message") and u["message"]["date"] > one_minute_ago]

if not recent:
    return []
return [{"json": recent[-1]}]
```

#### Node 4 - Switch, route by command type

- Enable **Options +** > **Fallback Output** > Extra Output
- Routing Rule 1: `{{ $json.message.text }}` contains `/status`
  - Rename output: status
- Routing Rule 2: `{{ $json.message }}` not exists (messages without text)
  - Rename output: not exists

#### Nodes B, C, D (/status branch)

Copy Nodes B, C and D from Workflow 1 (select them - Ctrl+C - new workflow - Ctrl+V): they're already configured in [Part 4](../intro/english.md#part-4-workflow-1---count-files-with-manual-trigger).

Connect the `/status` output of Node 4 to **Node B** (already configured in Part 4), already connected to Nodes C and D: same physical nodes, no reconfiguration needed.

#### Node 5 - IF (after the Fallback): is it a command?

- Condition: `{{ $json.message.text }}` matches regex `^\/\w+`

#### Node 6 - Telegram: unknown command
Copy Node D and modify it
- Credential: see [Configuring Telegram Credentials](../intro/english.md#configuring-telegram-credentials)
- Operation: Send Message
- Chat ID: your Chat ID (found in Part 3)
- Text: `Unknown command {{ $json.message.text }}`

Node D and Node 6 use the fixed Chat ID (found in Part 3): the dynamic Chat ID from `$json.message.chat.id` doesn't work in these paths.

> With the Telegram Trigger (webhook) the dynamic Chat ID `$json.message.chat.id` works correctly: available in the [server guide](../server/english.md)

---

## Process Monitoring with Python

### The project

Create a system that:
1. **Scans** the folder defined in `WORKSPACE_PATH`, one file at a time
2. **Records each file** in `processed.csv` during execution (with timestamp, folder and full path)
3. **Allows real-time monitoring** via `/status` on the Telegram bot
4. **Demonstrates the pattern** of background-process + PID monitoring, reusable for any long-running processing

The script runs in the background, writes its own PID to `pid.txt` at startup and deletes it at the end; a separate script (`workflow6/monitor.py`) aggregates the status at any time.

---

### Preparation: .env

If you use Docker, open the `.env` file and set the path of the folder to monitor:

```bash
# .env: uncomment and modify only this line
WORKSPACE_PATH=/home/mario/Documents
```

If you don't set `WORKSPACE_PATH`, the `./workspace` subfolder of the repository is mounted.

> If you modify `.env` after the first startup, restart with: `docker compose down && docker compose up -d`

---

### Python Script: process.py

Receives `--path` (the folder to scan) and `--interval` (seconds between one file and the next). At the end it calls `workflow6/monitor.py` internally to send the summary on Telegram.

For each processed file it appends a line to `/tmp/workflow5/processed.csv`:

| timestamp | dirname | path |
|-----------|---------|------|
| 2026-03-29T10:00:00 | /workspace/ | /workspace/report.pdf |
| 2026-03-29T10:00:05 | /workspace/ | /workspace/notes.txt |
| 2026-03-29T10:00:10 | /workspace/images/ | /workspace/images/foto.jpg |

#### Scanning logic

1. **Empty folder**: if `WORKSPACE_PATH` doesn't contain files, writes a single line with `path=.` and `dirname` equal to the base path
2. **Folder with files**: for each file (in alphabetical order, recursive):
   - Writes a line in `processed.csv` with timestamp, `dirname` (relative folder of the file) and `path` (full path)
   - Waits `--interval` seconds before moving to the next file

---

### Python Script: monitor.py

`monitor.py` aggregates the status into a single JSON by reading three sources:
- `pid.txt`, to know if `process.py` is still running (read from the folder specified with `--data`)
- `processed.csv`, total count and aggregation by `--column` (default: `dirname`) (read from the same `--data` folder)
- physical recursive count of subfolders (internal logic, auto-discovers all folders)

```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5
```

```json
{
  "running": true,
  "total_files": 42,
  "processed_total": 30,
  "per_folder": {
    "/workspace":        { "processed": 15, "present": 20 },
    "/workspace/images": { "processed": 10, "present": 12 }
  }
}
```

With `--format md` it returns the message formatted in Markdown instead of JSON:

```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5 --format md
```

To aggregate by `path` instead of `dirname`:

```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5 --column path
```

`monitor.py` runs once and terminates: there is no loop. The n8n workflow calls it on each `/status` received.

---

### Process Monitoring Workflows

These are two independent workflows based on the same scripts.

The workflows use the **Execute Command** node to launch Python scripts in the container. Since n8n 2.0 this node is blocked by default for security reasons. To re-enable it, add in `docker-compose.yml`:

```yaml
environment:
  - NODES_EXCLUDE=[]
```

If you prefer not to re-enable a potentially deprecated node, there are two alternatives:

| Alternative | How it works | Pros | Cons |
|-------------|-------------|------|------|
| **SSH Node** | SSH connection to the container or an external host that runs the command | Officially supported, not at risk of deprecation | Requires an SSH server and credentials to configure |
| **HTTP Request - external webhook** | The Python script runs as a separate service (e.g. Flask/FastAPI) and n8n calls it via HTTP | Decouples n8n from scripts, scalable | Requires an additional service to maintain |

The guide continues with Execute Command. If you use an alternative, replace that node while keeping the same command.

#### Workflow 5 - Scan start

Create a new workflow. For the Telegram node, copy the one already configured from Workflow 2 and just change the text.

```
[Manual Trigger]
  ↓
[Execute Command, start process.py in background]
  ↓
[Telegram: Send Message "scan started"]
```

> [Workflow diagram](../../mermaid/english/workflow5.mermaid) | [Sequence diagram](../../mermaid/english/workflow.monitoring.mermaid)

**Execute Command**
```bash
nohup python3 /home/node/.n8n-files/scripts/workflow5/process.py \
  --path /home/node/.n8n-files/workspace --interval 5 > /dev/null 2>&1 &
```

The Execute Command node launches the script in the background and returns **immediately**.

**Telegram: Send Text Message "scan started"**
- Credential: your Telegram credential
- Chat ID: your fixed Chat ID (found in Part 3)
- Text: `scan started`

This node immediately confirms to the user that the scan has started. The `process.py` script continues running on its own in the background, writes `pid.txt` and updates `processed.csv` in `/tmp/workflow5/` for each file. When it finishes, it calls `workflow6/monitor.py --format md` internally and sends a second Telegram message with the final summary on its own, without going through n8n.

To receive this final notification, set `TELEGRAM_CHAT_ID` in the `.env` file:
```bash
TELEGRAM_CHAT_ID=123456789   # your Chat ID (found in Part 3)
```

> If you modify `.env` after the first startup, restart with: `docker compose down && docker compose up -d`

#### Workflow 6 - Scan monitoring (same structure as Workflow 2)

```
[Node 1 - Schedule Trigger]
  ↓
[Node 2 - HTTP Request: getUpdates]
  ↓
[Node 3 - Code: filter recent messages]
  ↓
[Node 4 - Switch]
  ├── /status branch → [Execute Command: monitor.py --format md] → [Node D - Telegram]
  └── fallback branch → [Node 5 - IF regex] → [Node 6 - Telegram]
```

> [Workflow diagram](../../mermaid/english/workflow6.mermaid)

Create a new workflow. The fastest way: copy the entire Workflow 2 (select all nodes - Ctrl+C - new workflow - Ctrl+V), then modify only the `/status` branch: delete Nodes B and C and replace them with an Execute Command node connected directly to Node D.

**Execute Command (/status branch):**
```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5 \
  --format md
```

The `--format md` flag makes `monitor.py` return the Markdown-formatted message directly. In **Node D** set the Text field to `{{ $json.stdout }}`.

---

### Security for file workflows (note for developers)

**Beware of path injection:** In Execute Command commands, file names come from the filesystem. Make sure to:

1. Not use `eval` or unnecessary shell expansion
2. Use absolute paths instead of relative ones
3. Limit the monitored folder to a specific one (not `/` or `/home`)
4. If using Docker, mount only the necessary folder, not the entire home

```yaml
# In docker-compose.yml: mount ONLY the necessary folder
volumes:
  - /home/user/Documents:/home/node/.n8n-files/workspace:z
  # DON'T do:
  # - /home/user:/home/user  # too permissive
```
