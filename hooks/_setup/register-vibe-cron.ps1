# register-vibe-cron.ps1 — Windows Task Scheduler에 vibe-sunsang 3개 작업 등록
# 실행: powershell -ExecutionPolicy Bypass -File register-vibe-cron.ps1

$ErrorActionPreference = "Stop"
$ClaudeExe = "claude"  # PATH에 있어야 함
$HooksDir = "$env:USERPROFILE\.claude\hooks"
$BashExe = "C:\Program Files\Git\bin\bash.exe"

function Register-VibeTask {
    param($Name, $Time, $Action, $Args)
    $trigger = New-ScheduledTaskTrigger -Daily -At $Time
    $act = New-ScheduledTaskAction -Execute $Action -Argument $Args
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $Name -Trigger $trigger -Action $act -Settings $settings -Force | Out-Null
    Write-Host "✓ Registered: $Name at $Time"
}

# 1. 일간 — 23:00 변환·멘토링
Register-VibeTask -Name "vibe-sunsang-daily" -Time "23:00" `
    -Action $ClaudeExe `
    -Args '--no-interactive -p "/vibe-sunsang 변환 && /vibe-sunsang 멘토링"'

# 2. 주간 — 일요일 22:00 분석 (Windows는 요일 트리거 별도)
$weeklyTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "22:00"
$weeklyAct = New-ScheduledTaskAction -Execute $BashExe -Argument "`"$HooksDir\weekly-fit-analyzer.sh`""
Register-ScheduledTask -TaskName "vibe-sunsang-weekly" -Trigger $weeklyTrigger -Action $weeklyAct -Force | Out-Null
Write-Host "✓ Registered: vibe-sunsang-weekly (Sun 22:00)"

# 3. 월간 — 매월 1일 03:00
$monthlyTrigger = New-ScheduledTaskTrigger -Daily -At "03:00"  # 근사: 매일 실행 + 스크립트 내부서 1일만 처리
$monthlyAct = New-ScheduledTaskAction -Execute $BashExe -Argument "-c `"if [ `$(date +%d) = '01' ]; then $HooksDir/monthly-fit-report.sh; fi`""
Register-ScheduledTask -TaskName "vibe-sunsang-monthly" -Trigger $monthlyTrigger -Action $monthlyAct -Force | Out-Null
Write-Host "✓ Registered: vibe-sunsang-monthly (매월 1일 03:00)"

Write-Host "`n완료. 확인: schtasks /Query /TN vibe-sunsang-daily"
