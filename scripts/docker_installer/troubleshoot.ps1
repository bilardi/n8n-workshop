# Docker n8n Troubleshoot - PowerShell version

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Detect container name ----------------------------------------------------
$Container = docker compose -f "$ScriptDir\docker-compose.yml" ps -q n8n 2>$null
if (-not $Container) {
    Write-Host "Error: n8n container not found. Is it running?" -ForegroundColor Red
    Write-Host "  docker compose -f $ScriptDir\docker-compose.yml up -d"
    exit 1
}

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
    Write-Host "=== Docker n8n Troubleshoot ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Container: $Container"
    Write-Host ""
    Write-Host "  1) check python3        - verify python3 is available in the container"
    Write-Host "  2) run process.py       - scan workspace (foreground, for debugging)"
    Write-Host "  3) run monitor.py       - check scan status (JSON)"
    Write-Host "  4) run monitor.py --md  - check scan status (Markdown)"
    Write-Host "  5) container logs       - show last 50 lines of n8n logs"
    Write-Host "  6) shell                - open a shell inside the container"
    Write-Host "  q) Quit"
    Write-Host ""
    $choice = Read-Host "Choose [1-6, q]"

    switch ($choice) {
        "1" {
            Run-Cmd "docker exec $Container python3 --version"
        }
        "2" {
            Run-Cmd "docker exec $Container python3 /home/node/.n8n-files/scripts/workflow5/process.py --path /home/node/.n8n-files/workspace --interval 1"
        }
        "3" {
            Run-Cmd "docker exec $Container python3 /home/node/.n8n-files/scripts/workflow6/monitor.py --path /home/node/.n8n-files/workspace --data /tmp/workflow5"
        }
        "4" {
            Run-Cmd "docker exec $Container python3 /home/node/.n8n-files/scripts/workflow6/monitor.py --path /home/node/.n8n-files/workspace --data /tmp/workflow5 --format md"
        }
        "5" {
            Run-Cmd "docker compose -f $ScriptDir\docker-compose.yml logs --tail 50 n8n"
        }
        "6" {
            Run-Cmd "docker exec -it $Container /bin/sh"
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
