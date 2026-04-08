#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Detect container name ----------------------------------------------------
detect_container() {
    local name
    name=$(docker compose -f "$SCRIPT_DIR/docker-compose.yml" ps -q n8n 2>/dev/null || true)
    if [[ -z "$name" ]]; then
        echo "Error: n8n container not found. Is it running?"
        echo "  docker compose -f $SCRIPT_DIR/docker-compose.yml up -d"
        exit 1
    fi
    echo "$name"
}

CONTAINER=$(detect_container)

# --- Helpers ------------------------------------------------------------------
run_cmd() {
    local cmd="$1"
    echo
    echo "  $cmd"
    echo
    read -rp "Execute? [y/N] " answer
    if [[ "$answer" =~ ^[yY]$ ]]; then
        echo
        eval "$cmd"
        echo
    fi
}

# --- Menu ---------------------------------------------------------------------
while true; do
    echo
    echo "=== Docker n8n Troubleshoot ==="
    echo
    echo "Container: $CONTAINER"
    echo
    echo "  1) check python3        - verify python3 is available in the container"
    echo "  2) run process.py       - scan workspace (foreground, for debugging)"
    echo "  3) run monitor.py       - check scan status (JSON)"
    echo "  4) run monitor.py --md  - check scan status (Markdown)"
    echo "  5) container logs       - show last 50 lines of n8n logs"
    echo "  6) shell                - open a shell inside the container"
    echo "  q) Quit"
    echo
    read -rp "Choose [1-6, q]: " choice

    case "$choice" in
        1)
            run_cmd "docker exec $CONTAINER python3 --version"
            ;;
        2)
            run_cmd "docker exec $CONTAINER python3 /home/node/.n8n-files/scripts/workflow5/process.py --path /home/node/.n8n-files/workspace --interval 1"
            ;;
        3)
            run_cmd "docker exec $CONTAINER python3 /home/node/.n8n-files/scripts/workflow6/monitor.py --path /home/node/.n8n-files/workspace --data /tmp/workflow5"
            ;;
        4)
            run_cmd "docker exec $CONTAINER python3 /home/node/.n8n-files/scripts/workflow6/monitor.py --path /home/node/.n8n-files/workspace --data /tmp/workflow5 --format md"
            ;;
        5)
            run_cmd "docker compose -f $SCRIPT_DIR/docker-compose.yml logs --tail 50 n8n"
            ;;
        6)
            run_cmd "docker exec -it $CONTAINER /bin/sh"
            ;;
        q|Q)
            echo "Bye!"
            exit 0
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
