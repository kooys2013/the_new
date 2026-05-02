# prompt-refiner — UserPromptSubmit Level 0 (PowerShell mirror)
# origin: custom barbell design | adapted: 26/04/19
# policy: rules/prompt-refiner-policy.md
#
# NOTE: Bash version (2604191800_prompt-refiner.sh) is the primary.
#       This .ps1 is kept as Windows-native fallback only.
#       settings.json references the .sh; do NOT wire both simultaneously.
#
# Contract:
#   - <=20ms soft target (PowerShell cold-start is heavier; silent on overrun)
#   - 10% sampling gate
#   - SHA-256 first 8 chars only (NEVER raw prompt)

try {
    $ErrorActionPreference = 'SilentlyContinue'

    # --- Read stdin ---
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }

    # --- Sampling gate (10%) ---
    if ((Get-Random -Minimum 0 -Maximum 10) -ne 0) { exit 0 }

    # --- Parse JSON ---
    $obj = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (-not $obj) { exit 0 }
    $prompt = [string]$obj.prompt
    $sessionId = [string]$obj.session_id
    if ([string]::IsNullOrEmpty($prompt)) { exit 0 }

    # --- Metrics ---
    $length = $prompt.Length
    $hasQuestion = [bool]($prompt -match '[?？]|뭐|어떻게|왜|언제|어디')

    $score = 0
    if ($length -lt 20) { $score += 30 }
    if ($prompt -notmatch '뭐|어떻게|왜|언제|어디') { $score += 20 }
    $vagueMatches = [regex]::Matches($prompt, '이거|저거|그거|대충|아무거나')
    $vagueCount = [Math]::Min(3, $vagueMatches.Count)
    $score += $vagueCount * 30
    if ($prompt -match '뭐|어떻게|왜|언제|어디') { $score -= 20 }
    $score = [Math]::Max(0, [Math]::Min(100, $score))
    $ambiguity = [Math]::Round($score / 100.0, 2)

    # --- SHA-256 first 8 chars ---
    $bytes = [Text.Encoding]::UTF8.GetBytes($prompt)
    $sha = [Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha.ComputeHash($bytes)
    $hash = (($hashBytes | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 8)

    $sessionShort = if ($sessionId.Length -ge 8) { $sessionId.Substring(0, 8) } else { 'unknown0' }

    # --- Timestamp ISO 8601 ---
    $ts = (Get-Date -Format 'o')

    # --- Log path (daily rotate) ---
    $logDir = Join-Path $env:USERPROFILE '.claude\_cache\prompt-refine'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $day = Get-Date -Format 'yyMMdd'
    $logFile = Join-Path $logDir "$day.jsonl"

    # --- Build JSONL line ---
    $hasQuestionStr = if ($hasQuestion) { 'true' } else { 'false' }
    $line = '{"ts":"' + $ts + '","session":"' + $sessionShort + '","prompt_hash":"' + $hash + '","length":' + $length + ',"has_question":' + $hasQuestionStr + ',"ambiguity_score":' + $ambiguity + ',"sampled":true,"level":0}'

    Add-Content -Path $logFile -Value $line -Encoding UTF8
}
catch {
    # Silent fail — NEVER block the prompt pipeline
}
exit 0
