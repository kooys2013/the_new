#!/usr/bin/env bash
input=$(cat)

# 동시 실행 claude 세션 수 (메모리 500MB+ = 메인 세션)
CONCURRENT=$(tasklist 2>/dev/null | grep -i 'claude' | awk '{gsub(/,/,"",$5); if($5+0 > 500000) n++} END{print n+0}' || echo '?')

# Codex 잔여량 — Codex Proxy (localhost:8080) 쿼터 API
CODEX_QUOTA_JSON=""
CODEX_HEALTH_JSON=""
PROXY_CACHE="/tmp/.codex_proxy_$(date +%Y%m%d%H%M | head -c 11)"  # 5분 캐시

if [ -f "$PROXY_CACHE" ]; then
  CACHED=$(cat "$PROXY_CACHE" 2>/dev/null)
  CODEX_HEALTH_JSON=$(node -e "try{const d=JSON.parse(process.argv[1]);process.stdout.write(JSON.stringify(d.health||{}))}catch(e){}" -- "$CACHED" 2>/dev/null || echo "")
  CODEX_QUOTA_JSON=$(node -e "try{const d=JSON.parse(process.argv[1]);process.stdout.write(JSON.stringify(d.quota||{}))}catch(e){}" -- "$CACHED" 2>/dev/null || echo "")
else
  # health 확인
  CODEX_HEALTH_JSON=$(curl -s --max-time 1 "http://localhost:8080/health" 2>/dev/null || echo "")
  # proxy가 OK면 quota 조회
  if echo "$CODEX_HEALTH_JSON" | grep -q '"status":"ok"'; then
    _ACCT_ID=$(curl -s --max-time 1 "http://localhost:8080/auth/accounts" 2>/dev/null \
      | node -e "try{const c=[];process.stdin.on('data',x=>c.push(x));process.stdin.on('end',()=>{console.log(JSON.parse(c.join('')).accounts[0].id||'')})}catch(e){console.log('')}" 2>/dev/null | tr -d '\n')
    if [ -n "$_ACCT_ID" ]; then
      CODEX_QUOTA_JSON=$(curl -s --max-time 1 "http://localhost:8080/auth/accounts/$_ACCT_ID/quota" 2>/dev/null || echo "")
    fi
  fi
  # 캐시 저장
  [ -z "$CODEX_HEALTH_JSON" ] && _H="{}" || _H="$CODEX_HEALTH_JSON"
  [ -z "$CODEX_QUOTA_JSON" ]  && _Q="{}" || _Q="$CODEX_QUOTA_JSON"
  printf '{"health":%s,"quota":%s}' "$_H" "$_Q" > "$PROXY_CACHE" 2>/dev/null
fi

echo "$input" | CONCURRENT="$CONCURRENT" CODEX_QUOTA_JSON="$CODEX_QUOTA_JSON" CODEX_HEALTH_JSON="$CODEX_HEALTH_JSON" node -e "
const PROXY_URL = 'http://localhost:8080';
const chunks = [];
process.stdin.on('data', c => chunks.push(c));
process.stdin.on('end', () => {
  const d = JSON.parse(chunks.join(''));

  // 남은 시간 포맷: Xd Xh Xm (현재부터 리셋까지)
  function timeLeft(resetAt) {
    if (!resetAt) return '';
    // Unix 초 타임스탬프(숫자)와 ISO 문자열 모두 처리
    let resetMs;
    if (typeof resetAt === 'number') {
      // 1e10 이하면 초 단위 → ms로 변환
      resetMs = resetAt < 1e10 ? resetAt * 1000 : resetAt;
    } else {
      resetMs = new Date(resetAt).getTime();
    }
    const ms = resetMs - Date.now();
    if (ms <= 0) return '리셋중';
    const totalMin = Math.floor(ms / 60000);
    const d2 = Math.floor(totalMin / 1440);
    const hh = Math.floor((totalMin % 1440) / 60);
    const mm = totalMin % 60;
    if (d2 > 0 && hh > 0) return d2 + '일' + hh + '시';
    if (d2 > 0)            return d2 + '일';
    if (hh > 0)            return hh + '시' + mm + '분';
    return mm + '분';
  }

  // 토큰 수 포맷: 12,345 → 12k / 1,234,567 → 1.2m
  function fmtTokens(n) {
    if (!n || n === 0) return '0';
    if (n >= 1000000) return (n / 1000000).toFixed(1) + 'm';
    if (n >= 1000)    return Math.round(n / 1000) + 'k';
    return String(n);
  }

  // 1. 모델명
  const modelRaw = d.model?.id || '';
  const model =
    /opus-4-6/.test(modelRaw)    ? 'Opus 4.6'    :
    /sonnet-4-6/.test(modelRaw)  ? 'Sonnet 4.6'  :
    /haiku-4-5/.test(modelRaw)   ? 'Haiku 4.5'   :
    /opus/.test(modelRaw)        ? 'Opus'         :
    /sonnet/.test(modelRaw)      ? 'Sonnet'       :
    /haiku/.test(modelRaw)       ? 'Haiku'        :
    d.model?.display_name || modelRaw || '?';

  // 2. 에이전트 수
  const concurrent = process.env.CONCURRENT || '?';

  // 3. 세션 잔여 (5h window)
  const five    = d.rate_limits?.five_hour;
  const fivePct = five?.used_percentage;
  let sessionStr = '세션:-';
  if (fivePct != null) {
    const rem = Math.round(100 - fivePct);
    const t   = timeLeft(five?.resets_at);
    sessionStr = '세션:' + rem + '%' + (t ? '(' + t + ')' : '');
  }

  // 4. 주간 잔여 (7d window)
  const week    = d.rate_limits?.seven_day;
  const weekPct = week?.used_percentage;
  let weekStr = '주간:-';
  if (weekPct != null) {
    const rem = Math.round(100 - weekPct);
    const t   = timeLeft(week?.resets_at);
    weekStr = '주간:' + rem + '%' + (t ? '(' + t + ')' : '');
  }

  // 5. Codex 잔여량 — /auth/accounts/:id/quota API
  let codexStr = 'Codex:-';
  try {
    const healthRaw = process.env.CODEX_HEALTH_JSON || '';
    const quotaRaw  = process.env.CODEX_QUOTA_JSON  || '';

    // Proxy 상태 확인
    let proxyOn = false;
    if (healthRaw.startsWith('{')) {
      const hj = JSON.parse(healthRaw);
      proxyOn = hj.status === 'ok';
    }

    if (!proxyOn) {
      codexStr = '';
    } else if (quotaRaw.startsWith('{')) {
      const qj = JSON.parse(quotaRaw);
      const rl  = qj.quota?.rate_limit;          // 5h window
      const srl = qj.quota?.secondary_rate_limit; // 7d window

      if (rl) {
        // 5h 잔여
        const rem5 = Math.round(100 - (rl.used_percent || 0));
        const t5   = timeLeft(rl.reset_at);
        const arrow5 = rem5 > 80 ? '↑' : rem5 > 40 ? '→' : '↓';
        let part5 = rem5 + '%' + arrow5 + (t5 ? '(' + t5 + ')' : '');
        // 7d 잔여
        let part7 = '';
        if (srl) {
          const rem7 = Math.round(100 - (srl.used_percent || 0));
          const t7   = timeLeft(srl.reset_at);
          const arrow7 = rem7 > 80 ? '↑' : rem7 > 40 ? '→' : '↓';
          part7 = rem7 + '%' + arrow7 + (t7 ? '(' + t7 + ')' : '');
        }
        codexStr = 'Codex:' + part5 + (part7 ? '/' + part7 : '');
      } else {
        codexStr = 'Codex:On';
      }
    } else {
      codexStr = 'Codex:On';
    }
  } catch(e) { codexStr = 'Codex:?'; }

  // 6. Context % (transcript 크기 근사 — 200k 토큰 윈도우 가정, 1 token ≈ 4 chars)
  let ctxStr = '';
  try {
    const tp = d.transcript_path;
    if (tp) {
      const fs = require('fs');
      const sz = fs.statSync(tp).size; // bytes ≈ chars
      const approxTokens = sz / 4;
      const pct = Math.min(99, Math.round((approxTokens / 200000) * 100));
      const warn = pct >= 60 ? ' ⚠/compact' : '';
      ctxStr = 'Ctx:' + pct + '%' + warn;
    }
  } catch(e) {}

  // 포맷: 모델 | xN에이전트 | 세션:X%(Xh) | 주간:X%(Xd) | Ctx:X% | Codex:...
  const parts = [model, 'x' + concurrent, sessionStr, weekStr];
  if (ctxStr) parts.push(ctxStr);
  if (codexStr) parts.push(codexStr);
  process.stdout.write(parts.join(' | '));
});
"
