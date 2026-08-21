# run-ideas.ps1 — Startup Ideation Agent (Task Scheduler entry / on-demand).
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
. "C:\Users\fjmartins\Scripts\ops\mcp-scope.ps1"
. "C:\Users\fjmartins\Scripts\ops\tool-policy.ps1"
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

# Extra args built as one array: PowerShell expands an array into separate arguments for a
# native command. --disallowedTools stays LAST because it is variadic.
$extra = @('--settings','C:\Users\fjmartins\Scripts\ops\executor-hook-settings.json')
if ($mcpCfg) { $extra += @('--mcp-config',$mcpCfg,'--strict-mcp-config') }
$extra += '--disallowedTools'
$extra += $denied

$code = 1
for ($attempt = 1; $attempt -le 3; $attempt++) {
  if ($attempt -gt 1) { Log "RETRY $attempt/3 (prev exit=$code)"; Start-Sleep -Seconds 20 }
  $prompt | & $claude -p --permission-mode bypassPermissions --output-format text $extra 2>&1 |
    ForEach-Object { Add-Content $log $_ -Encoding utf8 }
  $code = $LASTEXITCODE
  if ($code -eq 0) { break }
}
if ($mcpCfg) { Remove-Item $mcpCfg -Force -ErrorAction SilentlyContinue }
Log "===== IDEAS RUN END exit=$code ====="
exit $code
