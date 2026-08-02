# Popcorn — Movie Tracker & Watchlist

Popcorn เป็น Flutter portfolio application สำหรับค้นหาและสำรวจภาพยนตร์จาก TMDB, ดูรายละเอียดภาพยนตร์, จัดการ Watchlist, บันทึกประวัติการรับชม, สร้าง Profile, เปลี่ยนภาษา และสาธิตแนวทาง production-readiness เช่น cache policy, typed failures, retry, stale-data UX, responsive layout, automated tests และ GitHub Actions CI

โปรเจกต์นี้ไม่ได้ตั้งใจเป็นเพียง UI mockup แต่จัดโครงสร้างให้สามารถใช้ประกอบการอธิบายงาน Mobile Application Development ได้ตั้งแต่ Requirement Flow, Architecture, REST API, State Management, Local Storage, Caching, Error Handling, Testing และ CI

Design direction ปัจจุบันเป็น **Cinematic Dark Minimal UI** เน้น poster/backdrop, dark surfaces, rounded cards, white primary actions และ accent สีส้ม

---

# Current Branch

Production-readiness Phase 1 อยู่ที่:

```text
feat/production-phase-1
```

Pull Request:

```text
PR #3 — feat: production readiness phase 1
```

Branch นี้รวม Profile/Settings จากงานก่อนหน้าไว้แล้ว จึงควร review และทดสอบจาก branch นี้แทน branch `feat/profile-settings`

---

# Feature Overview

## Movie Discovery

- Trending Movies
- Popular Movies
- Top Rated
- Upcoming
- Now Playing
- Search by query
- Filter by Genre
- Movie Roulette

## Movie Detail

- Backdrop
- Poster
- Title
- Rating
- Release year
- Runtime
- Genres
- Overview
- Budget
- Revenue
- Vote count
- Original language
- Cast
- YouTube Trailer
- Similar Movies
- Add to Watchlist
- Mark as Watched

## Watchlist

Statuses:

```text
Want to Watch
Watched
Favorite
```

User data:

```text
Personal Rating
Notes
Watched Date
Runtime
Genre
```

Derived statistics:

```text
Total Movies Watched
Total Watch Hours
Average Personal Rating
Favorite Genre
```

## Profile and Settings

- Editable display name
- Email
- Favorite genre
- Runtime English/Thai language switching
- Persisted notification preference
- Persisted trailer-autoplay preference
- Release Calendar shortcut
- About / App version

## Production Phase 1

- Hive-backed movie cache
- 30-minute configurable TTL
- Fresh-cache short circuit
- Network refresh when cache expires
- Stale-cache fallback
- Mock fallback when no cache exists
- Data-source metadata
- Typed failures
- Retry and offline/stale UX
- Ratio-based responsive layout
- Unit tests
- Widget tests
- Golden tests
- Integration tests
- GitHub Actions CI

---

# Tech Stack

| Area | Technology |
|---|---|
| Framework | Flutter / Dart |
| State Management | Riverpod |
| Navigation | go_router |
| Architecture | Lightweight Clean Architecture + MVVM-style presentation |
| HTTP | Dio |
| Retry | Custom `RateLimitInterceptor` |
| Remote API | TMDB API v3 |
| Local Storage | Hive |
| Localization | easy_localization + CSV loader |
| Environment | flutter_dotenv |
| Charts | fl_chart |
| Images | cached_network_image |
| Video | youtube_player_flutter |
| Unit/Widget Testing | flutter_test + mocktail |
| Integration Testing | integration_test |
| Visual Regression | Golden tests |
| CI | GitHub Actions |

---

# Quick Review Path

สำหรับ reviewer หรือผู้สัมภาษณ์ แนะนำให้ดูตามลำดับนี้:

1. อ่านหัวข้อ Architecture และ Data Flow ใน README
2. อ่าน [Code Walkthrough](docs/CODE_WALKTHROUGH.md)
3. อ่าน [Production Phase 1](docs/PRODUCTION_PHASE_1.md)
4. อ่าน [Testing Guide](docs/TESTING.md)
5. ดู `lib/features/movies/`
6. ดู `lib/features/watchlist/`
7. ดู `lib/features/profile/`
8. ดู `.github/workflows/flutter_ci.yml`
9. รัน `make check`
10. รัน Integration และ Golden tests

---

# Setup

## 1. Clone Repository

```bash
git clone https://github.com/dexter-cnx/movie_tracker.git
cd movie_tracker
```

Checkout Phase 1:

```bash
git fetch

git checkout feat/production-phase-1
git pull
```

## 2. Check Flutter

```bash
flutter --version
flutter doctor -v
```

โปรเจกต์กำหนด Dart SDK:

```yaml
environment:
  sdk: ">=3.4.0 <4.0.0"
```

## 3. Install Dependencies

```bash
flutter pub get
```

หรือ:

```bash
make get
```

---

# Environment Configuration

แอปอ่าน TMDB API Read Access Token จาก:

```text
assets/.env
```

## 1. Create `.env`

```bash
mkdir -p assets
touch assets/.env
```

## 2. Add TMDB Bearer Token

```env
TMDB_BEARER_TOKEN=your_tmdb_api_read_access_token
```

ใช้ **TMDB API Read Access Token** ไม่ใช่ API Key แบบสั้น

ตัวอย่างรูปแบบ:

```env
TMDB_BEARER_TOKEN=eyJhbGciOiJIUzI1NiJ9...
```

## 3. Asset Registration

`pubspec.yaml` ต้องมี:

```yaml
flutter:
  assets:
    - assets/langs/
    - assets/.env
```

## 4. Loading

`lib/main.dart` โหลดก่อน `runApp()`:

```dart
await dotenv.load(fileName: 'assets/.env');
```

Dio อ่าน token:

```dart
dotenv.env['TMDB_BEARER_TOKEN']
```

แล้วแนบ:

```http
Authorization: Bearer <token>
```

## 5. Security

ไม่ควร commit production token ลง public repository

แนะนำ `.gitignore`:

```gitignore
assets/.env
```

และเก็บ template:

```text
assets/.env.example
```

```env
TMDB_BEARER_TOKEN=
```

GitHub Actions สร้าง `.env` ว่างสำหรับ CI เพราะ automated tests ต้องไม่พึ่ง secret หรือ external TMDB availability

---

# Run Application

ดู device:

```bash
flutter devices
```

รัน:

```bash
flutter run
```

ระบุ device:

```bash
flutter run -d <device-id>
```

---

# Architecture

โปรเจกต์ใช้ lightweight Clean Architecture โดยรักษา boundary ที่สำคัญ แต่ยังไม่สร้าง Use Case class แยกสำหรับทุก operation

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
Dio / Hive
        ↓
TMDB / Device Storage
```

## Responsibility

### Presentation

- Flutter screens/widgets
- AsyncValue rendering
- loading/error/content states
- navigation
- localized UI
- user interactions

### Domain

- Movie entity
- Watchlist entity
- Repository contracts
- Movie load result metadata
- application-level data concepts

### Data

- TMDB JSON mapping
- REST endpoints
- cache serialization
- Hive access
- repository policy implementation

### Core

- Dio configuration
- retry interceptor
- typed failures
- responsive policy
- theme

---

# Project Structure

```text
lib/
├── app.dart
├── main.dart
│
├── core/
│   ├── errors/
│   │   └── app_failure.dart
│   ├── layout/
│   │   └── responsive_layout.dart
│   ├── network/
│   │   ├── dio_provider.dart
│   │   └── rate_limit_interceptor.dart
│   └── theme/
│       └── app_theme.dart
│
├── features/
│   ├── movies/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── mock_movies.dart
│   │   │   ├── movie_cache_local_data_source.dart
│   │   │   ├── movie_repository_impl.dart
│   │   │   └── tmdb_remote_data_source.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       └── movie_providers.dart
│   │
│   ├── watchlist/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── profile/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── home/
│   ├── search/
│   ├── movie_detail/
│   └── calendar/
│
└── shared/
    └── widgets/
```

รายละเอียด file-by-file อยู่ที่ [docs/CODE_WALKTHROUGH.md](docs/CODE_WALKTHROUGH.md)

---

# Application Startup

`main()` initialize:

```text
Flutter binding
→ EasyLocalization
→ .env
→ Hive
→ watchlist box
→ user preferences box
→ movie cache box
→ ProviderScope
→ EasyLocalization scope
→ PopcornApp
```

Hive boxes ถูกเปิดก่อน `runApp()` เพื่อให้ providers สามารถใช้งาน storage ได้ตั้งแต่ frame แรก

---

# Navigation

Main tabs ใช้ `ShellRoute`:

```text
Home
Explore
Watchlist
Profile
```

Additional routes:

```text
/calendar
/movie/:id
```

Bottom navigation derive selected index จาก current URI ไม่ได้เก็บ route index ซ้ำใน local widget state

---

# REST API

Remote data source รองรับ:

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

Movie Detail ใช้:

```text
append_to_response=credits,videos,similar
```

เพื่อดึง detail, cast, trailer และ similar movies ใน request เดียว

---

# HTTP Timeout และ Rate Limit

Dio configuration:

```text
Connect timeout: 10 seconds
Receive timeout: 12 seconds
```

`RateLimitInterceptor` ดัก HTTP 429

```text
429
 ↓
read retry count
 ↓
read Retry-After when available
 ↓
otherwise exponential delay
 ↓
retry request
```

Default delay:

```text
1s → 2s → 4s
```

Retry มี limit เพื่อป้องกัน infinite loop

---

# Typed Failure

Phase 1 เพิ่ม application-level failures:

```text
NetworkFailure
TimeoutFailure
UnauthorizedFailure
RateLimitFailure
ServerFailure
ParsingFailure
UnknownFailure
```

Presentation จึงไม่ต้องตรวจ `DioException` โดยตรง

ตัวอย่าง mapping:

```text
connection timeout → TimeoutFailure
401                → UnauthorizedFailure
429                → RateLimitFailure
500+               → ServerFailure
```

---

# Cache and Offline Policy

Movie cache ใช้ Hive `Box<Map>`

Default TTL:

```text
30 minutes
```

Flow:

```text
Read cache
   ↓
Fresh?
   ├── Yes → return fresh cache without network
   └── No
        ↓
Call TMDB
        ↓
Success?
   ├── Yes → save cache → return network result
   └── No
        ↓
Stale cache exists?
   ├── Yes → return stale cache + failure metadata
   └── No  → return mock data + failure metadata
```

Cache key รวมภาษา:

```text
trending:en-US
trending:th-TH
```

Result metadata ระบุ:

```text
network
freshCache
staleCache
mock
```

UI จึงสามารถแสดงข้อมูลเก่าพร้อม offline banner แทนการลบ content ทั้งหน้า

Force refresh ใช้สำหรับ Retry และ refresh ที่ต้อง bypass fresh cache

---

# Responsive Layout Using Screen Ratio

Phase 1 ไม่ใช้ absolute screen-width breakpoint เป็นเงื่อนไขหลัก แต่ใช้:

```text
ratio = screenWidth / screenHeight
```

Policy:

| Ratio | Class | Movie Columns |
|---:|---|---:|
| `< 0.62` | Tall Portrait | 2 |
| `0.62 – < 0.90` | Portrait | 3 |
| `0.90 – < 1.35` | Balanced | 4 |
| `>= 1.35` | Wide | 5 |

นำไปใช้กับ:

- Home padding/content composition
- Search grid
- Watchlist grid
- Watchlist statistics
- Card aspect ratio

Test ยืนยันว่า screen สองขนาดที่มี ratio เท่ากันจะเลือก layout class และ column count เดียวกัน

ข้อจำกัดของ ratio-only strategy คือ device ขนาดเล็กและขนาดใหญ่มากที่ ratio เท่ากันจะได้จำนวน columns เท่ากัน ซึ่งบันทึกไว้เป็น known limitation โดยตั้งใจให้ implementation ตรง requirement ปัจจุบัน

---

# State Management

Riverpod ใช้สำหรับ:

```text
Dependency Injection
Async State
Local Persistent State
Controller State
Provider Overrides in Tests
```

Movie flow:

```text
dioProvider
→ remote data source
→ cache data source
→ repository
→ movie providers
→ UI
```

Watchlist flow:

```text
Hive data source
→ WatchlistController
→ Home / Watchlist UI
```

Profile flow:

```text
Hive preferences source
→ ProfileController
→ Profile / Settings UI
```

---

# Local Storage

Hive boxes:

```text
watchlist_items
user_preferences
movie_cache
```

## Watchlist

เก็บ map จาก `WatchlistItem.toMap()`

## User Preferences

เก็บ record key `current`

## Movie Cache

เก็บ:

```text
cachedAt
items[]
```

การใช้ map ลด code generation สำหรับ demo แต่ production schema migration ต้องวางแผนเพิ่ม

---

# Localization

Single source of truth:

```text
assets/langs/langs.csv
```

รูปแบบ:

```csv
key,en,th
```

Usage:

```dart
'searchHint'.tr()
```

Named argument:

```dart
'welcome'.tr(namedArgs: {'name': name})
```

TMDB language mapping:

```text
en → en-US
th → th-TH
```

Localization test ตรวจ:

- file exists
- header
- column count
- blank values
- duplicate keys
- LF/CRLF normalization

---

# Testing Strategy

## Unit Tests

ครอบคลุม:

- Movie JSON mapping
- Missing-field normalization
- Repository remote success
- Repository fallback
- Cache serialization
- Cache freshness
- Cache policy
- Typed failure mapping
- Ratio policy
- Watchlist serialization
- Profile serialization
- Riverpod controllers

## Widget Tests

ครอบคลุม:

- ClayCard
- Poster fallback
- Profile page
- Home stale/offline state
- Retry UI
- Watchlist ratio-responsive grid

## Golden Tests

ตรวจ visual regression ของ Cinematic Dark components

```bash
make golden-update
make golden
```

## Integration Tests

### Watchlist Flow

```text
Movie Detail
→ Add to Watchlist
→ Save
→ Open Watchlist
→ Verify persisted item
```

### Profile and Language Flow

```text
Open Profile
→ Edit profile
→ Save
→ Switch to Thai
→ Verify state and localized UI
```

Run:

```bash
flutter devices
make integration DEVICE=<device-id>
```

---

# Makefile

ดู commands:

```bash
make help
```

Available targets:

```bash
make get
make clean
make format
make format-check
make analyze
make test
make test-unit
make test-widget
make golden
make golden-update
make integration DEVICE=<id>
make coverage
make check
make ci
```

Formatter ครอบคลุม:

```text
lib/
test/
integration_test/
```

ก่อน commit:

```bash
make format
make check
```

Full validation:

```bash
make format
make check
make golden
make integration DEVICE=<device-id>
```

`format-check` จะ exit code 1 เมื่อพบไฟล์ที่ยังไม่ได้ format ซึ่งเป็น expected behavior ให้รัน `make format` ก่อน

---

# GitHub Actions CI

Workflow:

```text
.github/workflows/flutter_ci.yml
```

Trigger:

```text
push to main
pull request to main
```

Pipeline:

```text
Checkout
→ Setup Flutter stable
→ Prepare empty assets/.env
→ flutter pub get
→ dart format check
→ flutter analyze
→ flutter test --coverage
→ upload coverage artifact
```

CI ไม่ใช้ real TMDB token และ tests ไม่ควรเรียก external service จริง

---

# Recommended Local Validation

```bash
git checkout feat/production-phase-1
git pull

make get
make format
make check
```

Golden:

```bash
make golden-update
# review generated PNG
make golden
```

Integration:

```bash
flutter devices
make integration DEVICE=<device-id>
```

Manual scenarios:

1. เปิด Home พร้อม network
2. ปิด network หลังมี cache แล้วตรวจ stale banner
3. ล้าง cacheและปิด network แล้วตรวจ mock notice
4. กด Retry แล้วตรวจ force refresh
5. เปลี่ยนภาษา EN/TH
6. restart app แล้วตรวจ preference persistence
7. เพิ่มหนังลง Watchlist
8. restart app แล้วตรวจ Watchlist persistence
9. หมุน portrait/landscape แล้วตรวจ ratio-based grid

---

# Documentation

- [Code Walkthrough](docs/CODE_WALKTHROUGH.md) — อธิบาย source แบบ file-by-file และ end-to-end flow
- [Production Phase 1](docs/PRODUCTION_PHASE_1.md) — ขอบเขต cache, failures, responsive, integration tests และ CI
- [Testing Guide](docs/TESTING.md) — วิธีรันและดูแล tests/goldens
- [Profile & Settings](docs/PROFILE_SETTINGS.md) — โครงสร้าง Profile/Settings

---

# Known Limitations

- ยังไม่มี login/authentication/refresh token
- ยังไม่มี secure token storage
- Search ยังไม่มี debounce/cancellation/latest-request-wins
- ยังไม่มี connectivity stream
- ยังไม่มี pagination
- ยังไม่มี crash reporting
- ยังไม่มี app lifecycle handling สำหรับ video
- Notification preference ยังไม่ schedule native notifications
- Autoplay preference ยังไม่ควบคุม player จริง
- Home Watch Stats ยังเป็น static demo data
- Ratio-only responsive policy ไม่พิจารณา minimum card extent
- CI ยังไม่รัน integration tests
- CI ยังไม่รัน golden tests
- ยังไม่มี build flavors
- ยังไม่มี signing/release pipeline
- ยังไม่มี coverage threshold

---

# Portfolio Relevance

Repo นี้ใช้แสดงประสบการณ์ในหัวข้อต่อไปนี้ได้:

- Flutter UI Development
- Riverpod State Management
- GoRouter Navigation
- REST API / JSON Mapping
- Dio Timeout / 429 Retry
- Repository Pattern
- Clean Architecture แบบ lightweight
- Hive Local Storage
- Cache / Stale Fallback
- Typed Error Handling
- Runtime Localization
- Ratio-based Responsive UI
- Unit / Widget / Golden / Integration Tests
- Git / Branch / Pull Request workflow
- GitHub Actions CI
- Technical Documentation

---

# Summary Data Flow

## Remote Movie Data

```text
UI
 ↓
Riverpod
 ↓
MovieRepository
 ↓
Cache check
 ↓
TMDB Remote Data Source
 ↓
Dio + Retry Interceptor
 ↓
TMDB
 ↓
Movie JSON Mapper
 ↓
Hive Cache
 ↓
MovieLoadResult
 ↓
UI with source/failure metadata
```

## Watchlist

```text
Movie Detail
 ↓
WatchlistController
 ↓
WatchlistLocalDataSource
 ↓
Hive
 ↓
Home / Watchlist rebuild
```

## Profile

```text
Profile UI
 ↓
ProfileController
 ↓
UserPreferencesLocalDataSource
 ↓
Hive
 ↓
State and locale update
```

Phase 1 ทำให้โปรเจกต์ขยับจาก UI/API demo ไปเป็น portfolio project ที่แสดง production concerns ได้ชัดขึ้น โดยเฉพาะ cache policy, stale-data UX, typed failure, automated testing และ CI
