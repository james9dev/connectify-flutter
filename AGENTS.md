# Connectify Flutter AI 운영 규칙

## 1) 프로젝트 스냅샷 (2026-03-12 기준)
- 앱 타입: Flutter 기반 인증/탭형 앱
- 핵심 스택: `flutter_bloc`, `get_it`, `http`, `json_serializable`, `kakao_flutter_sdk_*`, `flutter_secure_storage`
- 주요 진입점: `lib/main.dart` -> `lib/app.dart`
- 인증 흐름: `AuthenticationRepository`(토큰 저장/스트림) + `AuthenticationBloc`(라우팅 분기)
- 데이터 흐름: `ApiClient` -> `*Client` -> `*RepositoryImpl` -> `Bloc` -> `View`

## 2) 현재 구조 핵심
- 아키텍처는 Feature + Shared 혼합 구조다.
- 전역 DI는 `lib/core/di/di.dart`에서 `getIt`으로 등록한다.
- `App` 내부에서는 일부 의존성을 `getIt` 대신 직접 생성하고 있어 DI 일관성이 깨져 있다.
- 테스트는 기본 템플릿(`counter`) 상태이며 현재 앱 구조와 맞지 않는다.

## 3) 우선 리스크 (먼저 해결)
- `ApiClient.post()` URL 생성 방식 불일치 (`Uri.http` + https baseUrl) 가능성.
- 카카오톡 로그인 성공 분기에서 access token을 반환하지 않는 로직.
- `ExploreBloc`에서 빈 리스트일 때 `members.first` 접근 가능성.
- `ProfileBloc`이 데이터를 가져오기만 하고 상태를 emit하지 않음.
- `ProfileState.copyWith()`가 인자를 반영하지 않음.
- 토큰/응답 전문 `print` 로그 노출(보안 및 분석 노이즈).
- 테스트가 DI 초기화(`setupDI`) 없이 `App()`을 바로 pump하여 실패.

## 4) 바이브 코딩 규칙 (속도 + 몰입)
- 규칙 1: 한 번에 하나의 사용자 가치만 배포한다. (예: 로그인 안정화만)
- 규칙 2: 큰 리팩터링보다 작은 수직 슬라이스(도메인->블록->뷰)를 우선한다.
- 규칙 3: 막히면 즉시 우회 경로를 제시한다. (Stub/Feature Flag/임시 핸들러)
- 규칙 4: 설명은 짧고 행동은 빠르게 한다. 코드/검증 결과 중심으로 보고한다.
- 규칙 5: 실패를 숨기지 말고 “원인 + 다음 행동”을 같은 메시지에 남긴다.

## 5) 크레딧 효율 규칙 (토큰/시간 최적화)
- 규칙 1: 항상 범위를 먼저 제한한다. 전체 검색보다 `lib/features/...` 타깃 탐색부터 시작.
- 규칙 2: 파일 읽기는 필요한 부분만. (`sed -n`, `rg <symbol>`)
- 규칙 3: 생성보다 수정 우선. 기존 Bloc/Repository를 확장해 중복 파일 생성을 줄인다.
- 규칙 4: 검증은 단계적으로.
- `flutter analyze` -> 변경 영역 테스트 -> 필요 시 전체 `flutter test`
- 규칙 5: 로그는 구조화하고 최소화한다. 민감정보(access/refresh token)는 절대 출력 금지.
- 규칙 6: PR/커밋 단위는 작게 유지한다. (1 이슈 = 1 변경 묶음)
- 규칙 7: 동일 원인 에러는 재시도보다 가설 수정 후 1회 재검증한다.

## 6) 스마트 AI 품질 규칙 (정확도/회귀 방지)
- 규칙 1: Null/빈 배열/비동기 경계는 기본 방어코드부터 넣는다.
- 규칙 2: 상태 객체 `copyWith`와 `Equatable props` 동기화는 필수 점검 항목이다.
- 규칙 3: DI는 단일 방식으로 유지한다. (`getIt` 등록/해결 일관성)
- 규칙 4: 네트워크 레이어는 URL/헤더/예외 처리 규칙을 통일한다.
- 규칙 5: 인증 상태 전이는 3개만 명확히 관리한다.
- `unknown` / `authenticated` / `unauthenticated`
- 규칙 6: 테스트는 “현재 UI/라우팅 구조” 기준으로 갱신한다. 템플릿 테스트를 방치하지 않는다.

## 7) 작업 시작 체크리스트
- `main.dart` 초기화 순서(`ensureInitialized`, `dotenv`, SDK init, `setupDI`) 확인
- 변경 대상 Bloc의 Event/State/View 동기화 확인
- API 응답 DTO 파싱 실패 시 fallback 정책 확인
- 민감정보 로그 출력 여부 확인

## 8) 작업 완료 체크리스트
- `flutter analyze` 경고/오류 확인
- 변경 범위 테스트 통과 확인
- 크래시 가능 경로(빈 리스트, null 필드, 미등록 DI) 수동 점검
- 변경 이유/영향/남은 리스크를 5줄 내로 기록

## 9) 추천 작업 우선순위
- 1순위: 인증/토큰/DI 안정화
- 2순위: Explore/Profile 상태관리 결함 수정
- 3순위: 테스트 리베이스 + 최소 스모크 테스트 확보
- 4순위: 로그/예외 정책 정리
