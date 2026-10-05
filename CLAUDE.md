# CLAUDE.md — Unity 프로젝트 공통 컨벤션

> 이 파일은 Claude Code가 매 세션마다 자동으로 읽는 규칙집입니다.
> 코드 생성·수정·리팩토링 시 아래 규칙을 **반드시** 따르세요.
> 규칙을 벗어나는 판단이 필요하다고 느껴지면 코드 작성을 멈추고 사람에게 먼저 확인하세요.

---

## 1. 프로젝트 개요

- **엔진**: Unity 6 (6000.x)
- **언어**: C# (.NET Standard 2.1)
- **아키텍처**: Manager / Module / Service 3레이어 패턴
- **DI**: VContainer

---

## 2. 폴더 구조

폴더는 레이어(Manager/Module/Service)가 아니라 **기능 단위**로 분리합니다.

```
Assets/
├── 00_CommonFramework/        ← 두 프로젝트가 공유하는 공통 인프라
│   └── {대분류}/              ← 기능 그룹 (예: SystemManager, Gameplay)
│       └── {중분류}/          ← 구체 기능 (예: CameraManager, InputManager)
│           ├── {Feature}Manager.cs    ← 같은 기능의 모든 파일을 한 폴더에
│           ├── I{Feature}.cs
│           └── {Feature}Module.cs
├── 10_ProjectA/               ← 프로젝트 A 전용 (동일 구조)
└── 20_ProjectB/               ← 프로젝트 B 전용 (동일 구조)
```

**예시:**
```
00_CommonFramework/
└── SystemManager/
    └── CameraManager/
        ├── CameraManager.cs
        ├── IVirtualCamera.cs
        └── CameraSelectModule.cs
```

- 폴더 앞 숫자(`00_`, `10_`, `20_`)는 Unity Project 뷰 정렬 순서를 고정하기 위한 컨벤션입니다
- 같은 기능에 속하는 Manager · Module · Interface는 **같은 중분류 폴더**에 둡니다
- 공통 인프라는 반드시 `00_CommonFramework`에 작성하세요. `10_ProjectA` 또는 `20_ProjectB` 안에 인프라 코드를 직접 작성하지 마세요
- 어느 대분류·중분류에 넣어야 할지 판단이 서지 않으면 사람에게 확인하세요

---

## 3. 코드 컨벤션

### 네이밍

| 대상 | 규칙 | 예시 |
|---|---|---|
| 클래스 | PascalCase | `PlayerMover`, `EnemySpawner` |
| 인터페이스 | `I` 접두사 + PascalCase | `IInputReader`, `IDamageable` |
| 메서드·프로퍼티 | PascalCase | `GetHealth()`, `IsAlive` |
| private 필드 | `_` + camelCase | `_health`, `_speed` |
| 상수 | UPPER_SNAKE_CASE | `MAX_HEALTH`, `SPAWN_INTERVAL` |

### 클래스 역할

- **Manager**: 순수 C# 클래스. 두 가지 존재 방식이 있음:
  - 씬/전역 스코프 단독 존재 (예: GameManager) — VContainer 싱글턴으로 등록·주입
  - MonoBehaviour 단위 객체 소속 (예: 캐릭터·적처럼 개별 오브젝트가 있을 때) — MonoBehaviour가 필드로 소유하고 로직 위임
  - 가능하면 게임 로직을 직접 포함하지 않고 Module에 위임. 단, 기능이 1~2개로 단순하면 Module로 굳이 분리하지 않아도 됨
- **Module**: 순수 C# 클래스. Unity API에 의존하지 않음. `new`로 생성 가능해야 함
- **Service**: 파일·씬·에셋 등 외부 시스템 접점. 반드시 인터페이스로 추상화

### Module 분리 판단 기준

Manager · Module · Interface로 나누는 것 자체보다 **레이어 간 의존 방향을 지키는 것**이 더 중요하다. 처음부터 모든 기능을 Module로 쪼갤 필요는 없다. 나중에 기능이 늘거나 재사용이 필요해질 때 분리해도 된다 (예: 사칙연산만 있는 계산기라면 처음부터 `ComputeModule`을 만들 필요 없음).

판단이 애매하면 코드를 작성하기 전에 먼저 질문한다: "이 Manager에는 A기능, B기능, C기능이 있습니다. Module로 분리할까요, 아니면 Manager에 직접 구현할까요?"

### 의존 방향

```
Manager → Module
Manager → (interface를 통해) Service
```

- 역방향 금지: Module이 Manager를 직접 참조하면 안 됩니다
- Module끼리 직접 참조 금지: 필요 시 Manager를 통해 간접 통신
- 구체 클래스 직접 참조 금지: 항상 인터페이스를 통해 의존

---

## 4. 라이브러리 사용 범위

| 라이브러리 | 허용 범위 | 금지 |
|---|---|---|
| **VContainer** | Singleton Manager 등록·주입 | LifetimeScope 밖에서 `Container.Resolve<>()` 직접 호출 |
| **R3** | `ReactiveProperty`, `Subject`, `Subscribe`, `AddTo` | `SelectMany`, `FlatMap`, `Zip` 등 복잡한 Operator 체이닝 |
| **UniTask** | 파일 I/O, 씬 로딩, `UniTask.Delay` 시간 대기 | `Task`, `Thread`, 코루틴 혼용 |

허용 범위 밖의 기능이 필요하다고 판단되면 코드 작성을 **멈추고** 사람에게 먼저 확인하세요.

---

## 5. 금지 패턴

아래 패턴은 일반적으로 동작하더라도 이 프로젝트에서는 사용하지 마세요.

```csharp
// ❌ 씬 탐색 금지 — DI 주입으로 대체
FindObjectOfType<GameManager>();
GameObject.Find("Player");

// ❌ Singleton static Instance 직접 구현 금지 — VContainer 사용
public static T Instance { get; private set; }

// ❌ Resources.Load 금지 — AssetService(Addressables) 사용
Resources.Load<GameObject>("Prefabs/Enemy");

// ❌ PlayerPrefs 직접 접근 금지 — SaveService 사용
PlayerPrefs.SetInt("Score", 100);

// ❌ 비동기 혼용 금지 — UniTask async/await 단일 방식
StartCoroutine(SomeRoutine());
new Thread(() => { }).Start();

// ❌ 순수 로직을 MonoBehaviour에 직접 작성 금지 — Module로 분리
public class HealthLogic : MonoBehaviour { /* 순수 계산 로직 */ }
```

## 6. Memory
Memory 파일을 작성할 때 프로젝트 루트에 있는 Memory 폴더에도 똑같이 작성해서 git으로 파일을 관리할 수 있어야 한다.

## 코드 작성 라우팅

### 시스템 단위 → unity-dev-orchestrator
`docs/design/game-plan.md`의 시스템 단위 구현 요청("적 스폰 시스템 만들어줘", "다음 시스템 진행해")과
그 후속 요청("피드백 반영해줘", "다시", "이 버그만", "수치 조정")은 `unity-dev-orchestrator` Skill을 먼저 사용한다.
설계 승인 → 구현 → 리뷰 → 씬 구성 승인 → 4단계 검증 → 기록 흐름을 Orchestrator가 관리한다.

### 단일 클래스 소규모 수정 → add-feature
그 외 기능 추가·코드 작성 요청은 직접 처리하지 말고
반드시 add-feature 서브에이전트로 위임한다.

위임할 때 사용자 요청 원문을 그대로 전달한다.
"코드베이스를 검색·분석하라" 같은 지시나 분석 절차·판단 기준을 덧붙이지 않는다.
서브에이전트가 자체 정의(codebase-index.md 확인 → 유형 판단 → Skill 실행)대로 처리하도록 둔다.

## 하네스 (3D 탑다운 뱀서 MVP)
- 프로젝트 전용 코드: `Assets/10_ProjectA/00_Script/{대분류}/{중분류}/`, 네임스페이스 `O2un.ProjectA.{대분류}`
  (프리팹 `01_Prefabs`, SO `02_ScriptableObjects` — 폴더 인덱스는 `docs/conventions/convention.md`)
- 세부 C# 규칙: `docs/conventions/convention.md` → `csharp-convention-guide` Skill
- Agent: `.claude/agents/` (unity-architect, gameplay-engineer, code-reviewer, unity-ai-operator, add-feature)
- Skill: `.claude/skills/` (Orchestrator: `unity-dev-orchestrator`)
- 검증: Gate 1~3은 unity-ai-operator가 Unity 공식 MCP(`unity-mcp`)로 세션 안에서 수행, Gate 4는 Stop hook 뷰어(`.claude/hooks/open-viewer.ps1`, Node.js 필요)에서 제출
- 설계·검증·기록: `artifacts/` (C# 코드 금지), 지도는 `artifacts/README.md`
- 사람 승인: 설계안, 씬·프리팹·에셋 변경, `00_CommonFramework` 수정, 패키지·asmdef 추가

## 변경 이력
- 2026-10-05 unity-dev-harness로 오케스트레이션 하네스 구성 (Agent 4, Skill 5 신규, 기존 Skill 경로를 10_ProjectA로 갱신)
- 2026-10-05 `code-review` Skill → `convention-review`로 이름 변경 (내장 `/code-review` 명령과 충돌 방지)