# 건대어때

[![Flutter CI](https://github.com/kominsuk1064/kku_ottae/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/kominsuk1064/kku_ottae/actions/workflows/flutter-ci.yml)

건국대학교 글로컬캠퍼스 학생이 버스 도착 정보, 주변 편의시설, 교내 지도를 한 앱에서 확인할 수 있도록 만든 Flutter 앱입니다.

이 저장소의 고도화 목표는 기능 수를 늘리는 것이 아니라, 기존 사용자 흐름을 유지하면서 **구조, 테스트 가능성, 장애 대응 상태, 배포 검증 경험**을 코드로 보여주는 것입니다. 버스 정보와 즐겨찾기를 첫 번째 vertical slice로 리팩터링했고, 로그인과 회원가입 흐름에도 같은 경계를 확장했습니다.

## 해결하려는 문제

통학과 학교생활에 필요한 정보가 교통 API, 학교 웹사이트, 개별 장소 정보로 흩어져 있습니다. 건대어때는 학생이 자주 확인하는 정보를 다음 흐름으로 모읍니다.

- 정문·후문·KU스테이션 정류장의 실시간 시내버스 도착 정보 확인
- 시외버스 정보 및 자주 보는 항목 즐겨찾기
- 카페, 음식점, 마트 등 캠퍼스 주변 편의시설 탐색
- WebView에서 건국대학교 공식 캠퍼스 지도 확인
- Firebase 이메일/비밀번호 인증, 사용자 정보 및 피드백 저장

## 주요 기술

| 영역 | 기술 | 용도 |
| --- | --- | --- |
| UI | Flutter | Android/iOS 앱 UI |
| 상태·의존성 | flutter_riverpod | 버스·즐겨찾기·인증 상태와 의존성 관리 |
| 네트워크 | http | TAGO 버스 API 호출 |
| 로컬 저장소 | SharedPreferences | 즐겨찾기 영구 저장 |
| 백엔드 | Firebase Authentication, Cloud Firestore | 인증, 사용자 정보, 피드백 |
| 지도 | webview_flutter | 공식 캠퍼스 지도 표시 |
| 자동화 | GitHub Actions | 포맷, 정적 분석, 테스트, debug APK 빌드 |

## 리팩터링 범위

기존 앱은 화면에서 API 호출, JSON 파싱, 타이머, 로컬 저장을 함께 처리해 상태 전환과 실패 경로를 검증하기 어려웠습니다. 첫 번째 vertical slice에서는 버스와 즐겨찾기의 외부 의존성을 분리했습니다.

| 이전 문제 | 적용한 해결 방법 |
| --- | --- |
| 위젯에 TAGO 요청과 응답 해석이 결합됨 | API client, parser, Repository로 분리 |
| 화면의 가변 상태와 타이머에 갱신 책임이 집중됨 | Riverpod Notifier와 불변 UI 상태 적용 |
| 성공 응답 중심의 화면 처리 | loading, empty, success, error, retry 상태 명시 |
| 주기 요청이 화면 생명주기와 느슨하게 연결됨 | `autoDispose`, 타이머 취소, 중복 요청 방지 적용 |
| SharedPreferences 접근과 UI 상태 변경이 결합됨 | local storage, Repository, controller로 분리 |
| 외부 서비스 없이는 검증하기 어려움 | HTTP, Repository, 저장소를 fake로 교체 가능한 경계 구성 |

UI를 전면 재설계하지 않았으며 기존 화면과 즐겨찾기 저장 키(`favorites`)를 유지했습니다.

## 구조

```text
lib/
├─ features/
│  ├─ auth/
│  │  ├─ domain/       # 인증 모델, 실패 유형, Repository 계약
│  │  ├─ data/         # Firebase Auth 구현과 오류 매핑
│  │  └─ application/  # 로그인·회원가입·비밀번호 재설정 상태 관리
│  ├─ bus/
│  │  ├─ domain/       # 버스 모델과 Repository 계약
│  │  ├─ data/         # TAGO API client, parser, Repository 구현
│  │  └─ application/  # Riverpod provider, controller, 불변 UI 상태
│  ├─ favorites/
│  │  ├─ domain/       # 즐겨찾기 Repository 계약
│  │  ├─ data/         # SharedPreferences 저장소와 Repository 구현
│  │  ├─ application/  # 복원·변경·저장·재시도 상태 관리
│  │  └─ presentation/ # 기존 화면과 Riverpod 상태 연결
│  └─ profile/
│     ├─ domain/       # 사용자 프로필 모델과 Repository 계약
│     ├─ data/         # Firestore 프로필 저장 구현과 오류 매핑
│     └─ application/  # 프로필 저장소 의존성 제공
└─ screens/            # 기존 화면 및 vertical slice의 UI 연결 지점
```

현재 구조는 앱 전체에 적용된 완성형 Clean Architecture가 아닙니다. 버스·즐겨찾기·로그인·회원가입과 프로필 저장 로직에 feature-first 경계를 도입했고, 마이페이지 프로필 조회·비밀번호 변경·편의시설·지도 화면은 기존 screen 중심 구조를 유지합니다.

### 버스 데이터 흐름

```text
BusArrivalsScreen
  → BusArrivalsController (Riverpod, 15초 갱신)
  → BusArrivalRepository
  → TagoBusApiClient
  → TAGO API
```

TAGO의 `item`이 List, 단일 Map, null로 달라지는 응답과 `totalCount: 0`, XML 정책 오류 응답을 parser에서 처리합니다. 최초 요청과 수동 재시도는 loading을 표시하고, 갱신 중에는 기존 결과를 유지합니다. provider가 해제되면 polling timer와 소유한 HTTP client를 정리합니다.

### 즐겨찾기 데이터 흐름

```text
기존 화면
  → FavoritesBuilder
  → FavoritesController (Riverpod)
  → FavoriteRepository
  → SharedPreferences
```

즐겨찾기는 즉시 UI에 반영한 뒤 변경 순서대로 저장합니다. 복원·저장 실패는 사용자 상태로 노출하고 다시 시도할 수 있으며, 상세 오류는 디버깅 로그로 남깁니다.

### 로그인 데이터 흐름

```text
LoginScreen
  → LoginController (Riverpod)
  → AuthRepository
  → FirebaseAuthRepository
  → Firebase Authentication
```

로그인과 비밀번호 재설정은 하나의 불변 상태 흐름으로 관리합니다. Firebase 오류 코드는 앱의 인증 실패 유형으로 변환하고, 사용자가 보는 메시지와 상세 디버깅 로그를 분리합니다. 로그인 화면은 Firebase SDK를 직접 호출하지 않습니다.

### 회원가입 데이터 흐름

```text
JoinScreen
  → SignupController (Riverpod)
  ├─ AuthRepository → Firebase Authentication
  └─ UserProfileRepository → Cloud Firestore
```

계정 생성, 인증 메일 전송, 인증 확인, 프로필 저장을 단계별 불변 상태로 관리합니다. 계정이 생성된 뒤 메일 전송이나 프로필 저장이 실패하면 계정을 다시 만들지 않고 실패한 단계만 재시도합니다. 회원가입 화면은 Firebase Authentication과 Firestore SDK를 직접 호출하지 않습니다.

## 개발 환경

- Flutter `3.35.4` (CI 기준)
- Dart SDK `^3.8.1`
- Java `17` (Android 및 CI 기준)
- Android SDK와 실행할 emulator 또는 실제 기기
- Firebase 프로젝트 설정 파일
- 공공데이터포털에서 발급한 TAGO 서비스 키

Windows에서 Flutter plugin의 symbolic link 생성 오류가 발생하면 Windows 설정에서 **개발자 모드**를 활성화해야 합니다.

## 설정

### 1. 의존성 설치

```bash
git clone https://github.com/kominsuk1064/kku_ottae.git
cd kku_ottae
flutter pub get
```

### 2. Firebase

Firebase Console에서 앱을 등록한 뒤 대상 플랫폼의 설정 파일을 로컬에 배치합니다.

| 플랫폼 | 파일 위치 |
| --- | --- |
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |

두 파일은 `.gitignore`에 포함되어 있으므로 저장소에 커밋하지 않습니다. Android debug APK는 CI의 컴파일 검증을 위해 설정 파일 없이도 빌드되지만, 이 상태에서는 Firebase 기능을 실행할 수 없습니다. non-debug Android 빌드에는 `google-services.json`이 필요합니다.

### 3. TAGO API

실시간 버스 정보는 컴파일 타임 환경값으로 주입합니다.

| 이름 | 필수 여부 | 설명 |
| --- | --- | --- |
| `TAGO_KEY` | 필수 | 공공데이터포털 TAGO 서비스 키 |
| `CITY_CODE` | 선택 | TAGO 도시 코드, 기본값 `33020` |

```bash
flutter run --dart-define=TAGO_KEY=YOUR_TAGO_KEY --dart-define=CITY_CODE=33020
```

원문 서비스 키와 URL 인코딩된 키를 모두 받을 수 있습니다. 실제 키는 소스, README, 이슈, PR 본문에 기록하지 않습니다. `--dart-define`은 값을 앱 바이너리에서 완전히 숨기는 보안 저장소가 아니므로 배포 시 키 사용 제한과 교체 정책도 별도로 관리해야 합니다.

## 검증

로컬에서 CI와 같은 순서로 실행합니다.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

버스·즐겨찾기·인증 테스트는 실제 TAGO API, 로컬 기기 저장소, Firebase Authentication, Firestore에 연결하지 않도록 HTTP client, Repository, storage를 fake 또는 주입 가능한 구현으로 대체합니다. 마이페이지 프로필 조회와 비밀번호 변경 흐름은 아직 자동화 테스트 범위에 포함되지 않습니다.

- TAGO List/Map/null/빈 응답 및 XML 오류 파싱
- 네트워크 성공, 빈 응답, HTTP 오류, timeout
- 버스 loading/empty/success/error/retry와 15초 갱신 생명주기
- 즐겨찾기 추가, 삭제, 복원, 연속 저장, 실패 복구
- 버스 상태 화면과 즐겨찾기 연결 위젯
- Firebase 인증 오류 코드 매핑과 로그인 controller 상태 전환
- 로그인·비밀번호 재설정 loading/error/success 및 작은 화면 렌더링
- 회원가입 입력 검증, 이메일 인증, 중복 요청 방지와 단계별 재시도
- Firestore 프로필 오류 매핑, 저장 실패 복구와 회원가입 화면 상태

## CI

`.github/workflows/flutter-ci.yml`은 pull request, `main` push, 수동 실행에서 다음 검사를 수행합니다.

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed lib test`
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk --debug`

워크플로는 읽기 전용 저장소 권한, Flutter/Pub 및 Gradle 캐시, 같은 브랜치의 이전 실행 취소를 사용합니다. 외부 서비스 자격 증명 없이도 동일한 코드 경계를 검증합니다.

## 현재 제약과 다음 과제

- 비밀번호 변경·마이페이지 프로필 조회·피드백 저장은 아직 Firebase와 화면에 직접 결합되어 있으며 자동화 테스트가 없습니다.
- 시외버스, 편의시설, 지도 화면은 기존 screen 중심 구조와 고정 데이터를 유지합니다.
- 일부 기존 화면에는 작은 기기에서 추가 검증이 필요한 고정 크기 UI가 남아 있습니다.
- WebView 지도는 외부 학교 웹페이지와 네트워크 상태에 영향을 받습니다.
- 현재 CI는 Android debug APK까지만 검증하며 iOS build는 포함하지 않습니다.
- Android release signing은 운영 키로 구성되지 않았고 스토어 배포 자동화도 구현하지 않았습니다.
- 리팩터링 영역은 로컬 디버깅 로그를 남기지만 원격 crash reporting과 성능 관측은 아직 없습니다.

이 항목들은 완료된 기능처럼 포장하지 않고 후속 이슈에서 작은 단위로 개선합니다.
