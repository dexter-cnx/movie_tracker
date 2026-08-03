# Production Readiness — Phase 1

เอกสารนี้สรุปสิ่งที่เพิ่มใน Phase 1 เพื่อให้โปรเจกต์แสดงความสามารถที่ใกล้ production มากขึ้น โดยต่อยอดจาก Profile/Settings, test foundation และ Makefile ที่มีอยู่แล้ว

## Scope

Phase 1 ประกอบด้วย:

1. Profile และ Settings พร้อม local persistence
2. Integration tests สำหรับ critical user flows
3. Movie cache แบบ fresh cache → network → stale cache → mock fallback
4. Typed failure และ retry/offline UI
5. Responsive layout ที่ตัดสินจาก screen ratio
6. GitHub Actions CI

---

## Cache Policy

Trending feed ใช้ลำดับดังนี้:

```text
Fresh cache ภายใน TTL
    ↓
คืนข้อมูลทันทีโดยไม่เรียก network

Cache ไม่มีหรือหมดอายุ
    ↓
เรียก TMDB
    ↓ success
บันทึก Hive cache และคืน network data

Network failure
    ↓
มี stale cache → คืน stale cache พร้อม typed failure
ไม่มี stale cache → คืน mock data พร้อม typed failure
```

ไฟล์หลัก:

```text
lib/features/movies/data/movie_cache_local_data_source.dart
lib/features/movies/data/movie_repository_impl.dart
lib/features/movies/domain/entities/movie_load_result.dart
```

Default TTL ปัจจุบันคือ 30 นาที และสามารถ inject clock/TTL ใน test ได้

---

## Typed Failures

`lib/core/errors/app_failure.dart` map error เป็นประเภทที่ presentation เข้าใจได้:

- `NetworkFailure`
- `TimeoutFailure`
- `UnauthorizedFailure`
- `RateLimitFailure`
- `ServerFailure`
- `ParsingFailure`
- `UnknownFailure`

Home แสดง stale/mock data ต่อได้พร้อม offline notice และ Retry ส่วน Search มี blocking error card และ Retry เมื่อ operation throw error

---

## Ratio-Based Responsive Layout

โปรเจกต์ไม่ตัดสิน layout จากความกว้างอย่างเดียว แต่ใช้:

```text
ratio = screen width / screen height
```

Classification:

```text
ratio < 0.62         → tallPortrait
0.62 ถึง < 0.90     → portrait
0.90 ถึง < 1.35     → balanced
ratio >= 1.35        → wide
```

Grid columns:

```text
tallPortrait → 2
portrait     → 3
balanced     → 4
wide         → 5
```

ผลคืออุปกรณ์คนละขนาดที่มี ratio เดียวกันจะเลือก layout policy เดียวกัน ตาม requirement ของ Phase 1

ไฟล์หลัก:

```text
lib/core/layout/responsive_layout.dart
lib/features/home/presentation/home_page.dart
lib/features/search/presentation/search_page.dart
lib/features/watchlist/presentation/watchlist_page.dart
```

Tests:

```text
test/core/layout/responsive_layout_test.dart
test/widgets/watchlist_responsive_ratio_test.dart
```

---

## Integration Tests

### Profile and Language Flow

```text
Open Profile
→ Edit display name/email/favorite genre
→ Save
→ Change language to Thai
→ Verify state persistence and translated UI
```

File:

```text
integration_test/profile_settings_flow_test.dart
```

### Watchlist Flow

```text
Open deterministic Movie Detail
→ Add to Watchlist
→ Save
→ Navigate to Watchlist
→ Verify persisted movie and status
```

File:

```text
integration_test/watchlist_flow_test.dart
```

Run with:

```bash
make integration DEVICE=<device-id>
```

---

## Test Coverage Added

- Typed failure mapping
- Ratio classification and column policy
- Hive movie cache serialization
- Cache freshness
- Fresh cache bypasses network
- Expired cache refreshes network
- Network failure returns stale cache
- Missing cache returns mock fallback
- Force refresh bypasses fresh cache
- Home stale-cache UI
- Watchlist ratio-based grid
- Profile/language integration flow
- Movie detail/watchlist integration flow

---

## CI

Workflow:

```text
.github/workflows/flutter_ci.yml
```

Pull requests และ pushes เข้า `main` จะรัน:

```text
flutter pub get
dart format --set-exit-if-changed
flutter analyze
flutter test --coverage
```

Coverage artifact จะถูก upload เพื่อให้ reviewer ดาวน์โหลดตรวจได้

---

## Local Validation

```bash
make format
make check
```

รัน Integration Test บน emulator/device:

```bash
flutter devices
make integration DEVICE=<device-id>
```

Golden tests ยังคงรันแยก:

```bash
make golden
```

---

## Remaining Work After Phase 1

- Authentication และ secure token refresh
- Connectivity stream และ automatic refresh หลัง online
- Search debounce/cancellation/latest-request-wins
- App lifecycle handling สำหรับ trailer/player
- Crash reporting และ structured logging
- Build flavors, signing และ release workflow
- Cache สำหรับ endpoint อื่นนอกจาก Trending
