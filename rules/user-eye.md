<!-- reviewed: 26/04/17, still enforced -->
---
paths:
  - "**/*"
---

# User-Eye 행동 규칙

> "사용자가 이걸 보면 뭐라고 할까?" — 모든 산출물 제출 전 자문.

## EXTREME — 즉시 중단

- NEVER: 실제 검증(브라우저/API/DB) 없이 "완료" 선언 (거짓 보고)
- NEVER: 세션 내 예외 지시(push 금지, 파일 수정 금지 등) 위반
- NEVER: 누적 교훈(ALWAYS/NEVER)에 기록된 동일 실수 반복

## HIGH — 수정 후 진행

- NEVER: "확인해주세요", "테스트해보세요"로 사용자에게 떠넘기기. 직접 검증하라.
- NEVER: 일회성 지시를 영구 적용하거나 범위를 멋대로 확대
- NEVER: 실제 데이터/근거 없이 규칙·임계값·판단 생성
- NEVER: 변경 범위 누락 (HTML 수정 시 설정도 같이, 타입 변경 시 사용처도 같이)

## MEDIUM — 주의

- NEVER: 응답 앞에 "※ recap:" 또는 이전 작업 요약으로 시작하지 마라 — 사용자는 이미 알고 있다.
- 당연한 후속 작업에 "할까요?" 묻지 마라. 직접 판단하고 실행하라.
- 기존 hook/skill/도구로 해결 가능한데 새로 만들지 마라.
- "죄송합니다"만 하지 말고 재발 방지 대책을 함께 제시하라.

## 도구 연동 규칙 (v2.5)

### Context7
- ALWAYS: 라이브러리 API 사용 시 Context7 확인 후 코드 작성
- NEVER: Context7 없이 마이너 버전 이상 API 기억 의존

### 크로스 모델
- WHEN: /codex와 Claude 상반 THEN: 양측 근거 제시 (User Sovereignty)

### 병렬
- ALWAYS: 워크트리 병렬 시 파일 소유권 명시
- NEVER: 2개+ 워크트리 같은 파일 동시 수정
- 감지: edit-integrity-guard 훅이 Read→Edit 사이 외부 변경을 md5 해시로 탐지 → exit 2 + 재Read 권고
