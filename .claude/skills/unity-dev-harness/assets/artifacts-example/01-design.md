# 01. 설계

작성: unity-architect
일시: 2026-05-28 14:08
입력: `artifacts/00-input.md`

## 책임 분리
| 구성 | 책임 |
| --- | --- |
| `PlayerController` | 입력 수집, 이동 명령, 점프 명령, 지면 체크 결과 소비 |
| `GroundChecker` | Physics2D.OverlapCircle 기반 지면 판정 (분리해 재사용 가능) |
| `Rigidbody2D` | 실제 물리 적용 (PlayerController가 직접 velocity 조작) |

## 입력 → 물리 적용 흐름
```
Update()       → 입력 수집 (Horizontal, Jump)
              → groundChecker.IsGrounded 확인 (점프 가능 여부)
FixedUpdate()  → velocity.x = horizontal * moveSpeed
              → 점프 요청이 있고 grounded면 velocity.y = jumpForce, 요청 플래그 소거
```

## 필드/메서드 (요약)
```csharp
public class PlayerController : MonoBehaviour
{
    [SerializeField] float moveSpeed = 6f;
    [SerializeField] float jumpForce = 12f;
    [SerializeField] GroundChecker groundChecker;

    Rigidbody2D rb;
    float horizontal;
    bool jumpRequested;

    void Awake();
    void Update();        // 입력만 수집 (점프 요청 플래그 set)
    void FixedUpdate();   // 물리 적용 (이동·점프)
}

public class GroundChecker : MonoBehaviour
{
    [SerializeField] Transform checkPoint;
    [SerializeField] float radius = 0.1f;
    [SerializeField] LayerMask groundLayer;
    public bool IsGrounded { get; private set; }
    void FixedUpdate();
}
```

## 결정과 근거
- 입력 수집은 `Update`, 물리 적용은 `FixedUpdate`로 분리 (프레임 의존성 제거).
- 지면 체크는 `Physics2D.OverlapCircle` (간단·안정). Raycast 대비 코너 케이스 강함.
- 점프 요청을 플래그로 두는 이유: `Update`에서 감지한 키 입력을 다음 `FixedUpdate`에서 1회만 소비하기 위해.

## 컨벤션
- 직렬화 필드 `[SerializeField] private` 우선, public 필드 금지
- 매직넘버 제거 (속도·점프력은 SerializeField)

## 다음 단계
gameplay-engineer → `Assets/Scripts/Player/PlayerController.cs`, `Assets/Scripts/Player/GroundChecker.cs` 작성
