## Overview
게임 내 점수를 누적·관리하고 UI에 실시간으로 반영하는 기능

## Problem / Goal
점수 계산 로직이 MonoBehaviour에 섞여 있어
테스트가 어렵고 규칙 변경 시 UI 코드까지 수정해야 하는 문제 해결

## Functional Requirements
- **ScoreManager**: IScoreCalculator.Calculate(int basePoint)를 호출해 최종 점수를 결정한다
- **ScoreManager**: 누적 점수를 ReadOnlyReactiveProperty<int>로 노출한다
- **ScoreManager**: AddScore(int basePoint)가 호출되면 IScoreCalculator로 계산 후 점수에 합산한다
- **ScoreView**: ScoreManager.Score를 구독해 TMP_Text에 즉시 반영한다

## Constraints
- ScoreManager: 순수 C# 클래스 (MonoBehaviour 없음), CompositeDisposable로 구독 관리
- ScoreView: MonoBehaviour, TMP_Text를 SerializeField로 참조

## Out of Scope
- 콤보 배율, 시간 보너스, 리더보드 연동