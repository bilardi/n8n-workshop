# Installing n8n with Docker

## Table of Contents

1. [Download the repository](#first-of-all-download-the-repository)
2. [Why Docker](#recommended-method-docker)
3. [Windows](#docker-installation-windows)
4. [Linux and macOS](#docker-installation-linux-and-macos)
5. [Reading local files from workflows](#reading-local-files-from-workflows)
6. [WEBHOOK_URL: local vs server usage](#webhook_url-local-vs-server-usage)
7. [N8N_ENCRYPTION_KEY](#n8n_encryption_key-what-to-put)
8. [Backup and restore](#backup-and-restore)
9. [Troubleshoot](#troubleshoot)

---

## First of all: download the repository

Whatever system you use (Windows, Linux or macOS), the first step is always the same:

1. Download this repository as a **ZIP** ("Code - Download ZIP" button on GitHub)
2. Extract it to the folder you prefer
3. All necessary files (`docker-compose.yml`, `.env`, scripts) are already there

---

## Recommended method: Docker

**Docker is the simplest and recommended way** to install n8n, especially if you want to:
- Use it on multiple computers
- Share it with colleagues
- Not worry about installing dependencies (Node.js, etc.)
- Update and backup easily

**Why is Docker better than direct installation?**
- Works the same way on Windows, Mac and Linux
- Doesn't "pollute" your system with various packages
- One command to start, one to stop
- Data is safe in a separate volume

---

## Docker Installation: Windows

### Prerequisites

These three steps must be completed **in the order shown** before using any script or command.

**1. Enable WSL2**

Open PowerShell as administrator (search for "PowerShell" in the Start menu, right-click - "Run as administrator") and type:

```powershell
wsl --install
```

Restart the computer when prompted. WSL2 is the Linux engine that Docker relies on in Windows.

**2. Install Docker Desktop**

Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) and install. During installation make sure the **"Use WSL2 instead of Hyper-V"** option is checked.

**3. Start Docker Desktop**

Open Docker Desktop from the Start menu and wait until the whale icon in the taskbar becomes **stable** (stops animating). Only then is Docker ready.

> **Note:** Docker Desktop already includes **Docker Compose**: no need to install anything separately. It works on Windows 10/11 Home, Pro and Education.

---

### Option A: Guided script for non-programmers (recommended)

If you're not familiar with the command line, use the PowerShell script included in this guide: **`n8n-installer.ps1`**.

**How to use it:**
1. In the extracted folder, **right-click** on the file `scripts/docker_installer/n8n-installer.ps1`
2. Choose **"Run with PowerShell"**
3. If a security warning appears, click **"Open"** or **"Yes"**
4. Follow the on-screen instructions: you only need to answer a few simple questions

The script automatically:
- Verifies that Docker Desktop is installed and running
- Asks for port, timezone and encryption key
- Generates a security key to protect your credentials
- Creates the `.env` file with the configuration
- Starts n8n and opens the browser

> **First startup:** the first time Docker downloads the n8n image (~500 MB). It may take a few minutes. Subsequent startups are instant.

---

### Option B: Manual startup with Docker Compose

1. Open the `.env` file with Notepad and fill in at least the `N8N_ENCRYPTION_KEY` and `TELEGRAM_TOKEN` fields as suggested in the file's comments
2. Open **PowerShell** in the `scripts/docker_installer` folder (right-click on the folder - "Open in PowerShell") and type:

```powershell
docker compose up -d
```

Open the browser at: **http://localhost:5678**

> **Important:** The key in `.env` encrypts your credentials saved in n8n. Write it down in a safe place: if you lose it, you'll need to re-enter all credentials (email, Telegram, etc.).

> If you modify `.env` after the first startup, restart with: `docker compose down && docker compose up -d`

---

## Docker Installation: Linux and macOS

### Option A: Guided script for non-programmers (recommended)

Use the bash script included in this guide: **`n8n-installer.sh`**.

**How to use it:**
```bash
# From the extracted folder
bash scripts/docker_installer/n8n-installer.sh
```

The script:
- Automatically detects the operating system (Linux or macOS)
- If Docker is not present, shows the installation commands for your distribution and guides to Docker Desktop download
- Detects the system timezone and proposes it as default
- Generates a random security key
- Writes `.env` and starts n8n from the `scripts/docker_installer/` folder
- Opens the browser at the end

---

### Option B: Manual startup with Docker Compose

**On Linux**, if Docker is not installed, use your distribution's package manager:

```bash
# Debian/Ubuntu
sudo apt-get install docker.io docker-compose-plugin

# Fedora/RHEL
sudo dnf install docker docker-compose-plugin
```

**On macOS**, install Docker Desktop in one of two ways:

- With **Homebrew** (if already installed): `brew install --cask docker-desktop`
- Manually: download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/), choosing the version for **Apple Silicon** (M1/M2/M3) or **Intel**

After installation, launch Docker Desktop from the Applications folder and wait until the whale icon in the top bar becomes stable.

Then, for both systems:

1. Open the `.env` file with a text editor and fill in at least the `N8N_ENCRYPTION_KEY` and `TELEGRAM_TOKEN` fields as suggested in the file's comments
2. Open the **Terminal** in the `scripts/docker_installer` folder and type:

```bash
docker compose up -d
```

> **How to open Terminal in the right folder on macOS:** open Finder, go to the `scripts/docker_installer` folder, then drag the folder onto the Terminal icon in the Dock. Alternatively: `right-click on folder - New Terminal at Folder` (visible if you've enabled this option in System Preferences - Keyboard - Keyboard Shortcuts - Services).

Open the browser at: **http://localhost:5678**

> If you modify `.env` after the first startup, restart with: `docker compose down && docker compose up -d`

---

## Reading local files from workflows

By default n8n runs in an isolated Docker container: it cannot access your computer's files. To make a folder accessible, simply set `WORKSPACE_PATH` in the `.env` file:

```bash
# .env
WORKSPACE_PATH=/home/mario/documents
```

Files in that folder will be accessible in n8n at the path `/home/node/.n8n-files/workspace`. The included `docker-compose.yml` handles this automatically.

If you don't set `WORKSPACE_PATH`, the `./workspace` subfolder of the repository is mounted (included in the project as an empty folder ready to use).

> If you modify `.env` after the first startup, restart with: `docker compose down && docker compose up -d`

---

## WEBHOOK_URL: local vs server usage

Locally n8n uses `http://localhost:5678` as the address for webhooks - this works for HTTP Request nodes and generic webhooks, but **not** for the Telegram Trigger, which requires an HTTPS URL reachable from the internet.

If you install n8n on a public server with HTTPS (e.g. behind a reverse proxy with certificate), add in `.env`:

```bash
WEBHOOK_URL=https://n8n.yourdomain.com
```

Locally you don't need to set this variable - the Docker guide workflows use polling (Schedule + HTTP Request) precisely because `localhost` is not reachable by Telegram.

---

## N8N_ENCRYPTION_KEY: what to put

It's a password that n8n uses to encrypt your credentials (email, Telegram token, etc.) in the database. It must be a random string of **at least 32 characters**. The precise content doesn't matter: what matters is that it's long, random, and that you keep it safe.

**How to generate it:**

```bash
# Linux / macOS
openssl rand -hex 32
```

```powershell
# Windows PowerShell
-join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
```

Both commands produce a 64-character hexadecimal string, suitable as a key.

The `n8n-installer.ps1` and `n8n-installer.sh` scripts generate it automatically. If you configure `.env` manually, replace the placeholder value with a string generated as above.

---

## Backup and restore

n8n saves workflows, credentials and settings in the Docker volume `n8n_data`, separate from project files. Your scripts and `.env` are already in the repository folder, just copy them. The volume, however, must be exported explicitly.

### Backup

```bash
# Export the n8n_data volume to a compressed archive
docker run --rm -v n8n_data:/data -v "$(pwd)":/backup alpine \
  tar czf /backup/n8n_backup.tar.gz -C /data .
```

The `n8n_backup.tar.gz` file is created in the current folder. Keep it together with the `.env` (which contains the encryption key, without which saved credentials cannot be recovered).

### Restore

```bash
# Recreate the volume from backup (overwrites existing data)
docker run --rm -v n8n_data:/data -v "$(pwd)":/backup alpine \
  sh -c "cd /data && tar xzf /backup/n8n_backup.tar.gz"
```

After restoring, restart n8n: `docker compose up -d`

> **Note:** The backup includes only n8n data (workflows, credentials, settings). Files in the `downloads/`, `workspace/` and `scripts/` folders already live outside the volume: back them up separately if needed.

> **On Windows** replace `"$(pwd)"` with `${PWD}` in PowerShell, or use the full folder path (e.g. `C:\Users\Mario\backup`).

---

## Troubleshoot

Interactive script to diagnose and resolve the most common issues with the n8n Docker installation.

### When to use it

- You want to verify that Python is available in the container (required for Workflows 5 and 6)
- You want to run `process.py` or `monitor.py` in the foreground to see any errors
- You want to check the n8n container logs

### Requirements

- Docker Desktop running
- The n8n container started with `docker compose up -d`

### Usage

**Linux / macOS:**

```bash
./troubleshoot.sh
```

**Windows (PowerShell):**

```powershell
.\troubleshoot.ps1
```

The script automatically detects the n8n container from the `docker-compose.yml`.

### Menu

| Option | Command | Purpose |
|---------|---------|--------------|
| 1 | `python3 --version` | Verify that Python is installed in the container (custom Dockerfile) |
| 2 | `process.py` | Run the scan in the foreground - useful for seeing permission or path errors |
| 3 | `monitor.py` | Show scan status in JSON format |
| 4 | `monitor.py --format md` | Show scan status in Markdown format (as Telegram would see it) |
| 5 | `logs` | Show the last 50 lines of n8n container logs |
| 6 | `shell` | Open an interactive shell inside the container |

### Typical troubleshooting flow

1. **Option 1** - if it fails, the custom Dockerfile was not applied: rebuild with `docker compose up -d --build`
2. **Option 2** - runs `process.py` in the foreground: errors appear directly in the terminal (e.g. `PermissionError`, `FileNotFoundError`)
3. **Option 4** - verify that `monitor.py` produces the expected Markdown message
4. **Option 5** - check logs if n8n doesn't start or behaves abnormally

### Common issues

| Issue | Cause | Solution |
|----------|-------|-----------|
| `python3: not found` | Standard n8n image without Python | Use the custom Dockerfile and rebuild with `--build` |
| `PermissionError` on `pid.txt` or `processed.csv` | Script was trying to write in the scripts volume (read-only) | Scripts now write to `/tmp/workflow5/` (already fixed) |
| `Folder not found` | `WORKSPACE_PATH` not set or wrong path | Check `.env` and restart the container |
