# Production Readiness Phase 2 & 3

เอกสารนี้อธิบายงานที่เพิ่มต่อจาก Phase 1 เพื่อให้ Popcorn แสดงความสามารถที่พบใน Flutter production project ได้ชัดขึ้น ทั้ง Authentication, Secure Token Storage, Concurrent Refresh Protection, Connectivity Stream, Lifecycle Handling, Structured Logging, Crash Reporting Abstraction, Search Debounce, Latest-Request-Wins, Pagination, Build Environments, Performance Review, Product Requirements, Acceptance Criteria, Code Review และ Coverage Gate

---

## Phase 2 — Production Runtime Concerns

### 1. Authentication Architecture

เพิ่มโครงสร้าง:

```text
lib/features/auth/
├── data/
│   ├── auth_local_data_source.dart
│   ├── auth_remote_data_source.dart
│   └── auth_repository_impl.dart
├── domain/
│   ├── auth_repository.dart
│   └── auth_session.dart
└── presentation/
    ├── auth_controller.dart
    └── login_page.dart
```

#### AuthSession

`AuthSession` เก็บ:

```text
userId
accessToken
refreshToken
expiresAt
```

และมี `isExpired(now)` เพื่อแยก time policy ออกจาก UI

#### Secure Storage

`SecureAuthLocalDataSource` ใช้ `flutter_secure_storage` ไม่ใช้ Hive หรือ SharedPreferences สำหรับ token

เหตุผล:

- token เป็น credential ไม่ใช่ preference ทั่วไป
- Android ใช้ encrypted storage ตาม implementation ของ plugin
- iOS ใช้ Keychain
- logout สามารถลบ key เฉพาะกลุ่ม auth

#### Demo Auth API

`DemoAuthRemoteDataSource` จำลอง login และ refresh อย่าง deterministic เพื่อให้ reviewer ทดสอบ flow ได้โดยไม่ต้องมี backend จริง

ข้อจำกัดสำคัญ:

- ไม่ใช่ production identity provider
- token เป็น demo string
- ไม่ควรตีความว่าเป็น security implementation ของ backend
- จุดประสงค์คือแสดง mobile-side session architecture

### 2. Synchronized Token Refresh

`AuthRepositoryImpl` ใช้ `_refreshInFlight` เพื่อป้องกันหลาย request เรียก refresh พร้อมกัน

```text
Request A พบ token หมดอายุ ─┐
Request B พบ token หมดอายุ ─┼─> ใช้ Future refresh เดียวกัน
Request C พบ token หมดอายุ ─┘
```

Flow:

```text
validSession()
    ↓
มี session หรือไม่
    ├── ไม่มี → MissingSessionException
    └── มี
         ↓
หมดอายุหรือไม่
    ├── ไม่หมด → คืน session เดิม
    └── หมด
         ↓
มี refresh in-flight หรือไม่
    ├── มี → await Future เดิม
    └── ไม่มี → เริ่ม refresh และบันทึก Future
```

เมื่อ refresh สำเร็จ:

1. สร้าง normalized session
2. รักษา userId เดิม
3. update memory session
4. persist ลง Secure Storage
5. clear `_refreshInFlight`

เมื่อ refresh token ถูกปฏิเสธระหว่าง restore:

1. clear local token
2. return unauthenticated state
3. ไม่ปล่อย invalid session ให้ UI ใช้งานต่อ

### 3. Riverpod Auth Controller

`AuthController` เป็น `AsyncNotifier<AuthSession?>`

State meanings:

```text
AsyncLoading     = restore/login กำลังทำงาน
AsyncData(null)  = ยังไม่เข้าสู่ระบบ
AsyncData(value) = authenticated
AsyncError       = login/session operation ล้มเหลว
```

Operation:

- restore session ตอน provider ถูกสร้าง
- login
- logout
- ensure valid session

### 4. Connectivity Stream

เพิ่ม:

```text
lib/core/connectivity/connectivity_service.dart
```

Expose:

```dart
Stream<NetworkStatus> get changes;
Future<NetworkStatus> current();
```

Riverpod provider:

```text
connectivityServiceProvider
networkStatusProvider
```

ข้อสำคัญ:

Connectivity status บอกเพียงว่ามี network transport หรือไม่ ไม่ได้ยืนยันว่า TMDB หรือ Internet ปลายทางใช้งานได้จริง ดังนั้น repository ยังต้องจัดการ timeout/network error ตามเดิม

แนวทาง UI:

- offline → แสดง banner โดยไม่ล้างข้อมูลเดิม
- online restored → invalidate/refresh provider ที่เหมาะสม
- ไม่ reload ทุก screen โดยไม่มีเงื่อนไข

### 5. Application Lifecycle

เพิ่ม `AppLifecycleObserver`

รองรับ callback:

```text
onResumed
onPaused
```

Use cases:

- pause trailer เมื่อ app inactive/background
- refresh token หรือ stale data เมื่อกลับ foreground
- flush draft/preference ก่อนหยุดใช้งาน
- ป้องกัน media resource ทำงานต่อใน background

Lifecycle concern ถูกแยกเป็น reusable widget แทนการใส่ `WidgetsBindingObserver` ซ้ำในหลายหน้า

### 6. Structured Logging

เพิ่ม `AppLogger` abstraction และ `DeveloperAppLogger`

ระดับ log:

```text
DEBUG
INFO
WARNING
ERROR
```

Context ถูก redact สำหรับ key สำคัญ:

```text
authorization
token
accessToken
refreshToken
password
email
```

เป้าหมายคือไม่ให้ token หรือ PII หลุดเข้า console/crash report โดยไม่ตั้งใจ

### 7. Crash Reporting Abstraction

เพิ่ม `CrashReporter` และ `LoggingCrashReporter`

`main.dart` ติดตั้ง:

```text
FlutterError.onError
PlatformDispatcher.instance.onError
```

แยก framework error และ uncaught platform error

ใน production สามารถแทน `LoggingCrashReporter` ด้วย Firebase Crashlytics หรือ Sentry implementation โดยไม่เปลี่ยน application bootstrap contract

---

## Phase 3 — Portfolio Engineering Depth

### 8. Search Debounce และ Latest-Request-Wins

เพิ่ม:

```text
lib/core/async/debounced_latest_task.dart
```

ปัญหาที่แก้:

```text
ผู้ใช้พิมพ์ d
ผู้ใช้พิมพ์ du
ผู้ใช้พิมพ์ dune
```

ถ้าส่งทุก request ทันที อาจเกิด:

```text
request dune เสร็จก่อน
request d เสร็จทีหลัง
ผล d ทับผล dune
```

`DebouncedLatestTask` ใช้:

- Timer สำหรับ debounce
- generation number สำหรับ latest-request-wins
- dispose/cancel lifecycle

แม้ upstream request ยกเลิก transport ไม่ได้ทันที ผลเก่าจะไม่ถูก publish กลับ UI

การยกเลิกที่ network transport layer สามารถเพิ่ม Dio `CancelToken` ภายใน operation โดยไม่เปลี่ยน coordinator

### 9. Pagination

เพิ่ม:

```text
PagedMovies
TmdbRemoteDataSource.searchPage()
MovieRepository.searchPage()
```

`PagedMovies` เก็บ:

```text
items
page
totalPages
hasMore
```

และ `append(next)` รวมข้อมูลหน้าเดิมกับหน้าถัดไป

Repository fallback ใช้ mock result หน้าเดียวเมื่อ TMDB ล้มเหลว เพื่อรักษา deterministic demo behavior

UI iteration ถัดไปสามารถสร้าง pagination controller ที่มี state:

```text
items
currentPage
hasMore
isInitialLoading
isLoadingMore
failure
query
```

### 10. Coverage Gate

Makefile เพิ่ม:

```bash
make coverage-check
```

ค่า default:

```text
COVERAGE_MIN=55
```

override ได้:

```bash
make coverage-check COVERAGE_MIN=70
```

Coverage threshold เป็น baseline ไม่ใช่เป้าหมายสุดท้าย ควรเพิ่มทีละขั้นเมื่อ critical paths มี test ครบขึ้น

### 11. Build Environments

แนวทาง environment:

```text
development
staging
production
```

แต่ละ environment ควรแยก:

- app display name
- application id / bundle id suffix
- API base URL
- logging verbosity
- crash reporting
- mock fallback policy
- release signing

รายละเอียดอยู่ใน `docs/BUILD_AND_RELEASE.md`

### 12. Product and QA Documentation

เพิ่มเอกสาร:

```text
docs/PRODUCT_REQUIREMENTS.md
docs/USER_FLOWS.md
docs/ACCEPTANCE_CRITERIA.md
docs/PERFORMANCE_AND_DIAGNOSTICS.md
docs/CODE_REVIEW_CHECKLIST.md
```

Acceptance Criteria ใช้ ID เพื่อเชื่อม requirement กับ test เช่น:

```text
AC-AUTH-001
AC-CACHE-001
AC-WATCHLIST-001
AC-LOCALE-001
```

### 13. Pull Request Standard

เพิ่ม `.github/pull_request_template.md`

Checklist ครอบคลุม:

- requirement/AC
- screenshots
- tests
- lifecycle
- logging/privacy
- cache/migration
- release impact
- known risk

---

## Test Coverage ที่เพิ่ม

### Auth Repository

- valid session restore
- expired session refresh
- concurrent refresh deduplication
- refresh rejection clears storage

### Debounced Latest Task

- rapid requests publish newest result
- old in-flight result cannot overwrite new result

### Existing Phase 1 Tests

ยังคงครอบคลุม:

- cache policy
- typed failures
- responsive ratio
- watchlist persistence
- profile settings
- widget tests
- integration tests
- golden tests

---

## Validation Commands

```bash
flutter pub get
make format
make check
make coverage-check
```

Integration:

```bash
flutter devices
make integration DEVICE=<device-id>
```

Golden:

```bash
make golden
```

Release preparation:

```bash
flutter build appbundle --release
flutter build ipa --release
```

คำสั่ง release จริงต้องทำหลังตั้ง signing และ environment ตาม `docs/BUILD_AND_RELEASE.md`

---

## Known Limitations

1. Demo authentication ไม่ได้เชื่อม backend จริง
2. ยังไม่มี OAuth/OIDC provider
3. Connectivity status ไม่รับประกัน Internet reachability
4. Search coordinator มี latest-request-wins แต่ Search UI เดิมยังต้อง refactor ให้ใช้งานเต็มรูปแบบ
5. Pagination contract/data source พร้อมแล้ว แต่ infinite-scroll controller/UI ยังเป็น iteration ต่อไป
6. Crash reporter ปัจจุบัน log ใน local developer console
7. Native flavor และ signing ต้องตั้งใน Android Studio/Xcode environment จริง
8. Coverage threshold เริ่มที่ 55% เพื่อไม่ให้ CI ถูกล็อกด้วย legacy/demo UI ที่ยัง test ไม่ครบ

ข้อจำกัดเหล่านี้ถูกระบุโดยตั้งใจเพื่อไม่อ้างว่า demo implementation เป็น production backend/security/release system ที่สมบูรณ์
