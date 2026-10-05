---

name: create-component

description: 새로운 컴포넌트(기능 단위)를 처음부터 만든다. 기존 클래스 수정이 아니라 새 Manager·Module·Service 등을 새로 추가할 때 사용한다. 필요하면 베스트 프랙티스와 최신 API를 확인한 뒤 만든다.

argument-hint: "[만들 컴포넌트명과 역할]"

---

**$ARGUMENTS** — 새 컴포넌트를 프로젝트 컨벤션에 맞게 만든다.

## 1. 만들기 전 조사

- 익숙하지 않은 패턴·라이브러리 사용이 필요하면 **베스트 프랙티스**를 먼저 확인한다 (필요 시 웹 검색)
- Unity·VContainer·R3·UniTask 등 라이브러리의 **최신 API**가 필요하면 **context7**으로 현재 문서를 확인한다. 기억에만 의존해 옛 API를 쓰지 않는다
- CLAUDE.md의 라이브러리 허용 범위를 벗어나는 기능이 필요하면 멈추고 사람에게 먼저 확인한다

## 2. 컴포넌트 종류 판단 → 적절한 Skill로 라우팅

- **씬/전역 스코프 싱글턴 Manager** (GameManager, UIManager 등) → `add-global-manager` Skill로 라우팅
- **Manager가 위임할 순수 로직 Module** → `add-module` Skill로 라우팅
- **개별 오브젝트(캐릭터·적 등) 소속 Manager / Service / 그 외** → CLAUDE.md 컨벤션에 따라 직접 생성
- 어느 종류·위치에 둘지 애매하면 코드 작성 전에 사람에게 먼저 확인한다

## 3. 생성 후 검증

- 폴더가 기능 단위(대분류/중분류)로 올바르게 배치됐는지 확인
- 공통 인프라면 `00_CommonFramework`에 있는지 확인
- 의존 방향(Manager → Module, Manager →(interface)→ Service)을 지키는지 확인
- CLAUDE.md 금지 패턴 위반 없는지 확인