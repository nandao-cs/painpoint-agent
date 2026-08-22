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
# BRPX_RUN_ID is minted ONCE, outside the retry loop, so the 3 attempts share one cap window.
$env:BRPX_RUN_ID  = [guid]::NewGuid().ToString()
$env:BRPX_ROUTINE = 'startup-ideas'
# HOOK ASSERTION (2026-08-22). Two independent checks, both advisory - neither can
# abort a run, for the same reason ops\prompt-lint.ps1 only warns. The static one
# runs now; the breadcrumb it refers to is written by ops\executor-hook.js and read
# back by ops\health-check.ps1, which is what turns a silent disarm into a finding.
Log (Test-HookSettings)
Log ("Run id: {0}" -f $(if ($brpxRunId) { $brpxRunId } else { $env:BRPX_RUN_ID }))

# Extra args built as one array: PowerShell expands an array into separate arguments for a
# native command. --disallowedTools stays LAST because it is variadic.
$extra = @('--settings','C:\Users\fjmartins\Scripts\ops\executor-hook-settings.json')
if ($mcpCfg) { $extra += @('--mcp-config',$mcpCfg,'--strict-mcp-config') }
$extra += '--disallowedTools'
$extra += $denied

$code = 1
# BOUNDED RUN (added 2026-08-22). This launcher used to pipe straight into claude with
# NO time bound at all. The only backstop was the PainPointAgent task's ExecutionTimeLimit
# of PT4H - so a wedged MCP server or a dropped socket could burn four hours AND starve the
# later steps of run-daily-sequence.ps1, which runs painpoint -> ideas -> founder-scout in
# order. run-painpoint.ps1 has self-limited to 25 minutes for months; these two never did.
#
# Same shape as run-painpoint.ps1 deliberately: Start-Process plus a kill-on-close Job Object
# so detached MCP subprocesses die with the parent, and a timed WaitForExit.
$claudeTimeoutMin = 25
for ($attempt = 1; $attempt -le 3; $attempt++) {
  if ($attempt -gt 1) { Log "RETRY $attempt/3 (prev exit=$code)"; Start-Sleep -Seconds 20 }
  $tin = [IO.Path]::GetTempFileName(); $tout = [IO.Path]::GetTempFileName(); $terr = [IO.Path]::GetTempFileName()
  [IO.File]::WriteAllText($tin, $prompt, (New-Object System.Text.UTF8Encoding($false)))
  $job = $null
  try {
    $p = Start-Process -FilePath $claude -ArgumentList (@('-p','--permission-mode','bypassPermissions','--output-format','text') + $extra) `
           -RedirectStandardInput $tin -RedirectStandardOutput $tout -RedirectStandardError $terr -NoNewWindow -PassThru
    # Touch .Handle BEFORE the timed wait. Start-Process -PassThru returns a Process with no
    # cached handle, so after exit $p.ExitCode reads $null for SUCCESS and FAILURE alike.
    $null = $p.Handle
    try { $job = New-KillOnCloseJob "ClaudeRun_startupideas_${PID}_a$attempt"; Add-ProcessToJob -JobHandle $job -Process $p }
    catch { Log "WARN: job-object assign failed ($($_.Exception.Message)); taskkill-only fallback."; $job = $null }
    if ($p.WaitForExit($claudeTimeoutMin*60*1000)) {
      $p.WaitForExit()
      $code = $p.ExitCode
      if ($null -eq $code) { Log "ERROR ANOMALY: exited but ExitCode is null; outcome UNKNOWN, recording 126."; $code = 126 }
      if ($job) { Close-JobHandle -JobHandle $job }
    } else {
      Log "TIMEOUT: claude -p exceeded ${claudeTimeoutMin}min - killing the job tree (incl. MCP subprocesses)."
      if ($job) { Stop-JobTree -JobHandle $job }
      & taskkill.exe /PID $p.Id /T /F *> $null
      $code = 124
    }
  }
  catch { Log "ERROR attempt=$attempt : $($_.Exception.Message)"; $code = 1; if ($job) { try { Close-JobHandle -JobHandle $job } catch {} } }
  foreach ($tf in @($tout, $terr)) {
    if (Test-Path $tf) { $c = Get-Content $tf -Raw -ErrorAction SilentlyContinue; if ($c) { Add-Content $log $c -Encoding utf8 } }
  }
  Remove-Item $tin, $tout, $terr -Force -ErrorAction SilentlyContinue
  if ($code -eq 0 -or $code -eq 126) { break }
}
if ($mcpCfg) { Remove-Item $mcpCfg -Force -ErrorAction SilentlyContinue }
Log "===== IDEAS RUN END exit=$code ====="
exit $code
