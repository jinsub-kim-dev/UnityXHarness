# 글로벌 네이밍 룰

코드를 한눈에 어떤 용도인지 알 기 쉽게 표시하나 굳이 헝가리안 표기까지는 가지 않는다

| 용도 | 규칙 | 비고 |
| --- | --- | --- |
| 네임스페이스 | PascalCase |  |
| 클래스 | PascalCase |  |
| 인터페이스 | IPascalCase | 인터페이스는 클래스와 명확히 구분하기 위해 I를 붙임  |
| 메소드(함수) | PascalCase |  |
| 맴버변수(필드) | _camelCase | _(언더바)소문자시작 |
| 프로퍼티 | PascalCase |   |
| 지역변수(파라미터 포함) | camelCase | 소문자시작 카멜케이스 |
| 글로벌 상수 | ALL_UPPER_SNAKE_CASE | 상수 사용은 특별한 케이스기 때문에 전부 대문자 사용하여 명확히 표기함 |
- 네임스페이스
    
    3rd 파티 또는 작업자간의 네이밍 중복 처리를 위해 공통 룰을 가지고 네임스페이스를 만든다 
    
    ```csharp
    namespace 프로젝트명.대분류.모듈
    {
    }
    ```
    
    - 표
        
        현재는 예시 표 실제 작업시 추가
        
        | 대분류 | 모듈 | 비고 |
        | --- | --- | --- |
        | Core | Math | 프로젝트 공통, 전역 Utils extension 등 |
        | Manager | Input | 프로젝트 공통 매니저 |
        |  | Camera | 프로젝트 공통 매니저 |
        | Actors |  | 종류가 많아질 수 있는 비슷한 객체,개념 묶음 |
        | ProjectA | Manager | 프로젝트 전용 매니저 |
        |  | UI | 프로젝트 전용 UI |
    
- 폴더
    
    3rd 파티 및 유니티 기본 폴더들과 작업을 구분하기 위해 폴더명 규칙을 통일하도록 한다.
    
    내부 개발 폴더는 가장 상단에 위치하도록 **00.{ProjectName}** 로 명명한다
    
    내부 폴더는 개발자가 자주사용하는 순서를 기준으로 순서를 정한다
    
    | Index | 폴더명 | 용도 |
    | --- | --- | --- |
    | 00 | Script | 스크립트 |
    | 01 | Prefabs | 프리팹 |
    | 02 | ScriptableObjects | 스크립터블 오브젝트 |
    | 50 | 2DResources | 2D 리소스 |
    | 51 | 3DResources | 3D 리소스 |
    | 90 | Render | Materials , Shader 등 랜더관련 피쳐 |
    | 99 | DEV | 개발 관련 폴더 |
    | __ | 3rd | 3rd 파티 관련 폴더 등 |
    
    이하 세부 폴더는 자유롭게 작성한다
    

## 기타 규칙

- **if 규칙**
    1. IF 사용할때는 평가값이 앞으로 오도록 한다 if(false == something) , if(null == gameObject)
    2. 이유는 if(something = false) , if(gameObject = null) 등의 작성 실수 방지
- **캐싱**
    1. 게임 오브젝트를 캐싱하는경우가 있음 FindObject( “name”), getComponent 등..
        1. 최우선 규칙은 FindObject는 사용하지 않는다.
        2. 꼭 필요할경우 상의 후 사용하도록 한다.
        3. 에디터 툴에서만 사용되는 경우에는 예외(사용해도 크게 상관 없음)
    2. 캐싱을 하는경우 아래 규칙을 따라 사용
        
        ```csharp
        // Require인것만 캐싱해서 사용 외부에서 받아오는 캐싱은 DI규칙을 따른다
        [RequireComponent(typeof(SomeClass)]
        private SomeClass _chache;
        public SomeClass Cache => _chache ??= GetComponent<SomeClass>();
        
        // UnityEngine.Object 가아닌 NativeC# 클래스는 ??= 를 사용해도 된다.
        ```
        
- **내용이 없는 함수의 경우 명시적으로 표기**
    
    전제는 아래와 같다
    
    - 보통 abstract 클래스로인해 필수로 선언된 함수이지만 사용하지 않을때 (많아지면 설계의 문제이다  virtual 로변경하거나 클래스 분리를 고려하라
    - 위 조건으로 인해 선언 되었는데 아직 개발 구현 전 일경우 throw new System.NotImplementedException(); 를 호출하면 게속 예외 발생하니까 나지 않도록 하기 위함 필수 구현 항목일경우 NULL 입력하지 않고 예외 던지는 상태로 남겨둔다
    
    ```csharp
    void override Start()
    {
    // NULL
    }
    ```
    

## Dependency Injection

VContainer 를 DI 3rd파티로 사용한다.

DI 계층은 아래 계층 구조를 따른다.

<aside>
💡

- ProjectRootScope
    - SceneScope
</aside>

#### PorjectRootScope

프로그램이 실행되고 종료될때 까지 유지되는 SystemManager 클래스들 ProjectRootScope.cs 에 작성한다

RootScope 예시

| Class | 용도 | 비고 |
| --- | --- | --- |
| LogManager | 로그 매니저 |  |
| SceneManager | 씬 매니저 |  |
| InputManager | 입력 매니저 |  |

### SceneScope - CommonLifetimeScope

각 씬(모드)에 만 존재하면 되는 매니저 클래스 수동 바인딩 처리 등을 위하여 사용한다 CommonLifetimeScope 를 상속받도록 한다

Auto Inject GameObjects 대신 UI Roots 와 Batched Root Transform을 Inspector로 입력 받아 자동 주입 처리를 한다 IInitializable 일경우 주입 후 Initialize등 추가 처리를 호출해주기 위해서 사용함

### Mono Class

모노 클래스 Constructor 에 [Inject]를 넣는걸 빼먹는 실수가 많이 나와서 그냥 필드 자체에 [Inject]를 붙이는 규칙 사용 주입후 초기화처리가 필요할경우 IInitializable 를 상속받아 Initialize 를 호출하여 처리함

### 파라미터 갯수

파라미터 갯수가 늘어나면 별도 클래스로분리해서 처리한다 대표적인 사례는 부모클래스에 파라미터를 넘겨야 할 때 이다 아래 예시 확인

하나의 클래스에서 여러개의 파라미터를 받는데 해당 컨텐츠에 한정되는 경우 가독성을 위해 묶어서 처리해준다

- 코드
    
    ```csharp
    public sealed class CommonParameter
        {
            public DialogService DialogService {get;}
            public UISiwtchService UISwitch {get;}
            public PoolingManager PoolingManager {get;}
            public ReadonlyTr start{get;}
            public ReadonlyTr goal{get;}
            
            public CommonFieldParameter(DialogService calcService,
                UISiwtchService ui,
                PoolingManager pool,
                ReadonlyTrProvider provider)
            {
                DialogService = calcService;
                UISwitch = ui;
                PoolingManager = pool;
                
                start= provider.Get(Type.start);
                goal= provider.Get(Type.goal);
            }
        }
        
        public abstract class CommonManager : GameSubsystemBase
        {
    		    private readonly DialogService _dialog;
    		    private readonly UISiwtchService _ui;
    		    ...
    		    public CommonFieldManager(CommonParameter commonParam)
            {
    		        _dialog= commonParam.DialogService;
                _ui= commonParam.UISwitch ;
                ...
            }
        }
        
    		public sealed class RealManager : CommonManager
    		{
    				private readonly RealUIStateStore _uiState;
    		    private readonly RealNetwork _network;
    			  private readonly ISceneService _sceneService;
    			  ...
    				public RealManager(CommonParameter commonParam, RealManagerContext context, ISceneService sceneMnager)) : base(commonParam)
    				{
    						_readOnlyDialog = commonParam.DialogService;
    				
    						_uiState = context.UIState;
    						_network = context.NetworkManager;
    						_sceneService = sceneMnager;
    				}
    		}
            
    	  // RealManager만 주입받는 context 모음
    	  public sealed class RealManagerContext
        {
            public RealUIStateStore UIState {get;}
            public RealNetwork NetworkManager {get;}
            ...
            public OnGreenManagerContext(RealUIStateStore uiState, RealInfoStore infoWriter, RealNetwork network)
            {
                UIState = uiState;
                NetworkManager = network;
            }
        }
    ```
    

또한 하나의 클래스에 너무 많은 파라미터가 추가된다는건 기능분리가 제대로 되지 않는 증거가 될 수있어 SOLID 원칙 깨고 있지 않은지 확인 필요하다

### DI 규칙과 가독성을 위해 클래스는 아래 순서를 따라 작성한다

```csharp
public sealed class ClassName : Parent, Interface
{
		private readonly InjectedClass _injectedClass;
		public ClassName(InjectedClass inject)
		{
				_injectedClass = inject
		}
		// 생성자 위로는 DI받은 클래스만 작성한다
		// 생성자 아래는 Reactive 변수 들을 작성한다
		private readonly ReactiveProperty<int> _value = new();
		public ReadOnlyReactiveProperty<int> Value => _vlaue;
		
		// Init 에서 Reactive 변수들을 가공하고 구독한다
		protected override async UniTask InitAsync()
		{
				await base.InitAsync();
				_injectedClass.ReactiveValue.Subscribe(x=>_value = x.Reolve()).AddTo(DisposableR3);
				
				// 구독과 가공할 변수가 많으면 함수 분리는 자유롭게 한다
				SubscribeNetworkReactive();
				SubscribeManager();
    }
    
    private SubscribeNetworkReactive(){}
    private SubscribeManager(){}
    
    // 이하 자유롭게 코드 작성
}
```