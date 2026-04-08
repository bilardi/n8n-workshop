# Telegram Bot Troubleshoot - PowerShell version
param(
    [string]$Token
)

# --- Token -------------------------------------------------------------------
if (-not $Token) {
    $Token = Read-Host "Enter your Telegram Bot Token"
}
if (-not $Token) {
    Write-Host "Error: token is required." -ForegroundColor Red
    Write-Host "Usage: .\troubleshoot.ps1 -Token <TELEGRAM_TOKEN>"
    exit 1
}

$TokenShort = "$($Token.Substring(0,6))...$($Token.Substring($Token.Length - 4))"

# --- Helpers ------------------------------------------------------------------
function Run-Cmd {
    param([string]$Cmd)
    Write-Host ""
    Write-Host "  $Cmd" -ForegroundColor Cyan
    Write-Host ""
    $answer = Read-Host "Execute? [y/N]"
    if ($answer -match '^[yY]$') {
        Write-Host ""
        Invoke-Expression $Cmd
        Write-Host ""
    }
}

# --- Menu ---------------------------------------------------------------------
while ($true) {
    Write-Host ""
    Write-Host "=== Telegram Bot Troubleshoot ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Token: $TokenShort"
    Write-Host ""
    Write-Host "  1) getMe               - verify token and bot name"
    Write-Host "  2) getWebhookInfo       - show webhook and allowed_updates"
    Write-Host "  3) deleteWebhook        - remove webhook (drop pending updates)"
    Write-Host "  4) getUpdates           - fetch latest messages (offset=-1)"
    Write-Host '  5) fix allowed_updates  - reset filter to ["message"] via getUpdates POST'
    Write-Host "  q) Quit"
    Write-Host ""
    $choice = Read-Host "Choose [1-5, q]"

    switch ($choice) {
        "1" {
            Run-Cmd "Invoke-RestMethod -Uri 'https://api.telegram.org/bot$Token/getMe' | ConvertTo-Json -Depth 5"
        }
        "2" {
            Run-Cmd "Invoke-RestMethod -Uri 'https://api.telegram.org/bot$Token/getWebhookInfo' | ConvertTo-Json -Depth 5"
        }
        "3" {
            Run-Cmd "Invoke-RestMethod -Uri 'https://api.telegram.org/bot$Token/deleteWebhook?drop_pending_updates=true' | ConvertTo-Json -Depth 5"
        }
        "4" {
            Run-Cmd "Invoke-RestMethod -Uri 'https://api.telegram.org/bot$Token/getUpdates?offset=-1' | ConvertTo-Json -Depth 5"
        }
        "5" {
            Run-Cmd "Invoke-RestMethod -Uri 'https://api.telegram.org/bot$Token/getUpdates' -Method Post -ContentType 'application/json' -Body '{`"allowed_updates`":[`"message`"]}' | ConvertTo-Json -Depth 5"
        }
        "q" {
            Write-Host "Bye!"
            exit 0
        }
        default {
            Write-Host "Invalid choice." -ForegroundColor Yellow
        }
    }
}
