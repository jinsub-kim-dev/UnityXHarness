# Agent / Skill / Orchestrator 제작 사양 (Unity 게임 개발)

## 구성요소 정의

| 요소 | 담는 내용 | 위치 |
| --- | --- | --- |
| Agent | 역할, 책임, 입력, 출력, 도구 범위, 하지 말아야 할 일 | `.claude/agents/{name}.md` |
| Skill | 트리거, 절차, 출력 형식, 품질 기준, 예외 처리 | `.claude/skills/{name}/SKILL.md` |
| Orchestrator | 순서, 담당자, 중간 산출물, 검증, 실패 처리, 승인 조건 | `.claude/skills/unity-dev-orchestrator/SKILL.md` |

- Agent 파일에 절차 전체를 넣지 않는다(재사용 저하). 절차는 Skill로 분리한다.
- Skill에 역할·책임 정보를 넣지 않는다(책임 소재 불명). 역할은 Agent로 분리한다.
- Orchestrator Skill은 폴더명과 `name`이 `-orchestrator`로 끝나야 한다. 일반 Skill은 이 접미사를 쓰지 않는다.

## Agent 분리 기준

아래 중 2개 이상이 참일 때만 별도 Agent로 분리한다.

| 기준 | 분리 | 미분리 |
| --- | --- | --- |
| 컨텍스트 경계 | 보는 자료가 다름(설계 결정 vs 버그 추적) | 같은 스크립트를 계속 이어서 봄 |
| 전문성 | 설계 / 구현 / 디버깅 / 리뷰로 다름 | 같은 코드를 나눠 쓰는 정도 |
| 입출력 독립성 | 설계안만 넘기면 구현 가능 | 중간 판단을 계속 공유해야 함 |
| 재사용성 | 반복 호출됨(리뷰 등) | 1회성 작은 단계 |
| 부재 위험 | 빠지면 빌드/안전 깨짐 | Orchestrator 체크리스트로 대체 가능 |

Agent 수: 기본 3-4개, 최대 5개(unity-ai-operator 포함).

## 실행 모드 선택

| 조건 | 단일 흐름 | Subagent | Agent Team |
| --- | --- | --- | --- |
| 스크립트 1개 / 버그 1개 | 적합 | 과함 | 과함 |
| 독립 시스템 조사 후 결과 합침 | 가능 | 적합 | 과함 |
| 설계 결정이 구현 방향을 바꿈 | 부족 | 부족 | 적합 |
| 구현자-리뷰어 실시간 피드백 | 부족 | 제한적 | 적합 |
| 여러 시스템 병렬 구현 후 통합 | 순차만 | 주의 | 적합(파일 소유권 분리) |

판단 순서: 단일 흐름 → (컨텍스트 과대/독립 작업 많음) Subagent → (중간 상태 지속 동기화) Agent Team → 팀이면 동일 파일 동시 수정 금지(소유권 분리).

## Agent Team 최소 실행 계약

Agent Team으로 간주하려면 Agent 정의 파일 외에 Orchestrator Skill 안에 아래가 모두 있어야 한다.

| 계약 | 내용 |
| --- | --- |
| 팀 구성 | `TeamCreate`로 팀원 Agent 지정 |
| 작업 등록 | `TaskCreate`로 단계별 작업·담당자·의존 관계·완료 기준 |
| 상태 관리 | `TaskUpdate` / `TaskGet`으로 지연·차단·완료·재할당 |
| 메시지 규칙 | `SendMessage`로 컴파일 에러·설계 충돌·검토 의견 전달 대상 지정 |
| 파일 산출물 | 코드·씬·에셋은 `Assets/`, 문서는 `artifacts/` |
| 통합 절차 | Orchestrator가 산출물을 읽어 충돌·누락 정리 |
| 정리 절차 | `TeamDelete` + 다음 실행용 기록 |

## Orchestrator 실행 흐름

```
1. artifacts/ 확인 → 초기 실행 / 부분 재실행 / 새 실행 분기
2. 요청·게임 범위·제약·승인 지점 → artifacts/00-input.md
3. TeamCreate: 필요한 Agent 팀원 구성
4. TaskCreate: 설계 → 구현 → 검증 → 리뷰 단계 등록
5. 각 Task: 담당자 / 입력 파일 / 출력 위치(코드 Assets/, 문서 artifacts/) / 의존 관계 / 완료 기준
6. 팀원: TaskUpdate로 시작·차단·완료 갱신
7. Orchestrator: TaskGet으로 지연·누락·의존 막힘 확인
8. 팀원: SendMessage로 컴파일 에러·설계 충돌·검토 의견 공유
9. unity-ai-operator: 컴파일 검증·씬 구성 결과 → artifacts/
10. Orchestrator: 산출물 읽고 누락·충돌·승인 필요 지점 정리
11. 최종 결과(동작 코드 + 설계/검토 요약) 정리
12. artifacts/improvement-log.md 갱신
13. TeamDelete로 정리
```

MCP 미연동 시: 9번을 unity-ai-operator 대신 수동 체크리스트(사람이 컴파일/플레이 확인)로 대체한다.

## Agent 파일 템플릿

```md
---
name: gameplay-engineer
description: 호출 조건을 구체적으로. 예: C# 게임플레이 스크립트 작성·수정이 필요할 때.
tools: Read, Grep, Glob, Edit, Write
skills:
  - csharp-convention-guide
---

당신은 {역할 이름}입니다.

## 책임
- {이 Agent가 맡는 일}

## 입력
- {받아야 할 자료: 설계안, 기존 스크립트, 컨벤션}

## 출력
- {다음 단계가 바로 쓸 산출물 형식. 코드는 Assets/ 정규 위치}

## 작업 방식
1. 목적과 산출물 확인
2. 설계안·기존 코드 읽기
3. 컨벤션에 맞게 작성
4. 컴파일 가능 여부를 unity-ai-operator에 검증 요청

## 팀 통신 프로토콜
- 메시지 수신: {누구에게 어떤 요청을 받는가}
- 메시지 발신: {컴파일 에러·설계 질문을 누구에게}
- Task 처리: 공유 목록에서 {어떤 Task}를 맡는다
- 파일 산출물: 코드는 Assets/, 작업 노트는 artifacts/{phase}-{role}.md
- 차단 조건: {언제 멈추고 확인하는가}

## 하지 말아야 할 일
- 역할 밖 결정을 확정하지 않는다
- 검증 없이 씬·에셋을 직접 바꾸지 않는다 (unity-ai-operator 경유)
```

## 팀 패턴

| 패턴 | 적용 조건 | 구성 방식 |
| --- | --- | --- |
| Pipeline | 설계 → 구현 → 검증 → 리뷰 순서 고정 | 각 단계 산출물·완료 기준을 Task로 |
| Producer-Reviewer | 구현자/리뷰어 분리 | 컴파일 에러·컨벤션 위반을 메시지로 왕복 |
| Fan-out/Fan-in | 여러 시스템 병렬 후 통합 | 시스템별 Task 분리 + 파일 소유권 분리 |
| Supervisor | 작업마다 담당 변동(신규/버그/리팩토링) | Orchestrator가 Task 상태 보고 재배정 |

## 팀 크기

| 작업 규모 | 팀원 수 |
| --- | --- |
| 1인 작업 / 작은 기능 | 2-3명 |
| 소규모 팀 / 시스템 구현 | 3-5명 |

동일 코드를 전원이 계속 읽어야 하면 팀원을 늘리지 말고 Phase를 분할한다.

## 에러 처리

| 상황 | 처리 |
| --- | --- |
| 컴파일 에러 | debugger에 SendMessage → 원인 분석 → gameplay-engineer 수정 → 1회 재검증 |
| 팀원 멈춤 | TaskGet 확인 → SendMessage로 원인 확인 → 1회 재시도 |
| 설계-구현 충돌 | 한쪽을 지우지 않고 근거 남긴 뒤 Orchestrator 판단 |
| 입력 부족 | 추측 금지, 질문 목록 작성 후 멈춤 |
| 씬·에셋 위험 작업 | 사람 승인 전 생성·삭제·대규모 변경 완료 금지 |

## 금지 구조

- Agent 파일만 여러 개 만들고 `TeamCreate` 흐름이 없는 구조
- C# 코드를 `artifacts/`에만 두고 `Assets/`에 두지 않는 구조
- 컴파일·플레이 검증 없이 완료 처리하는 구조
- unity-ai-operator가 사람 승인 없이 씬을 변경하는 구조
