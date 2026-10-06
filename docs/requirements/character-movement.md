# Character Movement (CharacterMover + PlayerInputModule)

## Overview

탑다운 3D 뱀서에서 캐릭터를 이동시키는 시스템. 이동 실행 로직인 **CharacterMover**(플레이어·적 공용)와, 키보드 입력을 raw로 받는 **PlayerInputModule**, 그리고 그 입력을 카메라 기준 월드 방향으로 바꾸는 **교체 가능한 방향계산 Module**로 구성된다. 게임 코어 루프 ①(이동)의 기반이며, 이후 모든 시스템(추격 AI·자동공격 등)이 이 위에 얹힌다. CharacterController를 실제로 소유·구동하는 주체는 MonoBehaviour인 **ActorView**다.

## Goals

- 방향·속도를 받아 캐릭터를 XZ 평면에서 이동시키는 범용 `CharacterMover`를 제공한다.
- 플레이어·적이 동일한 `CharacterMover`를 재사용한다 (입력원·방향 소스만 다름).
- `PlayerInputModule`은 raw 키보드 입력만 담당하고 프로젝트 간 그대로 재사용한다.
- 카메라 기준 방향 계산을 별도 Module로 분리해, 프로젝트B에서 방향계산 Module만 교체 가능하게 한다.
- 이동 속도 등 스탯을 데이터로 주입받아, 이후 몬스터 스폰 시 데이터 기반 생성이 가능하게 한다.
- 캐릭터가 이동방향을 향해 부드럽게 보간 회전한다.
- `ActorView`가 `CharacterController`로 이동·회전 결과를 프레임레이트 독립적으로 반영한다.

## Out of Scope

- 점프·중력·낙하 (탑다운 평면 이동만; 기존 `PlayerMover`의 점프 로직 제거).
- 적 추격 AI의 목표 방향 계산 (별도 PRD; CharacterMover에 방향을 주입하는 쪽).
- 대시·넉백·이동 상태이상(슬로우/스턴) 등 이동 변형.
- 애니메이션 블렌딩·발소리 등 연출.
- 이동 가능 영역/충돌 지형 설계.
- 몬스터 스탯 데이터 스키마 자체 설계 (여기서는 속도 주입 경로만 확보).

## Technical Requirements

**CharacterMover** (`O2un.Actors`, 순수 C# Module, `new` 생성 가능)
- 입력: 월드 이동방향 `Vector3`(정규화, 크기 0~1), 이동 스탯(속도·회전속도)을 생성 시 데이터로 주입.
- 출력: `ReadOnlyReactiveProperty<Vector3> Velocity`(= dir * speed), 목표 회전 `Quaternion`(부드러운 보간용).
- Unity 씬/컴포넌트를 직접 참조하지 않는다. `Vector3`/`Quaternion` 수학만 사용.
- 속도는 내부 상수가 아니라 주입값(향후 몬스터 스폰 데이터 재사용)으로 보유.

**PlayerInputModule** (raw 입력 핸들러, 재사용)
- 기존 `GameInput.IPlayerActions` 콜백 핸들러 유지. raw `Vector2` 이동 입력만 노출.
- 방향 계산 책임을 가지지 않는다 → 프로젝트 간 그대로 재사용.

**방향계산 Module** (교체 가능, 예: `CameraRelativeMoveModule`)
- 인터페이스로 추상화하여 프로젝트별 구현 교체 가능 (예: `IMoveDirectionProvider`).
- 입력: raw `Vector2` + 게임플레이 카메라 basis(forward/right).
- 계산: 카메라 forward·right를 XZ 평면 투영 후 정규화 → `dir = (fwd * input.y + right * input.x)`, 크기 클램프.
- 출력: 월드 이동방향 `Vector3`.

**ActorView** (MonoBehaviour, `CharacterController` 소유)
- `CharacterController`를 필드로 소유하고 `CharacterMover`를 소유해 로직 위임.
- `Velocity`를 매 프레임 `CharacterController.Move(velocity * deltaTime)`로 반영.
- 목표 회전을 `Quaternion.RotateTowards`/`Slerp`로 부드럽게 보간 적용.
- VContainer로 `InputManager`/`CameraManager` 및 이동 스탯 데이터를 주입받아 플레이어에 배선.

```
[InputManager.Move (Vector2)]           ← PlayerInputModule (raw, 재사용)
        + [CameraManager basis]
        → IMoveDirectionProvider (교체 가능) → moveDir (Vector3)
        → CharacterMover(dir, statData)   → Velocity (Vector3) + 목표 Quaternion
        → ActorView (CharacterController.Move + 보간 회전)
```

## Acceptance Criteria

- [ ] WASD 입력 시 플레이어가 카메라 기준 방향으로 이동한다 (화면 위 = 카메라 전방).
- [ ] 카메라가 회전해도 입력 대비 이동방향이 카메라 기준으로 일관된다.
- [ ] 대각 입력 시 속도가 빨라지지 않는다 (방향 정규화).
- [ ] 캐릭터가 이동방향을 향해 부드럽게 회전한다 (즉시 스냅 아님).
- [ ] 동일 `CharacterMover`를 방향·스탯만 바꿔 주입하면 적도 이동한다 (재사용 검증).
- [ ] 이동 속도가 주입된 스탯 데이터 값을 따른다 (하드코딩 아님).
- [ ] `ActorView`가 `CharacterController.Move`로 이동을 적용하며, 프레임레이트가 달라도 이동거리가 일정하다.
- [ ] 입력이 없으면 즉시 정지한다.
- [ ] 방향계산 Module 구현을 교체해도 PlayerInputModule·CharacterMover·ActorView는 수정 없이 동작한다.

## Open Questions

- 방향계산 Module에 전달할 카메라 basis를 `CameraManager`가 노출할지(예: `Transform` 또는 forward/right 프로퍼티), `ActorView`가 카메라 참조에서 직접 뽑을지 — 배선 시점에 확정.
- 이동 스탯 데이터의 구체 타입/필드(속도·회전속도 외 포함 범위)는 몬스터 스탯 스키마 설계 시 확정.