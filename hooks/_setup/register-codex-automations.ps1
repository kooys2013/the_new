# register-codex-automations.ps1 — Codex Automations Task Scheduler 등록
# 등록 작업:
#   1. claude-codex-standup-daily      — 매일 09:00    (codex-daily-activity.sh)
#   2. claude-codex-dep-drift-weekly   — 매주 월 09:00 (dependency-drift-monitor.sh) [P1]
# Note: ci-failure-auto-triage.sh, dependency-drift-monitor.sh(PostToolUse) 는 settings.json 훅
# Note: performance-regression-tracker.sh 는 P2에서 등록
#
# 실행: powershell -ExecutionPolicy Bypass -File register-codex-automations.ps1

$ErrorActionPreference = "Stop"
$BashExe = "C:\Program Files\Git\bin\bash.exe"
$HooksDir = "$env:USERPROFILE\.claude\hooks"

if (-not (Test-Path $BashExe)) {
    Write-Error "bash.exe not found: $BashExe"
    exit 1
}

# === Task 1: claude-codex-standup-daily (매일 09:00) ===
$ScriptStandup = "$HooksDir\codex-daily-activity.sh"
if (-not (Test-Path $ScriptStandup)) {
    Write-Error "Standup script not found: $ScriptStandup"
    exit 1
}

$trigger1 = New-ScheduledTaskTrigger -Daily -At "09:00"
$action1 = New-ScheduledTaskAction -Execute $BashExe -Argument "`"$ScriptStandup`""
$settings1 = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -WakeToRun:$false `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName "claude-codex-standup-daily" `
    -Trigger $trigger1 `
    -Action $action1 `
    -Settings $settings1 `
    -Force | Out-Null

Write-Host "✓ Registered: claude-codex-standup-daily (daily 09:00)"

# === Task 2: claude-codex-dep-drift-weekly (매주 월요일 09:00) [P1] ===
$ScriptDepDrift = "$HooksDir\dependency-drift-monitor.sh"
if (-not (Test-Path $ScriptDepDrift)) {
    Write-Warning "Dep drift script not found: $ScriptDepDrift — skipping Task 2"
} else {
    # DayOfWeek = Monday (1)
    $trigger2 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "09:00"
    $action2 = New-ScheduledTaskAction -Execute $BashExe -Argument "`"$ScriptDepDrift`""
    $settings2 = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -WakeToRun:$false `
        -StartWhenAvailable

    Register-ScheduledTask `
        -TaskName "claude-codex-dep-drift-weekly" `
        -Trigger $trigger2 `
        -Action $action2 `
        -Settings $settings2 `
        -Force | Out-Null

    Write-Host "✓ Registered: claude-codex-dep-drift-weekly (Monday 09:00)"
}

# === 요약 ===
Write-Host ""
Write-Host "=== Registered Codex Automations Tasks ==="
$tasks = @("claude-codex-standup-daily", "claude-codex-dep-drift-weekly")
foreach ($t in $tasks) {
    $info = Get-ScheduledTaskInfo -TaskName $t -ErrorAction SilentlyContinue
    if ($info) {
        Write-Host ""
        Write-Host "[$t]"
        Write-Host "  NextRunTime : $($info.NextRunTime)"
        Write-Host "  LastRunTime : $($info.LastRunTime)"
        Write-Host "  LastResult  : $($info.LastTaskResult)"
    }
}

Write-Host ""
Write-Host "=== PostToolUse 훅 등록 현황 ==="
Write-Host "settings.json 에 등록된 PostToolUse 훅:"
Write-Host "  - PostToolUse(Bash)        : ci-failure-auto-triage.sh"
Write-Host "  - PostToolUse(Write+Edit)  : dependency-drift-monitor.sh"
Write-Host ""
Write-Host "=== Phase A+P1 완료 ==="
Write-Host "스모크 테스트:"
Write-Host "  1. bash ~/.claude/hooks/codex-daily-activity.sh"
Write-Host "  2. ls ~/.claude/_cache/codex-automations/"
Write-Host "  3. bash ~/.claude/hooks/dependency-drift-monitor.sh"
Write-Host "  4. ls ~/.claude/_cache/codex-automations/dep-drift-*.md"
