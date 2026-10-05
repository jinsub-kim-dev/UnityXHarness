# Codebase Index — `Assets/00_CommonFramework/00_Scripts`

> 각 클래스가 담당하는 기능과 역할 정리. 코드 변경 시 함께 갱신할 것.
> 루트 네임스페이스: `O2un`

---

## 1. 전체 구조 한눈에 보기

```
ProjectLifetimeScope (전역, 앱 수명)
├── InputManager        (EntryPoint, IInputReader)
├── DataProvider        (JSON 파일 저장/로드)
├── OptionManager       (IRootTask)
├── SceneManager        (ISceneService, ILoadingSource)
└── ProjectBootStrap    (EntryPoint: IRootTask 대기 → GameScene 로드)

LoadingSceneScope (Loading 씬) — 등록 없음, 부모 스코프의 ILoadingSource 사용
└── LoadingContext → LoadingVM → LoadingView

GameSceneScope (GameScene)
├── CameraManager
├── UIStore             (IUIReader, IUIWriter)
├── PlayerDataStore     (IPlayerDataReader, IPlayerDataWriter)
├── GameManager         (IGameFlow, IStartable)
└── ScoreManager        (IScoreReader, IScoreWriter)
    ├── PlayerContext → PlayerActor → PlayerMover / PlayerView
    ├── HudContext    → HudVM   → HudView
    └── ScoreContext  → ScoreVM → ScoreView
```

### 부팅 흐름
1. `ProjectLifetimeScope`가 전역 Manager들을 등록
2. `InputManager.Initialize()` — Input Actions 콜백 연결, Player 맵 활성화
3. `ProjectBootStrap.StartAsync()` — 모든 `IRootTask.WaitUntilReadyAsync()`를 병렬 대기 (현재 `OptionManager`만 해당)
4. `SceneManager.LoadSceneAsync(GAME_SCENE)` — Loading 씬 경유 후 GameScene 활성화
5. `GameSceneScope` 생성 → `GameManager.Start()`에서 게임 시작 (`GameState.Playing`)

### UI 패턴 (Context → VM → View)
- **Context** (MonoBehaviour): `[Inject]`로 의존성을 받아 VM 생성 후 View에 바인딩, `OnDestroy`에서 VM 해제
- **VM** (순수 C#): 데이터 소스를 구독해 화면용 `ReadOnlyReactiveProperty`로 가공
- **View** (MonoBehaviour): VM을 구독해 실제 UI 컴포넌트 갱신 (`AddTo(this)`)

---

## 2. DI (`DI/`) — 네임스페이스 `O2un.DI`

| 클래스 | 종류 | 역할 |
|---|---|---|
| `ProjectLifetimeScope` | `LifetimeScope` | 전역(프로젝트) 스코프. `InputManager`·`ProjectBootStrap`을 EntryPoint로, `DataProvider`·`OptionManager`·`SceneManager`를 Singleton(`AsImplementedInterfaces().AsSelf()`)으로 등록 |
| `GameSceneScope` | `LifetimeScope` | GameScene 스코프. 인스펙터의 `CinemachineCamera` 2개(`_gamePlay`, `_cinematic`)를 `CameraManager` 생성자 파라미터로 전달. `UIStore`·`PlayerDataStore`·`GameManager`·`ScoreManager`를 인터페이스로 등록 |
| `LoadingSceneScope` | `LifetimeScope` | Loading 씬 스코프. 등록 없이 부모 스코프 의존성만 사용 |
| `ProjectBootStrap` | `IAsyncStartable` | 앱 시작 진입점. 주입된 모든 `IRootTask`의 준비 완료를 `UniTask.WhenAll`로 대기한 뒤 GameScene 로드 |
| `IRootTask` | interface | 부팅 시 비동기 초기화가 필요한 Manager가 구현. `UniTask WaitUntilReadyAsync()` |

---

## 3. Manager (`Manager/`)

### Camera — `O2un.Camera`
| 클래스 | 역할 |
|---|---|
| `CameraManager` | Cinemachine 카메라 2대(게임플레이/시네마틱) 전환 관리. 생성 시 게임플레이 카메라 Priority=10. `SetFollowTarget(Transform)`으로 Follow/LookAt 설정, `SwitchToGamePlay()`(시네마틱 Priority=0) / `SwitchToCinematic()`(시네마틱 Priority=20)로 전환 |

### DataProvider — `O2un.Data`
| 클래스 | 역할 |
|---|---|
| `DataProvider` | 타입별 JSON 파일 영속화. 경로는 `Application.persistentDataPath/{TypeName}.json`. 메모리 캐시(`_cache`) + 변경 추적(`_dirty`) 구조 |
| | `Load<T>()` — 캐시 우선, 없으면 파일 읽기(없으면 `new T()`) 후 캐싱 |
| | `Save<T>(data)` — 캐시 갱신 + dirty 표시만 (디스크 기록 X) |
| | `Flush<T>()` / `Flush()` — dirty 상태인 타입(들)을 실제 파일로 기록 |

### Game — `O2un.Game`
| 클래스 | 역할 |
|---|---|
| `GameState` | enum: `Ready`, `Playing`, `Paused`, `GameOver` |
| `IGameFlow` | 게임 흐름 제어 인터페이스. `State`, `StartGame()`, `Pause()`, `Resume()`, `Restart()` |
| `GameManager` | `IGameFlow` 구현 + `IStartable`. 게임 상태 머신과 `Time.timeScale` 제어(Playing=1, Paused/GameOver=0). `Start()`에서 `IPlayerDataReader.CurrentHP`를 구독해 HP≤0이면 `EndGame()` → `GameOver`. `Restart()`는 `ISceneService`로 GameScene 재로드. 각 전이는 현재 상태 검사 후에만 수행 |

### Input — `O2un.Input`
| 클래스 | 역할 |
|---|---|
| `IInputReader` | 입력 읽기 인터페이스. `Move`(`ReadOnlyReactiveProperty<Vector2>`), `IsJumpPressed`(`Observable<Unit>`) |
| `InputType` | enum: `Player`, `UI` |
| `InputManager` | `IInputReader` 구현 + `IInitializable`. 자동 생성된 `GameInput` 액션 에셋을 소유하고 각 액션맵 콜백을 Module에 연결. `SwitchInput(InputType)`으로 Player/UI 액션맵 전환. `Dispose()`에서 콜백 해제 및 액션 해제 |
| `PlayerInputModule` | `GameInput.IPlayerActions` 구현. `OnMove` → `Move` ReactiveProperty 갱신, `OnJump`(performed) → `Jump` Subject 발행 |
| `UIInputModule` | `GameInput.IUIActions` 구현. 현재 `OnNewaction`만 있고 미구현(`NotImplementedException`) — 자리만 잡아둔 상태 |

### OptionManager — `O2un.Manager`
| 클래스 | 역할 |
|---|---|
| `OptionManager` | `IRootTask` 구현. 부팅 시 `DataProvider.Load<OptionsData>()`로 옵션 로드. `Save(OptionsData)`로 DataProvider에 저장 위임. 로드한 `_data`를 외부에 노출하는 API는 아직 없음 |

### SceneManager — `O2un.Manager`
| 클래스 | 역할 |
|---|---|
| `ISceneService` | 씬 로딩 서비스 인터페이스. `UniTask LoadSceneAsync(string)` |
| `SCENE_NAME` | 씬 이름 상수: `LOADING_SCENE = "Loading"`, `GAME_SCENE = "GameScene"` |
| `SceneManager` | `ISceneService` + `ILoadingSource` 구현. Loading 씬을 경유하는 2단계 씬 전환. 상태(`SceneState`: `Idle` → `TransitionToLoading` → `LoadingTarget` → `TransitionToTarget`)와 진행률(`LoadingProgress`)을 ReactiveProperty로 노출. `allowSceneActivation=false`로 대상 씬을 0.9까지 로드한 뒤 활성화. `Idle`이 아니면 중복 요청 무시, `finally`에서 Idle로 복귀. ※ 테스트용 `UniTask.Delay(1000)`이 루프 안에 있음 |

### Score — `O2un.Score`
| 클래스 | 역할 |
|---|---|
| `IScoreReader` | 점수 읽기. `Score`(`ReadOnlyReactiveProperty<int>`) |
| `IScoreWriter` | 점수 쓰기. `AddScore(int basePoint)` |
| `IScoreCalculator` | 점수 계산 규칙. `int Calculate(int basePoint)` |
| `ScoreCalculateModule` | `IScoreCalculator` 구현. 현재는 basePoint를 그대로 반환 (배율·보너스 등 확장 지점) |
| `ScoreManager` | `IScoreReader`/`IScoreWriter` 구현. `ScoreCalculateModule`을 내부 생성해 계산 위임 후 누적 |

---

## 4. Actor (`Actor/`) — 네임스페이스 `O2un.Actor` / `O2un.DataStore`

| 클래스 | 종류 | 역할 |
|---|---|---|
| `PlayerContext` | MonoBehaviour | 플레이어 오브젝트의 DI 진입점. `[Inject]`로 `IInputReader`·`IPlayerDataWriter`를 받아 `PlayerActor` 생성·초기화, `OnDestroy`에서 해제 |
| `PlayerActor` | 순수 C# (오브젝트 소속 Manager 역할) | 플레이어 로직 조율자. `PlayerMover`를 생성하고 `Velocity`를 `PlayerView`에 전달. 생성 시 HP=100 설정, 1초마다 HP -1 감소(`Observable.Interval`) |
| `PlayerMover` | 순수 C# (Module 역할) | 입력 → 이동 계산. `Move` 입력을 속도(`_speed=5`)를 곱한 XZ 평면 `Velocity`로 변환. 점프 입력 시 `JumpImpulse`(`_jumpForce=8`) 발행 (현재 구독자 없음) |
| `PlayerView` | MonoBehaviour | 실제 Transform 이동. `SetVelocity`로 받은 방향을 `FixedUpdate`에서 `transform.Translate` |
| `IPlayerDataReader` | interface | `CurrentHP`, `MaxHP` 읽기 전용 노출 |
| `IPlayerDataWriter` | interface | `Vary(int)` (증감), `SetCurrentHP(int)` |
| `PlayerDataStore` | 순수 C# | 플레이어 런타임 상태 저장소(HP). `Vary`는 0~MaxHP로 Clamp. MaxHP 기본값 100. Reader/Writer 분리로 쓰기 권한 제한 |

---

## 5. UI (`UI/`) — 네임스페이스 `O2un.UI` / `O2un.DataStore`

| 클래스 | 종류 | 역할 |
|---|---|---|
| `UIType` | enum | UI 종류: `HUD` |
| `IUIReader` / `IUIWriter` | interface | UI 표시 여부 읽기(`GetVisible`) / 쓰기(`Show`, `Hide`) |
| `UIStore` | 순수 C# | `UIType`별 표시 여부를 `ReactiveProperty<bool>`로 보관하는 저장소 (네임스페이스는 `O2un.DataStore`) |
| `HudContext` | MonoBehaviour | `IUIReader`·`IPlayerDataReader` 주입 → `HudVM` 생성 → `HudView` 바인딩 |
| `HudVM` | 순수 C# | `IsVisible`(UIStore의 HUD 표시 여부), `CurrentHP`(HP 비율 0~1 = CurrentHP/MaxHP) 제공 |
| `HudView` | MonoBehaviour | `IsVisible`로 GameObject 활성/비활성, HP 비율로 `Image.fillAmount`와 `%` 텍스트 갱신 |
| `ILoadingSource` | interface | 로딩 진행률 `LoadingProgress` 제공 (`SceneManager`가 구현) |
| `LoadingContext` | MonoBehaviour | `ILoadingSource` 주입 → `LoadingVM` 생성 → `LoadingView` 바인딩 |
| `LoadingVM` | 순수 C# | `ILoadingSource.LoadingProgress`를 `Progress`로 그대로 전달 |
| `LoadingView` | MonoBehaviour | 진행률로 `Image.fillAmount`와 `%` 텍스트 갱신 |
| `ScoreContext` | MonoBehaviour | `IScoreReader` 주입 → `ScoreVM` 생성 → `ScoreView` 바인딩 |
| `ScoreVM` | 순수 C# | `IScoreReader.Score`를 구독해 자체 `Score` 프로퍼티로 미러링 |
| `ScoreView` | MonoBehaviour | 점수를 `TMP_Text`에 표시 |

---

## 6. Data (`Data/`) — 네임스페이스 `O2un.Data`

`[Serializable]` POCO. `DataProvider`가 JSON으로 저장/로드하는 영속 데이터.

| 클래스 | 필드 | 사용처 |
|---|---|---|
| `OptionsData` | `MusicVolume`(1.0), `SfxVolume`(1.0), `Language`("ko") | `OptionManager` |
| `PlayerData` | `HighScore`(0), `CurrentChapter`(1), `Gold`(0) | 현재 사용처 없음 |

---

## 7. 인터페이스 → 구현체 매핑

| 인터페이스 | 구현체 | 등록 스코프 |
|---|---|---|
| `IInputReader` | `InputManager` | Project |
| `ISceneService`, `ILoadingSource` | `SceneManager` | Project |
| `IRootTask` | `OptionManager` |ㅔㅔ Project |
| `IGameFlow` | `GameManager` | GameScene |
| `IPlayerDataReader`, `IPlayerDataWriter` | `PlayerDataStore` | GameScene |
| `IUIReader`, `IUIWriter` | `UIStore` | GameScene |
| `IScoreReader`, `IScoreWriter` | `ScoreManager` | GameScene |
| `IScoreCalculator` | `ScoreCalculateModule` | (DI 미등록, `ScoreManager` 내부 `new`) |

---

## 8. 코드 리딩 중 발견한 이슈 / 컨벤션 차이

- `InputManager.Dispose()`가 `PlayerInputModule`·`UIInputModule`의 `Dispose()`를 호출하지 않음 (ReactiveProperty/Subject 미해제)
- `DataProvider`는 파일 I/O를 담당하는 Service 성격이지만 인터페이스 없이 구체 클래스로 `OptionManager`에 주입됨 (CLAUDE.md "Service는 인터페이스로 추상화", "구체 클래스 직접 참조 금지"와 차이)
- `DataProvider.Flush()`가 `UniTaskVoid` — 호출 측에서 완료 대기 불가. 현재 `Flush`를 호출하는 곳 없음 (저장이 디스크에 반영되지 않음)
- `SceneManager` 로딩 루프의 `UniTask.Delay(1000)`은 테스트용 지연
- `PlayerMover.JumpImpulse`를 구독하는 곳 없음, `PlayerView`의 점프 관련 필드는 주석 처리됨
- `UIInputModule.OnNewaction`은 `NotImplementedException` — UI 액션맵 활성화 후 해당 액션 입력 시 예외 발생
- `ProjectBootStrap.cs`에 사용하지 않는 `using`(`System.Collections`, `System.Threading.Tasks`)이 있음. `Select`를 쓰지만 `using System.Linq`가 없음 (컴파일 여부 확인 필요)
- `CameraManager`가 DI에 등록돼 있지만 아직 사용하는 곳 없음
- `UIStore`는 `UI/` 폴더에 있지만 네임스페이스는 `O2un.DataStore`, `PlayerDataStore`는 `Actor/` 폴더에 있음
