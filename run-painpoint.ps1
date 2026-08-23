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
# NOTE: the claude executable is resolved by ops\claude-run.ps1 ($Global:ClaudeExe),
# not here. A local $claude was left dangling by the 2026-08-23 refactor and is removed:
# a stale path variable is an invitation to spawn the model outside the shared core,
# which is exactly the second launch path agents-validate check 11 fails a launcher for.
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
# Enforced MCP write-capability policy (see file). Added 2026-08-17: this launcher
# was MISSED when the policy shipped, and it is the one that mattered - unlike the
# other four unenforced launchers (which load `notion` only), painpoint loads
# `affinity-official`, so it held unrestricted create_note / create_company /
# upsert_list_entry_field_values on a Mon+Thu schedule while its own specs say
# "never touch Affinity" three times. Computed once, outside the retry loop.
. "C:\Users\fjmartins\Scripts\ops\tool-policy.ps1"
# Proof that the PreToolUse hook is really in force this run (see file).
# `claude --help`: a --settings file that fails validation is SILENTLY IGNORED,
# and an ungoverned run logs identically to a governed one.
. "C:\Users\fjmartins\Scripts\ops\hook-assert.ps1"
$prompt = $prompt + (Get-PortfolioGuardNote)

$denied = Get-DeniedTools 'painpoint-agent'
Log ("Tool policy: grants=[{0}]{1}; {2} write tool(s) denied." -f `
     (($Global:ToolGrantsUsed -join ',') -replace '^$','none'), `
     $(if ($Global:ToolGrantIsFallback) { ' FALLBACK-not-in-policy-map' } else { '' }), `
     $denied.Count)
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
$unknownOutcome = $false

# --- SCOPED EXECUTOR RUN CONTEXT (added 2026-08-19) -------------------------
# painpoint-agent was the last routine delivering outside ops/act.py. agents.json
# recorded `sender_pattern: report\.py` and a note saying it "delivers through
# `python scripts/report.py`" - but report.py only writes markdown briefs to
# output/reports/ and sends nothing at all, so the routine declared gmail+telegram
# delivery and in fact delivered nothing, while ops/prompt-lint.ps1 CHECK 3 passed
# because that custom pattern matched the report.py line in the spec. Its delivery
# now goes through act.py like every other routine (spec STEP 7), which needs:
#   - BRPX_RUN_ID / BRPX_ROUTINE in the ENVIRONMENT (act.py reads them there, never
#     from its arguments, so a routine cannot forge its identity or reset a counter).
#     Without them act.py refuses outright with exit 3, "missing run context".
#   - --settings ops\executor-hook-settings.json, the PreToolUse hook that blocks a
#     direct send_gmail.py / send_alert.js call and does the per-run gate counting.
#     This launcher had NO hook, which mattered here more than anywhere: it is the
#     one routine loading affinity-official.
# BRPX_RUN_ID is minted ONCE, HERE, outside the retry loop, and reused across all 3
# attempts on purpose: a fresh id per attempt would reset every per-run cap, which is
# exactly the bypass closed in the hook on 2026-08-19. A routine that emitted N sends
# before timing out must not get N more.
$brpxRunId = [guid]::NewGuid().ToString()
# HOOK ASSERTION (2026-08-22). Two independent checks, both advisory - neither can
# abort a run, for the same reason ops\prompt-lint.ps1 only warns. The static one
# runs now; the breadcrumb it refers to is written by ops\executor-hook.js and read
# back by ops\health-check.ps1, which is what turns a silent disarm into a finding.
Log (Test-HookSettings)
Log ("Run id: {0}" -f $(if ($brpxRunId) { $brpxRunId } else { $env:BRPX_RUN_ID }))
# The launch sequence lives in ops\claude-run.ps1 (2026-08-22): lane mutex, retry
# loop, job-object kill, handle caching, exit-code discipline, log tee. It was
# hand-copied into thirteen launchers and drifted; now there is one copy.
# Behaviour here is unchanged - same 25min timeout, same 3 attempts, same 90s
# network backoff, same 124/126 rules.
. "C:\Users\fjmartins\Scripts\ops\claude-run.ps1"

# Initialised to FAILURE, not 0: the finally always runs, and an uninitialised
# $code would exit 0 and forge a success out of a crash.
$code = 1
try {
  $r = Invoke-ClaudeRun -Name 'painpoint-agent' -Prompt $prompt `
         -DeniedTools $denied -McpConfig $mcpCfg `
         -TimeoutMin 25 -MaxAttempts 3 `
         -LogFile $log -Logger ${function:Log} `
         -TaskLabel 'agent=painpoint-agent' `
         -RunContext @{ BRPX_RUN_ID = $brpxRunId; BRPX_ROUTINE = 'painpoint-agent' }
  $code = $r.ExitCode
}
finally {
  if ($mcpCfg) { Remove-Item $mcpCfg -Force -ErrorAction SilentlyContinue }
  Log "===== PAINPOINT RUN END exitcode=$code ====="
}
exit $code
