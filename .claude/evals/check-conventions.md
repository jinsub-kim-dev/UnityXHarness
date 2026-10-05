# C# 컨벤션 체크리스트

검증 대상: 이번 세션에서 수정·생성된 .cs 파일

## 항목

1. 네임스페이스가 프로젝트 규칙(MyGame.{Domain})을 따르는가?
2. 클래스명이 레이어 접미사 규칙을 따르는가? (Manager / Module / Service)
3. Module 클래스가 MonoBehaviour를 상속하지 않는가? (순수 C# 클래스 규칙)
4. FindObjectOfType을 사용하지 않는가? (VContainer DI 사용)
5. Singleton .Instance 패턴을 사용하지 않는가?
6. R3를 사용한다면 복잡한 오퍼레이터 체이닝 없이 기본 수준으로만 쓰는가?