# run-daily-sequence.ps1 — daily, in strict order:
#   1. painpoint agent  → discovers pain points, scores theses, refreshes the map
#   2. startup ideation → reads fresh theses, publishes startup ideas
#   3. founder scout    → finds people matching each new idea's Founder Profile
# Each stage depends on the previous one's output. Each sub-launcher already
# retries on socket drop and bills the subscription.
$ErrorActionPreference = 'Continue'
$proj = "C:\Users\fjmartins\painpoint-agent"
$log  = "C:\Users\fjmartins\Scripts\Logs\daily_sequence.log"
function Log($m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content $log "[$ts] $m" -Encoding utf8 }

Log "================ DAILY SEQUENCE START ================"

Log ">>> STEP 1/3 painpoint agent"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$proj\run-painpoint.ps1"
Log "<<< STEP 1/3 painpoint exit=$LASTEXITCODE"

Log ">>> STEP 2/3 startup ideation agent"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$proj\run-ideas.ps1"
Log "<<< STEP 2/3 ideas exit=$LASTEXITCODE"

Log ">>> STEP 3/3 founder scout agent"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$proj\run-founder-scout.ps1"
Log "<<< STEP 3/3 founder-scout exit=$LASTEXITCODE"

Log "================ DAILY SEQUENCE END ================"
