---
paths:
  - "**/*"
---
# 누적 교훈

## ALWAYS
- Write tool 전 반드시 Read 먼저
- lucide-react-native 아이콘 존재 확인 후 사용
- [RN] expo-file-system → 'expo-file-system/legacy'에서 import
- [RN] router.replace('/') 실패 시 Platform.OS==='web' 분기
- [GO] rules 파일 `paths:` frontmatter 검증 (`scope:` 잘못된 키)
- [GO] 장시간 세션 전 /save 체크포인트

## NEVER
- LangChain JsonOutputParser 반환값에 .get() 금지 (Pydantic 인스턴스)
- 전역 vector_store 싱글턴 재도입 금지
- [GO] rules/hooks 생성 후 settings.json 참조 미확인

## WHEN...THEN
- WHEN 같은 에러 2회 THEN unbounded 재검토
- WHEN PR 전 THEN /review + /cso 필수
- WHEN UI 신규 구현 THEN ui-ux-pro-max --design-system 먼저
- WHEN 프론트엔드 변경 완료 THEN /visual-proof 실행
- WHEN CLAUDE.md 50줄 초과 THEN rules/ 승격 검토
- WHEN 하네스 변경 THEN 훅·rules·스킬 정합 감사
