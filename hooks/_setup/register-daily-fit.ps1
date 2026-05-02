# register-daily-fit.ps1 — claude-daily-fit-deep 단독 등록
# 설계: plans/velvet-yawning-pixel.md Layer 2
# 실행: powershell -ExecutionPolicy Bypass -File register-daily-fit.ps1

$ErrorActionPreference = "Stop"
$BashExe = "C:\Program Files\Git\bin\bash.exe"
$HooksDir = "$env:USERPROFILE\.claude\hooks"
$ScriptPath = "$HooksDir\2604181801_daily-fit-analyzer.sh"

if (-not (Test-Path $BashExe)) {
    Write-Error "bash.exe not found: $BashExe"
    exit 1
}
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Analyzer script not found: $ScriptPath"
    exit 1
}

$trigger = New-ScheduledTaskTrigger -Daily -At "22:45"
$action = New-ScheduledTaskAction -Execute $BashExe -Argument "`"$ScriptPath`""
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -WakeToRun:$false `
    -StartWhenAvailable

# Note: RunLevel Highest omitted — requires admin; default user level is sufficient for bash script execution.
# If higher privileges needed later: re-run this script from elevated PowerShell.
Register-ScheduledTask `
    -TaskName "claude-daily-fit-deep" `
    -Trigger $trigger `
    -Action $action `
    -Settings $settings `
    -Force | Out-Null

Write-Host "✓ Registered: claude-daily-fit-deep (daily 22:45, Sunday skipped internally)"
Write-Host ""
Write-Host "=== Task Info ==="
Get-ScheduledTask -TaskName "claude-daily-fit-deep" | Format-List TaskName, State
$info = Get-ScheduledTaskInfo -TaskName "claude-daily-fit-deep"
Write-Host "NextRunTime : $($info.NextRunTime)"
Write-Host "LastRunTime : $($info.LastRunTime)"
