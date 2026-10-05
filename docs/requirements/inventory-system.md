# 인벤토리 시스템

## Overview
로그라이크 한 판(런) 동안 플레이어가 주운 아이템을 제한된 슬롯에 보관하고, 사용하거나 버릴 수 있는 기능.
플레이어는 GameScene에서 필드의 아이템을 주워 인벤토리에 넣고, 소모품을 써서 HP를 회복한다. 인벤토리는 GameScene 스코프에 있어서 `IGameFlow.Restart()`로 씬을 다시 불러오면 초기화된다. HP 변경은 기존 `IPlayerDataWriter`를 통해 처리한다.

## Goals
- 플레이어가 필드 아이템에 닿으면 아이템이 인벤토리 슬롯에 들어간다
- 같은 아이템은 최대 스택 수까지 한 슬롯에 겹쳐서 보관된다
- 인벤토리 슬롯 수에 상한이 있고, 가득 차면 새 아이템을 주울 수 없다
- 플레이어가 소모품을 사용하면 효과(HP 회복)가 적용되고 개수가 1 줄어든다
- 플레이어가 슬롯의 아이템을 버려 칸을 비울 수 있다
- 인벤토리 UI가 슬롯별 아이템 아이콘과 개수를 실시간으로 표시한다
- 런을 재시작하면 인벤토리가 빈 상태로 시작한다

## Out of Scope
- 패시브 아이템 / 스탯 보정 (공격력·이동속도 등): 스탯 시스템이 없음
- 장비 슬롯 (무기·방어구 착용)
- 격자형 배치, 드래그 앤 드롭으로 슬롯 재정렬
- 아이템 희귀도, 랜덤 드롭 테이블, 상점
- 런 사이에 인벤토리를 유지하거나 저장(DataProvider 연동)하는 기능
- HP 회복 외의 소모품 효과
- 버린 아이템을 필드에 다시 생성하는 기능 (버리면 사라짐)

## Technical Requirements
- 레이어 구성 (배치 폴더: `Assets/00_CommonFramework/00_Scripts/Manager/Inventory/`, 네임스페이스 `O2un.Inventory`)
  - `ItemData` (ScriptableObject): 아이템 정의. `Id`, `DisplayName`, `Icon`(Sprite), `MaxStack`, `ItemType`(enum: `Consumable`), `HealAmount`
  - `InventorySlot` (순수 C#): `ItemData Item`, `int Count`
  - `InventoryModule` (순수 C#, Module): 슬롯 배열 관리와 스택·추가·제거 계산. Unity API에 의존하지 않고 `new`로 생성할 수 있음. `bool TryAdd(ItemData)`, `bool Remove(int slotIndex, int count)`
  - `InventoryManager` (순수 C#, Manager): `IInventoryReader`/`IInventoryWriter` 구현. `InventoryModule`을 내부에서 생성해 계산을 맡기고, 사용 효과는 `IPlayerDataWriter.Vary(+HealAmount)`로 적용
  - `ItemPickup` (MonoBehaviour): 필드 아이템. `ItemData`를 SerializeField로 들고 있고, 플레이어와 닿으면 `IInventoryWriter.TryAdd` 호출. 성공하면 자기 자신을 Destroy
  - UI: `InventoryContext` → `InventoryVM` → `InventoryView` (기존 Context→VM→View 패턴), `UIType`에 `Inventory` 추가
- 사용 Unity 컴포넌트·API
  - `ItemPickup`: Collider (`isTrigger = true`), `OnTriggerEnter`
  - `InventoryView`: 슬롯 UI의 `Image`(아이콘), `TMP_Text`(개수)
- 물리·수치 설정
  - 슬롯 수: `MAX_SLOT_COUNT = 8`
  - 기본 최대 스택: 소모품 `MaxStack = 5`
  - HP 회복 포션: `HealAmount = 20` (MaxHP 100 기준, 상한은 `PlayerDataStore`의 Clamp 규칙을 따름)
- 의존·연동
  - 노출 인터페이스
    - `IInventoryReader`: `IReadOnlyList<ReadOnlyReactiveProperty<InventorySlot>> Slots` (또는 슬롯 변경 `Observable`)
    - `IInventoryWriter`: `bool TryAdd(ItemData)`, `bool Use(int slotIndex)`, `bool Drop(int slotIndex)`
  - 주입 인터페이스: `IPlayerDataWriter` (HP 회복)
  - 등록: `GameSceneScope`에 `InventoryManager`를 `IInventoryReader`, `IInventoryWriter`로 Singleton 등록
  - `ItemPickup`은 씬에 미리 배치된 오브젝트로, `GameSceneScope`의 autoInject 대상이거나 `[Inject]`로 `IInventoryWriter`를 받음 (`FindObjectOfType` 금지)

```csharp
public interface IInventoryReader
{
    IReadOnlyList<ReadOnlyReactiveProperty<InventorySlot>> Slots { get; }
}

public interface IInventoryWriter
{
    bool TryAdd(ItemData item);
    bool Use(int slotIndex);
    bool Drop(int slotIndex);
}
```

## Acceptance Criteria
- [ ] 빈 인벤토리에서 `TryAdd(포션)`을 호출하면 0번 슬롯에 Count=1로 들어가고 `true`를 반환한다
- [ ] 같은 아이템을 `MaxStack`(5)까지 추가하면 한 슬롯에 쌓이고, 6번째는 다음 빈 슬롯에 Count=1로 들어간다
- [ ] 8칸이 모두 다른 아이템이거나 최대 스택이면 `TryAdd`는 `false`를 반환하고 상태가 바뀌지 않는다
- [ ] `TryAdd`가 실패하면 필드의 `ItemPickup` 오브젝트는 사라지지 않는다
- [ ] HP 50에서 포션 슬롯에 `Use`를 호출하면 HP가 70이 되고 해당 슬롯 Count가 1 줄어든다
- [ ] Count가 1인 슬롯을 `Use`하면 슬롯이 비고(`Item == null`), 빈 슬롯에 `Use`/`Drop`을 호출하면 `false`를 반환한다
- [ ] `Drop`을 호출하면 해당 슬롯이 즉시 비워진다
- [ ] 슬롯 상태가 바뀌면 같은 프레임에 `InventoryView`의 아이콘과 개수 텍스트가 갱신된다
- [ ] `IGameFlow.Restart()` 후 인벤토리는 8칸 모두 빈 상태다
- [ ] `InventoryModule`은 Unity 없이 EditMode 테스트에서 `new`로 생성해 위 추가·스택·제거 규칙을 검증할 수 있다

## Open Questions
- **아이템 사용·버리기 입력**: 현재 `IInputReader`에는 Move/Jump만 있다. 숫자키(1~8)로 바로 사용할지, UI 액션맵으로 바꿔 슬롯을 선택할지 정해야 한다 (`UIInputModule`은 아직 구현되지 않음)
- **인벤토리 UI 표시 방식**: 항상 보이는 핫바인지, 키를 눌러 여는 창인지. 창이라면 열린 동안 `IGameFlow.Pause()`를 호출할지
- **충돌 감지 조건**: `PlayerView`는 `transform.Translate`로 움직이므로, `OnTriggerEnter`가 동작하려면 플레이어나 아이템 중 한쪽에 Rigidbody(kinematic)가 있어야 한다. 플레이어의 Collider/Rigidbody 구성과 판정 레이어를 확인해야 한다
- **`ItemData` 참조 방식**: `Resources.Load`는 금지이고 AssetService는 아직 없다. 지금은 `ItemPickup`의 SerializeField 직접 참조로 충분한지 확인이 필요하다
- **배치 위치**: 로그라이크 전용 기능이라면 `00_CommonFramework` 대신 `10_ProjectA`가 맞을 수 있다
- **HP가 가득 찼을 때 사용**: 포션을 소모할지, 사용을 막을지
