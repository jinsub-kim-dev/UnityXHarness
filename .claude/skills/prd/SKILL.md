---

name: prd

description: Unity 게임 기능 하나에 대한 요구사항 문서(PRD)를 작성해 docs/requirements/<기능명>.md 에 저장한다. 사용자가 `/prd <기능명>`을 입력하거나 "PRD 작성해줘", "요구사항 문서 만들어줘", "기능 명세 정리해줘"처럼 구현 전에 기능의 목표·범위·완료 기준을 문서로 정리하길 원할 때 사용한다. 코드를 바로 작성하는 요청에는 사용하지 않는다.

argument-hint: "[기능명]"

---

**$ARGUMENTS** — 이 기능의 PRD를 작성한다.

PRD는 이후 "이 문서 참고해서 구현해줘" 요청의 입력으로 쓰인다. 따라서 구현자가 추가 질문 없이 작업을 시작할 수 있을 만큼 구체적이어야 하고, 확정되지 않은 내용은 추측으로 채우지 말고 Open Questions로 드러내야 한다.

## 1. 기능명 파악

- `$ARGUMENTS`에 기능명이 있으면 그대로 사용한다
- 없으면 "어떤 기능의 PRD를 작성할까요?" 한 줄로만 묻고 답을 기다린다
- 파일명은 기능명을 영문 kebab-case로 바꿔 쓴다 (예: "인벤토리 시스템" → `inventory-system.md`). 한글 기능명이면 변환한 파일명을 초안과 함께 보여줘 사용자가 확인할 수 있게 한다

## 2. 맥락 확인

Technical Requirements가 실제 프로젝트 구조와 어긋나지 않도록 작성 전에 다음을 읽는다.

- `CLAUDE.md` — Manager / Module / Service 레이어, 폴더 규칙, 허용 라이브러리(VContainer·R3·UniTask), 금지 패턴
- `.claude/codebase-index.md` — 이미 있는 Manager·인터페이스. 새 기능이 기존 것(예: `IInputReader`, `IScoreWriter`, `IGameFlow`)과 연결된다면 그 이름을 그대로 쓴다
- `docs/requirements/<파일명>.md` 가 이미 있는지 확인해 둔다 (4단계에서 사용)

사용자가 준 정보만으로 Unity 컴포넌트·API·물리 설정을 정할 수 없으면 추측해서 적지 않는다. 짧게 질문하거나, 초안의 Open Questions에 넣는다. 잘못된 확정 스펙은 빈칸보다 구현을 더 크게 틀어지게 만든다.

## 3. 초안 작성

아래 템플릿의 섹션을 이 순서 그대로 채운다. 마크다운만 사용하고, 코드 블록은 Technical Requirements 섹션에서만 쓴다.

```markdown
# <기능명>

## Overview
<기능 한 줄 요약>
<게임 내 맥락: 어떤 상황에서 누가 이 기능을 쓰는지, 어떤 기존 시스템과 맞물리는지>

## Goals
- <동사 + 명사 형태의 달성 상태> (예: 플레이어가 아이템을 획득해 인벤토리에 보관한다)

## Out of Scope
- <이번 구현에서 명시적으로 제외하는 항목>

## Technical Requirements
- 레이어 구성: <Manager / Module / Service 와 각 역할, 배치 폴더>
- 사용 Unity 컴포넌트·API: <Rigidbody, Collider, Input System 액션 등>
- 물리·수치 설정: <레이어, 값, 단위>
- 의존·연동: <주입받는 인터페이스, 노출할 인터페이스>

## Acceptance Criteria
- [ ] <관찰 가능한 완료 기준>

## Open Questions
- <미결 사항>
```

작성 요령:

- **Goals**는 구현이 끝났을 때의 상태를 적는다. "~를 구현한다"보다 "플레이어가 ~할 수 있다"처럼 결과를 적어야 Acceptance Criteria로 이어지기 쉽다
- **Out of Scope**는 비워두지 않는다. 범위를 명시해야 구현 단계에서 기능이 불어나지 않는다
- **Technical Requirements**는 CLAUDE.md 규칙 안에서 설계한다. 금지 패턴(`FindObjectOfType`, static Instance, `Resources.Load`, `PlayerPrefs`, 코루틴 등)이 필요해 보이면 대안(DI 주입, AssetService, SaveService, UniTask)을 적거나 Open Questions로 올린다
- **Acceptance Criteria**는 플레이 테스트나 테스트 코드로 참/거짓을 판단할 수 있게 쓴다 ("잘 동작한다" ✗ → "점프 키 입력 시 지면에 있을 때만 점프한다" ✓)
- **Open Questions**가 없으면 "없음"이라고 적는다

## 4. 리뷰 요청

- 초안 전체를 대화에 보여주고, 수정할 부분이 있는지 묻는다. 아직 파일로 저장하지 않는다
- 피드백을 반영해 다시 보여주는 과정을 사용자가 확정할 때까지 반복한다
- 같은 경로에 파일이 이미 있으면 이 단계에서 함께 알리고, 덮어쓸지 확인을 받는다. 확인 없이 덮어쓰지 않는다

## 5. 파일 저장

- 확정되면 `docs/requirements/<파일명>.md` 에 저장한다. 다른 위치에는 저장하지 않는다
- 폴더가 없으면 만든다

## 6. 사용법 안내

저장 후 아래 메시지를 그대로 출력한다.

```
✅ docs/requirements/<파일명>.md 저장 완료
이제 Claude에게 이렇게 요청하세요:
"@docs/requirements/<파일명>.md 참고해서 구현해줘"
```
