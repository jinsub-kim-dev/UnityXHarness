---

name: add-global-manager

description: 씬/전역 스코프에 단독으로 존재하는 싱글턴 Manager를 추가한다. GameManager, UIManager, AudioManager처럼 특정 오브젝트에 종속되지 않고 독립적으로 존재하는 Manager에 사용한다. 개별 오브젝트(캐릭터·적 등)의 로직 조율자는 이 Skill 대상이 아님

argument-hint: "[ManagerName]"
allowed-tools:
- Bash
- Write
---

**$ARGUMENTS Manager**를 프로젝트 컨벤션에 맞게 생성한다.

## 파일 위치

- `{프로젝트루트}/{대분류}/$ARGUMENTS/$ARGUMENTSManager.cs`
- 같은 기능의 Module·Interface는 같은 폴더에 함께 둔다

## 클래스 규칙

- 순수 C# 클래스. 씬/전역 스코프에 싱글톤으로 단독 존재
- 생성자(Constructor)로만 의존성 주입. public setter · Singleton.Instance 패턴 금지
- 가능하면 게임 로직을 직접 포함하지 않고 Module에 위임
- 다른 Manager를 직접 참조하지 않음. Module과 Service를 통해서만 기능 사용
- 외부에 알려야 할 상태 변화는 ReactiveProperty<T> 또는 Subject<T>로 노출 (C# event 금지)

## DI 등록

- LifetimeScope에 `builder.Register<$ARGUMENTSManager>(Lifetime.Singleton).AsImplementedInterfaces()` 으로 등록

## 생성 후 검증

- 다른 Manager를 직접 참조하지 않는지 확인
- Singleton.Instance 패턴이 혼입되지 않았는지 확인
- CLAUDE.md 금지 패턴 위반 없는지 확인