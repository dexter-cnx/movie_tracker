# 05 — Repository, Cache และ Offline Strategy

บทนี้ทำให้แอปใช้งานได้ดีขึ้นเมื่อ network ช้า, หลุด หรือ API ตอบ error โดยไม่ทำให้ UI ต้องรู้รายละเอียดของ Dio/Hive

## 1. Repository เป็นผู้ตัดสินแหล่งข้อมูล

UI ไม่ควรถามว่า:

```text
มี cache ไหม?
network online ไหม?
retry กี่ครั้ง?
```

ให้ repository ตัดสินใจ แล้วส่งผลลัพธ์ที่มี semantics ชัดเจนกลับมา

ตัวอย่าง source:

```text
network
freshCache
staleCache
mock
```

## 2. Local Cache ด้วย Hive

สร้าง box สำหรับ movie cache:

```dart
await Hive.openBox<Map>(MovieCacheLocalDataSource.boxName);
```

record อย่างง่าย:

```text
cachedAt
items
```

ไม่จำเป็นต้องใช้ Hive generated adapter เสมอไป หากข้อมูลที่เก็บเป็น Map ที่ควบคุมได้และต้องการลด codegen เพิ่มอีกชุด

## 3. Fresh vs Stale

Cache ไม่ควรเป็น boolean แค่ “มี/ไม่มี” แต่ต้องรู้ freshness

```dart
bool isFresh(Duration ttl, DateTime now) {
  return now.difference(cachedAt) <= ttl;
}
```

ควร inject `now` ใน test เพื่อให้ deterministic

## 4. Trending flow

```text
read cache
  ↓
cache fresh และไม่ได้ force refresh?
  ├── yes → return freshCache
  └── no
       ↓
     remote
       ↓
     success?
       ├── yes → save cache → network
       └── no
            ↓
          stale cache มีไหม?
            ├── yes → staleCache + failure
            └── no → fallback/mock หรือ throw ตาม environment
```

## 5. Result type ที่บอก source

แทนที่จะคืน `List<Movie>` อย่างเดียว บาง flow ใช้ object เช่น:

```dart
class MovieLoadResult {
  const MovieLoadResult({
    required this.movies,
    required this.source,
    this.failure,
  });

  final List<Movie> movies;
  final MovieDataSource source;
  final AppFailure? failure;
}
```

UI จึงทำได้ เช่น:

```text
มีข้อมูลเก่า → แสดงต่อ + banner แจ้ง offline
ไม่มีข้อมูลเลย → blocking error + Retry
```

## 6. Connectivity ไม่ใช่ Source of Truth ของ request success

`connectivity_plus` บอกได้ว่า device มี transport หรือไม่ แต่ไม่ได้รับประกันว่า:

- DNS ใช้ได้
- TMDB reachable
- token ถูกต้อง
- server ไม่ล่ม

ดังนั้น Dio response/error ยังเป็น source of truth ของ request

Connectivity stream เหมาะสำหรับ UX เช่น offline banner

## 7. Typed Failure Mapping

สร้าง helper/map exception:

```text
DioExceptionType.connectionTimeout → TimeoutFailure
401 → UnauthorizedFailure
429 → RateLimitFailure
5xx → ServerFailure
connectionError → NetworkFailure
JSON/mapper error → ParsingFailure
อื่น ๆ → UnknownFailure
```

ข้อดีคือ repository test สนใจ business behavior มากกว่า plugin detail

## 8. 429 Retry

สร้าง interceptor ที่:

```text
response 429
 ↓
อ่าน retry count
 ↓
เกิน max?
 ├── yes → ส่ง error ต่อ
 └── no
      ↓
อ่าน Retry-After
      ↓
ไม่มี? ใช้ exponential delay
      ↓
retry request เดิม
```

เช่น:

```text
1s → 2s → 4s
```

ต้องจำกัดจำนวนครั้งเพื่อไม่ให้ request loop ไม่จบ

## 9. Force Refresh

Pull-to-refresh ควร bypass fresh-cache policy:

```dart
repository.getTrendingFeed(
  language,
  forceRefresh: true,
);
```

แต่ normal app launch สามารถใช้ fresh cache เพื่อเปิดหน้าเร็ว

## 10. Cache key

Cache key ต้องรวม dimension ที่ทำให้ response ต่างกัน เช่นภาษา

```text
trending:en-US
trending:th-TH
```

อย่าใช้ key เดียวแล้วให้ response ภาษาไทยทับภาษาอังกฤษ

## 11. Search fallback ต้องรักษา page semantics

ข้อผิดพลาดที่พบบ่อย:

```text
request page 2 fail
→ return mock page 1
```

ผลคือ caller append duplicate และ page state ถอยกลับ

fallback ที่ถูกต้องควรรักษา page:

```text
page 1 → อาจ fallback mocks
page > 1 → empty terminal page ของ page ที่ร้องขอ
```

## 12. Test Cases ที่ควรมี

```text
fresh cache → ไม่เรียก remote
stale cache + remote success → update cache
stale cache + remote fail → return stale data + failure
no cache + remote fail → fallback/error ตาม policy
forceRefresh → เรียก remote แม้ cache fresh
page 2 fail → ไม่คืน page 1 ซ้ำ
```

## เป้าหมายหลังจบบท

แอปควรเปิดข้อมูลเดิมได้เมื่อ network มีปัญหา, บอกผู้ใช้ได้ว่าข้อมูลมาจากไหน และไม่ให้ transport exception รั่วขึ้น UI
