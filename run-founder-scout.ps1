# run-founder-scout.ps1 — Founder Scout Agent. SCHEDULED, not on-demand: step 3/3 of
# run-daily-sequence.ps1, which the PainPointAgent task runs headless Mon + Thu 09:00.
# For each startup idea with no candidates yet, sources matching people via
# OpenMandate + Specter + Affinity + Hunter and writes them to the Notion
# Founder Candidates DB. SOURCE-ONLY: never contacts anyone, never touches Affinity-write.
# Bills the Claude subscription. Retries on socket drop.
#
# 2026-08-18: was entirely unscoped — no --mcp-config and no --disallowedTools — so the two
# rules in its own header ("never contacts anyone", "never touches Affinity-write") were prose
# only: the run held Superhuman send_draft/create_or_update_draft, the whole Affinity write
# surface including create_note, and Hunter's Start-Sequence. Now registered in
# ops\agents.json as 'founder-scout'; superhuman is out of scope entirely, affinity.write is
# not granted (Affinity stays read-only), and only Hunter's lookup tools survive the denylist.
$ErrorActionPreference = 'Continue'
$proj   = "C:\Users\fjmartins\painpoint-agent"
$claude = "C:\Users\fjmartins\.local\bin\claude.exe"
$log    = "C:\Users\fjmartins\Scripts\Logs\founder_scout.log"
function Log($m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Add-Content $log "[$ts] $m" -Encoding utf8 }

Log "===== FOUNDER SCOUT START ====="
Set-Location $proj
# Load secrets from the DPAPI-encrypted vault into the process env (inherited by the claude
# child, and from there by the email-mcp server). MISSING until 2026-08-18: this launcher was
# the only one in the fleet that never called it, so EmailMCP\server.py - which reads
# HUNTER_API_KEY / EMAILVERIFY_API_KEY straight from os.environ with no vault fallback - saw
# neither key and the find/verify waterfall silently degenerated to Prospeo-only ("Prospeo
# returned no_match then HTTP 429, and EmailVerify/Hunter keys are absent" in this log).
# MUST run BEFORE the ANTHROPIC_API_KEY clear below: the vault can contain that key and
# would otherwise re-set it, routing the run to the API key instead of the subscription.
$envBefore = @{}; Get-ChildItem Env: | ForEach-Object { $envBefore[$_.Name] = $true }
& "C:\Users\fjmartins\Scripts\ops\vault-load.ps1" | Out-Null
# PER-ROUTINE CREDENTIAL SCOPING (2026-08-18). vault-load is all-or-nothing: it exports all 12
# secrets, including AFFINITY_API_KEY - which is full read-write (its /whoami returns a single
# generic `api` scope; write endpoints return 422 field-validation, not 403, so authz passes)
# - and GMAIL_APP_PASSWORD. Bash is available to every routine, so an exported credential is a
# live write path that no --disallowedTools pattern can see. This routine's two hard rules are
# "never contact anyone" and "never write to Affinity"; dropping every secret it does not need
# makes both true at the CREDENTIAL level instead of only in prose. Self-maintaining: it
# clears whatever vault-load added that is not on the keep-list, so a new vault key is dropped
# by default rather than silently inherited.
$keepSecrets = @('HUNTER_API_KEY','EMAILVERIFY_API_KEY','PROSPEO_API_KEY','DROPCONTACT_API_KEY','APOLLO_API_KEY')
$droppedSecrets = @()
foreach ($e in @(Get-ChildItem Env: | Where-Object { -not $envBefore.ContainsKey($_.Name) })) {
  if ($keepSecrets -notcontains $e.Name) { [Environment]::SetEnvironmentVariable($e.Name, $null, 'Process'); $droppedSecrets += $e.Name }
}
Log ("Credential scope: kept [{0}]; dropped [{1}]." -f (($keepSecrets -join ',')), (($droppedSecrets -join ',') -replace '^$','none'))
$env:ANTHROPIC_API_KEY = $null   # bill to subscription
$prompt = Get-Content -Raw "$proj\scripts\founder-scout-run.md"

# Per-routine MCP server scoping + enforced write-capability policy (see ops\ for both).
. "C:\Users\fjmartins\Scripts\ops\mcp-scope.ps1"
. "C:\Users\fjmartins\Scripts\ops\tool-policy.ps1"
# Portfolio guard: this agent shortlists PEOPLE and writes an Outreach Angle for each, so a
# candidate who is already a portfolio founder is the same never_contact violation as a cold
# email. ops\portfolio-registry.json is the authority.
. "C:\Users\fjmartins\Scripts\ops\portfolio-guard.ps1"
$mcpCfg = New-ScopedMcpConfig 'founder-scout'
if ($mcpCfg) {
  Log "MCP scoped to: $($Global:McpUsed -join ', ')"
  if ($Global:McpDropped -and $Global:McpDropped.Count) {
    Log "MCP UNAVAILABLE this run: $($Global:McpDropped -join ', ') - substitutes and continues (no connector is on the critical path)."
  }
  $prompt = $prompt + (Get-McpDegradationNote)
}
else { Log "WARN: MCP scoping returned null -- falling back to the full server set." }
$prompt = $prompt + (Get-PortfolioGuardNote)

# The spec's search layer 4 names raw Hunter tools. This routine is now scoped to email-mcp
# instead (see ops\agents.json): Hunter is the SCARCEST free tier (~50 searches/mo) and being
# first-and-only burned it out - it sat at 50/50 and 100/100 on 2026-08-18. email-mcp runs
# Prospeo -> EmailVerify.io -> Hunter internally, so Hunter is still reached, just last.
# Without this note the model would look for tool names that no longer exist in the session.
$prompt = $prompt + @"


=== EMAIL ENRICHMENT: USE email-mcp, NOT RAW HUNTER ===
Step 5's Hunter tools (Person-Enrichment / Email-Finder / Email-Verifier) are NOT loaded this
run. Use the email-mcp server instead - it runs the same waterfall as code:
- find_email(first, last, company, domain)  ->  Prospeo, then EmailVerify.io, then Hunter.
- verify_email(email)                       ->  Hunter, then EmailVerify.io.
Map the result to Email Status: deliverable -> Verified, risky/catch-all -> Risky,
a pattern guess that did not verify -> Guessed, nothing found -> Unknown. Never invent an
address. If both providers are quota-exhausted, fall back to mailrook's validate-email-tool;
if that is also out, leave Email empty and set Email Status = Unknown - an empty field is
correct, a fabricated address is not. The ~40-call budget still applies.
"@

# Computed ONCE, outside the retry loop, so all 3 attempts use the identical denylist.
$denied = Get-DeniedTools 'founder-scout'
Log ("Tool policy: grants=[{0}]{1}; {2} write tool(s) denied." -f `
     (($Global:ToolGrantsUsed -join ',') -replace '^$','none'), `
     $(if ($Global:ToolGrantIsFallback) { ' FALLBACK-not-in-policy-map' } else { '' }), `
     $denied.Count)

# RUN CONTEXT + PreToolUse HOOK (2026-08-22). This launcher had neither, which made it one of
# the last two in the fleet whose ARGUMENT-level rules were prose only. --disallowedTools can
# say "not this tool"; it cannot say "not this company" or "not more than N times". Both of
# those matter here more than almost anywhere else, because this is the agent that handles
# REAL PEOPLE: without the hook, ops/portfolio-registry.json never gets consulted, so a
# portfolio founder could be written into the Founder Candidates DB with an Outreach Angle -
# the same never_contact violation as a cold email, one human step away from being sent.
# The hook also enforces the specter.call budget in ops/action-policy.json, which until now
# was a number nobody read.
#
# BRPX_RUN_ID is minted ONCE, HERE, outside the retry loop and reused by all 3 attempts: a
# fresh id per attempt would reset every per-run cap, so a run that spent its Specter budget
# before a socket drop would get the whole budget again. BRPX_ROUTINE must match the key in
# ops/action-policy.json ('founder-scout') - act.py fails OPEN and warns on an unknown routine,
# so a typo here silently disarms the gate rather than breaking the run.
$env:BRPX_RUN_ID  = [guid]::NewGuid().ToString()
$env:BRPX_ROUTINE = 'founder-scout'

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
Log "===== FOUNDER SCOUT END exit=$code ====="
exit $code
