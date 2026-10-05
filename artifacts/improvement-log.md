# 개선 기록

## 2026-10-05 하네스 구성

### 무엇이 아쉬웠나
- (코드 작업 전) 스킬의 검증 hook 자산이 CoplayDev MCP for Unity(HTTP) 전용이라 이 프로젝트의 Unity 공식 relay MCP(stdio)와 맞지 않았다.
- 폴더 규칙이 CLAUDE.md / convention.md / 실제 코드 세 곳에서 달랐다.

### 원인
- 공식 relay MCP는 Claude 세션 안에서만 호출 가능해 Stop hook 스크립트가 붙을 수 없다.
- `00_CommonFramework`는 공통 코드, 프로젝트 전용 코드는 별도 규칙이 필요했다.

### 반영
- Gate 1~3은 `unity-ai-operator`가 `unity-validation-gates` Skill로 세션 내 수행. Stop hook은 컨벤션 체크 → 뷰어 오픈만.
- 프로젝트 전용 코드: `Assets/10_ProjectA/00_Script/{대분류}/{중분류}/`, 네임스페이스 `O2un.ProjectA.{대분류}`.

### 다음 테스트
- 첫 시스템(플레이어 이동)에서 Gate 1~3이 공식 MCP로 실제 판정되는지, `02-validation.md` 게이트 표가 뷰어에 표시되는지 확인.
- EditMode 테스트가 asmdef 없이(Assembly-CSharp-Editor) 실행되는지 첫 실행에서 확인. 안 되면 asmdef 도입 여부를 사람에게 묻는다.

### 하네스 자체 개선 메모
- 이전 샘플 기록의 교훈(설계 항목이 구현에서 누락)을 반영해 01-design에 체크리스트 ID(D-xx)를 두고 code-reviewer가 1:1 매칭한다.
