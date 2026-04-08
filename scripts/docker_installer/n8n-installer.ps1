# install-n8n.ps1
# PowerShell script to configure and start n8n on Windows
# with Docker Desktop. Works on Windows 10/11 (Home, Pro, Education).
#
# How to use:
#   1. Right-click this file
#   2. Choose "Run with PowerShell"
#   (if prompted for confirmation, press Yes / Open)

# ─── Colors and helper functions ──────────────────────────────────────────────

function Write-Info    { param($text) Write-Host "  $text" -ForegroundColor Cyan }
function Write-Ok      { param($text) Write-Host "  [OK] $text" -ForegroundColor Green }
function Write-Err     { param($text) Write-Host "  [ERROR] $text" -ForegroundColor Red }
function Write-Warn    { param($text) Write-Host "  [!] $text" -ForegroundColor Yellow }
function Write-Title   {
    param($text)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
    Write-Host "  $text" -ForegroundColor White
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkCyan
}

function New-SecretKey {
    # Generates a random 40-character string (letters + digits)
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $key = -join (1..40 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    return $key
}

function Wait-Enter {
    Write-Host ""
    Write-Host "  Press ENTER to continue..." -ForegroundColor DarkGray
    $null = Read-Host
}

# Folder where this script lives (= extracted repository root)
$installDir = $PSScriptRoot

# ─── Welcome ───────────────────────────────────────────────────────────────────

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor DarkCyan
Write-Host "  ║         Guided n8n installation              ║" -ForegroundColor DarkCyan
Write-Host "  ║     Workflow automation on Windows           ║" -ForegroundColor DarkCyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor DarkCyan
Write-Host ""
Write-Info "This script configures and starts n8n on your computer."
Write-Info "No programming knowledge required: just answer a few questions."
Write-Host ""
Write-Info "Working directory: $installDir"
Write-Host ""
Write-Warn "Requirements to complete BEFORE running this script:"
Write-Warn "  1. Enable WSL2: open PowerShell as administrator and run: wsl --install"
Write-Warn "     then restart your computer when prompted."
Write-Warn "  2. Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
Write-Warn "     (choose the Windows version, make sure 'Use WSL2' is checked)"
Write-Warn "  3. Start Docker Desktop and wait for the whale icon to become stable."
Write-Host ""
Wait-Enter

# ─── STEP 1: Check Docker ─────────────────────────────────────────────────────

Write-Title "STEP 1 of 3 - Check Docker Desktop"

$dockerOk = $false
try {
    $version = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Docker found: $version"
        $dockerOk = $true
    }
} catch {
    $dockerOk = $false
}

if (-not $dockerOk) {
    Write-Err "Docker Desktop not found or not running."
    Write-Host ""
    Write-Info "What to do:"
    Write-Info "  1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/"
    Write-Info "  2. Install it and restart your computer"
    Write-Info "  3. Start Docker Desktop (whale icon in the system tray)"
    Write-Info "  4. Run this script again"
    Write-Host ""
    Wait-Enter
    exit 1
}

# Check that the Docker daemon is running
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Docker Desktop is installed but not running."
        Write-Info "Start Docker Desktop (search 'Docker Desktop' in the Start menu)"
        Write-Info "and wait for the whale icon to become stable, then run the script again."
        Wait-Enter
        exit 1
    }
} catch {
    Write-Err "Cannot communicate with Docker. Make sure Docker Desktop is running."
    Wait-Enter
    exit 1
}

Write-Ok "Docker Desktop is running."

# ─── STEP 2: Configuration ────────────────────────────────────────────────────

Write-Title "STEP 2 of 3 - Configuration"

# Port
Write-Host ""
Write-Info "n8n will be accessible from the browser at http://localhost:PORT"
Write-Info "The default port is 5678. Change it only if you know it is already in use."
$port = Read-Host "  Port (default 5678)"
if ([string]::IsNullOrWhiteSpace($port)) { $port = "5678" }

# Timezone
Write-Host ""
Write-Info "The timezone ensures workflows trigger at the correct local time."
$timezone = Read-Host "  Timezone (default Europe/Rome)"
if ([string]::IsNullOrWhiteSpace($timezone)) { $timezone = "Europe/Rome" }

# Encryption key
Write-Host ""
Write-Info "The encryption key protects passwords saved in n8n."
Write-Warn "Write it down and keep it safe: if you lose it, you will need to"
Write-Warn "re-enter all your credentials (email, Telegram, etc.)."
Write-Host ""
$generatedKey = New-SecretKey
Write-Host "  Auto-generated key:" -ForegroundColor White
Write-Host "  $generatedKey" -ForegroundColor Yellow
Write-Host ""
$keyChoice = Read-Host "  Use this key? (Y=Yes use this, N=enter my own, default Y)"

if ($keyChoice -match '^[Nn]') {
    $encryptionKey = Read-Host "  Enter your key (minimum 32 characters)"
    if ($encryptionKey.Length -lt 32) {
        Write-Warn "Key too short. The auto-generated key will be used instead."
        $encryptionKey = $generatedKey
    }
} else {
    $encryptionKey = $generatedKey
}

# ─── STEP 3: Write .env and start ─────────────────────────────────────────────

Write-Title "STEP 3 of 3 - Configuration and startup"

# Generate N8N_RUNNERS_AUTH_TOKEN (hex, 64 chars)
$runnersToken = -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) })

# Write .env with chosen values (full template matching .env.sample)
$envFile = Join-Path $installDir ".env"
@"
# .env - generated by install-n8n.ps1
# DO NOT share this file after filling it with your real keys

# Generate a secure random string:
#   Linux/macOS: openssl rand -hex 32
#   Windows PowerShell: -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
N8N_ENCRYPTION_KEY=$encryptionKey
N8N_PORT=$port
TIMEZONE=$timezone

# Telegram bot token (obtained from @BotFather).
# Required for the polling workflow that responds to bot commands.
TELEGRAM_TOKEN=
# Your Telegram account chat ID (found via getMe/getUpdates in Part 3 of the guide)
# TELEGRAM_CHAT_ID=123456789

# Path to the Downloads folder to monitor with the file-sorting workflow.
# Uncomment and replace with the real path to enable it.
# DOWNLOADS_PATH=C:\Users\YOUR_NAME\Downloads

# Host machine folder accessible inside n8n at /home/node/.n8n-files/workspace.
# Defaults to the ./workspace subfolder of the project.
# Uncomment to use a different folder.
# WORKSPACE_PATH=C:\Users\YOUR_NAME\Documents

# n8n REST API key - required for Workflow 8 (monitor) to query the n8n API.
# Generate it in n8n: Settings -> API -> Create an API Key
# N8N_API_KEY=your_api_key_here

# Shared secret between n8n and the task runner (required for Python in the Code node).
# Generate a secure random string, e.g.: openssl rand -hex 32
N8N_RUNNERS_AUTH_TOKEN=$runnersToken
"@ | Out-File -FilePath $envFile -Encoding UTF8 -Force
Write-Ok "Written: $envFile"

# Start n8n
Write-Host ""
Write-Info "Starting n8n with Docker Compose... (may take a few minutes the first time)"
Write-Host ""

Set-Location $installDir
$output = docker compose up -d 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Ok "n8n started successfully!"
} else {
    Write-Err "Something went wrong during startup."
    Write-Host ""
    Write-Host $output -ForegroundColor DarkGray
    Write-Host ""
    Write-Info "Try opening Docker Desktop and check for errors."
    Wait-Enter
    exit 1
}

# ─── Final result ─────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║         n8n started successfully!            ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Ok "n8n is available at:"
Write-Host ""
Write-Host "      http://localhost:$port" -ForegroundColor Yellow
Write-Host ""
Write-Info "To start n8n in the future, open PowerShell in this folder and run:"
Write-Info "    docker compose up -d"
Write-Host ""

# Automatically open the browser
$openBrowser = Read-Host "  Open n8n in the browser now? (Y/N, default Y)"
if ($openBrowser -notmatch '^[Nn]') {
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:$port"
}

Write-Host ""
Wait-Enter