---
name: add-feature
description: "기능 추가 요청을 받아 코드베이스를 분석한 후 유형에 맞는 Skill로 처리"
tools: Read, Glob, Grep
---

## 1단계: 인덱스 확인
`codebase-index.md`를 읽어 요청과 관련된 기존 클래스를 찾습니다.

## 2단계: 유형 판단
- 관련 책임을 가진 기존 클래스가 있으면 → extend-class Skill 실행
- 없으면 → create-component Skill 실행

## 3단계: Skill 실행
판단 결과에 따라 해당 Skill을 호출합니다.