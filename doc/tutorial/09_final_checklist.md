# 09 — Checklist จากศูนย์ถึงสถานะปัจจุบัน

ไฟล์นี้ใช้เป็น roadmap/checklist สำหรับสร้างโปรเจกต์ใหม่ตาม tutorial โดยไม่หลุดลำดับ และใช้ตรวจว่าของที่ทำสอดคล้องกับ Popcorn Movie Tracker ปัจจุบันหรือยัง

## Phase 0 — Project Foundation

- [ ] `flutter create popcorn_movie_tracker`
- [ ] ตั้ง Dart SDK constraint
- [ ] เพิ่ม dependencies หลัก
- [ ] สร้าง `core/`, `features/`, `shared/`
- [ ] เพิ่ม `ProviderScope`
- [ ] เพิ่ม `.env` policy
- [ ] เพิ่ม Makefile
- [ ] `flutter analyze` ผ่าน
- [ ] `flutter test` ผ่าน

## Phase 1 — UI Foundation

- [ ] Material 3 theme
- [ ] design tokens กลาง
- [ ] `ClayCard`
- [ ] `ClayIconButton`
- [ ] `AppShell`
- [ ] Home
- [ ] Explore/Search
- [ ] Watchlist
- [ ] Profile
- [ ] Movie Detail route
- [ ] GoRouter + ShellRoute
- [ ] SafeArea / overflow handling

## Phase 2 — Localization

- [ ] Easy Localization
- [ ] CSV source of truth
- [ ] ภาษาอังกฤษ
- [ ] ภาษาไทย
- [ ] named arguments เช่น `{name}`
- [ ] API language mapping `en-US` / `th-TH`
- [ ] localization test helper

## Phase 3 — Domain Layer

- [ ] `Movie`
- [ ] `Genre`
- [ ] `CastMember`
- [ ] `PagedMovies`
- [ ] Repository contract
- [ ] Domain ไม่มี import Dio/Hive/Flutter UI

## Phase 4 — Network

- [ ] Dio provider
- [ ] TMDB Base URL
- [ ] Bearer token
- [ ] timeout
- [ ] logging/redaction
- [ ] rate-limit interceptor
- [ ] typed failures

## Phase 5 — Retrofit + Freezed

- [ ] `TmdbApiClient`
- [ ] Retrofit endpoints
- [ ] `TmdbMovieDto`
- [ ] `TmdbMoviePageDto`
- [ ] Genre DTO
- [ ] Credits/Cast DTO
- [ ] Videos DTO
- [ ] Similar movies DTO
- [ ] `toDomain()` mapping
- [ ] `build_runner`
- [ ] `make codegen`
- [ ] CI codegen step
- [ ] DTO mapping tests

## Phase 6 — Remote Data Source

- [ ] popular
- [ ] trending
- [ ] top rated
- [ ] upcoming
- [ ] now playing
- [ ] movie detail
- [ ] genres
- [ ] discover
- [ ] search
- [ ] search pagination
- [ ] `append_to_response=credits,videos,similar`

## Phase 7 — Cache / Offline

- [ ] Hive init
- [ ] movie cache box
- [ ] cache timestamp
- [ ] TTL/freshness
- [ ] fresh cache path
- [ ] network path
- [ ] stale cache fallback
- [ ] fallback policy ตาม environment
- [ ] offline banner
- [ ] pull-to-refresh bypass cache
- [ ] cache key แยกภาษา

## Phase 8 — State Management

- [ ] repository provider
- [ ] trending provider
- [ ] profile controller
- [ ] watchlist controller
- [ ] search controller
- [ ] state immutable/update ชัดเจน
- [ ] dependency override สำหรับ test

## Phase 9 — Search Quality

- [ ] search-as-you-type
- [ ] debounce
- [ ] latest-request-wins
- [ ] superseded Future complete
- [ ] cancel/dispose
- [ ] pagination
- [ ] load-more guard
- [ ] load-more retry
- [ ] preserve old results on next-page failure
- [ ] empty state
- [ ] loading state
- [ ] error state

## Phase 10 — Authentication

- [ ] `AuthSession`
- [ ] auth repository
- [ ] remote auth source
- [ ] secure local source
- [ ] access token
- [ ] refresh token
- [ ] expiry
- [ ] restore session
- [ ] one in-flight refresh
- [ ] logout invalidates pending refresh
- [ ] Login route reachable from normal navigation

## Phase 11 — Profile / Settings

- [ ] display name
- [ ] email
- [ ] favorite genre
- [ ] language
- [ ] notifications
- [ ] autoplay trailer
- [ ] normalize invalid stored values
- [ ] persistence
- [ ] runtime app version จาก `package_info_plus`

## Phase 12 — Image / Media

- [ ] `AppImage`
- [ ] network cache
- [ ] placeholder
- [ ] error fallback
- [ ] retry
- [ ] DPR-based decode dimensions
- [ ] `Poster` wrapper
- [ ] backdrop
- [ ] cast profile image
- [ ] Hero optional
- [ ] zoom optional
- [ ] lifecycle-safe trailer

## Phase 13 — Responsive UX

- [ ] phone portrait
- [ ] phone landscape
- [ ] tablet portrait
- [ ] tablet landscape
- [ ] ratio-based layout helper
- [ ] adaptive grid columns
- [ ] adaptive padding
- [ ] no bottom-nav overflow
- [ ] ellipsis long text
- [ ] semantics สำหรับ tappable cards

## Phase 14 — Testing

- [ ] domain unit tests
- [ ] DTO mapping tests
- [ ] repository/cache tests
- [ ] debounce tests
- [ ] pagination tests
- [ ] auth race-condition tests
- [ ] profile tests
- [ ] widget tests
- [ ] localization widget tests
- [ ] responsive tests
- [ ] golden tests
- [ ] integration tests

## Phase 15 — CI / Delivery

- [ ] GitHub Actions
- [ ] dependency install
- [ ] generated-source step
- [ ] format check
- [ ] analyze
- [ ] tests
- [ ] coverage
- [ ] coverage threshold
- [ ] artifact upload
- [ ] branch protection
- [ ] resolve review conversations ก่อน merge

## Phase 16 — App Identity

- [ ] App display name = `Popcorn Movie Tracker`
- [ ] Android label
- [ ] iOS bundle display name
- [ ] app icon source
- [ ] launcher icon generation
- [ ] reinstall validation บนอุปกรณ์จริง

## Final Validation

ก่อนถือว่า tutorial project อยู่ในระดับเดียวกับ baseline นี้ ให้รัน:

```bash
flutter pub get
make codegen
make format
make check
make coverage-check
make golden
```

และบน simulator/device:

```bash
flutter devices
make integration DEVICE=<device-id>
```

จากนั้นทดสอบด้วยมืออย่างน้อย:

```text
Launch → Home
Home → Movie Detail → Back
Home → Explore → Search → Pagination
Explore → Offline/Retry
Movie Detail → Watchlist
Watchlist → Responsive layouts
Profile → Language switch
Profile → Autoplay toggle
Profile → Login → Logout
Kill/relaunch → persistence/session restore
```

## Definition of Done

โปรเจกต์ไม่ควรถูกเรียกว่า “เสร็จ” เพียงเพราะ happy path เปิดได้ แต่ควรผ่าน 4 แกนนี้:

```text
Correctness
  → behavior ถูกต้องทั้ง happy/non-happy path

Maintainability
  → boundary ชัด, DTO ไม่รั่วเข้า UI, dependency เปลี่ยนได้

User Experience
  → loading/error/offline/empty/responsive ทำงานจริง

Delivery Confidence
  → codegen + format + analyze + tests + CI ทำซ้ำได้
```

นี่คือจุดที่ tutorial ตั้งใจพาไปถึง: จาก Flutter project เปล่า ไปเป็น mobile application ที่อธิบาย architecture ได้, ทดสอบได้ และพร้อมต่อยอดเป็น production system มากกว่า demo UI ธรรมดา
