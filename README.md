# Connectify Flutter

## Connectify
- AI Coding Agents를 활용하여 진행 중인 Connectify App 프로젝트
- Planning, App, Design, API, DB, Infra까지 서비스 개발 전 영역에 AI 협업 방식을 적용해 1인 개발 진행
- 이 저장소는 Connectify Flutter 앱 클라이언트를 담당

## Key Features
- 온라인 소셜 데이팅 서비스
- 소셜 인증
- 회원 검증
- 이미지 검증
- 회원 추천, 매칭
- 인앱 결제, 상품 구독
- 푸시 알림 수신(Firebase Messaging)

## Architecture
- **Flutter, Bloc, GetIt, Feature + Shared + Core 구조를 활용한 프로젝트**
- **App 데이터 흐름: `ApiClient -> *Client -> *RepositoryImpl -> Bloc -> View`**
- **Server 아키텍처 연계 기준: [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)**

## App Tech Stack
- Flutter, Dart SDK `^3.8.0`
- flutter_bloc, bloc, equatable, formz
- get_it
- http, json_serializable
- kakao_flutter_sdk_*
- flutter_secure_storage
- firebase_core, firebase_messaging

## Server Tech Stack (Reference)
- Java, Spring boot 3.0, Spring security
- JPA, MYSQL
- JWT
- GCP: Cloud SQL, Cloud Storage, Cloud Run
- Hexagonal Architecture

## API Server
[API Server Github Link 'connectify-api-server-gcp'](https://github.com/james9dev/connectify-api-server-gcp)
- Java, Spring boot 3.0, JPA, GCP, Hexagonal Architecture

## Getting Started
### Prerequisites
- Flutter SDK (stable)
- Xcode / Android Studio

### Run
```bash
flutter pub get
flutter run
```

### Dev Commands
```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure
```text
lib/
  core/          # di, network, push
  shared/        # authentication, models
  features/      # sign, onboarding, tab_controller, member...
```

## AI Collaboration Guide
- [Vibe Coding Rules](AGENTS.md)
- AI Context & Credit Strategy: `AGENTS.md`의 `5) 크레딧 효율 규칙`, `6) 스마트 AI 품질 규칙`
