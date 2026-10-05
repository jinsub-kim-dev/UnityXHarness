---
name: scene-setup
description: 설계 문서(01-design.md)의 "씬·프리팹 변경" 목록을 Unity 공식 MCP(Unity_RunCommand)로 적용한다 — GameObject 생성, 컴포넌트 부착, 프리팹 생성, LifetimeScope 참조 연결, 레이어/태그 설정. 변경 전 요약을 사람에게 보여주고 승인받은 뒤에만 실행한다. unity-ai-operator가 사용한다. C# 코드 작성이나 검증에는 사용하지 않는다.
---

# Scene Setup

## 입력
- `artifacts/01-design.md`의 "씬·프리팹 변경" 표
- 구현 완료된 스크립트 (컴파일 통과 상태여야 함 — Gate 1 미통과면 진행하지 않음)

## 절차
1. **현재 상태 조회**: `Unity_RunCommand`로 대상 씬의 관련 오브젝트·컴포넌트를 읽기 전용으로 조회해 로그로 출력.
2. **변경 요약 작성** (사람 승인용):
   ```md
   위임 대상: Unity 공식 MCP (Unity_RunCommand)
   작업 유형: 컴포넌트 부착 | 씬 구성 | 프리팹 생성 | 레이어/태그
   대상 씬/에셋:
   변경 목록:
     1. {GameObject 경로} — {추가/수정 내용}
   생성될 파일: Assets/10_ProjectA/01_Prefabs/...
   되돌리는 방법: Undo 등록 / git 되돌림
   ```
3. **사람 승인 대기**. 승인 전에는 아무 것도 바꾸지 않는다. 대규모 변경이면 먼저 커밋을 권한다.
4. **실행**: 작은 단위로 `Unity_RunCommand` 실행.
   - 생성: `result.RegisterObjectCreation(obj)` / 수정 전 `result.RegisterObjectModification(obj)` / 삭제는 `result.DestroyObject(obj)`
   - 프리팹: `PrefabUtility.SaveAsPrefabAsset`으로 `Assets/10_ProjectA/01_Prefabs/{대분류}/`에 저장
   - 씬 저장: `EditorSceneManager.MarkSceneDirty` 후 `EditorSceneManager.SaveScene`
   - `.unity`/`.prefab`/`.asset` 파일을 셸로 직접 수정·삭제하지 않는다.
5. **확인**: `Unity_GetConsoleLogs`로 에러 확인, 필요 시 `Unity_SceneView_CaptureMultiAngleSceneView`로 배치 확인.
6. 실패·예상 외 결과면 1회 재시도 후 사람에게 보고.

## 출력
- 변경된 씬·프리팹 (Assets/)
- `artifacts/02-validation.md` 하단 `## 씬 구성 기록`에 변경 목록·결과 추가

## 품질 기준
- 승인받은 목록 밖의 변경이 없다.
- 프리팹은 `10_ProjectA/01_Prefabs` 아래에만 생성된다.
- `00_CommonFramework` 에셋 변경은 별도로 명시 승인받는다.
