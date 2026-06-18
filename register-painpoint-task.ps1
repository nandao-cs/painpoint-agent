# register-painpoint-task.ps1 — register the weekly Pain Point pipeline.
# Runs as the current user, only when logged on (inherits env), catch-up if missed.
#   powershell -ExecutionPolicy Bypass -File register-painpoint-task.ps1

$ErrorActionPreference = 'Stop'
$proj   = "C:\Users\fjmartins\painpoint-agent"
$runner = "$proj\run-painpoint.ps1"
$user   = "$env:USERDOMAIN\$env:USERNAME"

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$runner`"" `
  -WorkingDirectory $proj
$trigger = New-ScheduledTaskTrigger -Daily -At 12:00PM
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd `
  -ExecutionTimeLimit (New-TimeSpan -Hours 2) -MultipleInstances IgnoreNew `
  -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "PainPointAgent" -Force `
  -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
  -Description "Pain Point Discovery Agent - daily 12:00 scrape/discover/validate/thesis -> Notion." | Out-Null
Write-Host "Registered PainPointAgent (daily 12:00)" -ForegroundColor Green
Get-ScheduledTask -TaskName "PainPointAgent" | Get-ScheduledTaskInfo | Select-Object @{N='Task';E={'PainPointAgent'}}, NextRunTime | Format-Table -AutoSize
