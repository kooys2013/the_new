---
description: 'React 함수형 컴포넌트를 TypeScript와 Tailwind CSS로 생성합니다'
argument-hint: '[컴포넌트명]'
allowed-tools:
  [
    'Write',
    'Glob',
    'Read',
  ]
---

# Claude 명령어: Add Component

React 함수형 컴포넌트를 TypeScript와 Tailwind CSS로 자동 생성하는 커맨드입니다.

## 사용법

```
/add-component [컴포넌트명]
```

### 예시

```
/add-component Button
/add-component UserCard
/add-component NavigationBar
```

## 기능

### 자동 생성 항목
- **파일 위치**: `src/components/[컴포넌트명].tsx`
- **컴포넌트 이름**: PascalCase 자동 변환
- **기본 구조**: React 함수형 컴포넌트
- **TypeScript**: Props 인터페이스 포함
- **Tailwind CSS**: 기본 스타일 템플릿
- **내보내기**: 기본 export 포함

## 생성되는 템플릿

```tsx
'use client';

import React from 'react';

interface [컴포넌트명]Props {
  // Props를 여기에 추가하세요
}

export const [컴포넌트명]: React.FC<[컴포넌트명]Props> = ({
  // Props 분해
}) => {
  return (
    <div className="flex items-center justify-center">
      <p>컴포넌트 내용</p>
    </div>
  );
};

export default [컴포넌트명];
```

## 프로세스

1. 컴포넌트 이름 입력 확인
2. PascalCase로 자동 변환
3. `src/components/` 디렉토리 확인
4. 중복 파일 검사
5. TypeScript + Tailwind 템플릿으로 파일 생성
6. 경로 및 완료 메시지 출력

## 네이밍 규칙

### 입력 포맷
```
✅ 좋은 예시:
Button
UserCard
NavigationBar
FormInput
ModalDialog

❌ 피해야 할 예시:
button          # 소문자 (자동 변환됨)
user-card       # 케밥케이스
User_Card       # 스네이크케이스
```

### 자동 변환
- `button` → `Button`
- `user-card` → `UserCard`
- `user_card` → `UserCard`

## 생성된 파일 구조

```
src/components/
├── Button.tsx
├── UserCard.tsx
├── NavigationBar.tsx
└── ...
```

## 사용 예시

### 간단한 컴포넌트
```
/add-component Badge
```

결과:
```tsx
'use client';

import React from 'react';

interface BadgeProps {
  // Props를 여기에 추가하세요
}

export const Badge: React.FC<BadgeProps> = ({
  // Props 분해
}) => {
  return (
    <div className="flex items-center justify-center">
      <p>컴포넌트 내용</p>
    </div>
  );
};

export default Badge;
```

## 팁

### Props 추가하기
생성 후 템플릿에서 Props 인터페이스 수정:

```tsx
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
}
```

### Tailwind 스타일 활용
기본 유틸리티 클래스 예시:
```tsx
<div className="flex flex-col gap-4 p-4 rounded-lg bg-white shadow-md">
  {/* 내용 */}
</div>
```

### ShadcnUI 통합
생성된 컴포넌트에 ShadcnUI 컴포넌트 임포트 가능:

```tsx
import { Button } from '@/components/ui/button';
```

## 자주 묻는 질문

**Q: 기존 컴포넌트를 덮어쓰나요?**
- A: 아니오. 같은 이름의 파일이 있으면 경고 후 생성하지 않습니다.

**Q: Props 인터페이스를 자동으로 생성할 수 있나요?**
- A: 현재는 빈 인터페이스로 생성되며, 수동으로 추가하셔야 합니다.

**Q: 다른 폴더에 생성할 수 있나요?**
- A: 현재는 `src/components/`에만 생성됩니다. 생성 후 파일을 이동하세요.
