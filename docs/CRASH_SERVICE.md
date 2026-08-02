# Crash Service Integration

Popcorn ใช้ crash reporting แบบ vendor-neutral เพื่อให้ source ปัจจุบันรันได้โดยไม่ต้องมี Firebase project หรือ Sentry DSN แต่ยังสามารถเปลี่ยน provider ภายหลังโดยไม่แก้ caller ใน feature และ application bootstrap

## Current Implementation

```text
CrashService
    ↓
CrashReporter interface
    ↓
LoggingCrashReporter
    ↓
AppLogger
    ↓
dart:developer log
```

ไฟล์หลัก:

```text
lib/core/crash/crash_reporter.dart
lib/core/logging/app_logger.dart
lib/main.dart
```

`CrashService` เป็น application-facing API ส่วน `CrashReporter` เป็น provider contract

Current provider คือ:

```dart
const crashService = CrashService(
  LoggingCrashReporter(DeveloperAppLogger()),
);
```

ดังนั้น application สามารถทดสอบ flow ต่อไปนี้ได้โดยไม่ต้องมี external credential:

- service initialization
- non-fatal Flutter framework errors
- fatal uncaught platform errors
- breadcrumbs
- user context
- custom context
- stack traces
- fatal/non-fatal metadata

## Global Error Sources

`main.dart` เชื่อม:

```text
FlutterError.onError
PlatformDispatcher.instance.onError
```

Flutter framework error ถูกส่งเป็น non-fatal ส่วน uncaught platform-dispatcher error ถูกส่งเป็น fatal

## Sensitive Data

Crash context ส่งผ่าน `AppLogger` ซึ่ง redact key สำคัญ เช่น:

```text
authorization
token
accessToken
refreshToken
password
email
```

Feature code ไม่ควรส่ง raw credential หรือข้อมูลส่วนตัวลง `reason` เพราะ `reason` เป็นข้อความ ไม่ใช่ structured context ที่ผ่าน key-based redaction

## Future Firebase Crashlytics Adapter

เมื่อมี Firebase project จริง ให้สร้าง implementation ใหม่:

```dart
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this.crashlytics);

  final FirebaseCrashlytics crashlytics;

  @override
  Future<void> initialize() async {
    await crashlytics.setCrashlyticsCollectionEnabled(true);
  }

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const {},
  ) async {
    for (final entry in context.entries) {
      await crashlytics.setCustomKey(entry.key, entry.value ?? '<null>');
    }
    await crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  // Implement breadcrumb, setUser and setContext using Crashlytics APIs.
}
```

แล้วเปลี่ยนเฉพาะ composition root:

```dart
final crashService = CrashService(
  FirebaseCrashReporter(FirebaseCrashlytics.instance),
);
```

Caller เช่น `recordPlatformError()`, `breadcrumb()` และ `setUser()` ไม่ต้องเปลี่ยน

## Future Sentry Adapter

เมื่อมี Sentry DSN จริง ให้สร้าง:

```dart
class SentryCrashReporter implements CrashReporter {
  // Map record() to Sentry.captureException(),
  // breadcrumb() to Sentry.addBreadcrumb(),
  // setUser() and setContext() to Sentry.configureScope().
}
```

จากนั้นเปลี่ยนเฉพาะ provider construction ใน `main.dart`

DSN ต้องมาจาก secure CI/CD environment หรือ native configuration ไม่ควร commit ลง repository

## Tests

```text
test/core/crash/crash_reporter_test.dart
```

Test ตรวจ:

- logging provider initialize ได้โดยไม่ใช้ external credential
- fatal flag และ custom context ถูกส่งเข้า logger
- `CrashService` map platform error ไปยัง provider contract ถูกต้อง

## Production Checklist

- [ ] เลือก Crashlytics หรือ Sentry
- [ ] เพิ่ม SDK dependency
- [ ] เพิ่ม environment-specific configuration
- [ ] inject credential/DSN ผ่าน CI secrets
- [ ] ปิดหรือจำกัด collection ตาม privacy policy
- [ ] upload Android/iOS symbols
- [ ] ทดสอบ non-fatal event
- [ ] ทดสอบ fatal crash ใน staging build
- [ ] ตรวจว่า token/password/email ไม่ปรากฏใน event
- [ ] ตั้ง release/environment tag
- [ ] ตั้ง alerting และ issue ownership
