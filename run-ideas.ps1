# run-ideas.ps1 — Startup Ideation Agent. SCHEDULED: step 2/3 of run-daily-sequence.ps1,
# which the PainPointAgent task runs headless Mon + Thu 09:00.
# Reads the fund's theses + pain points and publishes startup ideas to the
# Notion Startup Ideas DB. Bills the Claude subscription. Retries on socket drop.
#
# 2026-08-18: was entirely unscoped — no --mcp-config and no --disallowedTools — so a routine
# that only creates pages in one Notion DB connected all 15 MCP servers and held every write
# tool in them. Now registered in ops\agents.json as 'startup-ideas': notion is the only
# server scoped in, so "Never write to Affinity. Never message founders." is structural
# (those tools do not exist in the session), and notion.create is its only granted capability.
$ErrorActionPreference = 'Continue'
$proj   = "C:\Users\fjmartins\painpoint-agent"
$claude = "C:\Users\fjmartins\.local\bin\claude.exe"
$log    = "C:\Users\fjmartins\Scripts\Logs\startup_ideas.log"
function Log($m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content $log "[$ts] $m" -Encoding utf8 }

Log "===== IDEAS RUN START ====="
Set-Location $proj
# NO vault-load HERE, DELIBERATELY - do not "fix" this by adding it back. This routine needs
# no secret at all: its only MCP server (notion) is an OAuth HTTP connector and its other
# input is a local sqlite file. vault-load is all-or-nothing and would export AFFINITY_API_KEY
# (full read-write) plus GMAIL_APP_PASSWORD into a process that also has Bash - i.e. a live
# path to exactly the two things this spec forbids: "Never write to Affinity. Never message
# founders." Not exporting the credential is what makes those rules true rather than stated.
$env:ANTHROPIC_API_KEY = $null   # bill to subscription
$prompt = Get-Content -Raw "$proj\scripts\ideas-run.md"

# Per-routine MCP server scoping + enforced write-capability policy (see ops\ for both).
# Job-Object helpers (New-KillOnCloseJob / Stop-JobTree / Close-JobHandle) for the
# bounded run below - without them a timeout cannot reap detached MCP children.
. "C:\Users\fjmartins\Scripts\ops\concurrency.ps1"
. "C:\Users\fjmartins\Scripts\ops\mcp-scope.ps1"
. "C:\Users\fjmartins\Scripts\ops\tool-policy.ps1"
# Proof that the PreToolUse hook is really in force this run (see file).
# `claude --help`: a --settings file that fails validation is SILENTLY IGNORED,
# and an ungoverned run logs identically to a governed one.
. "C:\Users\fjmartins\Scripts\ops\hook-assert.ps1"
$mcpCfg = New-ScopedMcpConfig 'startup-ideas'
if ($mcpCfg) {
  Log "MCP scoped to: $($Global:McpUsed -join ', ')"
  if ($Global:McpDropped -and $Global:McpDropped.Count) {
    Log "MCP UNAVAILABLE this run: $($Global:McpDropped -join ', ') - substitutes and continues (no connector is on the critical path)."
  }
  $prompt = $prompt + (Get-McpDegradationNote)
}
else { Log "WARN: MCP scoping returned null -- falling back to the full server set." }

# Computed ONCE, outside the retry loop, so all 3 attempts use the identical denylist.
$denied = Get-DeniedTools 'startup-ideas'
Log ("Tool policy: grants=[{0}]{1}; {2} write tool(s) denied." -f `
     (($Global:ToolGrantsUsed -join ',') -replace '^$','none'), `
     $(if ($Global:ToolGrantIsFallback) { ' FALLBACK-not-in-policy-map' } else { '' }), `
     $denied.Count)

# RUN CONTEXT + PreToolUse HOOK (2026-08-22). Added for the same reason as run-founder-scout,
# though the surface here is smaller: notion is the only server scoped in, so what the hook
# actually buys is (a) the portfolio never-touch gate on every page this routine creates - an
# idea page whose wedge names a portfolio company is exactly the kind of row that should not be
# published unreviewed - and (b) the notion.create grant check, which is defence in depth behind
# ops/tool-policy.ps1 rather than a second copy of it.
#
# NOTE act.py's ledger is a local SQLite file, so the caps are counted even here, where the
# launcher deliberately loads NO vault secrets (see above). Nothing about this needs a
# credential, which is why adding the hook does not reopen the credential hole closed above.
#
# BRPX_RUN_ID is minted ONCE here so the 3 attempts share one cap window, but it is
# EXPORTED by Invoke-ClaudeRun after the lane is acquired - see its -RunContext note:
# with BRPX_RUN_ID visible, the lane-abort Telegram alert would be routed through
# act.py's gated, counted path, so a run that never started would spend the budget
# it is reporting it could not use.
$brpxRunId = [guid]::NewGuid().ToString()
# HOOK ASSERTION (2026-08-22). Two independent checks, both advisory - neither can
# abort a run, for the same reason ops\prompt-lint.ps1 only warns. The static one
# runs now; the breadcrumb it refers to is written by ops\executor-hook.js and read
# back by ops\health-check.ps1, which is what turns a silent disarm into a finding.
Log (Test-HookSettings)
Log ("Run id: {0}" -f $(if ($brpxRunId) { $brpxRunId } else { $env:BRPX_RUN_ID }))

# The launch sequence lives in ops\claude-run.ps1 (2026-08-22). Two things change
# for this launcher beyond the de-duplication:
#
#   1. IT GAINS THE LANE MUTEX. It had none, so it could run a second `claude -p`
#      beside a heavy fund routine that believed it held the fleet alone.
#   2. Its timeout path gets Stop-RunOnTimeout. The inline version here was the
#      pre-2026-08-19 shape - Stop-JobTree, then taskkill on an already-reaped PID.
#      That is harmless only because this file runs under
#      $ErrorActionPreference='Continue'; under 'Stop' the same three lines
#      rewrote 124 as 1 thirty-eight times. Relying on a preference setting to
#      keep a bug latent is not a fix.
#
# The 25min bound itself (added 2026-08-22) is unchanged. Before it this launcher
# piped straight into claude with NO time bound at all, backstopped only by the
# PainPointAgent task's PT4H limit - so a wedged MCP server could burn four hours
# AND starve the later steps of run-daily-sequence.ps1, which runs
# painpoint -> ideas -> founder-scout in order.
. "C:\Users\fjmartins\Scripts\ops\claude-run.ps1"

# Initialised to FAILURE, not 0: the finally always runs, and an uninitialised
# $code would exit 0 and forge a success out of a crash.
$code = 1
try {
  $r = Invoke-ClaudeRun -Name 'startup-ideas' -Prompt $prompt `
         -DeniedTools $denied -McpConfig $mcpCfg `
         -TimeoutMin 25 -MaxAttempts 3 `
         -LogFile $log -Logger ${function:Log} `
         -TaskLabel 'routine=startup-ideas' `
         -RunContext @{ BRPX_RUN_ID = $brpxRunId; BRPX_ROUTINE = 'startup-ideas' }
  $code = $r.ExitCode
}
finally {
  if ($mcpCfg) { Remove-Item $mcpCfg -Force -ErrorAction SilentlyContinue }
  Log "===== IDEAS RUN END exit=$code ====="
}
exit $code
