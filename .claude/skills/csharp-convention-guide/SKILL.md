---
name: csharp-convention-guide
description: 이 프로젝트의 C# 작성 규칙 모음. gameplay-engineer가 C# 코드를 작성·수정할 때, code-reviewer가 컨벤션을 점검할 때 참조한다. 원문은 docs/conventions/convention.md와 CLAUDE.md이며 이 Skill은 그 내용을 작업용 체크리스트로 옮긴 것이다. 설계 판단(어떤 클래스를 만들지)에는 system-design Skill을 쓴다.
---

# C# 컨벤션 가이드

원문: `docs/conventions/convention.md`, `CLAUDE.md`. 둘이 충돌하거나 이 문서와 원문이 다르면 **원문이 우선**이고, 판단이 서지 않으면 멈추고 사람에게 묻는다.

## 1. 위치와 네임스페이스

| 대상 | 규칙 |
| --- | --- |
| 프로젝트 전용 코드 | `Assets/10_ProjectA/00_Script/{대분류}/{중분류}/` |
| 프리팹 / SO / 3D 리소스 / 렌더 / 개발용 | `10_ProjectA/01_Prefabs`, `02_ScriptableObjects`, `51_3DResources`, `90_Render`, `99_DEV` |
| 공통 인프라 | `Assets/00_CommonFramework/00_Scripts/...` — **수정·추가는 사람 승인 필요** |
| 네임스페이스 (ProjectA) | `O2un.ProjectA.{대분류}` (예: `O2un.ProjectA.Enemy`) |
| 네임스페이스 (Common) | 기존 그대로 `O2un.{대분류}` |

같은 기능의 Manager·Module·Interface는 같은 중분류 폴더에 둔다.

## 2. 네이밍

| 대상 | 규칙 |
| --- | --- |
| 네임스페이스·클래스·메서드·프로퍼티 | PascalCase |
| 인터페이스 | `I` + PascalCase |
| 멤버 필드 | `_camelCase` |
| 지역변수·파라미터 | camelCase |
| 상수 | `ALL_UPPER_SNAKE_CASE` |

## 3. 기타 규칙 (convention.md)

- **if 비교는 평가값을 앞에**: `if (null == target)`, `if (false == isAlive)`, `if (0 >= hp)`
- **Find 금지**: `FindObjectOfType`, `GameObject.Find` 금지 (에디터 툴 전용 코드만 예외)
- **캐싱**: `RequireComponent`로 보장된 컴포넌트만 지연 캐싱. 외부에서 받는 참조는 DI로.
  ```csharp
  [RequireComponent(typeof(Rigidbody))]
  private Rigidbody _body;
  public Rigidbody Body => _body ??= GetComponent<Rigidbody>();
  ```
  (UnityEngine.Object가 아닌 순수 C# 클래스만 `??=` 사용 가능 — UnityEngine.Object 필드는 위 패턴처럼 `GetComponent` 결과에만 사용)
- **빈 함수는 명시**: 본문에 `// NULL`. 아직 구현 전인 필수 항목은 `throw new System.NotImplementedException();`로 남긴다.
- **파라미터가 많아지면 묶는다**: 특정 클래스 전용이면 `{Class}Context`, 공통이면 `CommonParameter` 형태의 sealed 클래스로 묶어 주입. 파라미터 과다는 책임 분리 실패 신호로 보고 설계를 다시 본다.
- **주석**: 기능·블록 설명 주석과 XML 문서 주석을 달지 않는다. 의도는 네이밍으로 드러낸다. (`// NULL`과 convention.md가 요구하는 구획 표시는 예외)

## 4. DI (VContainer)

- 스코프 계층: `ProjectLifetimeScope`(앱 수명 SystemManager) → 씬 스코프(`GameSceneScope` 등)
- 씬 한정 Manager는 씬 스코프에 등록. `LifetimeScope` 밖에서 `Container.Resolve<>()` 호출 금지.
- **MonoBehaviour는 필드에 `[Inject]`**를 붙인다(생성자/메서드 주입 아님). 주입 후 초기화가 필요하면 `IInitializable`.
- 순수 C# 클래스는 생성자 주입.
- **클래스 작성 순서**:
  1. DI로 받은 `readonly` 필드
  2. 생성자 (생성자 위에는 DI 필드만)
  3. Reactive 필드(`ReactiveProperty`, `Subject`)와 읽기 전용 노출 프로퍼티
  4. 초기화(`Initialize`/`InitAsync`)에서 구독·가공. 구독이 많으면 `SubscribeXxx()`로 분리
  5. 이하 자유

```csharp
public sealed class EnemySpawnManager : IInitializable, IDisposable
{
    private readonly IWaveTable _waveTable;
    private readonly IGameFlow _gameFlow;
    public EnemySpawnManager(IWaveTable waveTable, IGameFlow gameFlow)
    {
        _waveTable = waveTable;
        _gameFlow = gameFlow;
    }

    private readonly ReactiveProperty<int> _aliveCount = new();
    public ReadOnlyReactiveProperty<int> AliveCount => _aliveCount;
    private readonly CompositeDisposable _disposables = new();

    public void Initialize()
    {
        SubscribeGameFlow();
    }

    private void SubscribeGameFlow() { }

    public void Dispose()
    {
        _disposables.Dispose();
        _aliveCount.Dispose();
    }
}
```

## 5. 레이어와 의존 방향 (CLAUDE.md)

- Manager → Module, Manager → (interface) → Service. 역방향·Module 간 직접 참조 금지.
- Module: 순수 C#, Unity API 비의존, `new`로 생성 가능. 상태 변화는 `ReactiveProperty`/`Subject`로 노출 (C# event 금지).
- Service: 파일·씬·에셋 등 외부 접점. 반드시 인터페이스로 추상화.
- 구체 클래스 직접 참조 금지 — 인터페이스로 의존.
- 순수 로직을 MonoBehaviour에 직접 작성 금지. MonoBehaviour는 Context(DI 진입점)·View(Transform/물리/렌더 반영) 역할만.

## 6. 라이브러리 허용 범위

| 라이브러리 | 허용 | 금지 |
| --- | --- | --- |
| VContainer | Singleton Manager 등록·주입 | 스코프 밖 `Resolve` |
| R3 | `ReactiveProperty`, `Subject`, `Subscribe`, `AddTo` (`Observable.Interval`/`EveryUpdate` 등 기존 코드에 쓰인 기본 팩토리 포함) | `SelectMany`, `FlatMap`, `Zip` 등 복잡한 Operator 체이닝 |
| UniTask | 파일 I/O, 씬 로딩, `UniTask.Delay` | `Task`, `Thread`, 코루틴 혼용 |

금지 패턴: `static Instance` 싱글턴, `Resources.Load`, `PlayerPrefs` 직접 접근, `StartCoroutine`.
범위 밖 기능이 필요하면 **코드 작성을 멈추고** 사람에게 확인한다.

## 7. 성능 (뱀서 특성상 중요)

- 적·투사체·경험치 오브젝트는 수백 개 단위로 생긴다. `Instantiate`/`Destroy` 반복 대신 풀링을 설계에서 정한다.
- `Update` 안에서 LINQ, 문자열 조합, 클로저 할당, `GetComponent` 금지.
- 최근접 탐색 등 O(n²)이 될 수 있는 로직은 설계 문서의 방식(예: 주기 제한, 공간 분할)을 따른다.

## 8. 작성 후 자체 점검

- [ ] 위치·네임스페이스가 1번 표와 일치
- [ ] if 평가값 앞 배치
- [ ] Find·Instance·Resources·PlayerPrefs·Coroutine 없음
- [ ] MonoBehaviour 주입은 필드 `[Inject]`
- [ ] 클래스 작성 순서 준수
- [ ] 기능 설명 주석 없음
- [ ] Module에 `using UnityEngine` 없음 (수학 타입이 꼭 필요하면 설계 문서에 근거가 있어야 함)
