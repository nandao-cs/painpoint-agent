# run-founder-scout.ps1 — Founder Scout Agent (on-demand / scheduled).
# For each startup idea with no candidates yet, sources matching people via
# OpenMandate + Specter + Affinity + Hunter and writes them to the Notion
# Founder Candidates DB. SOURCE-ONLY: never contacts anyone, never touches Affinity-write.
# Bills the Claude subscription. Retries on socket drop.
$ErrorActionPreference = 'Continue'
$proj   = "C:\Users\fjmartins\painpoint-agent"
$claude = "C:\Users\fjmartins\.local\bin\claude.exe"
$log    = "C:\Users\fjmartins\Scripts\Logs\founder_scout.log"
function Log($m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content $log "[$ts] $m" -Encoding utf8 }

Log "===== FOUNDER SCOUT START ====="
Set-Location $proj
$env:ANTHROPIC_API_KEY = $null   # bill to subscription
$prompt = Get-Content -Raw "$proj\scripts\founder-scout-run.md"
$code = 1
for ($attempt = 1; $attempt -le 3; $attempt++) {
  if ($attempt -gt 1) { Log "RETRY $attempt/3 (prev exit=$code)"; Start-Sleep -Seconds 20 }
  $prompt | & $claude -p --permission-mode bypassPermissions --output-format text 2>&1 |
    ForEach-Object { Add-Content $log $_ -Encoding utf8 }
  $code = $LASTEXITCODE
  if ($code -eq 0) { break }
}
Log "===== FOUNDER SCOUT END exit=$code ====="
exit $code
