# Build, Signing and Release

## Environments

Popcorn กำหนด environment policy ใน `AppConfig`:

```text
development
staging
production
```

| Environment | App Name | Verbose Log | Mock Fallback |
|---|---|---:|---:|
| development | Popcorn Dev | on | on |
| staging | Popcorn Staging | on | on |
| production | Popcorn | off | off |

Dart config เป็น policy layer เท่านั้น การแยก application ID, bundle ID, icon, signing และ native scheme ต้องตั้งค่าใน Android/iOS project เพิ่มเติม

## Android Flavors

แนวทาง `android/app/build.gradle`:

```gradle
android {
    flavorDimensions "environment"

    productFlavors {
        development {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "Popcorn Dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "Popcorn Staging"
        }
        production {
            dimension "environment"
            resValue "string", "app_name", "Popcorn"
        }
    }
}
```

ตัวอย่าง IDs:

```text
com.dexter.popcorn.dev
com.dexter.popcorn.staging
com.dexter.popcorn
```

## Android Signing

ห้าม commit:

```text
*.jks
*.keystore
key.properties
storePassword
keyPassword
```

Release flow:

```text
CI secret / secure local file
        ↓
key.properties
        ↓
signingConfigs.release
        ↓
productionRelease
```

Build:

```bash
flutter build appbundle \
  --flavor production \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols/android
```

Artifacts:

```text
build/app/outputs/bundle/productionRelease/*.aab
build/symbols/android/
```

เก็บ symbol file ให้ตรงกับ versionCode เพื่อใช้ decode stack trace

## iOS Schemes and Configurations

แนะนำสร้าง:

```text
Debug-development
Release-development
Debug-staging
Release-staging
Debug-production
Release-production
```

Schemes:

```text
development
staging
production
```

Bundle IDs:

```text
com.dexter.popcorn.dev
com.dexter.popcorn.staging
com.dexter.popcorn
```

แต่ละ scheme ต้อง map ไป `.xcconfig` ที่ถูกต้อง

Build IPA:

```bash
flutter build ipa \
  --flavor production \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols/ios
```

## Versioning

`pubspec.yaml`:

```yaml
version: 1.1.0+2
```

Mapping:

```text
1.1.0 = user-facing version
2     = Android versionCode / iOS build number
```

Rules:

- build number ต้องเพิ่มทุก store upload
- version name ใช้ semantic versioning ตาม scope
- hotfix เพิ่ม patch
- backward-compatible feature เพิ่ม minor
- breaking product change เพิ่ม major

## Pre-release Validation

```bash
flutter clean
flutter pub get
make format-check
flutter analyze
make coverage-check
make golden
flutter devices
make integration DEVICE=<device-id>
```

Manual scenarios:

- clean install
- upgrade from previous build
- no TMDB token
- offline launch with cache
- offline launch without cache
- language switch
- auth restore/logout
- background/foreground
- add and persist Watchlist
- orientation change

## CI/CD Stages

```text
Validate
  ↓
Unit/Widget/Golden
  ↓
Coverage Gate
  ↓
Build Development/Staging
  ↓
QA Approval
  ↓
Build Signed Production Artifact
  ↓
Internal Distribution
  ↓
Store Submission
```

## Fastlane Direction

Suggested lanes:

```text
android internal
android production
ios beta
ios release
```

Fastlane configuration and store credentials are deliberately not committed in this portfolio repository

## Release Checklist

- [ ] Requirements/AC linked
- [ ] PR approved
- [ ] CI green
- [ ] integration tests pass on real device/simulator
- [ ] golden baseline reviewed
- [ ] version/build incremented
- [ ] environment verified
- [ ] production secrets injected securely
- [ ] signing identity verified
- [ ] release notes prepared
- [ ] privacy/log redaction reviewed
- [ ] symbols archived
- [ ] rollback plan documented
