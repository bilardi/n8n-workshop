# n8n Guide - Download and upload workflows
## Move your workflows from one instance to another

---

## Table of contents

1. [From the n8n interface](#from-the-n8n-interface)
2. [From Docker CLI](#from-docker-cli)
3. [From REST API](#from-rest-api)
4. [What gets exported and what doesn't](#what-gets-exported-and-what-doesnt)
5. [Official resources](#official-resources)

---

## From the n8n interface

### Export a workflow

1. Open the workflow you want to export
2. Click the **⋮** menu (three dots) in the top right corner
3. Select **Download**
4. The browser downloads a `.json` file named after the workflow

The file contains the full definition: nodes, connections, settings, and node positions on the canvas.

> The interface does not support downloading multiple workflows at once: for bulk export see [Docker CLI](#from-docker-cli) or [REST API](#from-rest-api).

### Import from file

1. Open the target instance in the browser
2. Create a new workflow: top left menu → **Create workflow**
3. In the empty workflow, click the **...** (three dots) menu in the top right corner
4. Select **Import from File**
5. Choose the `.json` file downloaded earlier
6. The nodes appear on the canvas: check that everything is connected correctly
7. Click **Save**

### Import from URL

If the JSON file is accessible via URL (e.g. a direct link from a repository or a server):

1. Create a new workflow
2. Menu **...** → **Import from URL**
3. Paste the URL of the `.json` file
4. Check and save

---

## From Docker CLI

Self-hosted only. Commands must be run on the already running n8n container.

> In the examples the container name is `docker_installer-n8n-1` (default from this project's `docker-compose.yml`). Replace it with your container name; you can find it with `docker ps`.

### Export all workflows

Save the workflows inside the container:

```bash
docker exec docker_installer-n8n-1 n8n export:workflow --all \
  --output=/tmp/all-workflows.json
```

Then copy the file to the host:

```bash
docker cp docker_installer-n8n-1:/tmp/all-workflows.json ./downloads/
```

To export one `.json` file per workflow:

```bash
docker exec docker_installer-n8n-1 sh -c "mkdir -p /tmp/workflows && n8n export:workflow --all --separate --output=/tmp/workflows/"
docker cp docker_installer-n8n-1:/tmp/workflows/. ./downloads/
```

> `--all` exports all workflows, including archived ones. For a readable backup already split into separate files, use `--backup` instead of `--all --separate`:
>
> ```bash
> docker exec docker_installer-n8n-1 sh -c "mkdir -p /tmp/workflows && n8n export:workflow --backup --output=/tmp/workflows/"
> ```

### Import a workflow

Copy the file into the container and import:

```bash
docker cp ./downloads/workflow.json docker_installer-n8n-1:/tmp/workflow.json
docker exec docker_installer-n8n-1 n8n import:workflow --input=/tmp/workflow.json
```

---

## From REST API

For those who want to automate the export, n8n exposes a REST API.

### Export a workflow

The workflow ID is in the URL when you open it in the editor: `http://localhost:5678/workflow/abcdefgABCDEFG`. The last part is the ID.

```bash
cd n8n
export $(grep -v '^#' scripts/docker_installer/.env | xargs)
export WORKFLOW_ID=abcdefgABCDEFG
curl -H "X-N8N-API-KEY: $N8N_API_KEY" \
  http://localhost:5678/api/v1/workflows/$WORKFLOW_ID \
  -o workflow.json
```

### Import a workflow

```bash
curl -X POST -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflow.json \
  http://localhost:5678/api/v1/workflows
```

> To enable the REST API on a self-hosted installation, you need `N8N_API_KEY` in the `.env` file and in the `environment:` block of `docker-compose.yml`: see the [Docker guide](../docker/english.md).

---

## What gets exported and what doesn't

| Included in the JSON file | Not included |
|---------------------------|--------------|
| Nodes and connections | Credentials (tokens, passwords, API keys) |
| Workflow settings | Environment variables (`$env.*`) |
| Node positions on the canvas | Execution history |
| Sticky notes | Tags assigned to the workflow |

**After importing, you need to:**
- Recreate **credentials** on the target instance (Telegram, Gmail, Outlook, etc.) and reassign them to nodes: each node using a credential will show a warning until you select a valid one
- Verify that **environment variables** exist on the new instance (e.g. `TELEGRAM_TOKEN`, `N8N_API_KEY` in `.env` and `docker-compose.yml`)
- Check **file paths**: if the workflow uses Read/Write File or Execute Command nodes with absolute paths (e.g. `/home/node/.n8n-files/scripts/`), make sure the folder structure is the same

---

## Official resources

- [n8n Docs: Import/Export](https://docs.n8n.io/workflows/export-import/)
- [n8n REST API](https://docs.n8n.io/api/api-reference/)
