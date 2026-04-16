# Telegram Bot Troubleshoot

Interactive script to diagnose and resolve the most common issues with the Telegram bot used in n8n workflows.

## When to use it

- `getUpdates` always returns `result: []` even after sending a message to the bot
- You want to verify that the token is correct and the bot responds
- You suspect that a webhook or `allowed_updates` filter is blocking messages

## Requirements

- The Telegram bot token (found in the `.env` file or from BotFather)
- `curl` and `python3` installed (Linux/macOS) or PowerShell (Windows)

## Usage

**Linux / macOS:**

```bash
./troubleshoot.sh <TELEGRAM_TOKEN>
```

**Windows (PowerShell):**

```powershell
.\troubleshoot.ps1 -Token <TELEGRAM_TOKEN>
```

If you don't pass the token as an argument, the script asks for it interactively.

## Menu

| Option | API Command | Purpose |
|---------|-------------|--------------|
| 1 | `getMe` | Verify that the token is valid and show the bot name |
| 2 | `getWebhookInfo` | Show if there's an active webhook and which `allowed_updates` are set |
| 3 | `deleteWebhook` | Remove the webhook and delete queued updates |
| 4 | `getUpdates` | Retrieve the latest messages received by the bot (offset=-1) |
| 5 | fix `allowed_updates` | Reset the filter to `["message"]` - fixes the case where the bot only receives "poll" type updates |

## Typical troubleshooting flow

1. **Option 1** - confirm that the token is correct and that the bot name matches the one you're writing to
2. **Option 2** - check `allowed_updates`: if it contains only `["poll"]`, messages are discarded
3. **Option 5** - reset the filter to `["message"]`
4. **Option 2** - verify that `allowed_updates` now contains `["message"]`
5. Send a message to the bot on Telegram
6. **Option 4** - verify that the message appears in `result`

## Most common issue

If you've used the **Telegram Trigger** node in n8n (even just once for testing), this can set `allowed_updates: ["poll"]` on the bot. From that point on `getUpdates` always returns `result: []` for normal messages. Option 5 of the script fixes this issue.
