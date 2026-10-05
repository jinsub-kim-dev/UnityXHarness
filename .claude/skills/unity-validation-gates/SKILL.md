---
name: unity-validation-gates
description: 구현 후 4단계 검증 게이트 중 Gate 1(컴파일)·Gate 2(Play 모드 콘솔 에러)·Gate 3(자동 기능 테스트)를 Unity 공식 MCP(unity-mcp relay — Unity_RunCommand, Unity_GetConsoleLogs)로 세션 안에서 실행하고 artifacts/02-validation.md를 기록한다. unity-ai-operator가 사용한다. 씬·프리팹 구성에는 scene-setup Skill을 쓴다.
---

# Unity Validation Gates (공식 MCP)

## 전제
- 이 프로젝트의 MCP는 **Unity 공식 relay MCP**(`.mcp.json`의 `unity-mcp`)다. CoplayDev 도구(`refresh_unity`, `manage_editor`, `read_console`, `gate3_run_test`)는 없다.
- 사용 도구: `mcp__unity-mcp__Unity_RunCommand`(C# 실행, 클래스명 `CommandScript`, `internal`, `IRunCommand`), `mcp__unity-mcp__Unity_GetConsoleLogs`, 필요 시 `Unity_Camera_Capture`·`Unity_SceneView_CaptureMultiAngleSceneView`.
- MCP 호출이 실패하면(에디터 미실행 등) 해당 게이트를 `🔧 수동 검증 필요`로 기록하고 수동 체크리스트를 남긴다. **거짓 통과 금지.**
- Play 모드 진입 전 씬에 저장 안 된 변경이 있으면 사람에게 저장을 요청하고 기다린다.

## 게이트 규칙
- 순서: Gate 1 → 2 → 3. 실패하면 그 단계에서 멈추고 02-validation에 기록 → Orchestrator에 보고. 수정 후 **실패한 게이트부터** 재검증.
- 같은 게이트 연속 실패 2회면 자동 재시도를 멈추고 사람에게 보고.

## Gate 1 — 컴파일
1. `Unity_RunCommand`로 리프레시·컴파일 요청:
   ```csharp
   using UnityEditor;
   using UnityEditor.Compilation;
   internal class CommandScript : IRunCommand
   {
       public void Execute(ExecutionResult result)
       {
           AssetDatabase.Refresh(ImportAssetOptions.ForceUpdate);
           CompilationPipeline.RequestScriptCompilation();
           result.Log("refresh+compile requested");
       }
   }
   ```
2. 몇 초 뒤 상태 확인(`EditorApplication.isCompiling`, `EditorUtility.scriptCompilationFailed`)을 `result.Log`로 출력. 컴파일 중이면 재확인(최대 60초).
3. `Unity_GetConsoleLogs`(`logTypes: "Error"`)로 `error CS` 라인 확인.
4. 프로젝트에 컴파일 에러가 있으면 `Unity_RunCommand` 자체가 컴파일 실패를 반환할 수 있다 — 그 경우도 Gate 1 실패로 보고 에러 내용을 기록.
- 통과: `scriptCompilationFailed == false` 이고 `error CS` 0건.

## Gate 2 — Play 모드 런타임 에러
1. 콘솔 비우기(`UnityEditor.LogEntries`를 리플렉션으로 `Clear` 호출, 실패해도 진행 — 이후 판정은 진입 시각 이후 로그 기준).
2. 대상 씬이 열려 있는지 확인(`00-input.md`의 테스트 씬, 기본 `Assets/Scenes/Bootstrap.unity` — Bootstrap → Loading → GameScene 부팅 흐름을 거쳐야 DI가 정상 구성된다. GameScene 로드까지 기다린 뒤 판정).
3. `EditorApplication.EnterPlaymode()` 실행 → 이후 호출에서 `EditorApplication.isPlaying`이 true가 될 때까지 확인.
4. 5초 이상 실행(시스템 특성상 웨이브 등 시간 의존이면 시나리오에 적힌 시간만큼).
5. `Unity_GetConsoleLogs`(`logTypes: "Error,Exception,Assert"`, `includeStackTrace: true`)로 확인.
- 통과: Error/Exception/Assert 0건. 경고는 기록만.
- Gate 3을 이어서 실행하면 Play 모드를 유지하고, 아니면 `EditorApplication.ExitPlaymode()`.

## Gate 3 — 자동 기능 테스트
`artifacts/01-design.md`의 **자동 검증 시나리오(T-xx)**를 그대로 수행한다.

| 방식 | 사용 시점 | 방법 |
| --- | --- | --- |
| Play 모드 프로브 | 씬에서 동작을 봐야 하는 항목(스폰 수, 이동, 피격) | Play 중 `Unity_RunCommand`로 상태 조회(오브젝트 수, 위치, 컴포넌트 값)·입력 대체 호출 후 `result.Log`로 값 출력, 기준과 비교 |
| EditMode 단위 테스트 | 순수 C# Module 로직 | `UnityEditor.TestTools.TestRunner.Api.TestRunnerApi`로 EditMode 실행, `ICallbacks.RunFinished` 결과를 로그로 출력 (비동기이므로 결과 로그를 다시 조회) |
| 스크린샷 | 카메라·연출 확인 보조 | `Unity_Camera_Capture` — 판정 근거가 아니라 4단계 사용자 확인용 첨부 |

- 프로브에서 Find 계열 사용은 **검증 스크립트(에디터 전용)이므로 허용**된다(convention.md 예외). 게임 코드에는 넣지 않는다.
- 프로브가 씬·에셋을 바꾸면 안 된다. 생성한 임시 오브젝트는 `result.DestroyObject`로 정리.
- EditMode 테스트 첫 실행 시 asmdef 없이(Assembly-CSharp-Editor) 테스트가 발견되는지 확인한다. 발견되지 않으면 asmdef 도입이 필요하다는 것을 **사람 승인 항목**으로 보고하고 프로브 방식만으로 진행한다.
- 끝나면 `EditorApplication.ExitPlaymode()`.
- 통과: 모든 T-xx가 기준 충족. 일부 미실행이면 `⚠️`로 사유 기록.

## 출력 — `artifacts/02-validation.md`
뷰어가 `게이트 진행 요약` 다음 표의 **두 번째 열**(결과)에서 ✅/❌/⏳/🔧를 읽는다. 표 형식을 바꾸지 않는다. 재검증으로 통과하면 `❌→✅`로 적는다.

```md
# 02. 검증 (4단계 게이트)

작성: unity-ai-operator (Unity 공식 MCP)
일시: YYYY-MM-DD HH:mm
대상: {시스템명}

## 게이트 진행 요약
| 단계 | 결과 | 시간 |
| --- | --- | --- |
| 1. 컴파일 | ✅ 통과 | HH:mm |
| 2. 런타임 에러 | ✅ 통과 | HH:mm |
| 3. 기능 점검 (자동) | ❌→✅ 재통과 | HH:mm |
| 4. 기능 점검 (사용자) | ⏳ 대기 (뷰어에서 제출 예정) | - |

## Gate 3 시나리오 결과
| ID | 방식 | 측정값 | 기준 | 결과 |

## 실패 상세
(에러 원문, 스택 트레이스 요약, 재현 절차)

## 사용자 확인 가이드 (4단계)
- 확인할 동작:
- 조작 방법:
- 기대 결과:
```

## 품질 기준
- 각 게이트 결과에 근거(로그 값·측정값)가 있다.
- MCP 실패와 검증 실패를 구분해 기록한다(`🔧` vs `❌`).
- Play 모드를 켜둔 채로 끝내지 않는다.
