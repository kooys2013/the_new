#!/usr/bin/env bash
# MemPalace 백업 — cron 매일 02:00 권장 (3-2-1 백업 룰)
# v4 (2605011041)
set -euo pipefail
trap 'exit 0' ERR

MEMPALACE_DIR="${HOME}/.mempalace"
[ -d "$MEMPALACE_DIR" ] || exit 0

BACKUP_DIR="${HOME}/.mempalace-backup"
mkdir -p "$BACKUP_DIR"

DATE=$(date +%Y%m%d)
ARCHIVE="${BACKUP_DIR}/mempalace-${DATE}.tar.gz"

# 이미 오늘 백업했으면 skip
[ -f "$ARCHIVE" ] && exit 0

cd "$MEMPALACE_DIR"
# wings/, rooms/, drawers/, kg/ 등 표준 디렉토리 백업
tar -czf "$ARCHIVE" --exclude="*.tmp" --exclude="*.lock" . 2>/dev/null || exit 0

# 14일 보존, 14일 이상 자동 삭제
find "$BACKUP_DIR" -name "mempalace-*.tar.gz" -mtime +14 -delete 2>/dev/null

# 외부 cold storage (S3/Backblaze)는 사용자 별도 설정
echo "[mempalace-backup] DONE: ${DATE}"
exit 0
