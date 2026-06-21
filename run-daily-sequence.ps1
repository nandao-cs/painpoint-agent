# run-daily-sequence.ps1 — daily: painpoint agent, THEN startup ideation agent.
# Ideas depend on fresh theses, so they run strictly after the painpoint pass.
# Each sub-launcher already retries on socket drop and bills the subscription.
$ErrorActionPreference = 'Continue'
$proj = "C:\Users\fjmartins\painpoint-agent"
$log  = "C:\Users\fjmartins\Scripts\Logs\daily_sequence.log"
function Log($m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content $log "[$ts] $m" -Encoding utf8 }

Log "================ DAILY SEQUENCE START ================"

Log ">>> STEP 1/2 painpoint agent"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$proj\run-painpoint.ps1"
Log "<<< STEP 1/2 painpoint exit=$LASTEXITCODE"

Log ">>> STEP 2/2 startup ideation agent"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$proj\run-ideas.ps1"
Log "<<< STEP 2/2 ideas exit=$LASTEXITCODE"

Log "================ DAILY SEQUENCE END ================"
