# React Native (Expo) 프로젝트 CLAUDE.md 보일러플레이트

> unbounded-engine 셋업 모드에서 Expo/RN 프로젝트 감지 시 자동 참조

```markdown
# [프로젝트명] — React Native (Expo)

## 스택
- Expo SDK {버전} (Managed / Bare)
- TypeScript
- Expo Router (파일 기반 라우팅)
- {상태관리}: Zustand / Redux / Context
- {UI}: NativeWind / React Native Paper / Tamagui

## 빌드·실행
- `npx expo start` — 개발 서버
- `npx expo run:ios` / `npx expo run:android` — 네이티브 빌드
- `eas build` — 프로덕션 빌드
- `eas submit` — 스토어 제출

## 아키텍처
- Expo Router: `app/` (layout.tsx, index.tsx, [id].tsx)
- 네비게이션: Stack / Tabs / Drawer (expo-router)
- 네이티브 모듈: expo-camera, expo-location, expo-file-system 등

## 도메인 규칙
- ALWAYS: expo-file-system documentDirectory, EncodingType은 'expo-file-system/legacy'에서 import (SDK 54+)
- ALWAYS: lucide-react-native 아이콘은 node_modules에서 존재 확인 후 사용
- ALWAYS: Platform.OS 분기로 웹/네이티브 차이 처리
- NEVER: 웹 전용 API (window, document) 직접 사용 금지
- NEVER: router.replace('/') 웹 정적 빌드에서 직접 사용 금지 → Platform.OS==='web' 분기
- WHEN: 이미지 THEN: expo-image 사용 (Image from RN 대신)
- WHEN: 저장소 THEN: expo-secure-store (민감) / @react-native-async-storage (일반)
- WHEN: 카메라·위치 THEN: 권한 요청 먼저 (expo-permissions)

## 코딩 도구
- bkit PDCA + g-stack /review + /cso
- visual-proof (에뮬레이터 스크린샷)

## 누적 교훈
<!-- retrospective-engine 자동 추가 -->
```
