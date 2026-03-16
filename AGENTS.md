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

## 10) 커밋 규칙 (Connectify 표준)
- 목표: 커밋 하나만 읽어도 "무엇이 왜 바뀌었는지"와 "안전성"이 보이게 만든다.
- 원칙 1: 하나의 커밋은 하나의 의도만 담는다. (기능 추가, 버그 수정, 리팩터링, 설정 변경을 섞지 않는다)
- 원칙 2: 동작 변경과 포맷 변경을 분리한다. (예외: 변경 파일이 매우 적고 리뷰 이득이 없을 때만 합친다)
- 원칙 3: 실패한 실험 코드는 커밋하지 않는다. (주석 처리된 임시 코드, 사용하지 않는 변수/파일 금지)
- 원칙 4: 비밀값을 절대 커밋하지 않는다. (`.env`, 토큰, 키, 개인정보)

- 메시지 형식: `<type>(<scope>): <summary>`
- 제목 길이: 50자 내외, 최대 72자
- 제목 문체: 현재형/명령형, 마침표 없음
- 본문 규칙: 필요 시 아래 3줄 구조를 사용한다.
- `why: 변경 이유`
- `what: 핵심 변경`
- `test: 검증 결과`

- 타입(type) 표준:
- `feat`: 사용자 가치가 늘어나는 기능 추가
- `fix`: 실제 버그 수정
- `refactor`: 동작 동일, 구조 개선
- `perf`: 성능 개선
- `test`: 테스트 추가/수정
- `docs`: 문서 변경
- `chore`: 개발 편의/설정/정리
- `build`: 의존성/빌드 시스템 변경
- `ci`: CI 파이프라인 변경
- `revert`: 이전 커밋 되돌림

- 스코프(scope) 표준:
- `auth`, `sign`, `explore`, `profile`, `tab`, `network`, `di`, `core`, `ui`, `test`, `config`, `docs`

- 커밋 크기 가이드:
- 권장 변경 파일 수: 3~12개
- 권장 순수 코드 변경량: 400라인 이내
- 이 범위를 넘으면 커밋을 분리한다.

- 검증 가이드:
- `feat`/`fix`/`refactor`/`perf`는 최소 `flutter analyze`를 통과하거나, 미통과 사유를 본문 `test:`에 기록한다.
- 테스트를 못 돌렸다면 이유를 본문에 반드시 남긴다.

- Flutter 전용 규칙:
- `*.g.dart` 변경은 원본 모델 변경과 같은 커밋에 포함한다.
- DI 등록 변경(`get_it`)은 사용처 변경과 함께 커밋한다.
- Bloc의 Event/State/View 변경은 가능한 한 같은 커밋에 묶는다.

- 권장 예시:
- `fix(auth): avoid duplicate DI registration in app bootstrap`
- `fix(sign): return kakao token on talk-login success path`
- `refactor(profile): model loading state in profile bloc`
- `chore(config): set dart formatter line length to 200`

## 11) 외부 참조 소스 규칙 (기획 문서 + 서버 API)
- 공식 기획 문서 루트: `../../Planning/Service Docs/`
- 공식 서버 API 프로젝트 루트: `../../API_server_v2/`

- 작업 시작 규칙:
- Flutter 기능 작업을 시작하기 전에 기획 문서에서 요구사항/화면 정의를 먼저 확인한다.
- API 연동 작업은 서버 프로젝트의 컨트롤러/DTO/문서를 함께 확인한 뒤 진행한다.
- 기획 문서와 서버 구현이 충돌하면 임의 판단으로 확정하지 말고 차이를 명시해 보고한다.

- 참조 우선순위:
- 화면 UX/문구/플로우: 기획 문서 우선
- 요청/응답 스펙/에러코드: 서버 API 구현 + 서버 문서 우선
- Flutter 내부 구조/상태 흐름: 본 프로젝트 코드 우선

- 변경 동기화 규칙:
- API 스펙이 바뀌면 Flutter 변경과 함께 서버 근거 파일 경로를 기록한다.
- 기획 변경으로 화면 동작이 바뀌면 기획 문서 파일명을 커밋/작업 요약에 남긴다.
- 서버 변경이 선행되지 않은 필드는 Flutter에서 추정 구현하지 않는다. (임시값/가짜 필드 금지)

- 권장 참조 파일 예시:
- 기획: `기획서_mvp_v0.1.md`, `화면정의서_mvp_v0.1.md`, `기능 개요.md`, `profile_tags.md`
- 서버: `../../API_server_v2/README.md`, `../../API_server_v2/docs/`, `../../API_server_v2/src/`

## 12) 아키텍처 및 폴더 규칙 (Flutter App 표준)
- 아키텍처 원칙:
- 본 앱은 `Feature + Shared + Core` 혼합 구조를 기본으로 한다.
- 의존 방향은 `presentation -> domain -> data -> core`로 단방향 유지한다.
- `shared`는 전역 인증/공통 모델/공통 상태만 둔다. (기능 전용 로직 금지)
- `core`는 DI, 네트워크, 공통 DTO, 에러/유틸만 둔다.

- 폴더 배치 원칙:
- 기능 코드는 `lib/features/<feature>/` 하위에 배치한다.
- 각 feature는 가능하면 `data`, `domain`, `presentation` 3계층을 유지한다.
- Bloc은 `presentation/bloc`, 화면은 `presentation/view`(또는 `views`)로 통일한다.
- 탭별 기능은 `features/tab_controller/tab_x_<name>/` 네이밍을 유지한다.
- 공통 모델은 `lib/shared/models`, 전역 인증은 `lib/shared/authentication`에만 위치시킨다.

- 파일 네이밍 원칙:
- API 호출: `*_client.dart`
- 저장소 구현: `*_repository_impl.dart`
- 추상 저장소: `domain/*_repository.dart`
- 상태관리: `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- 화면: `*_page.dart`, 재사용 UI 조각: `*_form.dart`, `*_view.dart`

- DI/생명주기 규칙:
- DI 등록은 `lib/core/di/di.dart` 단일 진입점에서 관리한다.
- `setupDI()`는 idempotent 유지한다.
- 화면/Bloc에서 구현체 직접 생성 금지, 인터페이스 주입 우선.
- 전역 상태(Auth 등)는 앱 루트에서만 생성하고 하위로 전달한다.

- 금지 규칙:
- Feature 간 내부 구현 직접 참조 금지 (인터페이스 통해 접근)
- `presentation` 계층에서 `http` 직접 호출 금지
- 토큰/민감정보 로그 출력 금지
- 임시 주석 코드/미사용 파일 커밋 금지

- 변경 체크 규칙:
- 새 기능 추가 시: 폴더 생성 -> domain 계약 -> data 구현 -> bloc/state -> view 순서로 작업
- API 변경 시: 서버 근거 경로 + Flutter 변경 파일을 함께 기록
