# Profile & Settings

Feature นี้เพิ่ม local user profile และ app preferences โดยใช้ Hive + Riverpod ตาม architecture เดียวกับ Watchlist

## Features

- แก้ไข Display Name
- บันทึก Email
- บันทึก Favorite Genre
- เปลี่ยนภาษา English / Thai แบบ runtime
- เปิด/ปิด Release & Watchlist Notifications preference
- เปิด/ปิด Autoplay Trailer preference
- เปิด Release Calendar จากหน้า Profile
- แสดง App version

> Notification และ Autoplay ในรอบนี้เป็น persisted preferences และ UI controls ก่อน ส่วน platform notification scheduling และการนำ autoplay preference ไปควบคุม YouTube player สามารถเชื่อมต่อใน iteration ถัดไป

## Data Flow

```text
ProfilePage
    ↓
ProfileController (Riverpod Notifier)
    ↓
UserPreferencesLocalDataSource
    ↓
Hive Box<Map>
```

## Files

```text
lib/features/profile/
├── data/
│   └── user_preferences_local_data_source.dart
├── domain/
│   └── user_preferences.dart
└── presentation/
    ├── profile_controller.dart
    └── profile_page.dart
```

## Persistence

Hive box:

```text
user_preferences
```

Record key:

```text
current
```

ข้อมูลถูกเก็บเป็น JSON-compatible map เพื่อให้สอดคล้องกับ Watchlist persistence strategy และไม่ต้องใช้ generated Hive adapter

## Language Switching

หน้า Profile เรียก:

```dart
await context.setLocale(Locale(languageCode));
```

จากนั้นบันทึก `languageCode` ผ่าน `ProfileController` การแปล UI ยังคงใช้ `assets/langs/langs.csv` เป็น source of truth

## Tests

```text
test/features/profile/domain/user_preferences_test.dart
test/features/profile/data/user_preferences_local_data_source_test.dart
test/features/profile/presentation/profile_controller_test.dart
test/widgets/profile_page_test.dart
```

ครอบคลุม:

- Default preferences
- Map serialization / normalization
- Hive load / save
- Riverpod initial state
- Profile updates
- Language / notifications / autoplay updates
- Profile page rendering

รันเฉพาะ profile tests:

```bash
flutter test test/features/profile test/widgets/profile_page_test.dart
```

หรือรวม unit tests:

```bash
make test-unit
```
