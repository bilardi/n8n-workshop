#!/usr/bin/env bash
set -euo pipefail

# --- Token -------------------------------------------------------------------
TELEGRAM_TOKEN="${1:-}"
if [[ -z "$TELEGRAM_TOKEN" ]]; then
    read -rp "Enter your Telegram Bot Token: " TELEGRAM_TOKEN
fi
if [[ -z "$TELEGRAM_TOKEN" ]]; then
    echo "Error: token is required."
    echo "Usage: $0 <TELEGRAM_TOKEN>"
    exit 1
fi

TOKEN_SHORT="${TELEGRAM_TOKEN:0:6}...${TELEGRAM_TOKEN: -4}"

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
    echo "=== Telegram Bot Troubleshoot ==="
    echo
    echo "Token: $TOKEN_SHORT"
    echo
    echo "  1) getMe               - verify token and bot name"
    echo "  2) getWebhookInfo       - show webhook and allowed_updates"
    echo "  3) deleteWebhook        - remove webhook (drop pending updates)"
    echo "  4) getUpdates           - fetch latest messages (offset=-1)"
    echo "  5) fix allowed_updates  - reset filter to [\"message\"] via getUpdates POST"
    echo "  q) Quit"
    echo
    read -rp "Choose [1-5, q]: " choice

    case "$choice" in
        1)
            run_cmd "curl -s https://api.telegram.org/bot${TELEGRAM_TOKEN}/getMe | python3 -m json.tool"
            ;;
        2)
            run_cmd "curl -s https://api.telegram.org/bot${TELEGRAM_TOKEN}/getWebhookInfo | python3 -m json.tool"
            ;;
        3)
            run_cmd "curl -s 'https://api.telegram.org/bot${TELEGRAM_TOKEN}/deleteWebhook?drop_pending_updates=true' | python3 -m json.tool"
            ;;
        4)
            run_cmd "curl -s 'https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates?offset=-1' | python3 -m json.tool"
            ;;
        5)
            run_cmd "curl -s -X POST 'https://api.telegram.org/bot${TELEGRAM_TOKEN}/getUpdates' -H 'Content-Type: application/json' -d '{\"allowed_updates\":[\"message\"]}' | python3 -m json.tool"
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
