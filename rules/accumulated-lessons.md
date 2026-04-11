---
paths:
  - "**/*"
---
# 누적 교훈

## ALWAYS
- Write tool 전 반드시 Read 먼저 [SCP-5] [since:26/03/15] [reinforced:26/04/11]
- lucide-react-native 아이콘 존재 확인 후 사용 [SCP-3] [since:26/03/20]
- [RN] expo-file-system → 'expo-file-system/legacy'에서 import [SCP-1] [since:26/03/22]
- [RN] router.replace('/') 실패 시 Platform.OS==='web' 분기 [SCP-3] [since:26/03/25]
- [GO] rules 파일 `paths:` frontmatter 검증 (`scope:` 잘못된 키) [SCP-1] [since:26/04/05]
- [GO] 장시간 세션 전 /save 체크포인트 [SCP-2] [since:26/04/08]

## NEVER
- LangChain JsonOutputParser 반환값에 .get() 금지 (Pydantic 인스턴스) [SCP-1] [since:26/03/10] [reinforced:26/04/05]
- 전역 vector_store 싱글턴 재도입 금지 [SCP-3] [since:26/03/18]
- [GO] rules/hooks 생성 후 settings.json 참조 미확인 [SCP-1] [since:26/04/06]

## WHEN...THEN
- WHEN 같은 에러 2회 THEN unbounded 재검토 [since:26/03/15] [reinforced:26/04/08]
- WHEN PR 전 THEN /review + /cso 필수 [since:26/03/15] [reinforced:26/04/10]
- WHEN UI 신규 구현 THEN ui-ux-pro-max --design-system 먼저 [since:26/03/28]
- WHEN 프론트엔드 변경 완료 THEN /visual-proof 실행 [since:26/03/28]
- WHEN CLAUDE.md 50줄 초과 THEN rules/ 승격 검토 [since:26/04/01]
- WHEN 하네스 변경 THEN 훅·rules·스킬 정합 감사 [since:26/04/05] [reinforced:26/04/11]

## 메타데이터 규칙
- [SCP-N]: 해당 교훈이 방어하는 실패 유형
- [since:YY/MM/DD]: 최초 기록일
- [reinforced:YY/MM/DD]: 마지막 참조/강화 날짜
- 90일간 reinforced 없으면 [STALE] 태그 자동 부여 (auto-triggers.md 연동)
