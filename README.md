# 건대어때

[![Flutter CI](https://github.com/kominsuk1064/kku_ottae/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/kominsuk1064/kku_ottae/actions/workflows/flutter-ci.yml)

건국대학교 글로컬캠퍼스 학생이 버스 도착 정보, 주변 편의시설, 교내 지도를 한 앱에서 확인할 수 있도록 만든 Flutter 앱입니다.

이 저장소의 고도화 목표는 기능 수를 늘리는 것이 아니라, 기존 사용자 흐름을 유지하면서 **구조, 테스트 가능성, 장애 대응 상태, 배포 검증 경험**을 코드로 보여주는 것입니다. 버스 정보와 즐겨찾기를 첫 번째 vertical slice로 리팩터링했고, 로그인·회원가입·계정 세션·프로필 조회·피드백 제출·캠퍼스 지도 흐름에도 같은 경계를 확장했습니다.

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
| 상태·의존성 | flutter_riverpod | 버스·즐겨찾기·인증·프로필·피드백·지도 상태와 의존성 관리 |
| 네트워크 | http | TAGO 버스 API 호출 |
| 로컬 저장소 | SharedPreferences | 즐겨찾기 영구 저장 |
| 백엔드 | Firebase Authentication, Cloud Firestore | 인증, 사용자 정보, 피드백 |
| 운영 관측 | Firebase Crashlytics | release 환경의 fatal·non-fatal 오류 보고 |
| 지도 | webview_flutter | 공식 캠퍼스 지도 표시 |
| 자동화 | GitHub Actions | 포맷, 정적 분석, 테스트, debug APK와 수동 서명 AAB 빌드 |

## 리팩터링 범위

기존 앱은 화면에서 API 호출, JSON 파싱, 타이머, 로컬 저장을 함께 처리해 상태 전환과 실패 경로를 검증하기 어려웠습니다. 첫 번째 vertical slice에서는 버스와 즐겨찾기의 외부 의존성을 분리했습니다.

| 이전 문제 | 적용한 해결 방법 |
| --- | --- |
| 위젯에 TAGO 요청과 응답 해석이 결합됨 | API client, parser, Repository로 분리 |
| 화면의 가변 상태와 타이머에 갱신 책임이 집중됨 | Riverpod Notifier와 불변 UI 상태 적용 |
| 성공 응답 중심의 화면 처리 | loading, empty, success, error, retry 상태 명시 |
| 주기 요청이 화면 생명주기와 느슨하게 연결됨 | `autoDispose`, 타이머 취소, 중복 요청 방지 적용 |
| SharedPreferences 접근과 UI 상태 변경이 결합됨 | local storage, Repository, controller로 분리 |
| 마이페이지에서 인증 사용자와 Firestore 문서를 직접 조회함 | Auth·Profile Repository와 프로필 controller로 분리 |
| 피드백 화면에서 사용자 확인과 Firestore 저장을 직접 처리함 | Auth·Feedback Repository와 제출 controller로 분리 |
| WebView 오류를 로그만 남기고 빈 화면으로 유지함 | 지도 controller, WebView 어댑터, loading·error·retry 상태로 분리 |
| 초기·홈 화면의 큰 고정 여백과 버튼 높이가 작은 화면에서 넘침 | 화면 제약 기반 크기, 최대 너비, 스크롤 가능한 레이아웃 적용 |
| 편의시설 그리드와 상세 카드가 고정 폭을 가정해 긴 이름·주소가 넘침 | 폭별 1·2·3열 그리드, 콘텐츠 최대 너비, 줄바꿈 가능한 공용 카드 적용 |
| Android가 예제 식별자와 debug release 서명을 사용함 | 정식 application ID, 외부 키스토어 기반 release 서명과 누락 설정 preflight 적용 |
| 처리된 오류가 로컬 로그에만 남아 운영 장애를 확인하기 어려움 | 주입 가능한 오류 reporter, 전역 handler와 release 전용 Crashlytics 적용 |
| 외부 서비스 없이는 검증하기 어려움 | HTTP, Repository, 저장소를 fake로 교체 가능한 경계 구성 |

UI를 전면 재설계하지 않았으며 기존 화면과 즐겨찾기 저장 키(`favorites`)를 유지했습니다.

## 구조

```text
lib/
├─ core/
│  └─ observability/  # 오류 모델, reporter와 전역 Flutter·비동기 handler
├─ features/
│  ├─ auth/
│  │  ├─ domain/       # 인증 모델, 실패 유형, Repository 계약
│  │  ├─ data/         # Firebase Auth 구현과 오류 매핑
│  │  └─ application/  # 로그인·회원가입·비밀번호 변경·세션 상태 관리
│  ├─ bus/
│  │  ├─ domain/       # 버스 모델과 Repository 계약
│  │  ├─ data/         # TAGO API client, parser, Repository 구현
│  │  └─ application/  # Riverpod provider, controller, 불변 UI 상태
│  ├─ campus_map/
│  │  ├─ application/  # WebView 로드·진행률·타임아웃·오류 상태 관리
│  │  └─ presentation/ # 플랫폼 WebView 어댑터와 상태별 화면
│  ├─ feedback/
│  │  ├─ domain/       # 피드백 모델, 실패 유형, Repository 계약
│  │  ├─ data/         # Firestore 피드백 저장 구현과 오류 매핑
│  │  └─ application/  # 별점·검증·제출 상태와 의존성 관리
│  ├─ favorites/
│  │  ├─ domain/       # 즐겨찾기 Repository 계약
│  │  ├─ data/         # SharedPreferences 저장소와 Repository 구현
│  │  ├─ application/  # 복원·변경·저장·재시도 상태 관리
│  │  └─ presentation/ # 기존 화면과 Riverpod 상태 연결
│  └─ profile/
│     ├─ domain/       # 사용자 프로필 모델과 Repository 계약
│     ├─ data/         # Firestore 프로필 조회·저장, 문서 파싱과 오류 매핑
│     └─ application/  # 프로필 조회 상태 관리와 저장소 의존성 제공
└─ screens/            # 기존 화면 및 vertical slice의 UI 연결 지점
```

현재 구조는 앱 전체에 적용된 완성형 Clean Architecture가 아닙니다. 버스·즐겨찾기·인증 세션·프로필·피드백·캠퍼스 지도 로직에 feature-first 경계를 도입했고, 편의시설 화면은 기존 screen 중심 구조를 유지합니다.

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

### 계정 세션 데이터 흐름

```text
ChangePasswordScreen ─→ ChangePasswordController ─┐
                                                  ├→ AuthRepository
MyPageScreen ─→ SessionSignOutBuilder             │  → FirebaseAuthRepository
             └→ AuthSessionController ────────────┘  → Firebase Authentication
```

비밀번호 변경은 현재 비밀번호 재인증과 새 비밀번호 적용을 하나의 Repository 작업으로 처리합니다. Firebase 내부 오류는 사용자 메시지와 분리하며 진행 중인 중복 요청을 차단합니다. 로그아웃은 Firebase 세션 종료에 성공한 뒤에만 초기 화면으로 이동하고, 실패하면 현재 화면을 유지한 채 다시 시도할 수 있습니다.

### 프로필 데이터 흐름

```text
MyPageScreen
  → UserProfileController (Riverpod)
  ├─ AuthRepository → 현재 로그인 사용자
  └─ UserProfileRepository → Firestore users/{uid}
```

마이페이지는 Firebase SDK를 직접 호출하지 않고 loading, empty, success, error 상태만 렌더링합니다. 프로필 문서가 없거나 필드가 누락된 경우를 안전하게 처리하며, 실패 상세는 디버깅 로그에 남기고 사용자에게는 작업에 맞는 메시지와 재시도를 제공합니다.

### 피드백 데이터 흐름

```text
FeedbackScreen
  → FeedbackSubmissionController (Riverpod)
  ├─ AuthRepository → 현재 로그인 사용자
  └─ FeedbackRepository → Firestore feedbacks
```

피드백 화면은 Firebase SDK를 직접 호출하지 않습니다. 별점과 입력 검증, submitting, success, failure 상태를 하나의 불변 흐름으로 관리하며 진행 중인 중복 제출을 차단합니다. 기존 `feedbacks` 컬렉션과 `userId`, `rating`, `comment`, `createdAt` 필드를 유지하고, 실패 상세는 디버깅 로그와 사용자 메시지로 분리합니다.

### 캠퍼스 지도 데이터 흐름

```text
CampusMapScreen
  → CampusMapController (Riverpod, autoDispose)
  → CampusMapBrowser
  → webview_flutter
  → 건국대학교 공식 캠퍼스 지도
```

화면은 WebView controller를 직접 다루지 않고 플랫폼 어댑터를 통해 로드와 새로고침만 요청합니다. 로딩 진행률, 성공, 주 프레임 네트워크·HTTP 오류, 20초 타임아웃과 재시도를 불변 상태로 관리하며, 이미지 같은 하위 리소스 하나의 실패가 전체 지도 오류 화면으로 바뀌지 않도록 구분합니다. provider가 해제되면 로드 타이머를 취소하고, 상세 WebView 오류는 디버깅 로그에만 남깁니다. 앱에서 호출하는 지도와 TAGO 주소는 HTTPS를 사용하며 Android manifest의 전역 cleartext 허용은 제거했습니다.

### 운영 오류 관측 흐름

```text
FlutterError.onError / PlatformDispatcher.onError
  └─ AppErrorReporter
     ├─ DeveloperLogAppErrorReporter
     └─ FirebaseCrashlyticsAppErrorReporter (release only)

BusArrivalsController / FavoritesController
  └─ AppErrorReporter (non-fatal)
```

전역 Flutter framework 오류와 처리되지 않은 비동기 오류는 fatal로, 버스 조회와 즐겨찾기 복원·저장 실패는 사용자 상태를 유지하면서 non-fatal로 기록합니다. reporter는 Riverpod provider로 주입하므로 테스트에서는 Firebase 대신 fake를 사용합니다. debug와 profile 빌드는 원격 수집을 비활성화하고 로컬 개발 로그만 남깁니다. 이메일, 학번, API 키와 같은 사용자 입력이나 비밀값을 custom key 또는 로그에 추가하지 않습니다.

### 반응형 진입 화면

`InitialScreen`과 `HomeScreen`은 `LayoutBuilder`에서 사용 가능한 화면 제약을 읽어 로고와 간격의 상·하한을 정합니다. 콘텐츠에는 최대 너비를 적용해 태블릿과 가로 화면에서 과도하게 늘어나지 않게 하고, 세로 공간이 부족하면 `SingleChildScrollView`로 모든 동작에 접근할 수 있습니다. 기존 로그인·회원가입·프로필·버스·편의시설·학교지도 이동 흐름과 색상, 로고 자산은 유지했습니다.

### 반응형 편의시설 화면

편의시설과 음식점 카테고리는 사용 가능한 폭에 따라 1·2·3열로 전환하고, 목록 콘텐츠는 최대 너비를 적용해 태블릿에서 과도하게 늘어나지 않도록 했습니다. 상세 카드의 상호명과 주소는 즐겨찾기 버튼 및 위치 아이콘 옆에서 남은 폭을 사용해 여러 줄로 표시합니다. 기존 카테고리 이동 경로, 장소 데이터, SharedPreferences에 저장되는 즐겨찾기 키 형식은 변경하지 않았습니다.

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

Android 앱은 application ID `com.kominsuk1064.kkuottae`로 등록해야 합니다. 이전 예제 ID로 만든 `google-services.json`은 새 빌드와 호환되지 않습니다.

| 플랫폼 | 파일 위치 |
| --- | --- |
| Android | `android/app/google-services.json` |
| iOS | `ios/Runner/GoogleService-Info.plist` |

두 파일은 `.gitignore`에 포함되어 있으므로 저장소에 커밋하지 않습니다. Android debug APK는 CI의 컴파일 검증을 위해 설정 파일 없이도 빌드되지만, 이 상태에서는 Firebase 기능을 실행할 수 없습니다. non-debug Android 빌드에는 `google-services.json`이 필요합니다.

Crashlytics 원격 수집은 release 빌드에서만 활성화됩니다. Android release는 프로세스 시작 시점부터 수집하고, iOS release는 Flutter 초기화에서 활성화합니다. Android와 iOS의 debug·profile은 네이티브 설정과 Flutter 초기화에서 수집을 비활성화합니다. 실제 Firebase Console 수신 여부는 운영 Firebase 설정과 서명을 주입한 release 빌드에서 확인해야 합니다. 앱에는 검증 목적의 강제 crash 버튼을 추가하지 않았습니다.

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

### 4. Android release 서명

Android 표시 이름은 `건대어때`, application ID와 namespace는 `com.kominsuk1064.kkuottae`를 사용합니다. release 빌드는 debug 키로 대체되지 않으며 Firebase 설정과 별도의 upload key가 모두 있어야 합니다.

application ID가 달라지면 기존 `com.example.ottae_fixed` 설치본과 별도 앱으로 취급되므로 실제 배포 전에 이 값을 확정해야 합니다. Firebase Android 앱도 같은 ID로 새로 등록합니다.

1. 비밀번호를 명령행에 기록하지 않고 대화형으로 upload key를 생성합니다.

```bash
keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. `android/key.properties.example`을 `android/key.properties`로 복사하고 실제 값을 입력합니다.

| 이름 | 설명 |
| --- | --- |
| `storeFile` | `android` 디렉터리 기준 키스토어 경로 또는 절대 경로 |
| `storePassword` | 키스토어 비밀번호 |
| `keyAlias` | upload key 별칭 |
| `keyPassword` | upload key 비밀번호 |

3. 같은 application ID로 발급한 `android/app/google-services.json`을 배치하고 AAB를 빌드합니다.

```bash
flutter build appbundle --release --dart-define=TAGO_KEY=YOUR_TAGO_KEY --dart-define=CITY_CODE=33020
```

`key.properties`, `*.jks`, `*.keystore`, Firebase 설정 파일은 Git에서 제외됩니다. release 설정이 없거나 예시 값이 남아 있으면 Gradle이 누락 항목을 표시하고 빌드를 중단합니다.

### 5. GitHub Actions release 설정

`.github/workflows/android-release.yml`은 `main` 브랜치에서 수동으로만 실행됩니다. 다음 값을 **Settings → Secrets and variables → Actions → Repository secrets**에 등록합니다.

| Secret | 설명 |
| --- | --- |
| `ANDROID_RELEASE_KEYSTORE_BASE64` | upload keystore 파일 전체를 base64로 변환한 값 |
| `ANDROID_RELEASE_STORE_PASSWORD` | 키스토어 비밀번호 |
| `ANDROID_RELEASE_KEY_ALIAS` | upload key 별칭 |
| `ANDROID_RELEASE_KEY_PASSWORD` | upload key 비밀번호 |
| `FIREBASE_ANDROID_CONFIG_BASE64` | 새 application ID용 `google-services.json` 전체를 base64로 변환한 값 |
| `TAGO_KEY` | 공공데이터포털 TAGO 서비스 키 |

Windows PowerShell에서는 다음 명령으로 줄바꿈 없는 base64 값을 만들 수 있습니다. 출력값은 파일이나 저장소에 남기지 않고 해당 GitHub Secret에 바로 등록합니다.

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/upload-keystore.jks"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/google-services.json"))
```

GitHub의 **Actions → Android Release → Run workflow**에서 `main`을 선택하고 version name과 이전 배포보다 큰 build number를 입력합니다. workflow는 포맷, 정적 분석과 전체 테스트를 먼저 통과한 뒤 다음 항목을 검증합니다.

- 필수 Secret 존재 여부와 version 입력 범위
- Firebase 설정의 package ID `com.kominsuk1064.kkuottae`
- upload keystore, store password와 key alias
- Gradle release 서명과 생성된 AAB 서명

성공하면 서명된 AAB와 SHA-256 checksum을 하나의 artifact로 14일간 보관합니다. workflow는 저장소 쓰기 권한이 없고 Play Store 업로드, Git tag 또는 GitHub Release 생성은 수행하지 않습니다. 임시 키스토어와 Firebase 설정은 성공 여부와 관계없이 job 마지막에 삭제합니다.

## 검증

로컬에서 CI와 같은 순서로 실행합니다.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

버스·즐겨찾기·인증·프로필·피드백·오류 관측 테스트는 실제 TAGO API, 로컬 기기 저장소, Firebase Authentication, Firestore, Crashlytics에 연결하지 않도록 HTTP client, Repository, storage, reporter를 fake 또는 주입 가능한 구현으로 대체합니다.

- TAGO List/Map/null/빈 응답 및 XML 오류 파싱
- 네트워크 성공, 빈 응답, HTTP 오류, timeout
- 버스 loading/empty/success/error/retry와 15초 갱신 생명주기
- 즐겨찾기 추가, 삭제, 복원, 연속 저장, 실패 복구
- 버스 상태 화면과 즐겨찾기 연결 위젯
- Firebase 인증 오류 코드 매핑과 로그인 controller 상태 전환
- 로그인·비밀번호 재설정 loading/error/success 및 작은 화면 렌더링
- 회원가입 입력 검증, 이메일 인증, 중복 요청 방지와 단계별 재시도
- Firestore 프로필 오류 매핑, 저장 실패 복구와 회원가입 화면 상태
- 비밀번호 재인증·변경의 검증, 오류 변환, loading/success 상태
- 실제 로그아웃, 중복 요청 방지, 실패 후 재시도와 화면 이동
- Firestore 프로필 문서 없음·필드 누락 파싱과 현재 사용자 조회
- 프로필 loading/empty/success/error/retry 상태와 작은 화면 렌더링
- 피드백 입력 경계, 별점, 로그인 상태, 중복 제출과 Firestore 오류 매핑
- 피드백 submitting/error/retry/success 상태와 작은 화면 렌더링
- 지도 로딩 진행률, 주 프레임·하위 리소스 네트워크·HTTP 오류 구분, timeout과 중복 새로고침
- 지도 loading/error/retry/success 상태와 작은 화면 렌더링
- 초기·홈 화면의 320×480 세로 및 568×320 가로 레이아웃과 기존 네비게이션
- 편의시설 1·2·3열 전환, 긴 상호명·주소, 목록 스크롤과 11개 카테고리 이동 경로
- Flutter framework·비동기 fatal 오류 전달과 reporter 실패 격리
- 버스 조회 및 즐겨찾기 복원·저장 실패의 non-fatal 오류 보고

## CI

`.github/workflows/flutter-ci.yml`은 pull request, `main` push, 수동 실행에서 다음 검사를 수행합니다.

1. `flutter pub get`
2. `dart format --output=none --set-exit-if-changed lib test`
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk --debug`

워크플로는 읽기 전용 저장소 권한, Flutter/Pub 및 Gradle 캐시, 같은 브랜치의 이전 실행 취소를 사용합니다. 외부 서비스 자격 증명 없이도 동일한 코드 경계를 검증합니다.

`.github/workflows/android-release.yml`은 일반 CI와 분리된 수동 release 경로입니다. `main`의 코드만 대상으로 같은 품질 검사를 다시 실행하고, Repository Secrets를 임시 파일과 Gradle 환경변수로 주입해 서명 AAB와 checksum artifact를 생성합니다. release 실행은 겹치지 않으며 이전 실행을 자동 취소하지 않습니다.

## 현재 제약과 다음 과제

- 시외버스와 편의시설 데이터는 기존 screen 중심 구조와 고정 데이터를 유지합니다.
- 편의시설 화면은 반응형 레이아웃을 적용했지만 장소 데이터의 최신성 검증과 별도 데이터 계층은 아직 없습니다.
- WebView 지도는 오류·타임아웃·재시도 상태를 제공하지만 콘텐츠 가용성은 외부 학교 웹페이지와 네트워크 상태에 영향을 받습니다.
- PR CI는 Android debug APK까지만 검증하며 iOS build는 포함하지 않습니다.
- Android 수동 release workflow는 구성했지만 Repository Secrets를 사용한 실제 서명 AAB 실행은 운영 자격 증명 등록 후 확인해야 하며, Play Store 배포 자동화는 아직 없습니다.
- Crashlytics 수신은 운영 설정을 주입한 Android release에서 확인해야 하며 성능 추적과 iOS dSYM 업로드 자동화는 아직 없습니다.

이 항목들은 완료된 기능처럼 포장하지 않고 후속 이슈에서 작은 단위로 개선합니다.
