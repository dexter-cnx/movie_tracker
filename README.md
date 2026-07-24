# Popcorn - Movie Tracker & Watchlist

**Popcorn - Movie Tracker & Watchlist** เป็น Flutter demo application สำหรับค้นหาและสำรวจภาพยนตร์ ดูรายละเอียดหนัง จัดการ Watchlist / Watched / Favorite และบันทึกข้อมูลส่วนตัวของผู้ใช้ไว้ในเครื่องด้วย Hive

แอปใช้ **TMDB API v3** เป็นแหล่งข้อมูลหลัก และมี **mock data fallback 10 เรื่อง** เพื่อให้ demo UI และ core flow ยังใช้งานได้เมื่อ TMDB ไม่พร้อมใช้งานหรือยังไม่ได้ตั้งค่า Bearer Token

Design ปัจจุบันเป็นแนว **Cinematic Dark Minimal UI** เน้น poster/backdrop ขนาดใหญ่ dark surface, rounded card, white pill action และ accent สีส้ม

---

## Quick Review Path

สำหรับ reviewer ที่ต้องการดูโปรเจกต์อย่างรวดเร็ว แนะนำลำดับนี้:

1. Setup และ Run จากหัวข้อด้านล่าง
2. อ่าน [Code Walkthrough](docs/CODE_WALKTHROUGH.md)
3. อ่าน [Testing Guide](docs/TESTING.md)
4. ดู `lib/features/movies/` สำหรับ data/domain/presentation flow
5. ดู `lib/features/watchlist/` สำหรับ Hive + Riverpod local state
6. รัน `make check`
7. สร้าง Golden baseline ด้วย `make golden-update`

---

## Tech Stack

- **Framework:** Flutter
- **State Management / DI:** Riverpod
- **Architecture:** Lightweight Clean Architecture + MVVM-style presentation
- **HTTP Client:** Dio
- **Rate Limit Handling:** Custom `RateLimitInterceptor` สำหรับ HTTP 429
- **Local Storage:** Hive
- **Charts:** fl_chart
- **Localization:** easy_localization
- **Localization Source of Truth:** `assets/langs/langs.csv`
- **Environment:** flutter_dotenv
- **Navigation:** go_router
- **Remote API:** TMDB API v3

---

# Setup

## 1. Clone repository

```bash
git clone https://github.com/dexter-cnx/movie_tracker.git
cd movie_tracker
```

สำหรับ branch ที่มี comprehensive tests และ Makefile:

```bash
git checkout test/comprehensive-suite
```

## 2. Install dependencies

```bash
flutter pub get
```

หรือ:

```bash
make get
```

---

# Environment Configuration

แอปอ่าน TMDB API Read Access Token ผ่าน `flutter_dotenv`

## 1. สร้างไฟล์ `.env`

สร้างไฟล์:

```text
assets/.env
```

## 2. เพิ่ม TMDB Bearer Token

```env
TMDB_BEARER_TOKEN=your_tmdb_api_read_access_token
```

ใช้ค่า **API Read Access Token** จาก TMDB ไม่ใช่ API Key แบบสั้น

ตัวอย่างรูปแบบ:

```env
TMDB_BEARER_TOKEN=eyJhbGciOiJIUzI1NiJ9...
```

## 3. ตรวจ `pubspec.yaml`

ไฟล์ env และ localization ต้องถูกประกาศเป็น asset:

```yaml
flutter:
  assets:
    - assets/langs/
    - assets/.env
```

## 4. การโหลด env

`lib/main.dart` โหลดไฟล์ก่อน `runApp()`:

```dart
await dotenv.load(fileName: 'assets/.env');
```

Network layer อ่าน token จาก:

```dart
dotenv.env['TMDB_BEARER_TOKEN']
```

แล้วเพิ่ม header:

```http
Authorization: Bearer <token>
```

## 5. เมื่อไม่มี Token

สำหรับ demo นี้ หาก token ไม่มีหรือ remote request fail, `MovieRepositoryImpl` จะ fallback ไปใช้ built-in mock data เพื่อให้ UI ยังเปิดและทดสอบ flow ได้

## Security

ไม่ควร commit production token ลง public repository

แนะนำให้ ignore:

```gitignore
assets/.env
```

และเก็บ template แยกเป็น:

```text
assets/.env.example
```

เช่น:

```env
TMDB_BEARER_TOKEN=your_tmdb_api_read_access_token
```

---

# Run

```bash
flutter run
```

หรือเลือก device ก่อน:

```bash
flutter devices
flutter run -d <device-id>
```

---

# Architecture

โปรเจกต์ใช้ **Clean Architecture แบบ lightweight** โดยแยก movie feature เป็น `data / domain / presentation` และใช้ Riverpod เป็นทั้ง dependency composition และ state exposure

```text
UI / Presentation
      ↓
Riverpod Provider / Controller
      ↓
Repository Interface
      ↓
Repository Implementation
      ↓
Remote / Local Data Source
      ↓
TMDB API / Hive
```

โครงสร้างนี้เป็น pragmatic architecture สำหรับขนาด demo app ปัจจุบัน จึงยังไม่ได้สร้าง Use Case class สำหรับทุก operation โดย presentation/provider สามารถเรียก repository abstraction โดยตรง

## Project Structure

```text
lib/
├── core/
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
│   │   │   ├── movie_repository_impl.dart
│   │   │   ├── tmdb_remote_data_source.dart
│   │   │   └── mock_movies.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       └── movie_providers.dart
│   │
│   ├── home/
│   ├── movie_detail/
│   ├── search/
│   ├── calendar/
│   └── watchlist/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/
│   └── widgets/
│
├── app.dart
└── main.dart
```

รายละเอียด flow แบบ file-by-file ดูที่ [docs/CODE_WALKTHROUGH.md](docs/CODE_WALKTHROUGH.md)

---

# Core Features

## Home Dashboard

- Welcome header
- Search entry UI
- Watch Stats chart ด้วย `fl_chart`
- Trending Movies จาก TMDB / mock fallback
- Watchlist preview จาก Hive
- Navigation ไป Movie Detail และ Watchlist

> Watch Stats ปัจจุบันยังเป็น static demo data ยังไม่ได้ aggregate จาก watch history จริง

## Movie Detail

- Backdrop
- Title / Rating / Release Year / Runtime
- Genre chips
- Rating Distribution chart
- Budget / Revenue / Vote Count / Original Language
- Overview
- Cast
- YouTube Trailer
- Watchlist actions
- Similar Movies

Movie detail request ใช้:

```text
append_to_response=credits,videos,similar
```

## Watchlist / My List

ข้อมูลถูกเก็บใน Hive ด้วย `WatchlistItem`

รองรับ status:

- Want to Watch
- Watched
- Favorite

ข้อมูลเพิ่มเติม:

- Personal Rating
- Notes
- Watched Date
- Runtime
- Genre

สถิติที่หน้า Watchlist คำนวณ:

- Total Movies Watched
- Total Hours
- Average Rating
- Favorite Genre

## Search & Discover

- Search movie
- Genre filters
- Trending
- Top Rated
- Upcoming
- Now Playing
- Movie Roulette

## Release Calendar

นำเสนอ upcoming content ในรูปแบบ timeline / calendar-inspired screen

---

# Network Layer

`dioProvider` สร้าง Dio instance กลางด้วย:

```text
Base URL: https://api.themoviedb.org/3
Connect timeout: 10s
Receive timeout: 12s
```

`RateLimitInterceptor` ดัก HTTP `429 Too Many Requests`

Flow:

```text
429
 ↓
อ่าน retryCount
 ↓
ตรวจ maxRetries
 ↓
อ่าน Retry-After ถ้ามี
 ↓
ถ้าไม่มี ใช้ exponential delay
 ↓
retry request
```

Default delay โดยประมาณ:

```text
1s → 2s → 4s
```

---

# Mock Data Fallback

`MovieRepositoryImpl` เป็น policy boundary ระหว่าง remote data และ fallback

```text
Repository call
    ↓
TMDB Remote Data Source
    ↓ success
TMDB result
```

เมื่อเกิด exception:

```text
TMDB error
    ↓
MovieRepositoryImpl._fallback()
    ↓
Mock Movies
    ↓
UI
```

ข้อดีคือ demo ยังใช้งานได้เมื่อไม่มี token หรือ network มีปัญหา

สำหรับ production ควรแยก error category เช่น authentication, network, timeout และ parsing error แทนการ fallback ทุก exception แบบเดียวกัน

---

# Local Storage

Hive ใช้เก็บข้อมูล Watchlist แบบ persistent local storage

```text
MovieDetailPage
      ↓
WatchlistController
      ↓
WatchlistLocalDataSource
      ↓
Hive Box<Map>
```

ข้อมูลเก็บเป็น JSON-compatible map ผ่าน `WatchlistItem.toMap()` / `fromMap()` เพื่อลด generated adapter overhead สำหรับ demo

หลัง `save()` หรือ `delete()` controller จะโหลด `getAll()` ใหม่และ update Riverpod state ทำให้หน้า Home และ Watchlist rebuild ตามข้อมูลล่าสุด

---

# Localization

Source of truth:

```text
assets/langs/langs.csv
```

รูปแบบ:

```csv
key,en,th
welcome,Welcome {name},ยินดีต้อนรับ {name}
searchHint,"Search movie, actor, genre...",ค้นหาหนัง นักแสดง แนวหนัง...
```

UI ใช้ `.tr()` เช่น:

```dart
'searchHint'.tr()
```

TMDB locale mapping:

```text
en → en-US
th → th-TH
```

มี localization validation test ตรวจ:

- CSV file exists
- Header ถูกต้อง
- จำนวน columns ถูกต้อง
- ไม่มี blank value
- ไม่มี duplicate key
- รองรับ LF / CRLF line ending

---

# Testing

Test suite ครอบคลุมหลายระดับ

## Unit / Model Tests

- `MovieModel` JSON mapping
- default / normalization behavior
- `WatchlistItem` serialization
- language mapping และ provider arguments

## Repository Tests

- Remote success path
- Mock fallback path
- Search / Genre / Detail fallback policy

## Network Tests

- Non-429 pass-through
- 429 retry success
- Retry limit

## Persistence Tests

- Hive data source `getAll()` sorting
- `save()`
- `delete()`

## Riverpod Controller Tests

- Initial state
- Save refreshes state
- Delete refreshes state

## Localization Tests

- CSV schema validation
- Blank rows / values
- Duplicate key protection
- Cross-platform line ending normalization

## Widget Tests

- Shared `ClayCard`
- `Poster` fallback behavior

## Golden Tests

Golden tests ใช้ตรวจ visual regression ของ Cinematic Dark UI components

สร้าง/update baseline:

```bash
make golden-update
```

จากนั้น commit generated PNG และตรวจ baseline ด้วย:

```bash
make golden
```

Golden test ไม่ได้รวมใน default test run จนกว่าจะเปิด `RUN_GOLDENS=true`

ดูรายละเอียดที่ [docs/TESTING.md](docs/TESTING.md)

---

# Makefile

ดูรายการคำสั่ง:

```bash
make help
```

คำสั่งหลัก:

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
make coverage
make check
make ci
```

Workflow แนะนำก่อน commit:

```bash
make format
make check
```

`make check` ทำตามลำดับ:

```text
format-check
   ↓
analyze
   ↓
test
```

หมายเหตุ: `format-check` ตั้งใจ fail เมื่อพบไฟล์ที่ยังไม่ได้ format ดังนั้นให้รัน `make format` ก่อนเมื่อ formatter แจ้ง `Changed ...`

---

# Recommended Validation

ก่อน merge หรือ release:

```bash
make format
make check
make golden
```

สำหรับ coverage:

```bash
make coverage
```

---

# Known Limitations / Technical Debt

- `AppTheme.light` ใช้ `Brightness.dark` จริง ชื่อควรถูกปรับในอนาคต
- Home Watch Stats ยังเป็น static demo data
- Search ยังไม่มี debounce / cancellation / latest-request-wins
- Repository fallback จับ exception ทุกประเภทเหมือนกัน
- Cast UI ยังไม่ได้ใช้ `profilePath` แม้ model รองรับ
- Similar Movies ยังไม่มี tap navigation ไป detail
- Watchlist statistics ยัง derive ใน widget
- Watchlist เป็น local-only ยังไม่มี authentication หรือ cloud sync
- Golden baseline ต้อง generate และ commit จาก Flutter environment จริง

---

# Documentation

- [Code Walkthrough](docs/CODE_WALKTHROUGH.md) — อธิบาย source flow แบบ file-by-file พร้อมเหตุผลของแต่ละ layer
- [Testing Guide](docs/TESTING.md) — วิธีรัน unit/widget/golden tests และ Makefile workflow

---

# Summary

Popcorn แยก network, repository policy, domain model, Riverpod state และ Hive persistence ออกจากกันในระดับที่เหมาะกับ demo application ปัจจุบัน

Flow หลักของ remote data คือ:

```text
UI
 ↓
Riverpod
 ↓
MovieRepository
 ↓
TmdbRemoteDataSource
 ↓
Dio + RateLimitInterceptor
 ↓
TMDB
```

ส่วน local watchlist คือ:

```text
UI
 ↓
WatchlistController
 ↓
WatchlistLocalDataSource
 ↓
Hive
```

Test suite และ Makefile ถูกเพิ่มเพื่อให้ตรวจ behavior, persistence, network retry, localization structure, widgets และ visual regression ได้เป็นระบบมากขึ้น
