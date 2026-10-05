---

name: add-module

description: Manager가 로직을 위임할 순수 C# Module을 추가한다. Unity API에 의존하지 않고 new로 생성 가능한 게임 로직에 사용한다. 파일·씬·에셋 등 외부 시스템 접점은 Service 대상이므로 이 Skill 대상이 아님

argument-hint: "[ModuleName]"

---

**$ARGUMENTS Module**을 프로젝트 컨벤션에 맞게 생성한다.

## 파일 위치

- 프로젝트 전용: `Assets/10_ProjectA/00_Script/{대분류}/{중분류}/$ARGUMENTSModule.cs` (네임스페이스 `O2un.ProjectA.{대분류}`)
- 공통 인프라: `Assets/00_CommonFramework/00_Scripts/{대분류}/{중분류}/` — 사람 승인 필요
- 이 Module을 소유하는 Manager와 같은 폴더에 둔다
- 세부 규칙은 `csharp-convention-guide` Skill을 따른다

## 클래스 규칙

- 순수 C# 클래스. Unity API에 의존하지 않음
- `new`로 생성 가능해야 함. 필요한 값은 생성자로 전달
- Manager를 직접 참조하지 않음 (역방향 의존 금지)
- 다른 Module을 직접 참조하지 않음. 필요 시 Manager를 통해 간접 통신
- 외부에 알려야 할 상태 변화는 ReactiveProperty<T> 또는 Subject<T>로 노출 (C# event 금지)

## Manager 연결

- VContainer에 등록하지 않음. 소유 Manager가 `new`로 생성해 필드로 보관
- Module이 IDisposable이면 소유 Manager의 Dispose에서 함께 해제

## 생성 후 검증

- Unity API 의존이 없는지 확인
- Manager·다른 Module을 직접 참조하지 않는지 확인
- CLAUDE.md 금지 패턴 위반 없는지 확인
