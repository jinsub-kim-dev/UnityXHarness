# C# 컨벤션 체크리스트

검증 대상: 이번 세션에서 수정·생성된 .cs 파일 (`Assets/` 아래, 서드파티 `Assets/Packages`·`TextMesh Pro`·`TutorialInfo` 제외)
기준 원문: `CLAUDE.md`, `docs/conventions/convention.md`

## 항목

1. 네임스페이스가 위치에 맞는가? (`10_ProjectA` → `O2un.ProjectA.{대분류}`, `00_CommonFramework` → `O2un.{대분류}`)
2. 프로젝트 전용 코드가 `Assets/10_ProjectA/00_Script/` 아래에 있는가?
3. Module 클래스가 MonoBehaviour를 상속하지 않고 UnityEngine API에 의존하지 않는가?
4. FindObjectOfType / GameObject.Find를 사용하지 않는가? (Editor 전용 코드 제외)
5. Singleton static Instance 패턴, Resources.Load, PlayerPrefs, StartCoroutine을 사용하지 않는가?
6. R3를 기본 수준(ReactiveProperty, Subject, Subscribe, AddTo)으로만 쓰고 SelectMany/Zip 등 복잡한 체이닝이 없는가?
7. if 비교에서 평가값(null, true/false, 상수)이 앞에 오는가? (`if (null == x)`)
8. MonoBehaviour의 VContainer 주입이 필드 `[Inject]`로 되어 있는가?
9. private 필드는 `_camelCase`, 상수는 `UPPER_SNAKE_CASE`인가?
10. 기능·블록 설명 주석이나 XML 문서 주석을 추가하지 않았는가? (`// NULL` 제외)
