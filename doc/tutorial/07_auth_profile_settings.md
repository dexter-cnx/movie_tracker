# 07 — Authentication, Profile และ Settings

บทนี้เพิ่ม authentication/session flow, secure storage และ profile/settings โดยคง boundary ให้ UI ไม่รู้รายละเอียดการเก็บ token

## 1. Auth Domain

สร้าง `AuthSession`:

```dart
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);
}
```

การส่ง `now` เข้า method ทำให้ test expiry logic ได้ deterministic

Repository contract:

```dart
abstract interface class AuthRepository {
  Future<AuthSession?> restore();
  Future<AuthSession> login(String email, String password);
  Future<AuthSession?> validSession();
  Future<void> logout();
}
```

## 2. Secure Storage

Token ไม่ควรเก็บใน SharedPreferences

ใช้:

```yaml
flutter_secure_storage: ^9.2.4
```

local data source รับผิดชอบ key และ serialization

```text
auth_access_token
auth_refresh_token
auth_expires_at
auth_user_id
```

Presentation ไม่ควรรู้ key เหล่านี้

## 3. Restore Session ตอนเริ่ม Auth Flow

flow:

```text
restore()
 ↓
ไม่มี session → unauthenticated
 ↓
มี session
 ↓
หมดอายุ?
 ├── no → authenticated
 └── yes → refresh
```

หาก refresh token ถูก reject ให้ clear local credentials

## 4. ป้องกัน Concurrent Refresh

หลาย request อาจพบ token expired พร้อมกัน

ไม่ควรยิง refresh 5 ครั้งพร้อมกัน

ใช้ one in-flight Future:

```dart
Future<AuthSession>? _refreshInFlight;

Future<AuthSession> _refresh() {
  return _refreshInFlight ??= _performRefresh().whenComplete(() {
    _refreshInFlight = null;
  });
}
```

ทุก caller await Future เดียวกัน

## 5. Logout ต้อง Invalidate Refresh ที่กำลังทำงาน

กรณีสำคัญ:

```text
refresh เริ่ม
 ↓
ผู้ใช้กด logout
 ↓
local storage ถูก clear
 ↓
refresh response กลับทีหลัง
```

หากเอา response ไปเขียน session ใหม่ ผู้ใช้จะกลับ authenticated หลัง logout

ใช้ generation/token เพื่อ invalidate result:

```dart
var _sessionGeneration = 0;

Future<void> logout() async {
  _sessionGeneration++;
  _session = null;
  await local.clear();
}
```

ตอน refresh จบตรวจ generation ก่อน accept result

## 6. Auth Controller

Controller แปลง repository state ให้ UI ใช้งานง่าย เช่น:

```text
initial/loading/authenticated/unauthenticated/error
```

Login page ไม่ควรเรียก remote data source โดยตรง

## 7. Navigation ไป Login ต้องเข้าถึงได้จริง

การมี route `/login` อย่างเดียวไม่พอ ต้องมี entry point จาก normal flow เช่น Profile

```dart
TextButton(
  onPressed: () => context.push('/login'),
  child: const Text('Sign in'),
)
```

และควร trigger session restore ในจุดที่เหมาะสม ไม่ใช่เฉพาะตอนเปิด LoginPage เท่านั้น

## 8. User Preferences

Profile settings เป็นข้อมูลคนละประเภทกับ auth credential

ตัวอย่าง:

```dart
class UserPreferences {
  const UserPreferences({
    this.displayName = 'Dexter',
    this.email,
    this.favoriteGenre,
    this.languageCode = 'en',
    this.notificationsEnabled = true,
    this.autoplayTrailers = false,
  });
}
```

ข้อมูลทั่วไปใช้ Hive/local storage ได้ ไม่จำเป็นต้อง secure storage ทุก field

## 9. Normalize Stored Values

เมื่ออ่านข้อมูลเก่า อย่าเชื่อ storage 100%

เช่น:

```text
displayName = "   " → fallback "Dexter"
languageCode = "jp" → fallback "en"
```

migration/fallback ที่ data/domain boundary ทำให้ UI ไม่ต้อง defensive ซ้ำ

## 10. Profile Controller

Controller ทำงานเช่น:

```text
load preferences
update display name
update email
change language
notifications toggle
autoplay trailers toggle
persist after change
```

ทุก update ควรสร้าง state ใหม่และ persist ผ่าน data source/repository

## 11. Language Setting

เมื่อ user เปลี่ยนภาษา:

1. update preference
2. เปลี่ยน EasyLocalization locale
3. provider ที่ key ด้วย language จะ refresh response ตามภาษาใหม่

ต้องระวัง cache key ให้แยก `en-US` และ `th-TH`

## 12. App Version

อย่า hard-code version ใน About page เช่น:

```dart
const Text('1.0.0')
```

ใช้ `package_info_plus` เพื่ออ่าน version/build number จาก package metadata

เมื่อ `pubspec.yaml` เปลี่ยนเป็น `1.1.0+2` UI จะ sync อัตโนมัติ

## 13. Tests ที่ควรมี

Auth:

```text
restore no session
restore valid session
expired session refresh success
refresh failure clears session
concurrent validSession uses one refresh
logout invalidates in-flight refresh
```

Profile:

```text
defaults are safe
invalid stored values normalize
load initial preferences
update and persist profile fields
setting toggles persist independently
```

## เป้าหมายหลังจบบท

ผู้ใช้ควร login/logout ได้อย่าง deterministic, credential อยู่ secure storage, profile/settings persist ได้ และ lifecycle ของ refresh token ไม่สร้าง race condition
