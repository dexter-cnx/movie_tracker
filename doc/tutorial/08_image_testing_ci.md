# 08 — Image, Responsive UI, Testing และ CI

บทสุดท้ายด้าน implementation รวมหัวข้อ production-quality ที่ทำให้โปรเจกต์ไม่ได้หยุดแค่ “เปิดได้” แต่มี behavior ที่เสถียรและตรวจสอบซ้ำได้

## 1. Shared Image Widget

Movie app ใช้รูปจำนวนมากและแสดงซ้ำหลายหน้า หากทุกหน้าจัดการ network image เองจะเกิด config drift

สร้าง `AppImage` กลาง:

```text
lib/shared/widgets/app_image.dart
```

หน้าที่:

- network image loading
- disk/memory cache
- placeholder
- failed state
- retry
- fade-in
- optional Hero
- optional zoom
- circle/rounded shape
- decode size ตาม device pixel ratio

ตัวอย่าง API:

```dart
AppImage.network(
  url,
  width: 145,
  height: 217,
  radius: 18,
  fit: BoxFit.cover,
)
```

## 2. Decode Image ให้ใกล้ Display Size

ภาพจาก TMDB อาจใหญ่กว่าที่ card ใช้มาก

```dart
final dpr = MediaQuery.devicePixelRatioOf(context);
final cacheWidth = (width * dpr).round();
```

การ decode ใกล้ target size ลด memory pressure โดยเฉพาะ grid ที่มีหลาย poster พร้อมกัน

ต้อง guard ค่า:

```text
null
double.infinity
<= 0
```

ก่อนส่งเป็น cache dimension

## 3. ไม่ล้าง Memory Cache ทุกครั้งที่ Dispose

ใน movie app poster เดิมมักถูกใช้ซ้ำใน:

```text
Home
Search
Watchlist
Similar Movies
```

หาก `clearMemoryCacheWhenDispose: true` เป็น default จะเกิด decode ซ้ำและภาพกระพริบเมื่อ scroll กลับ

ดังนั้น default ควรเป็น false และเปิดเฉพาะ use case ที่มีเหตุผล

## 4. Poster Wrapper

ให้ `Poster` เป็น domain-oriented widget ที่รู้วิธีสร้าง TMDB image URL:

```dart
final url = path == null
    ? null
    : 'https://image.tmdb.org/t/p/w500$path';
```

จากนั้น delegate rendering ไป `AppImage`

ข้อดีคือ UI feature ใช้:

```dart
Poster(
  path: movie.posterPath,
  title: movie.title,
)
```

แทนการประกอบ URL ซ้ำทุกหน้า

## 5. Movie Detail Media

Backdrop ใช้ image pipeline เดียวกัน

Cast profile ใช้ circle mode

Trailer แยกเป็น lifecycle-aware component เพื่อ:

- pause เมื่อ app background
- dispose controller
- เคารพ autoplay setting

## 6. Responsive Grid

จำนวน column ควรอิง helper กลาง:

```dart
final columns = ResponsiveLayout.gridColumns(size);
```

จากนั้น:

```dart
SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: columns,
  childAspectRatio: ratioClass == DeviceRatioClass.wide
      ? .74
      : .67,
)
```

ต้องทดสอบ tablet/landscape ด้วย ไม่ใช่แค่ phone portrait

## 7. Testing Pyramid

โปรเจกต์แบ่ง test โดยประมาณ:

```text
Unit Tests
  → domain/data/controller logic

Widget Tests
  → rendering + interaction + responsive behavior

Golden Tests
  → visual regression

Integration Tests
  → flow ข้ามหลาย feature บนอุปกรณ์จริง/simulator
```

## 8. Unit Test

เหมาะกับ:

```text
DTO → Domain mapping
cache freshness
repository fallback
failure mapping
search debounce
pagination
profile normalization
auth refresh race
```

ใช้ `mocktail` เมื่อ dependency เป็น interface/class ที่เหมาะกับ mocking

## 9. Widget Test

ตัวอย่างที่ควรมี:

```text
Home แสดง stale-cache notice แต่ยังเห็น movie content
Profile แสดง account/settings
Watchlist เปลี่ยน grid columns ตาม screen ratio
AppImage empty URL แสดง fallback
```

Localization test ต้อง wrap widget ด้วย helper ที่ initialize EasyLocalization เพื่อให้ test environment ใกล้ runtime จริง

## 10. Golden Test

Golden เหมาะกับหน้าที่ visual hierarchy สำคัญ เช่น:

```text
Home phone
Home tablet
Watchlist phone
Profile
```

รัน:

```bash
make golden
```

update baseline:

```bash
make golden-update
```

อย่า update golden แบบอัตโนมัติใน CI เพราะจะทำให้ regression กลายเป็น baseline ใหม่โดยไม่ review

## 11. Integration Test

ตัวอย่าง flow:

```text
เปิด Watchlist
เพิ่ม/แก้รายการ
กลับหน้าเดิม
ตรวจ state/persistence
```

หรือ profile settings:

```text
เปิด Profile
เปลี่ยน setting
ออกหน้า
กลับเข้ามา
ตรวจค่าที่ยังอยู่
```

รัน:

```bash
make integration DEVICE=<device-id>
```

## 12. Code Generation เป็นส่วนหนึ่งของ Build

เมื่อใช้ Retrofit + Freezed ต้องถือ codegen เป็น build step ไม่ใช่งาน manual ที่จำเอาเอง

```bash
make codegen
```

`make check` ควรขึ้นกับ codegen:

```make
check: codegen format-check analyze test
```

CI ก็เช่นกัน:

```text
flutter pub get
 ↓
build_runner
 ↓
format check
 ↓
analyze
 ↓
test + coverage
```

## 13. GitHub Actions

Pipeline หลัก:

```text
Checkout
Setup Flutter
Prepare environment file
flutter pub get
Generate Retrofit/Freezed sources
Verify formatting
flutter analyze
flutter test --coverage
Coverage threshold
Upload coverage artifact
```

## 14. Coverage Gate

Coverage ไม่ได้แปลว่า test ดีเสมอไป แต่ threshold ช่วยป้องกันการเพิ่ม code จำนวนมากโดยไม่มี test เลย

โปรเจกต์ใช้ขั้นต่ำประมาณ:

```text
55%
```

ควรเพิ่ม threshold เมื่อ test suite mature ขึ้น ไม่ควรไล่เปอร์เซ็นต์จนต้องเขียน test ที่ไม่มีคุณค่า

## 15. App Name / Icon

ชื่อที่แสดงบน launcher:

```text
Popcorn Movie Tracker
```

Android ดูที่ `android:label`

iOS ดูที่ `CFBundleDisplayName`

Icon ใช้ `flutter_launcher_icons` เพื่อให้ source image เดียว generate platform assets ได้

หลังเปลี่ยน icon/name บนอุปกรณ์จริงอาจต้อง uninstall แอปเก่าเพราะ launcher cache

## 16. Validation ก่อน Merge

รันอย่างน้อย:

```bash
flutter pub get
make codegen
make format
make check
```

และเมื่อแตะ visual/integration behavior:

```bash
make golden
make integration DEVICE=<device-id>
```

## เป้าหมายหลังจบบท

โปรเจกต์ควรมี image pipeline กลาง, responsive behavior ที่ test ได้, codegen deterministic และ CI ที่ block merge เมื่อ format/analyze/test/coverage ไม่ผ่าน
