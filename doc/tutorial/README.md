# Tutorial: สร้าง Popcorn Movie Tracker จากศูนย์จนถึงโครงสร้างปัจจุบัน

เอกสารชุดนี้เป็นบทเรียนภาษาไทยแบบค่อยเป็นค่อยไป โดยตั้งใจให้เริ่มจาก Flutter project เปล่า แล้วพัฒนาไปจนได้ architecture และ feature ใกล้เคียงกับ `Popcorn Movie Tracker` ใน repository นี้

เป้าหมายไม่ใช่แค่ทำให้แอป “รันได้” แต่ให้เข้าใจเหตุผลของการแยก layer, การจัดการ network/cache/state, การทดสอบ และการทำ production-readiness ด้วย

## สิ่งที่จะได้เมื่อเรียนจบ

- Flutter + Material 3
- Riverpod สำหรับ state management และ dependency composition
- GoRouter สำหรับ navigation
- Dio + Retrofit สำหรับ REST API
- Freezed + json_serializable สำหรับ DTO/model
- Repository pattern และ lightweight Clean Architecture
- Hive สำหรับ local cache และ watchlist/profile persistence
- Search debounce + latest-request-wins + pagination
- Authentication/session/refresh-token flow
- Easy Localization แบบ CSV-first
- Responsive layout สำหรับ phone/tablet
- Extended Image สำหรับ network image/cache
- Unit test, widget test, golden test และ integration test
- GitHub Actions, coverage gate, Makefile และ code generation

## ลำดับบทเรียน

1. [เริ่มโปรเจกต์และวางโครงสร้าง](01_project_setup.md)
2. [Architecture, Domain และ Dependency Flow](02_architecture.md)
3. [UI, Routing, Theme และ Localization](03_ui_routing_localization.md)
4. [TMDB API ด้วย Dio + Retrofit + Freezed](04_network_retrofit_freezed.md)
5. [Repository, Cache และ Offline Strategy](05_repository_cache_offline.md)
6. [Riverpod, Search, Debounce และ Pagination](06_state_search_pagination.md)
7. [Authentication, Profile และ Settings](07_auth_profile_settings.md)
8. [Image, Responsive UI, Testing และ CI](08_image_testing_ci.md)
9. [Checklist จากศูนย์ถึงสถานะปัจจุบัน](09_final_checklist.md)

## Architecture ปลายทาง

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
Retrofit / Dio / Hive / Secure Storage
    ↓
TMDB / Device Storage
```

สำหรับ network DTO:

```text
TMDB JSON
    ↓
Retrofit Client
    ↓
Freezed DTO + json_serializable
    ↓
toDomain()
    ↓
Movie / Genre
```

## วิธีใช้ tutorial นี้

แนะนำให้สร้าง branch แยกสำหรับฝึก เช่น:

```bash
git checkout -b tutorial/from-zero
```

จากนั้นทำตามทีละบท และรัน validation หลังจบบท:

```bash
flutter pub get
make codegen
make check
```

> หมายเหตุ: source code ใน repository คือ source of truth หากตัวอย่างใน tutorial ต่างจากโค้ดล่าสุด ให้ยึด implementation ปัจจุบันใน `lib/` และ test เป็นหลัก
