# Performance and Diagnostics Guide

## Goals

เอกสารนี้กำหนดวิธีตรวจ Performance, Crash, Memory และ Network อย่างเป็นระบบ แทนการแก้ปัญหาจากความรู้สึกหรือการเดา

## 1. Frame Performance

ใช้ Flutter DevTools Performance view ตรวจ:

- UI thread frame time
- Raster thread frame time
- Jank เกิน frame budget
- shader compilation
- layout/build spikes

ขั้นตอน:

```bash
flutter run --profile
```

จากนั้น:

1. เปิด DevTools
2. เข้า Performance
3. กด Record
4. ทำ flow Home → Search → Detail → Watchlist
5. หยุด Record
6. ตรวจ frame ที่เกิน budget

สิ่งที่ควรตรวจใน source:

- งาน parse/sort ขนาดใหญ่ใน `build()`
- nested scroll view ที่สร้าง child มากเกินไป
- fixed-size image ใหญ่กว่าขนาด render
- widget rebuild จาก provider ที่ scope กว้างเกินไป
- chart repaint โดยไม่จำเป็น

## 2. Rebuild Analysis

ใช้ Flutter Inspector และ `debugPrintRebuildDirtyWidgets` เฉพาะ debug investigation

แนวทาง:

- แยก widget ที่ไม่ขึ้นกับ state เป็น `const`
- watch provider เฉพาะค่าที่ต้องใช้
- ใช้ selector เมื่อ state object ใหญ่
- หลีกเลี่ยงสร้าง controller/player ใน `build()`

## 3. Memory

ใช้ DevTools Memory:

1. เก็บ snapshot ก่อนเปิด Movie Detail
2. เปิด/ปิด Detail และ Trailer หลายรอบ
3. force GC
4. เปรียบเทียบ retained objects

ตรวจ class:

- `YoutubePlayerController`
- `TextEditingController`
- `Timer`
- `StreamSubscription`
- `ProviderContainer`
- image cache

ทุก controller/subscription/timer ต้องมี owner และ lifecycle สำหรับ dispose ชัดเจน

## 4. Image Performance

- ใช้ image size ที่ใกล้กับ render size
- หลีกเลี่ยงโหลด original-size TMDB image เมื่อ card ใช้เพียง thumbnail
- ใช้ cached image provider สำหรับ list/grid
- มี placeholder และ error fallback
- ทดสอบ slow network และ image failure

## 5. Network Diagnostics

เก็บข้อมูลต่อ request โดยไม่ log credential:

```text
method
path
statusCode
duration
retryCount
cacheSource
failureType
```

ห้าม log:

```text
Authorization
Access Token
Refresh Token
Password
Raw Email
```

วิเคราะห์:

- DNS/connect timeout
- receive timeout
- 429 frequency
- 401 refresh loops
- payload size
- duplicate requests
- pagination ordering

## 6. Crash Handling

Bootstrap ติดตั้ง:

```text
FlutterError.onError
PlatformDispatcher.instance.onError
```

Crash reporter contract ต้องรับ:

```text
error
stackTrace
fatal
reason
```

Production implementation สามารถเปลี่ยนเป็น Crashlytics/Sentry โดยคง interface เดิม

## 7. Search Performance

ใช้ debounce ลด request ระหว่างพิมพ์ และ latest-request-wins ป้องกัน stale result

Metric ที่ควรวัด:

- keystroke ถึง request start
- request duration
- result render duration
- duplicate request count
- ignored stale response count

## 8. Pagination Performance

- load page ถัดไปเมื่อใกล้ list end ไม่ใช่ทุก scroll event
- มี `isLoadingMore` guard
- ไม่ request page เดิมซ้ำ
- หยุดเมื่อ `hasMore == false`
- รักษารายการเดิมเมื่อ load-more fail
- แสดง retry เฉพาะ footer

## 9. Cache Diagnostics

ควร log source แบบไม่ sensitive:

```text
network
freshCache
staleCache
mock
```

ตรวจ:

- cache hit rate
- stale fallback count
- cache age
- cache write failure
- force refresh usage

## 10. Performance Review Checklist

ก่อน release:

- [ ] Profile mode flow ถูกบันทึกอย่างน้อยหนึ่งรอบ
- [ ] ไม่มี controller/subscription leak ที่ตรวจพบ
- [ ] Home/Search scrolling ไม่เกิด jank ต่อเนื่อง
- [ ] image failure ไม่ crash
- [ ] retry ไม่ loop ไม่สิ้นสุด
- [ ] refresh token ถูก deduplicate
- [ ] log ไม่มี token/password/email
- [ ] list pagination ไม่โหลด page ซ้ำ
- [ ] offline/stale data ไม่ถูกล้างโดยไม่จำเป็น

## 11. Reporting Template

```text
Scenario:
Device / OS:
Flutter mode:
Build commit:
Observed symptom:
Expected behavior:
Reproduction steps:
Frame timeline:
Memory before/after:
Network requests:
Logs (redacted):
Suspected owner/layer:
Fix:
Regression test:
```
