#!/usr/bin/env bash
# install-n8n.sh
# Interactive script to configure and start n8n on Linux and macOS
# with Docker Desktop (or Docker Engine on Linux).
#
# How to use:
#   chmod +x install-n8n.sh
#   ./install-n8n.sh

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

info()  { echo -e "  ${CYAN}$*${NC}"; }
ok()    { echo -e "  ${GREEN}[OK]${NC} $*"; }
err()   { echo -e "  ${RED}[ERROR]${NC} $*"; }
warn()  { echo -e "  ${YELLOW}[!]${NC} $*"; }
title() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}$*${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

wait_enter() {
    echo ""
    echo -e "  ${GRAY}Press ENTER to continue...${NC}"
    read -r
}

new_secret_key() {
    # Generates 40 random alphanumeric characters (compatible with Linux and macOS).
    # pipefail is temporarily disabled because head closes the pipe after 40
    # characters, causing SIGPIPE on tr, which would exit the script with pipefail on.
    set +o pipefail
    LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 40
    set -o pipefail
}

# Detect the operating system
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "other" ;;
    esac
}

# Open URL in the browser (compatible with Linux and macOS)
open_browser() {
    local url="$1"
    local os
    os=$(detect_os)
    case "$os" in
        macos) open "$url" ;;
        linux) xdg-open "$url" 2>/dev/null || true ;;
    esac
}

# Folder where this script lives (= extracted repository root)
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Welcome ───────────────────────────────────────────────────────────────────

clear
echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║         Guided n8n installation              ║${NC}"
echo -e "${CYAN}  ║   Workflow automation on Linux/macOS         ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════════════╝${NC}"
echo ""

OS=$(detect_os)
if [ "$OS" = "macos" ]; then
    info "Detected system: macOS"
elif [ "$OS" = "linux" ]; then
    info "Detected system: Linux"
fi

echo ""
info "This script configures and starts n8n on your computer."
info "No programming knowledge required: just answer a few questions."
echo ""
info "Working directory: $INSTALL_DIR"
echo ""
warn "Requirement: Docker Desktop must be installed and running before proceeding."
warn "If you don't have it yet: https://www.docker.com/products/docker-desktop/"
echo ""
wait_enter

# ─── STEP 1: Check Docker ─────────────────────────────────────────────────────

title "STEP 1 of 3 - Check Docker"

# Check that docker is in PATH
if ! command -v docker &>/dev/null; then
    err "The 'docker' command was not found."
    echo ""
    if [ "$OS" = "linux" ]; then
        info "Install Docker with your distribution's package manager:"
        info "  Debian/Ubuntu:   sudo apt-get install docker.io docker-compose-plugin"
        info "  Fedora/RHEL:     sudo dnf install docker docker-compose-plugin"
        info "Or install Docker Desktop: https://www.docker.com/products/docker-desktop/"
        info "Then run this script again."
    elif [ "$OS" = "macos" ]; then
        if command -v brew &>/dev/null; then
            echo ""
            read -rp "  Homebrew is available. Install Docker Desktop via brew? (Y/N, default Y): " brew_answer
            brew_answer="${brew_answer:-Y}"
            if [[ "$brew_answer" =~ ^[Yy]$ ]]; then
                info "Installing Docker Desktop..."
                brew install --cask docker-desktop
                ok "Docker Desktop installed."
                warn "Launch Docker Desktop from the Applications folder and wait"
                warn "for the whale icon in the menu bar to become stable."
                warn "Then run this script again."
                wait_enter
                exit 0
            fi
        fi
        info "Download Docker Desktop from: https://www.docker.com/products/docker-desktop/"
        info "Choose the Apple Silicon (M1/M2/M3) or Intel version depending on your Mac."
        info "Then run this script again."
    fi
    wait_enter
    exit 1
fi

DOCKER_VERSION=$(docker --version 2>&1)
ok "Docker found: $DOCKER_VERSION"

# Check that the Docker daemon is running
if ! docker info &>/dev/null; then
    err "Docker is installed but not running."
    echo ""
    if [ "$OS" = "macos" ]; then
        info "Open Docker Desktop from the Applications folder and wait"
        info "for the whale icon in the menu bar to become stable."
    elif [ "$OS" = "linux" ]; then
        info "Start the Docker service with:"
        info "  sudo systemctl start docker"
        info "To start it automatically at boot:"
        info "  sudo systemctl enable docker"
    fi
    info "Then run this script again."
    wait_enter
    exit 1
fi

ok "Docker is running."

# Check Docker Compose (plugin v2: 'docker compose', or legacy v1: 'docker-compose')
COMPOSE_CMD=""
if docker compose version &>/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    err "Docker Compose not found."
    echo ""
    if [ "$OS" = "linux" ]; then
        info "Install Docker Compose with:"
        info "  sudo apt-get install docker-compose-plugin -y"
    elif [ "$OS" = "macos" ]; then
        info "Docker Compose is bundled with Docker Desktop."
        info "Update Docker Desktop to the latest version."
    fi
    wait_enter
    exit 1
fi

ok "Docker Compose found (command: $COMPOSE_CMD)."

# ─── STEP 2: Configuration ────────────────────────────────────────────────────

title "STEP 2 of 3 - Configuration"

# Port
echo ""
info "n8n will be accessible from the browser at http://localhost:PORT"
info "The default port is 5678. Change it only if you know it is already in use."
read -rp "  Port (default 5678): " PORT
PORT="${PORT:-5678}"

# Timezone
echo ""
info "The timezone ensures workflows trigger at the correct local time."
# Try to detect the system timezone
DETECTED_TZ=""
if [ "$OS" = "macos" ]; then
    DETECTED_TZ=$(readlink /etc/localtime | sed 's|/var/db/timezone/zoneinfo/||')
elif [ -f /etc/timezone ]; then
    DETECTED_TZ=$(cat /etc/timezone)
elif [ -L /etc/localtime ]; then
    DETECTED_TZ=$(readlink /etc/localtime | sed 's|.*zoneinfo/||')
fi
DEFAULT_TZ="${DETECTED_TZ:-Europe/Rome}"
info "Detected timezone: $DEFAULT_TZ"
read -rp "  Timezone (default $DEFAULT_TZ): " TIMEZONE
TIMEZONE="${TIMEZONE:-$DEFAULT_TZ}"

# Encryption key
echo ""
info "The encryption key protects passwords saved in n8n."
warn "Write it down and keep it safe: if you lose it, you will need to"
warn "re-enter all your credentials (email, Telegram, etc.)."
echo ""
GENERATED_KEY=$(new_secret_key)
echo -e "  Auto-generated key:"
echo -e "  ${YELLOW}$GENERATED_KEY${NC}"
echo ""
read -rp "  Use this key? (Y=Yes use this, N=enter my own, default Y): " key_answer
key_answer="${key_answer:-Y}"

if [[ "$key_answer" =~ ^[Nn]$ ]]; then
    read -rp "  Enter your key (minimum 32 characters): " ENCRYPTION_KEY
    if [ ${#ENCRYPTION_KEY} -lt 32 ]; then
        warn "Key too short. The auto-generated key will be used instead."
        ENCRYPTION_KEY="$GENERATED_KEY"
    fi
else
    ENCRYPTION_KEY="$GENERATED_KEY"
fi

# ─── STEP 3: Write .env and start ─────────────────────────────────────────────

title "STEP 3 of 3 - Configuration and startup"

# Generate N8N_RUNNERS_AUTH_TOKEN (hex, 64 chars)
if command -v openssl &>/dev/null; then
    RUNNERS_TOKEN=$(openssl rand -hex 32)
else
    # Fallback: use /dev/urandom
    set +o pipefail
    RUNNERS_TOKEN=$(LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | head -c 64)
    set -o pipefail
fi

# Write .env with chosen values (full template matching .env.sample)
cat > "$INSTALL_DIR/.env" <<EOF
# .env - generated by install-n8n.sh
# DO NOT share this file after filling it with your real keys

# Generate a secure random string:
#   Linux/macOS: openssl rand -hex 32
#   Windows PowerShell: -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
N8N_ENCRYPTION_KEY=${ENCRYPTION_KEY}
N8N_PORT=${PORT}
TIMEZONE=${TIMEZONE}

# Telegram bot token (obtained from @BotFather).
# Required for the polling workflow that responds to bot commands.
TELEGRAM_TOKEN=
# Your Telegram account chat ID (found via getMe/getUpdates in Part 3 of the guide)
# TELEGRAM_CHAT_ID=123456789

# Path to the Downloads folder to monitor with the file-sorting workflow.
# Uncomment and replace with the real path to enable it.
# DOWNLOADS_PATH=/home/YOUR_USER/Downloads

# Host machine folder accessible inside n8n at /home/node/.n8n-files/workspace.
# Defaults to the ./workspace subfolder of the project.
# Uncomment to use a different folder.
# WORKSPACE_PATH=/home/YOUR_USER/Documents

# n8n REST API key - required for Workflow 8 (monitor) to query the n8n API.
# Generate it in n8n: Settings → API → Create an API Key
# N8N_API_KEY=your_api_key_here

# Shared secret between n8n and the task runner (required for Python in the Code node).
# Generate a secure random string, e.g.: openssl rand -hex 32
N8N_RUNNERS_AUTH_TOKEN=${RUNNERS_TOKEN}
EOF
chmod 600 "$INSTALL_DIR/.env"
ok "Written: $INSTALL_DIR/.env"

# Start n8n
echo ""
info "Starting n8n with Docker Compose... (first run downloads the image, may take a few minutes)"
echo ""

cd "$INSTALL_DIR"
if $COMPOSE_CMD up -d; then
    ok "n8n started successfully!"
else
    err "Something went wrong during startup."
    echo ""
    info "Check the logs with:  $COMPOSE_CMD logs"
    info "Or try running the script again."
    wait_enter
    exit 1
fi

# ─── Final result ─────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}  ╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║         n8n started successfully!            ║${NC}"
echo -e "${GREEN}  ╚══════════════════════════════════════════════╝${NC}"
echo ""
ok "n8n is available at:"
echo ""
echo -e "      ${YELLOW}http://localhost:${PORT}${NC}"
echo ""
info "To start n8n in the future, open a Terminal in this folder and run:"
info "    $COMPOSE_CMD up -d"
echo ""

read -rp "  Open n8n in the browser now? (Y/N, default Y): " open_answer
open_answer="${open_answer:-Y}"
if [[ "$open_answer" =~ ^[Yy]$ ]]; then
    sleep 2
    open_browser "http://localhost:${PORT}"
fi

echo ""
wait_enter