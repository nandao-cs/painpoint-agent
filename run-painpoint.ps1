# run-painpoint.ps1 — unattended Pain Point Discovery pipeline (Task Scheduler entry).
# 1. scrape enabled sources -> raw_posts
# 2. headless Claude pass: discovery -> score -> report -> thesis (+Readwise+Notion) -> graph
# Retries the Claude pass up to 3x on the transient socket error. Bills to the
# Claude subscription. Logs to Scripts\Logs\painpoint_agent.log.

$ErrorActionPreference = 'Continue'
$proj   = "C:\Users\fjmartins\painpoint-agent"
$claude = "C:\Users\fjmartins\.local\bin\claude.exe"
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
$log    = "C:\Users\fjmartins\Scripts\Logs\painpoint_agent.log"
function Log($m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content $log "[$ts] $m" }

Log "===== PAINPOINT RUN START ====="
Set-Location $proj

# --- 1. scrape (public sources always; Reddit only if creds in .env) ---
Log "scrape: pulling sources..."
& $python "$proj\scripts\scrape.py" 2>&1 | ForEach-Object { Add-Content $log $_ }
Log "scrape: done"

# --- 1b. refresh AI x security pain-velocity radar (feeds Phase 2.6) ---
Log "ai_trends: computing..."
& $python "$proj\scripts\ai_trends.py" 2>&1 | ForEach-Object { Add-Content $log $_ }
Log "ai_trends: done"

# --- 2. headless pipeline pass (discovery -> thesis -> graph), with retry ---
$env:ANTHROPIC_API_KEY = $null   # bill to subscription
$prompt = Get-Content -Raw "$proj\scripts\pipeline-run.md"
$maxAttempts = 3; $code = 1
for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
  if ($attempt -gt 1) { Log "RETRY $attempt/$maxAttempts (previous exitcode=$code)"; Start-Sleep -Seconds 20 }
  try {
    $prompt | & $claude -p --permission-mode bypassPermissions --output-format text 2>&1 |
      ForEach-Object { Add-Content $log $_ }
    $code = $LASTEXITCODE
  } catch { Log "ERROR attempt=$attempt : $($_.Exception.Message)"; $code = 1 }
  Log "pipeline attempt=$attempt exitcode=$code"
  if ($code -eq 0) { break }
}
Log "===== PAINPOINT RUN END exitcode=$code ====="
exit $code
