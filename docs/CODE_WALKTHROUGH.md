# Code Walkthrough — Popcorn Movie Tracker & Watchlist

เอกสารนี้อธิบาย source ของ branch `feat/production-phase-2-3` แบบ file-by-file และ flow-by-flow สำหรับใช้ review architecture, เตรียมสัมภาษณ์งาน และอธิบายเหตุผลเชิงวิศวกรรมของระบบ

โปรเจกต์ใช้ lightweight Clean Architecture + MVVM-style presentation โดยรักษา boundary สำคัญระหว่าง UI, Riverpod state, repository contract, data source และ storage แต่ไม่เพิ่ม Use Case class สำหรับทุก operation เพื่อหลีกเลี่ยง boilerplate ที่เกินขนาดของ portfolio application

---

# 1. System Overview

```text
Flutter UI
    ↓
Riverpod Provider / Controller
    ↓
Domain Repository Contract
    ↓
Repository Implementation
    ↓
Remote / Local Data Sources
    ↓
Dio / Hive / Secure Storage
    ↓
TMDB / Device Storage
```

ระบบแบ่งเป็น:

```text
core/
  async, config, connectivity, crash, errors,
  layout, lifecycle, logging, network, theme

features/auth/
  secure session and refresh flow

features/movies/
  TMDB, JSON mapping, cache, pagination

features/watchlist/
  persistent local collection

features/profile/
  profile and settings

features/home, search, movie_detail, calendar/
  presentation screens
```

---

# 2. Application Bootstrap

## `lib/main.dart`

ลำดับ startup:

```text
WidgetsFlutterBinding.ensureInitialized()
        ↓
Install AppLogger / CrashReporter
        ↓
FlutterError.onError
        ↓
PlatformDispatcher.instance.onError
        ↓
EasyLocalization.ensureInitialized()
        ↓
dotenv.load('assets/.env')
        ↓
Hive.initFlutter()
        ↓
Open watchlist, preferences, movie-cache boxes
        ↓
ProviderScope
        ↓
EasyLocalization
        ↓
PopcornApp
```

Global error handling แยก 2 ช่องทาง:

- `FlutterError.onError` สำหรับ framework error
- `PlatformDispatcher.instance.onError` สำหรับ uncaught asynchronous/platform error

ทั้งสองส่งเข้า `CrashReporter` abstraction แทนการผูกกับ Crashlytics/Sentry โดยตรง

---

# 3. Routing

## `lib/app.dart`

Main routes:

```text
/
/explore
/watchlist
/profile
```

Top-level routes:

```text
/login
/calendar
/movie/:id
```

Main tabs ใช้ `ShellRoute` เพื่อแชร์ `AppShell`

Login แยกเป็น top-level route เพื่อให้เปิดจาก Profile หรือ auth redirect ในอนาคตได้

Movie detail รับ `movieId` จาก path parameter และใช้ `int.tryParse` เพื่อป้องกัน parse exception

---

# 4. Environment Configuration

## `lib/core/config/app_environment.dart`

`AppEnvironment`:

```text
development
staging
production
```

`AppConfig` กำหนด policy:

```text
appName
enableVerboseLogs
enableMockFallback
```

Production config ปิด verbose log และ mock fallback โดยตั้งใจ แม้ native flavor wiring ยังต้องตั้งใน Android/iOS project

---

# 5. Structured Logging

## `lib/core/logging/app_logger.dart`

`AppLogger` มี method:

```text
debug
info
warning
error
```

`DeveloperAppLogger` ใช้ `dart:developer.log`

ก่อนเขียน context จะ redact key:

```text
authorization
token
accessToken
refreshToken
password
email
```

ตัวอย่าง:

```text
{accessToken: abc, page: 2}
        ↓
{accessToken: <redacted>, page: 2}
```

การ redact ที่ logger boundary ลดโอกาสที่ developer เผลอส่ง credential ไปยัง console/crash service

---

# 6. Crash Reporter

## `lib/core/crash/crash_reporter.dart`

`CrashReporter.record()` รับ:

```text
error
stackTrace
fatal
reason
```

`LoggingCrashReporter` เป็น default implementation สำหรับ portfolio

Production สามารถสร้าง:

```text
CrashlyticsCrashReporter
SentryCrashReporter
```

โดยไม่แก้ caller ใน bootstrap

---

# 7. Connectivity Stream

## `lib/core/connectivity/connectivity_service.dart`

Domain-facing enum:

```text
NetworkStatus.online
NetworkStatus.offline
```

Interface:

```dart
Stream<NetworkStatus> get changes;
Future<NetworkStatus> current();
```

`PluginConnectivityService` map result จาก `connectivity_plus`

Riverpod:

```text
connectivityServiceProvider
networkStatusProvider
```

`networkStatusProvider` emit current status ก่อน แล้วจึง forward stream changes

ข้อสำคัญ: online transport ไม่ได้ยืนยันว่า TMDB reachable ดังนั้น actual Dio error ยังคงเป็น source of truth ของ request success/failure

---

# 8. Application Lifecycle

## `lib/core/lifecycle/app_lifecycle_observer.dart`

Widget ใช้ `WidgetsBindingObserver`

Mapping:

```text
resumed → onResumed
inactive/hidden/paused/detached → onPaused
```

Use cases:

- pause trailer
- validate auth session เมื่อกลับ foreground
- refresh stale data
- flush local draft
- stop expensive resource ใน background

Observer ถูก remove ใน `dispose()` ป้องกัน callback หลัง widget ถูกทำลาย

---

# 9. Dio and Rate Limit

## `lib/core/network/dio_provider.dart`

Dio config:

```text
Base URL: https://api.themoviedb.org/3
Connect timeout: 10 seconds
Receive timeout: 12 seconds
```

TMDB application token อ่านจาก `.env`

## `lib/core/network/rate_limit_interceptor.dart`

429 flow:

```text
429
 ↓
read retry count
 ↓
max reached?
 ├── yes → forward error
 └── no
      ↓
Retry-After available?
 ├── yes → use server delay
 └── no  → exponential delay
      ↓
retry original RequestOptions
```

Default delay:

```text
1s → 2s → 4s
```

---

# 10. Typed Failures

## `lib/core/errors/app_failure.dart`

Failure hierarchy:

```text
NetworkFailure
TimeoutFailure
UnauthorizedFailure
RateLimitFailure
ServerFailure
ParsingFailure
UnknownFailure
```

Presentation ไม่ต้อง import Dio เพื่อแยก 401/429/timeout

Repository และ UI จึง test failure branch ด้วย application type ที่ stable กว่า plugin exception

---

# 11. Movie Domain and Mapping

## `lib/features/movies/domain/entities/movie.dart`

`Movie` เป็น domain shape ที่ UI ใช้

## `lib/features/movies/data/models/movie_model.dart`

`MovieModel.fromJson()` map external TMDB response เป็น domain entity

หน้าที่:

- normalize null/missing value
- map genres
- map cast
- select trailer
- map similar movies

Raw JSON ไม่ถูกส่งขึ้น presentation

---

# 12. TMDB Remote Data Source

## `lib/features/movies/data/tmdb_remote_data_source.dart`

รองรับ:

```text
popular
trending
top rated
upcoming
now playing
detail
search
genres
discover
search pagination
```

`searchPage()` map:

```text
results      → List<Movie>
page         → current page
total_pages  → totalPages
```

`append_to_response=credits,videos,similar` ลดจำนวน request ของ detail screen

---

# 13. Movie Cache

## `lib/features/movies/data/movie_cache_local_data_source.dart`

Cache record:

```text
cachedAt
items
```

`CachedMovieList.isFresh(ttl, now)` ทำ freshness decision แบบ inject เวลาได้ จึง test deterministic

Movie ถูก serialize เป็น Hive-compatible map ไม่ใช้ generated adapter

---

# 14. Repository Cache Policy

## `lib/features/movies/data/movie_repository_impl.dart`

Trending flow:

```text
read cache
  ↓
fresh and not forceRefresh?
  ├── yes → freshCache result
  └── no
       ↓
remote request
       ↓
success?
  ├── yes → write cache → network result
  └── no
       ↓
stale cache exists?
  ├── yes → staleCache + failure
  └── no  → mock + failure
```

`MovieLoadResult` ส่งทั้ง movies, source และ optional failure

UI จึงตัดสินใจได้ว่าควรแสดง content พร้อม notice หรือ blocking error

---

# 15. Search Debounce and Latest-Request-Wins

## `lib/core/async/debounced_latest_task.dart`

State ภายใน:

```text
Timer
_generation
_disposed
```

ทุก `run()` เพิ่ม generation

เมื่อ operation เสร็จ:

```text
generation ตรงกับ latest?
  ├── yes → publish result
  └── no  → return null / ignore stale result
```

ประโยชน์:

- ลด request ระหว่างพิมพ์
- ป้องกัน response เก่าทับ response ใหม่
- dispose/cancel ได้เมื่อ page ถูกทำลาย

Coordinator ไม่ผูกกับ Dio จึงใช้กับ repository, local search หรือ async validation ได้

---

# 16. Pagination

## `lib/features/movies/domain/entities/paged_movies.dart`

Fields:

```text
items
page
totalPages
```

Computed:

```text
hasMore = page < totalPages
```

`append(next)`:

```text
old items + next items
page = next.page
totalPages = next.totalPages
```

Repository fallback เมื่อ remote search page fail จะคืน deterministic mock result หนึ่งหน้า

Infinite-scroll controller/UI ยังเป็น known remaining work

---

# 17. Authentication Domain

## `lib/features/auth/domain/auth_session.dart`

Fields:

```text
userId
accessToken
refreshToken
expiresAt
```

`isExpired(now)` ทำให้ time logic test ได้

## `lib/features/auth/domain/auth_repository.dart`

Contract:

```text
restore
login
validSession
logout
```

---

# 18. Secure Auth Storage

## `lib/features/auth/data/auth_local_data_source.dart`

ใช้ `FlutterSecureStorage`

Keys:

```text
auth.userId
auth.accessToken
auth.refreshToken
auth.expiresAt
```

`read()` คืน null เมื่อ record ไม่ครบ เพื่อไม่สร้าง partial session

`clear()` ลบ credential ทั้งกลุ่ม

Token จึงไม่อยู่ใน Hive/SharedPreferences

---

# 19. Demo Auth API

## `lib/features/auth/data/auth_remote_data_source.dart`

`DemoAuthRemoteDataSource` มี:

```text
login
refresh
```

Login validation:

```text
email ต้องมี @
password อย่างน้อย 6 ตัวอักษร
```

Session มีอายุ 15 นาที

Refresh token ที่ไม่ขึ้นต้นด้วย demo format จะ throw `RefreshTokenExpiredException`

นี่เป็น deterministic fake เพื่อสาธิต client architecture ไม่ใช่ backend security

---

# 20. Auth Repository and Concurrent Refresh

## `lib/features/auth/data/auth_repository_impl.dart`

Memory state:

```text
_session
_refreshInFlight
```

`validSession()`:

```text
load current session
  ↓
missing?
  ├── yes → MissingSessionException
  └── no
       ↓
expired?
  ├── no → return current
  └── yes
       ↓
_refreshInFlight exists?
  ├── yes → await existing Future
  └── no  → create refresh Future
```

ทุก concurrent caller จึง share refresh call เดียว

หลัง refresh:

- preserve userId
- replace tokens/expiry
- persist secure session
- clear in-flight future

Refresh rejection ระหว่าง restore จะ logout และคืน null

---

# 21. AuthController and Login UI

## `lib/features/auth/presentation/auth_controller.dart`

เป็น `AsyncNotifier<AuthSession?>`

State:

```text
AsyncLoading
AsyncData(null)
AsyncData(session)
AsyncError
```

## `lib/features/auth/presentation/login_page.dart`

มี email/password controllers และ dispose ครบ

Login button disable ระหว่าง loading

Success → pop route

Failure → localized error

Default demo credential ถูกใส่เพื่อ reviewer ทดลอง flow ได้ทันที

---

# 22. Watchlist

Watchlist flow:

```text
MovieDetail
  ↓
WatchlistController.save()
  ↓
WatchlistLocalDataSource
  ↓
Hive
  ↓
reload state
  ↓
Home/Watchlist rebuild
```

Statistics derive จาก watched items:

- count
- total runtime / 60
- average personal rating
- favorite genre frequency

---

# 23. Profile and Localization

Profile preferences เก็บใน Hive

รองรับ:

```text
display name
email
favorite genre
language
notification preference
autoplay preference
```

Runtime language flow:

```text
select locale
  ↓
context.setLocale()
  ↓
persist languageCode
  ↓
widget tree rebuilds
```

CSV validation test ตรวจ header, column count, blank value, duplicate key และ LF/CRLF

---

# 24. Ratio-Based Responsive Layout

## `lib/core/layout/responsive_layout.dart`

ใช้:

```text
ratio = width / height
```

Policy:

| Ratio | Class | Columns |
|---:|---|---:|
| `< 0.62` | Tall Portrait | 2 |
| `0.62 – < 0.90` | Portrait | 3 |
| `0.90 – < 1.35` | Balanced | 4 |
| `>= 1.35` | Wide | 5 |

Apply กับ Home, Search, Watchlist และ statistics grid

Test ยืนยัน screen ต่างขนาดแต่ ratio เท่ากันได้ layout class เดียวกัน

---

# 25. Testing Strategy

## Unit

- JSON mapping
- cache freshness/policy
- typed failure mapping
- 429 retry
- Hive serialization
- Profile controller
- Auth restore/refresh
- concurrent refresh deduplication
- debounce/latest wins
- responsive ratio
- localization CSV

## Widget

- shared components
- profile settings
- stale/offline Home state
- responsive Watchlist grid

## Integration

- profile edit + locale switch
- detail → watchlist persistence

## Golden

- cinematic dark shared components

---

# 26. Makefile and Coverage Gate

Commands:

```bash
make format
make check
make coverage-check
make integration DEVICE=<id>
make golden
```

Coverage default:

```text
55%
```

CI fail เมื่อ line coverage ต่ำกว่า threshold

---

# 27. GitHub Actions

Pipeline:

```text
checkout
→ Flutter setup
→ create CI .env
→ pub get
→ format check
→ analyze
→ tests with coverage
→ coverage threshold
→ upload lcov
```

Integration tests ไม่รันบน generic Linux job เพราะต้องมี emulator/device configuration แยก

---

# 28. Requirements and Review Process

Documentation:

```text
PRODUCT_REQUIREMENTS.md
USER_FLOWS.md
ACCEPTANCE_CRITERIA.md
PERFORMANCE_AND_DIAGNOSTICS.md
BUILD_AND_RELEASE.md
CODE_REVIEW_CHECKLIST.md
```

PR template บังคับให้ระบุ:

- requirement/AC
- test evidence
- network/error cases
- responsive/localization
- lifecycle/performance
- release risk

---

# 29. Known Gaps

- Demo Auth ไม่ใช่ OAuth/OIDC production backend
- Search UI ยังต้อง wire `DebouncedLatestTask` เต็มรูปแบบ
- Pagination controller/infinite scroll ยังไม่เสร็จ
- Connectivity stream ยังต้องเชื่อม targeted refresh UX เพิ่ม
- Lifecycle observer ยังต้องผูกกับ YouTube controller
- Crash reporter ยังเป็น local logging implementation
- Native flavors/signing ยังต้อง configure ใน Android/iOS project

Known gaps ถูกบันทึกโดยตั้งใจเพื่อให้ reviewer แยกระหว่างสิ่งที่ implement แล้วกับ design direction ที่ยังไม่สมบูรณ์
