#!/usr/bin/env bash
# prompt-refiner — UserPromptSubmit Level 0 (silent 10% sampling)
# origin: custom barbell design | adapted: 26/04/19
# policy: rules/prompt-refiner-policy.md
#
# Contract (hardcoded SLA):
#   - <=20ms execution (silent exit 0 on timeout)
#   - 10% sampling gate ($RANDOM % 10 == 0)
#   - NEVER store raw prompt (SHA-256 first 8 chars only)
#   - Level 0 = log only, no statusMessage, no additionalContext

set +e  # never fail the prompt pipeline
# NOTE: no internal watchdog — Claude Code hook timeout governs runtime.
#       Script is designed to complete in <20ms on normal prompts.

# --- Read stdin JSON (non-blocking) ---
INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && exit 0

# --- Sampling gate (10%) ---
if [ $(( RANDOM % 10 )) -ne 0 ]; then
  exit 0
fi

# --- Extract fields (jq optional, fallback to grep/sed) ---
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)
  SESSION=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null)
else
  PROMPT=$(echo "$INPUT" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -c 10000)
  SESSION=$(echo "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "$PROMPT" ] && exit 0

# --- Metrics ---
LENGTH=${#PROMPT}

# has_question: ? or ？ or 뭐/어떻게/왜
HAS_QUESTION=false
if echo "$PROMPT" | grep -qE '[?？]|뭐|어떻게|왜|언제|어디'; then
  HAS_QUESTION=true
fi

# ambiguity_score computation
SCORE=0
# length < 20 → +0.3
[ "$LENGTH" -lt 20 ] && SCORE=$(( SCORE + 30 ))
# no WH-word → +0.2
if ! echo "$PROMPT" | grep -qE '뭐|어떻게|왜|언제|어디'; then
  SCORE=$(( SCORE + 20 ))
fi
# 다의어: 이거/저거/그거/대충/아무거나 (max 3 occurrences, +0.3 each capped)
VAGUE_COUNT=$(echo "$PROMPT" | grep -oE '이거|저거|그거|대충|아무거나' | wc -l)
[ "$VAGUE_COUNT" -gt 3 ] && VAGUE_COUNT=3
SCORE=$(( SCORE + VAGUE_COUNT * 30 ))
# WH-word present → -0.2
if echo "$PROMPT" | grep -qE '뭐|어떻게|왜|언제|어디'; then
  SCORE=$(( SCORE - 20 ))
fi
# clamp [0, 100]
[ "$SCORE" -lt 0 ] && SCORE=0
[ "$SCORE" -gt 100 ] && SCORE=100
# to decimal 0.00~1.00
AMBIGUITY=$(awk "BEGIN { printf \"%.2f\", $SCORE / 100 }")

# --- SHA-256 first 8 chars (privacy) ---
if command -v sha256sum >/dev/null 2>&1; then
  HASH=$(printf "%s" "$PROMPT" | sha256sum | cut -c1-8)
elif command -v shasum >/dev/null 2>&1; then
  HASH=$(printf "%s" "$PROMPT" | shasum -a 256 | cut -c1-8)
else
  HASH="nohash00"
fi

SESSION_SHORT=$(echo "$SESSION" | cut -c1-8)
[ -z "$SESSION_SHORT" ] && SESSION_SHORT="unknown0"

# --- Timestamp (ISO 8601 local) ---
TS=$(date +"%Y-%m-%dT%H:%M:%S%z" 2>/dev/null | sed 's/\(..\)$/:\1/')
[ -z "$TS" ] && TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Log directory (daily rotate) ---
LOG_DIR="$HOME/.claude/_cache/prompt-refine"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
DAY=$(date +%y%m%d)
LOG_FILE="$LOG_DIR/${DAY}.jsonl"

# --- Append jsonl line ---
printf '{"ts":"%s","session":"%s","prompt_hash":"%s","length":%d,"has_question":%s,"ambiguity_score":%s,"sampled":true,"level":0}\n' \
  "$TS" "$SESSION_SHORT" "$HASH" "$LENGTH" "$HAS_QUESTION" "$AMBIGUITY" \
  >> "$LOG_FILE" 2>/dev/null

exit 0
