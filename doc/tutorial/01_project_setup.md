# 01 — เริ่มโปรเจกต์และวางโครงสร้าง

บทนี้เริ่มจาก Flutter project เปล่า และเตรียม foundation ให้พร้อมสำหรับ Movie Tracker ที่มีหลาย feature โดยไม่รีบใส่ abstraction เกินความจำเป็น

## 1. สร้างโปรเจกต์

```bash
flutter create popcorn_movie_tracker
cd popcorn_movie_tracker
```

ตรวจ environment:

```bash
flutter doctor
flutter --version
```

ตั้งชื่อ package ใน `pubspec.yaml`:

```yaml
name: popcorn_movie_tracker
description: Popcorn - Movie Tracker & Watchlist portfolio app.
publish_to: "none"
version: 1.1.0+2

environment:
  sdk: ">=3.4.0 <4.0.0"
```

## 2. Dependencies หลัก

โปรเจกต์ปัจจุบันแบ่ง dependencies เป็น 4 กลุ่มใหญ่

### Application / State / Navigation

```yaml
flutter_riverpod: ^2.6.1
go_router: ^14.8.1
shared_preferences: ^2.5.5
```

### Network / API / Serialization

```yaml
dio: ^5.8.0+1
retrofit: ^4.4.2
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0
```

### Local Storage / Device

```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
flutter_secure_storage: ^9.2.4
connectivity_plus: ^6.1.4
package_info_plus: ^8.3.0
```

### UI / Media / Localization

```yaml
easy_localization: ^3.0.7+1
easy_localization_loader: ^2.0.2
extended_image: ^9.1.0
fl_chart: ^0.71.0
youtube_player_flutter: ^9.1.1
```

### Dev dependencies สำหรับ code generation และ test

```yaml
build_runner: ^2.4.11
freezed: ^2.5.8
json_serializable: ^6.8.0
retrofit_generator: ^9.1.5
mocktail: ^1.0.4
csv: ^6.0.0
```

หลังแก้ `pubspec.yaml`:

```bash
flutter pub get
```

## 3. สร้างโครงสร้าง folder

ใช้แนวทาง feature-first แต่ภายใน feature ยังแยก data/domain/presentation

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
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── movies/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── home/
│   ├── movie_detail/
│   ├── profile/
│   ├── search/
│   └── watchlist/
├── shared/
│   └── widgets/
├── app.dart
└── main.dart
```

เหตุผลที่ใช้แบบนี้:

- feature ที่เกี่ยวข้องอยู่ใกล้กัน
- ลดการไล่หาไฟล์ข้าม `data/`, `domain/`, `presentation/` ทั้งโปรเจกต์
- แยก boundary ชัดพอสำหรับ test
- ไม่สร้าง UseCase class ทุก operation หากไม่ได้มี business rule ที่ซับซ้อน

## 4. Bootstrap ใน `main.dart`

ลำดับที่ควรมี:

```text
WidgetsFlutterBinding.ensureInitialized()
        ↓
ติดตั้ง global error handlers
        ↓
EasyLocalization.ensureInitialized()
        ↓
โหลด assets/.env
        ↓
Hive.initFlutter()
        ↓
เปิด Hive boxes
        ↓
ProviderScope
        ↓
EasyLocalization
        ↓
PopcornApp
```

ตัวอย่างแนวคิด:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: PopcornApp(),
    ),
  );
}
```

ในโปรเจกต์จริงยังมี crash reporter และ environment bootstrap เพิ่มด้วย

## 5. Environment file

สร้าง:

```text
assets/.env
```

ตัวอย่าง:

```env
TMDB_BEARER_TOKEN=YOUR_TOKEN
```

อย่า commit credential จริง และเพิ่มใน `.gitignore`:

```gitignore
/assets/.env
```

ใน CI สามารถสร้างไฟล์ placeholder เพื่อให้ asset resolution ไม่ fail

## 6. Makefile ตั้งแต่ต้น

เป้าหมายคือให้ทุกคนใช้คำสั่งชุดเดียวกัน

```make
get:
	flutter pub get

codegen:
	dart run build_runner build --delete-conflicting-outputs

format:
	dart format lib test integration_test

analyze:
	flutter analyze

test:
	flutter test

check: codegen format-check analyze test
```

หลังบทนี้ควรรันได้:

```bash
flutter pub get
flutter analyze
flutter test
```

## 7. สิ่งที่ยังไม่ควรรีบทำ

อย่าเพิ่งสร้าง abstraction เช่น:

- `BaseUseCase`
- `BaseRepository`
- `BaseRemoteDataSource`
- generic response wrapper หลายชั้น

ให้เริ่มจาก boundary ที่มีเหตุผลจริงก่อน แล้วค่อย abstraction เมื่อเห็น pattern ซ้ำจาก code ที่มีอยู่

## เป้าหมายหลังจบบท

คุณควรมี Flutter project ที่:

- build ได้
- มี package dependencies พร้อม
- มี folder architecture ที่รองรับ feature เพิ่ม
- มี environment file policy
- มี command สำหรับ format/analyze/test/codegen
