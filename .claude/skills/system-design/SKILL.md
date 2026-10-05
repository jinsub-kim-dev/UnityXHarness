---
name: system-design
description: game-plan의 시스템 하나(예: 적 스폰 & 웨이브, 자동 공격)를 Manager/Module/Service/View로 나누고 DI 등록 위치·수치 초기값·검증 시나리오까지 정한 설계 문서 artifacts/01-design.md를 작성한다. unity-architect가 구현 전에 사용한다. 코드를 직접 작성하거나 단일 클래스의 작은 수정에는 사용하지 않는다.
---

# System Design

## 역할
구현자가 추가 질문 없이 작업할 수 있고, 리뷰어가 항목별로 대조할 수 있는 설계안을 만든다.

## 입력 (먼저 읽기)
1. `artifacts/00-input.md` — 대상 시스템, 범위, 승인 지점
2. `docs/design/game-plan.md` — Key Systems 해당 행, Core Loop, MVP/나중 경계
3. `docs/requirements/{system}.md` — 있으면 우선 기준
4. `.claude/codebase-index.md` — 재사용할 기존 클래스·인터페이스·DI 스코프
5. `.claude/skills/csharp-convention-guide/SKILL.md` — 위치·네임스페이스·레이어 규칙
6. 직전 시스템의 `artifacts/improvement-log.md` — 이어받을 결정

## 절차
1. **범위 고정**: MVP 항목만 설계한다. "나중" 항목은 확장 지점(인터페이스 자리)만 언급하고 구현 대상에서 뺀다.
2. **재사용 판단**: `00_CommonFramework`의 기존 클래스(예: `IGameFlow`, `IPlayerDataReader`, `IInputReader`, `CameraManager`)로 해결되는지 먼저 본다. Common을 수정해야 하면 **사람 승인 항목**으로 표시한다.
3. **책임 분리**: Manager / Module / Service / Context(MonoBehaviour, DI 진입) / View(MonoBehaviour, 반영) 로 나눈다. Module 분리가 과하면 Manager에 직접 두고 이유를 적는다(CLAUDE.md "Module 분리 판단 기준").
4. **의존 그래프**: 화살표로 적고 역방향·Module 간 참조가 없는지 확인한다.
5. **DI 등록**: 어느 LifetimeScope에 어떤 Lifetime·인터페이스로 등록하는지 표로 적는다. 프로젝트 전용 Scope가 필요하면 위치와 이유를 적는다.
6. **런타임 데이터**: 수치 초기값(체력·속도·간격 등)과 보관 위치(상수 / ScriptableObject `02_ScriptableObjects` / 코드 기본값)를 정한다. game-plan대로 "임의 초기값, 이후 조정" 원칙.
7. **성능**: 대량 오브젝트(적·투사체·경험치)는 풀링 방식, 탐색 비용(최근접 적 등) 처리 방식을 정한다.
8. **씬·프리팹 변경 목록**: 필요한 GameObject·프리팹·컴포넌트 부착·레이어/태그를 나열한다. 모두 사람 승인 대상이다.
9. **체크리스트 ID**: 구현이 반드시 지켜야 할 항목을 `D-01`부터 번호를 붙인다. 리뷰어가 1:1로 대조한다.
10. **자동 검증 시나리오**: Gate 3에서 확인할 것을 `T-01`부터 적는다. 각 항목에 방식(EditMode 단위 테스트 / Play 모드 프로브)과 통과 기준을 적는다.

## 출력 — `artifacts/01-design.md`

```md
# 01. 설계 — {시스템명}

작성: unity-architect
일시: YYYY-MM-DD HH:mm
대상: game-plan Development Order {n}

## 범위
- 포함:
- 제외(나중):

## 재사용 / 영향 범위
| 기존 클래스 | 사용 방식 | Common 수정 필요 |

## 클래스 구조
| 클래스 | 레이어 | 위치 | 네임스페이스 | 책임 |

## 의존 그래프
(텍스트 화살표)

## DI 등록
| 타입 | 스코프 | Lifetime | 노출 인터페이스 |

## 데이터 흐름
(입력/이벤트 → 처리 → 상태 → View 순서)

## 수치 초기값
| 항목 | 값 | 보관 위치 |

## 성능 고려

## 씬·프리팹 변경 (사람 승인 필요)
| 대상 | 변경 | 비고 |

## 설계 체크리스트
- D-01:
- D-02:

## 자동 검증 시나리오 (Gate 3)
| ID | 방식 | 절차 | 통과 기준 |

## 확인 필요
```

## 품질 기준
- 모든 클래스에 위치·네임스페이스·레이어가 있다.
- Module에 Unity API 의존이 없다(필요 시 근거).
- D-xx가 "검증 가능한 문장"이다(예: "적 사망 시 경험치 드랍 이벤트를 1회 발행").
- T-xx가 1개 이상 있고 각 통과 기준이 관찰 가능한 값이다.
- 허용 라이브러리 범위 밖이 필요하면 설계를 멈추고 확인 필요에 적는다.
- 설계안은 **사람 승인 전까지 구현으로 넘기지 않는다** (Orchestrator가 승인받음).
