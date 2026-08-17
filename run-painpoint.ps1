# ============================================================
# run-painpoint.ps1 -- unattended Pain Point Discovery pipeline (Task Scheduler entry).
# 1. scrape enabled sources -> raw_posts (local, unlocked -- no MCP/claude calls)
# 2. AI x security pain-velocity radar (local, unlocked)
# 3. headless Claude pass: discovery -> score -> report -> thesis (+Readwise+Notion+
#    Specter/Granola/Affinity for the Phase 2.6 validation gate) -> graph
#
# Rewritten 2026-07-28 to match the safety pattern used by run-agent.ps1/run-linkedin.ps1/
# run-routine.ps1 -- this launcher had been missed by every prior safety pass and still had:
# (a) the prompt piped through PowerShell's `|`, which corrupts em-dashes/curly-quotes via
#     the console codepage -- confirmed live in Logs\painpoint_agent.log before this fix;
# (b) no lane mutex at all, so it could run truly concurrently with any other routine
#     (e.g. LinkedInDaily, both weekdays/scheduled around midday);
# (c) no MCP scoping (always connected all 13 servers) and no Job-Object process-tree kill
#     on a hang (taskkill /T alone misses detached MCP-server grandchildren).
# The two Python pre-steps stay exactly as before, running BEFORE the mutex is acquired --
# verified they only hit public HTTP APIs + local SQLite, no MCP/claude calls, so they carry
# no cross-routine race risk and don't need to be serialized against the rest of the fleet.
# ============================================================
$ErrorActionPreference = 'Continue'
$proj   = "C:\Users\fjmartins\painpoint-agent"
$claude = "C:\Users\fjmartins\.local\bin\claude.exe"; if (-not (Test-Path $claude)) { $claude = "claude" }
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
$logDir = "C:\Users\fjmartins\Scripts\Logs"
$log    = Join-Path $logDir "painpoint_agent.log"
function Log($m){ Add-Content -Path $log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m" -Encoding utf8 }
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

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

# --- 2. headless pipeline pass (discovery -> thesis -> graph) ---
# Load secrets from the DPAPI-encrypted vault into the process env (inherited by the claude
# child). NOTE: this routine's own scrape.py secrets (GITHUB_TOKEN/STACKEXCHANGE_KEY) are read
# directly from a local .env file, not the vault -- this call is for the MCP servers below
# (notion/readwise/specter/granola/affinity-official are all OAuth-based, no env keys needed
# either, so vault-load is effectively a no-op here today but kept for parity/future-proofing).
& "C:\Users\fjmartins\Scripts\ops\vault-load.ps1" | Out-Null

# Lane-based mutex + Job-Object kill helpers (see file for the 2026-07-20 incident this fixes).
. "C:\Users\fjmartins\Scripts\ops\concurrency.ps1"
# Per-routine MCP server scoping (see file) -- cuts connection/handshake overhead by not
# loading all 13 globally-configured servers when a routine only needs a handful.
. "C:\Users\fjmartins\Scripts\ops\mcp-scope.ps1"
$mcpCfg = New-ScopedMcpConfig 'painpoint-agent'
if ($mcpCfg) {
  Log "MCP scoped to: $($Global:McpUsed -join ', ')"
  if ($Global:McpDropped -and $Global:McpDropped.Count) {
    Log "MCP UNAVAILABLE this run: $($Global:McpDropped -join ', ') - substitutes and continues (no connector is on the critical path)."
  }
}
else { Log "WARN: MCP scoping returned null -- falling back to full server set." }

$prompt = Get-Content -Raw -Path "$proj\scripts\pipeline-run.md"
$prompt = $prompt + (Get-McpDegradationNote)
# Portfolio guard applies: phase 2.6 validates trend themes against capital signals and
# can surface named companies into Notion theses, so it needs the never_source rule.
. "C:\Users\fjmartins\Scripts\ops\portfolio-guard.ps1"
$prompt = $prompt + (Get-PortfolioGuardNote)
$env:ANTHROPIC_API_KEY = $null   # bill to subscription
Log "Billing routed to Claude subscription."

# 'painpoint-agent' is unlisted in ops\concurrency.ps1's lane table, so Get-Lane's fail-safe
# default assigns it 'standard' -- serializes with the rest of the fleet instead of risking a
# concurrent claude -p / MCP-connector race (the original 2026-07-17 failure mode).
$lane = Get-Lane 'painpoint-agent'
Log "Assigned lane: $lane"
$gmutex = New-Object System.Threading.Mutex($false, "FunnelAgentRun_${lane}_$env:USERNAME")
$gheld  = $false
$maxAttempts = 3   # kept at painpoint's existing value (heavier 4-phase pipeline than linkedin-daily's 2)
$code   = 1
try {
  $gheld = Wait-LaneMutexOrAbort -Mutex $gmutex -Lane $lane -TaskLabel "agent=painpoint-agent" -LogFn ${function:Log}
  if (-not $gheld) { $code = $Global:LaneAbortExitCode }
  else {

  $claudeTimeoutMin = 25
  $lastWasNetworkError = $false
  for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    if ($attempt -gt 1) {
      # 2026-07-23 fix: transient ENOTFOUND blips need real recovery time, not a 20s retry into the same outage.
      $backoffSec = if ($lastWasNetworkError) { 90 } else { 20 }
      Log "RETRY attempt $attempt/$maxAttempts (previous exitcode=$code, backoff=${backoffSec}s$(if ($lastWasNetworkError) { ' - network error detected' }))"
      Start-Sleep -Seconds $backoffSec
    }
    $tin = [IO.Path]::GetTempFileName(); $tout = [IO.Path]::GetTempFileName(); $terr = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($tin, $prompt, (New-Object System.Text.UTF8Encoding($false)))
    $job = $null
    try {
      $claudeArgs = @('-p','--permission-mode','bypassPermissions','--output-format','text')
      if ($mcpCfg) { $claudeArgs += @('--mcp-config',$mcpCfg,'--strict-mcp-config') }
      $p = Start-Process -FilePath $claude -ArgumentList $claudeArgs `
             -RedirectStandardInput $tin -RedirectStandardOutput $tout -RedirectStandardError $terr -NoNewWindow -PassThru
      try { $job = New-KillOnCloseJob "ClaudeRun_painpointagent_${PID}_a$attempt"; Add-ProcessToJob -JobHandle $job -Process $p }
      catch { Log "WARN: job-object assign failed ($($_.Exception.Message)); falling back to taskkill-only kill."; $job = $null }
      if ($p.WaitForExit($claudeTimeoutMin*60*1000)) {
        $p.WaitForExit()   # flush race guard: ExitCode can read $null right after WaitForExit returns true
        $code = $p.ExitCode
        if ($null -eq $code) { Log "NOTE: process exited but ExitCode read null; treating as success (0) to avoid a false retry."; $code = 0 }
        if ($job) { Close-JobHandle -JobHandle $job }
      } else {
        Log "TIMEOUT: claude -p exceeded ${claudeTimeoutMin}min - killing job (all descendants incl. MCP subprocesses)."
        if ($job) { Stop-JobTree -JobHandle $job }
        & taskkill.exe /PID $p.Id /T /F *> $null
        $code = 124
      }
    }
    catch { Log "ERROR attempt=$attempt : $($_.Exception.Message)"; $code = 1; if ($job) { try { Close-JobHandle -JobHandle $job } catch {} } }
    $lastWasNetworkError = $false
    foreach ($tf in @($tout, $terr)) {
      if (Test-Path $tf) {
        $c = Get-Content $tf -Raw -ErrorAction SilentlyContinue
        if ($c) {
          Add-Content -Path $log -Value $c -Encoding utf8
          if ($c -match 'ENOTFOUND|Unable to connect to API|ECONNRESET|ETIMEDOUT') { $lastWasNetworkError = $true }
        }
      }
    }
    Remove-Item $tin, $tout, $terr -Force -ErrorAction SilentlyContinue
    Log "pipeline attempt=$attempt exitcode=$code"
    if ($code -eq 0) { break }
  }
  }
} finally {
  if ($gheld) { try { $gmutex.ReleaseMutex() } catch {} ; Log "Lane mutex released." }
  $gmutex.Dispose()
  if ($mcpCfg) { Remove-Item $mcpCfg -Force -ErrorAction SilentlyContinue }
}
Log "===== PAINPOINT RUN END exitcode=$code ====="
exit $code
