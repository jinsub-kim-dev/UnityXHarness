# 00. 입력 정리

작성: Orchestrator
일시: 2026-05-28 14:00

## 요청
2D 플랫포머용 PlayerController를 만들어 달라. WASD로 이동하고 스페이스로 점프하며, 지면 체크가 포함되어야 한다.

## 게임 범위
- 차원/장르: **2D 플랫포머** (물리·충돌·이동 중심)
- 작업 성격: **신규 설계**
- Unity AI 연동: **Unity 6 AI + MCP 연결됨**
- 규모: **1인 작업**

## 제약
- Unity 6 (6000.x), Built-in Render Pipeline
- 새 입력 시스템(Input System) 사용 안 함, 기존 `Input.GetKey` 계열 유지
- 기존 폴더 구조: `Assets/Scripts/Player/`, `Assets/Scripts/Common/`

## 사람 승인 지점
- Player GameObject에 컴포넌트 부착 (씬 변경)
- 충돌 레이어 신규 생성 필요 시

## 7요소 초안
| 요소 | 내용 |
| --- | --- |
| 목표 | 동작하는 `Assets/Scripts/Player/PlayerController.cs` + 설계 노트 |
| 컨텍스트 | 2D 플랫포머, Rigidbody2D 기반, 기존 `Common/GameManager.cs` 참고 |
| 도구 | Read/Edit + Unity AI MCP |
| 중간 산출물 | `artifacts/01-design.md` (입력→물리 적용 흐름, 클래스 구조) |
| 검증 | 4단계 게이트 (컴파일 → 런타임 → 기능 자동 → 사용자 확인) |
| 권한과 승인 | Player GameObject 컴포넌트 부착 전 승인 |
| 기록과 개선 | `artifacts/improvement-log.md`에 결정·실패 사유 기록 |

## 확인 필요
- 점프 입력은 스페이스만? 게임패드 대응은? → 키보드만으로 진행(피드백에서 재확인)
