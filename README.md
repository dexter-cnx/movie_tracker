# Popcorn — Movie Tracker & Watchlist

Popcorn เป็น Flutter portfolio application สำหรับค้นหาและสำรวจภาพยนตร์จาก TMDB, ดูรายละเอียด, จัดการ Watchlist, บันทึกสถานะ Watched/Favorite, สร้าง Profile, เปลี่ยนภาษา และสาธิตแนวทาง production engineering ตั้งแต่ REST API, Caching, Error Handling, Authentication, Secure Token Storage, Responsive UI, Automated Tests, CI และ Release Preparation

Design direction เป็น **Cinematic Dark Minimal UI** เน้น poster/backdrop, dark surfaces, rounded cards, white primary actions และ accent สีส้ม

---

# Current Development Branch

```text
feat/production-phase-2-3
```

Branch นี้ต่อยอดจาก `feat/production-phase-1` และรวมงาน Profile/Settings, cache, typed failure, ratio-responsive layout, Integration Test และ CI จาก Phase 1 ไว้แล้ว

---

# Production Readiness Scope

## Phase 1

- Hive-backed movie cache
- Configurable 30-minute TTL
- Fresh-cache short circuit
- Network refresh on cache expiry
- Stale-cache fallback
- Mock fallback when no cache exists
- Data-source metadata
- Typed failures
- Retry and stale/offline UX
- Responsive layout based on `width / height`
- Unit, Widget, Golden and Integration Tests
- GitHub Actions CI

## Phase 2

- Demo Authentication flow
- Secure access/refresh-token storage
- Session restoration
- Token expiration handling
- Synchronized refresh to prevent duplicate refresh calls
- Runtime connectivity stream
- Application lifecycle abstraction
- Structured logger with sensitive-field redaction
- Crash reporter abstraction
- Global Flutter and platform error handlers
- Environment configuration for development/staging/production
- Build/signing/release documentation

## Phase 3

- Debounced asynchronous task coordinator
- Latest-request-wins protection
- Paginated TMDB search contract
- `PagedMovies` append/hasMore model
- Product Requirements
- User Flows
- Acceptance Criteria IDs
- Performance/Memory/Crash/Network diagnostics guide
- Pull Request template
- Code Review checklist
- Coverage threshold in Makefile and GitHub Actions

รายละเอียดเชิงลึกอยู่ที่ [Production Phase 2 & 3](docs/PRODUCTION_PHASE_2_3.md)

---

# Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter / Dart |
| State Management / DI | Riverpod |
| Navigation | go_router |
| Architecture | Lightweight Clean Architecture + MVVM-style presentation |
| HTTP | Dio |
| Remote API | TMDB API v3 |
| Rate Limit | Custom 429 retry interceptor |
| Local Storage | Hive |
| Credential Storage | flutter_secure_storage |
| Connectivity | connectivity_plus |
| Localization | easy_localization + CSV loader |
| Environment | flutter_dotenv + `AppConfig` |
| Charts | fl_chart |
| Images | cached_network_image |
| Video | youtube_player_flutter |
| Tests | flutter_test, mocktail, integration_test |
| Visual Regression | Golden Tests |
| CI | GitHub Actions |

---

# Quick Review Path


1. อ่าน README ส่วน Architecture และ Data Flow
2. อ่าน [Code Walkthrough](docs/CODE_WALKTHROUGH.md)
3. อ่าน [Production Phase 1](docs/PRODUCTION_PHASE_1.md)
4. อ่าน [Production Phase 2 & 3](docs/PRODUCTION_PHASE_2_3.md)
5. อ่าน [Product Requirements](docs/PRODUCT_REQUIREMENTS.md)
6. อ่าน [Acceptance Criteria](docs/ACCEPTANCE_CRITERIA.md)
7. ดู `lib/features/auth/`
8. ดู `lib/features/movies/`
9. ดู `lib/core/connectivity/`, `lib/core/logging/`, `lib/core/crash/`
10. ดู `.github/workflows/flutter_ci.yml`
11. รัน `make check` และ `make coverage-check`

---

# Setup

```bash
git clone https://github.com/dexter-cnx/movie_tracker.git
cd movie_tracker
git fetch
git checkout feat/production-phase-2-3
flutter pub get
```

สร้างไฟล์:

```text
assets/.env
```

แล้วเพิ่ม TMDB API Read Access Token:

```env
TMDB_BEARER_TOKEN=your_tmdb_api_read_access_token
```

ห้าม commit token จริงลง public repository

รันแอป:

```bash
flutter run
```

---

# Architecture

```text
Presentation / UI
        ↓
Riverpod Provider / Controller
        ↓
Domain Repository Interface
        ↓
Repository Implementation
        ↓
Remote / Local Data Sources
        ↓
Dio / Hive / Secure Storage
        ↓
TMDB / Device Storage
```

## Presentation

รับผิดชอบ:

- Flutter screens/widgets
- AsyncValue rendering
- loading/error/content/offline states
- navigation
- localized UI
- user interaction

## Domain

รับผิดชอบ:

- entities
- repository contracts
- session and pagination concepts
- source/failure metadata

## Data

รับผิดชอบ:

- TMDB endpoints
- JSON mapping
- Hive serialization
- Secure Storage
- repository policy
- cache/fallback strategy

## Core

รับผิดชอบ:

- Dio configuration
- retry interceptor
- typed failures
- responsive policy
- connectivity
- lifecycle
- logging/crash abstraction
- environment configuration

---

# Project Structure

```text
lib/
├── core/
│   ├── async/
│   ├── config/
│   ├── connectivity/
│   ├── crash/
│   ├── errors/
│   ├── layout/
│   ├── lifecycle/
│   ├── logging/
│   ├── network/
│   └── theme/
├── features/
│   ├── auth/
│   ├── movies/
│   ├── watchlist/
│   ├── profile/
│   ├── home/
│   ├── search/
│   ├── movie_detail/
│   └── calendar/
├── shared/
├── app.dart
└── main.dart
```

---

# Authentication and Token Management

Authentication เป็น deterministic demo เพื่อแสดง mobile-side architecture โดยไม่ต้องมี backend จริง

```text
LoginPage
   ↓
AuthController
   ↓
AuthRepository
   ├── DemoAuthRemoteDataSource
   └── SecureAuthLocalDataSource
```

`AuthSession` เก็บ:

```text
userId
accessToken
refreshToken
expiresAt
```

Token ถูกเก็บด้วย `flutter_secure_storage` ไม่ใช้ Hive หรือ SharedPreferences

## Session Restoration

```text
Application starts
    ↓
AuthController.build()
    ↓
AuthRepository.restore()
    ↓
Read Secure Storage
    ↓
Session valid?
   ├── Yes → authenticated
   └── No  → refresh or clear session
```

## Concurrent Refresh Protection

`AuthRepositoryImpl` ใช้ `_refreshInFlight` เพื่อให้หลาย request ที่พบ token หมดอายุพร้อมกันรอ refresh Future เดียวกัน

```text
Request A ─┐
Request B ─┼─> one refresh call
Request C ─┘
```

มี unit test ตรวจว่า remote refresh ถูกเรียกเพียงครั้งเดียว

---

# REST API and Pagination

รองรับ endpoint:

```text
/movie/popular
/trending/movie/week
/movie/top_rated
/movie/upcoming
/movie/now_playing
/search/movie
/genre/movie/list
/discover/movie
/movie/{id}
```

Movie detail ใช้:

```text
append_to_response=credits,videos,similar
```

Search pagination ใช้:

```dart
Future<PagedMovies> searchPage(
  String query,
  String language,
  int page,
);
```

`PagedMovies` มี:

```text
items
page
totalPages
hasMore
append(next)
```

---

# Cache and Offline Policy

Trending feed ใช้ Hive cache

```text
Read cache
   ↓
Fresh?
   ├── Yes → return cache without network
   └── No
        ↓
Call TMDB
        ↓
Success?
   ├── Yes → write cache → return network result
   └── No
        ↓
Stale cache exists?
   ├── Yes → return stale cache + failure metadata
   └── No  → return mock data + failure metadata
```

Data source metadata:

```text
network
freshCache
staleCache
mock
```

UI จึงแสดงข้อมูลเก่าพร้อม stale/offline notice ได้โดยไม่ล้าง content

---

# Error Handling and Retry

Application failures:

```text
NetworkFailure
TimeoutFailure
UnauthorizedFailure
RateLimitFailure
ServerFailure
ParsingFailure
UnknownFailure
```

Dio timeout:

```text
connect: 10 seconds
receive: 12 seconds
```

HTTP 429 retry:

```text
Retry-After when present
otherwise exponential delay
1s → 2s → 4s
```

Retry มี limit เพื่อป้องกัน infinite loop

---

# Connectivity

`ConnectivityService` expose:

```dart
Stream<NetworkStatus> get changes;
Future<NetworkStatus> current();
```

`networkStatusProvider` ให้ UI subscribe ผ่าน Riverpod

หมายเหตุ: Connectivity status บอก network transport ไม่ได้ยืนยันว่า Internet/TMDB ใช้งานได้จริง จึงต้องใช้ร่วมกับ actual request error

---

# Lifecycle

`AppLifecycleObserver` รองรับ:

```text
onPaused
onResumed
```

ใช้สำหรับ:

- pause trailer/media
- validate session เมื่อกลับ foreground
- refresh stale data แบบ targeted
- flush draft/preference
- dispose resource อย่างถูกต้อง

---

# Logging and Crash Reporting

`AppLogger` รองรับ:

```text
DEBUG
INFO
WARNING
ERROR
```

Sensitive keys ถูก redact:

```text
authorization
token
accessToken
refreshToken
password
email
```

`main.dart` ติดตั้ง:

```text
FlutterError.onError
PlatformDispatcher.instance.onError
```

`CrashReporter` เป็น abstraction ที่เปลี่ยนเป็น Crashlytics/Sentry implementation ได้ภายหลัง

---

# Search Debounce and Latest Request Wins

`DebouncedLatestTask<T>` ใช้ Timer และ generation counter

```text
rapid input
   ↓
restart debounce timer
   ↓
start latest operation
   ↓
older result returns later?
   ├── Yes → ignore
   └── No  → publish
```

จุดนี้ป้องกัน stale response ทับผลลัพธ์ล่าสุด แม้ transport request เก่าจะยกเลิกไม่ทัน

---

# Ratio-Based Responsive Layout

ใช้:

```text
ratio = screenWidth / screenHeight
```

| Ratio | Class | Columns |
|---:|---|---:|
| `< 0.62` | Tall Portrait | 2 |
| `0.62 – < 0.90` | Portrait | 3 |
| `0.90 – < 1.35` | Balanced | 4 |
| `>= 1.35` | Wide | 5 |

ใช้กับ Home, Search, Watchlist และ statistics grid

ข้อจำกัด: อุปกรณ์ขนาดต่างกันแต่ ratio เท่ากันจะได้ layout class เดียวกัน ซึ่งเป็น behavior ตาม requirement ปัจจุบัน

---

# Local Storage

Hive boxes:

```text
watchlist_items
user_preferences
movie_cache
```

Secure credentials:

```text
flutter_secure_storage
```

แยก credential storage ออกจาก preference/cache storage โดยตั้งใจ

---

# Testing

## Unit Tests

- Movie JSON mapping
- Repository fallback/cache policy
- Typed failure mapping
- Rate-limit retry
- Watchlist serialization/persistence
- Profile preferences
- Auth session restoration
- Concurrent token refresh
- Debounced latest task
- Responsive ratio policy
- Localization CSV validation

## Widget Tests

- Shared Clay components
- Profile settings
- Home stale/offline state
- Watchlist responsive grid

## Integration Tests

- Profile edit + language switch
- Movie Detail → Add to Watchlist → Verify persistence

## Golden Tests

```bash
make golden-update
make golden
```

---

# Makefile

```bash
make help
make get
make format
make format-check
make analyze
make test
make test-unit
make test-widget
make integration DEVICE=<device-id>
make golden
make golden-update
make coverage
make coverage-check
make check
make ci
```

Coverage threshold default:

```text
55%
```

override:

```bash
make coverage-check COVERAGE_MIN=70
```

---

# CI

GitHub Actions ตรวจ:

```text
Checkout
→ Setup Flutter
→ Prepare empty CI .env
→ flutter pub get
→ format check
→ flutter analyze
→ flutter test --coverage
→ enforce coverage threshold
→ upload lcov artifact
```

---

# Build and Release

Environment policy:

```text
development
staging
production
```

รายละเอียด Android flavors, iOS schemes, signing, obfuscation, symbol files, versioning และ release checklist อยู่ที่ [Build and Release](docs/BUILD_AND_RELEASE.md)

---

# Documentation Index

- [Code Walkthrough](docs/CODE_WALKTHROUGH.md)
- [Testing](docs/TESTING.md)
- [Profile Settings](docs/PROFILE_SETTINGS.md)
- [Production Phase 1](docs/PRODUCTION_PHASE_1.md)
- [Production Phase 2 & 3](docs/PRODUCTION_PHASE_2_3.md)
- [Product Requirements](docs/PRODUCT_REQUIREMENTS.md)
- [User Flows](docs/USER_FLOWS.md)
- [Acceptance Criteria](docs/ACCEPTANCE_CRITERIA.md)
- [Performance and Diagnostics](docs/PERFORMANCE_AND_DIAGNOSTICS.md)
- [Build and Release](docs/BUILD_AND_RELEASE.md)
- [Code Review Checklist](docs/CODE_REVIEW_CHECKLIST.md)

---

# Known Limitations

- Demo Auth ไม่ใช่ production identity provider
- ยังไม่มี OAuth/OIDC backend
- Connectivity status ไม่รับประกัน Internet reachability
- Search coordinator พร้อมแล้ว แต่ Search UI ยังต้อง refactor ให้ใช้ debounce เต็มรูปแบบ
- Pagination contract/data source พร้อมแล้ว แต่ infinite-scroll controller/UI ยังไม่เสร็จ
- Crash reporter ปัจจุบันเขียนลง developer log
- Native flavor/signing ต้องตั้งใน Android/iOS project และ environment จริง
- Notification และ trailer-autoplay settings ยังไม่เชื่อม platform service/player behavior ครบ

ข้อจำกัดถูกระบุชัดเพื่อไม่อ้างว่า portfolio implementation เป็น backend/security/release system ที่เสร็จสมบูรณ์

---

# Local Validation

```bash
flutter pub get
make format
make check
make coverage-check
make golden
flutter devices
make integration DEVICE=<device-id>
```

Environment ที่ใช้แก้ source ผ่าน GitHub connector ไม่สามารถรัน Flutter SDK ได้ จึงต้องยืนยัน formatter, analyzer, compiler, host tests, golden tests และ integration tests บนเครื่อง local/CI ก่อน merge
