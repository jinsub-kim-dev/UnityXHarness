---
name: convention-review
description: 코드 리뷰를 실행합니다. CLAUDE.md·docs/conventions/convention.md 컨벤션과 artifacts/01-design.md 설계 체크리스트를 기준으로 변경된 코드를 리뷰할 때 사용합니다.
disable-model-invocation: true
---

변경된 파일(`git status`/`git diff`)을 아래 기준으로 리뷰하고 결과를 보고하세요.

## 기준 (우선순위 순)
1. **설계 매칭**: `artifacts/01-design.md`가 있으면 D-xx 항목마다 구현 위치를 찾아 대조. 누락은 ❌
2. **컴파일 가능성**: 누락된 using, 잘못된 시그니처, 존재하지 않는 API
3. **레이어·의존 방향**: Manager → Module, Manager →(interface)→ Service. 역방향·Module 간 참조·구체 클래스 의존 금지. Module의 Unity API 의존 금지
4. **컨벤션**: `csharp-convention-guide` Skill 기준 — 위치·네임스페이스(`O2un.ProjectA.{대분류}`), 네이밍, if 평가값 앞 배치, MonoBehaviour 필드 `[Inject]`, 클래스 작성 순서, 기능 설명 주석 금지, 금지 패턴(Find·Instance·Resources·PlayerPrefs·Coroutine), 라이브러리 허용 범위
5. **성능**: Update 내 할당·LINQ·GetComponent, 대량 오브젝트 풀링 누락, O(n²) 탐색

## 출력
✅/⚠️/❌로 표시하고, 위반 항목은 파일 이름과 라인 번호와 함께 알려주세요.
`code-reviewer` 에이전트가 사용할 때는 `artifacts/03-review.md` 양식(설계 체크리스트 매칭 / 차단 이슈 / 비차단 이슈 / 판정)으로 저장합니다.
