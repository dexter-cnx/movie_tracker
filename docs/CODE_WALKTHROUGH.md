# Code Walkthrough — Popcorn Movie Tracker & Watchlist

เอกสารนี้อธิบายการทำงานของ source code ตามลำดับตั้งแต่แอปเริ่มทำงาน ไปจนถึงการโหลดข้อมูลจาก TMDB, fallback เป็น mock data, การจัดการ state ด้วย Riverpod, การเก็บ Watchlist ด้วย Hive และแนวทางการทดสอบ

จุดประสงค์คือให้สามารถใช้เอกสารนี้ประกอบการอธิบายโค้ดกับ reviewer ได้ โดยอ้างอิงชื่อไฟล์และ class/method ที่มีอยู่จริงในโปรเจกต์

---

## 1. ภาพรวม Architecture

โปรเจกต์ใช้แนวทาง **Clean Architecture แบบ lightweight + MVVM-style presentation** โดยเน้นแยก responsibility ของส่วนที่เกี่ยวข้องกับข้อมูลภาพยนตร์ออกเป็น `data / domain / presentation`

```text
UI / Presentation
      ↓
Riverpod Provider / Controller
      ↓
Repository Interface (Domain)
      ↓
Repository Implementation (Data)
      ↓
Remote Data Source / Local Data Source
      ↓
TMDB API / Hive
```

โครงสร้างปัจจุบันเป็นแบบ pragmatic มากกว่า Clean Architecture เต็มรูปแบบ กล่าวคือ feature `movies` มีการแยก `data`, `domain`, `presentation` ชัดเจน ขณะที่ feature อย่าง `home`, `search`, `movie_detail`, `calendar` ทำหน้าที่เป็น presentation feature ที่ reuse movie providers และ repository เดียวกัน

โปรเจกต์ยังไม่มี Use Case class แยกทุก operation โดยจงใจให้ Riverpod provider/controller เรียก repository โดยตรง เพื่อลด boilerplate สำหรับขนาดของ demo app ปัจจุบัน

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> UI ไม่เรียก Dio หรือ Hive โดยตรง ข้อมูลภาพยนตร์ผ่าน Repository abstraction ส่วน state ที่ UI สนใจถูก expose ผ่าน Riverpod provider/controller ทำให้ network, persistence และ presentation แยกหน้าที่กันชัดเจนในระดับที่เหมาะกับขนาดโปรเจกต์

---

## 2. App Startup

### `lib/main.dart`

`main()` เป็น entry point ของแอป และ initialize dependency ที่จำเป็นก่อน `runApp()`

ลำดับหลักคือ:

```text
WidgetsFlutterBinding.ensureInitialized()
        ↓
EasyLocalization.ensureInitialized()
        ↓
dotenv.load('assets/.env')
        ↓
Hive.initFlutter()
        ↓
Hive.openBox<Map>('watchlist_items')
        ↓
ProviderScope
        ↓
EasyLocalization
        ↓
PopcornApp
```

สิ่งสำคัญคือ Hive box ถูกเปิดก่อนสร้าง `WatchlistController` เพราะ `watchlistDataSourceProvider` ใช้ `Hive.box<Map>()` โดยสมมติว่า box ถูกเปิดแล้ว

`EasyLocalization` ครอบ `PopcornApp` เพื่อให้ widget ภายในสามารถใช้ `.tr()` และเข้าถึง `context.locale` ได้

`ProviderScope` เป็น root scope ของ Riverpod ทำให้ provider ทั้งแอปสามารถ resolve dependency ผ่าน `ref.watch()` และ `ref.read()`

### จุดที่ควรระวัง

ไฟล์ `assets/langs/langs.csv` ถูกโหลดในช่วง startup ดังนั้น malformed CSV อาจกระทบการเริ่มแอป ปัจจุบันจึงมี localization CSV test เพื่อตรวจ header, จำนวน column, blank value และ duplicate key ก่อน release

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> `main()` เตรียม localization, environment และ local database ก่อนสร้าง UI เพื่อให้ provider ที่พึ่งพา Hive และ locale พร้อมใช้งานตั้งแต่ frame แรก

---

## 3. Routing และ App Shell

### `lib/app.dart`

`GoRouter` กำหนด navigation หลักของแอป

```text
/
├── /explore
├── /watchlist
├── /calendar
└── /movie/:id
```

เส้นทางหลัก 4 หน้าอยู่ภายใต้ `ShellRoute` และใช้ `AppShell` ร่วมกัน จึงสามารถคง bottom navigation เดียวกันไว้ขณะสลับ Home, Explore, Watchlist และ Calendar

Movie Detail แยกออกจาก ShellRoute:

```dart
GoRoute(
  path: '/movie/:id',
  builder: (_, state) => MovieDetailPage(
    movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
  ),
)
```

แนวทางนี้ทำให้ Detail screen สามารถแสดงเต็มหน้าจอโดยไม่ต้องใช้ bottom navigation ของ main shell

`MaterialApp.router` รับ theme, router และ localization delegates จาก `EasyLocalization`

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Main tabs ใช้ `ShellRoute` เพื่อแชร์ navigation shell ส่วน Movie Detail แยกเป็น top-level route เพื่อให้ user focus กับ content และใช้ back navigation ตามธรรมชาติ

---

## 4. Theme และ Shared UI

### `lib/core/theme/app_theme.dart`

`AppColors` เป็น semantic color tokens ของ Cinematic Dark UI เช่น:

- `background`
- `surface`
- `card`
- `cardAlt`
- `text`
- `secondary`
- `orange`
- `button`

`AppTheme.light` แม้ชื่อ property จะเป็น `light` แต่ ThemeData ปัจจุบันใช้ `Brightness.dark` และ `ColorScheme.dark` ตาม design direction ล่าสุด

จุดนี้เป็น naming debt เล็กน้อยที่ควร rename เป็น `dark` หรือ `cinematicDark` ในอนาคตเพื่อให้ชื่อสอดคล้องกับ implementation

### `lib/shared/widgets/clay_widgets.dart`

ประกอบด้วย reusable UI components เช่น:

- `ClayCard`
- `ClayIconButton`
- `Poster`

`Poster` รับ `posterPath` จาก TMDB แล้วประกอบ URL:

```text
https://image.tmdb.org/t/p/w500{posterPath}
```

เมื่อไม่มี image path จะ fallback เป็น title placeholder และเมื่อ network image error จะ fallback เป็น movie icon

การรวม visual rules ไว้ใน shared widgets ลดการเขียน decoration ซ้ำใน Home, Search, Watchlist และ Detail

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Theme token กำหนด visual language กลาง ส่วน shared widgets ทำหน้าที่ enforce card radius, border, shadow และ poster behavior ให้หน้าต่าง ๆ มี UI consistency

---

## 5. Network Setup

### `lib/core/network/dio_provider.dart`

`dioProvider` สร้าง Dio instance กลางของแอป

ค่าหลักประกอบด้วย:

```text
baseUrl        = https://api.themoviedb.org/3
connectTimeout = 10 seconds
receiveTimeout = 12 seconds
```

Bearer token ถูกอ่านจาก:

```dart
dotenv.env['TMDB_BEARER_TOKEN']
```

ถ้ามี token จะเพิ่ม:

```http
Authorization: Bearer <token>
```

Dio instance เดียวกันถูกติดตั้ง `RateLimitInterceptor`

---

## 6. HTTP 429 Retry

### `lib/core/network/rate_limit_interceptor.dart`

`RateLimitInterceptor` ดักเฉพาะ `DioException` ที่ response status เป็น `429`

Flow:

```text
Dio request
   ↓
429 Too Many Requests?
   ├── No  → ส่ง error ต่อด้วย handler.next()
   └── Yes
        ↓
อ่าน retryCount จาก RequestOptions.extra
        ↓
ถึง maxRetries หรือยัง?
   ├── Yes → ส่ง error ต่อ
   └── No
        ↓
อ่าน Retry-After header
        ↓
ถ้าไม่มี ใช้ exponential delay
        ↓
เพิ่ม retryCount
        ↓
dio.fetch(request)
```

Default exponential delay เป็นประมาณ:

```text
1s → 2s → 4s
```

เพราะใช้ `1 << retryCount`

Test ครอบคลุม behavior สำคัญ ได้แก่ non-429 pass-through, retry success และหยุด retry เมื่อถึง limit

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Rate-limit handling อยู่ใน network concern ไม่กระจาย logic retry ไปตามแต่ละ repository method ทำให้ทุก TMDB request ได้ behavior เดียวกัน

---

## 7. Domain Model

### `lib/features/movies/domain/entities/movie.dart`

`Movie` เป็น domain entity ที่ presentation ใช้งาน

ข้อมูลหลักเช่น:

```text
id
title
overview
posterPath
backdropPath
releaseDate
voteAverage
genreIds
popularity
runtime
budget
revenue
voteCount
originalLanguage
genres
cast
trailerKey
similar
```

Entity มี computed property:

```dart
int get releaseYear =>
    int.tryParse(releaseDate.split('-').first) ?? 0;
```

ดังนั้น UI ไม่ต้อง parse ปีซ้ำเอง

`CastMember` เป็น domain object ขนาดเล็กสำหรับชื่อและ profile image

---

## 8. Mapping TMDB JSON

### `lib/features/movies/data/models/movie_model.dart`

`MovieModel.fromJson()` รับ raw JSON จาก TMDB แล้วแปลงเป็น `Movie`

หน้าที่สำคัญ:

1. normalize primitive fields
2. ให้ default value เมื่อ field หาย
3. map genre IDs และ genre names
4. map cast จาก `credits.cast`
5. หา YouTube Trailer/Teaser ตัวแรกจาก `videos.results`
6. map `similar.results` กลับเป็น `Movie`

ตัวอย่าง normalization:

```text
missing id            → 0
blank/missing title   → Untitled
missing overview      → ''
missing vote_average  → 0
```

การรวม mapping ไว้ที่ data layer ทำให้ widget ไม่ต้องรู้ shape ของ TMDB JSON

Test ของไฟล์นี้ตรวจทั้ง normal response และ edge cases ของข้อมูลที่หายหรือผิดรูปแบบ

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Presentation ใช้ `Movie` ที่มี shape แน่นอน ส่วนความไม่แน่นอนของ external JSON ถูกจัดการใน `MovieModel.fromJson()` จุดเดียว

---

## 9. Remote Data Source

### `lib/features/movies/data/tmdb_remote_data_source.dart`

`TmdbRemoteDataSource` เป็นชั้นที่รู้ endpoint ของ TMDB โดยตรง

helper `_params(language)` ใส่ parameter กลาง:

```text
language
include_image_language = th,en,null
include_video_language = th,en
```

helper `_list()` ลด code ซ้ำของ endpoint ที่ return `results`

Endpoints ที่รองรับ:

```text
/movie/popular
/trending/movie/week
/movie/top_rated
/movie/upcoming
/movie/now_playing
/search/movie
/genre/movie/list
/discover/movie
/movie/{id}
```

Movie Detail ใช้:

```text
append_to_response=credits,videos,similar
```

เพื่อดึงข้อมูล detail, cast, trailer และ similar movies ใน request หลักเดียว

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Data Source รับผิดชอบ protocol/API contract เท่านั้น ไม่ตัดสินใจเรื่อง fallback และไม่จัดการ UI state

---

## 10. Repository และ Mock Fallback

### `lib/features/movies/domain/repositories/movie_repository.dart`

`MovieRepository` เป็น abstraction ที่ presentation/provider พึ่งพา

จึงสามารถเปลี่ยน implementation หรือ mock ใน test ได้โดยไม่แก้ UI

### `lib/features/movies/data/movie_repository_impl.dart`

`MovieRepositoryImpl` ใช้ `_fallback()` เพื่อให้ remote request fallback เป็น mock data เมื่อเกิด exception

```text
Repository request
      ↓
Remote Data Source
      ↓ success
return TMDB data

หรือ

Remote Data Source
      ↓ exception
return mock data
```

Fallback ถูกปรับตาม operation เช่น:

- Trending / Popular → `mockMovies`
- Top Rated → sort mock ตาม `voteAverage`
- Upcoming → reverse mock list
- Now Playing → 6 รายการแรก
- Search → filter title
- Genre → fallback genre list
- Discover → filter `genreIds`
- Detail → movie ที่ id ตรง หรือ mock ตัวแรก

ข้อดีคือ demo app ยังใช้งานได้เมื่อไม่มี token หรือ TMDB unavailable

ข้อควรเข้าใจคือ implementation ปัจจุบัน catch exception ทุกประเภท ดังนั้น authentication error, network error และ parsing error จะ fallback เหมือนกันทั้งหมด ซึ่งเหมาะกับ demo แต่ production ควรแยก error category และ observability ให้ละเอียดกว่าเดิม

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Repository เป็น policy boundary: Data Source มีหน้าที่เรียก API ส่วน Repository เป็นคนตัดสินใจว่าจะคืน remote result หรือ fallback data

---

## 11. Riverpod Providers

### `lib/features/movies/presentation/movie_providers.dart`

Provider หลัก:

```text
movieRepositoryProvider
trendingProvider
movieDetailProvider
genresProvider
```

`movieRepositoryProvider` ประกอบ dependency chain:

```text
dioProvider
   ↓
TmdbRemoteDataSource
   ↓
MovieRepositoryImpl
```

`apiLanguage()` map locale ของแอป:

```text
en → en-US
th → th-TH
```

`MovieDetailArg` override `==` และ `hashCode` เพื่อใช้เป็น key ของ `FutureProvider.family` ได้อย่าง deterministic

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Riverpod ทำหน้าที่ทั้ง dependency injection และ state exposure โดย UI watch เฉพาะ provider ที่ต้องการ แทนการสร้าง Dio/Repository เองใน widget

---

## 12. Home Flow

### `lib/features/home/presentation/home_page.dart`

`HomePage` เป็น `ConsumerWidget`

ตอน build:

```dart
final lang = apiLanguage(context.locale.languageCode);
final trending = ref.watch(trendingProvider(lang));
final watchlist = ref.watch(watchlistControllerProvider);
```

จึง subscribe state สองส่วนพร้อมกัน:

1. Trending movie แบบ async
2. Watchlist local state แบบ synchronous list

`trending.when()` map Riverpod AsyncValue เป็น:

```text
data    → horizontal movie cards
loading → CircularProgressIndicator
error   → empty placeholder
```

เมื่อกด movie card:

```dart
context.push('/movie/${m.id}')
```

ส่วน Watchlist preview จะใช้ข้อมูลจริงจาก Hive เมื่อมี item แต่ถ้ายังว่างจะแสดง demo rows

Watch Stats ใช้ `fl_chart` แสดงกราฟตัวอย่าง 7 bars โดยปัจจุบันยังเป็น static demo data ไม่ได้คำนวณจาก watch history จริง

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Home เป็น composition screen ที่รวม remote async state และ local persistent state โดย Riverpod ทำให้ widget rebuild เฉพาะเมื่อ provider ที่ watch เปลี่ยน

---

## 13. Search & Discover Flow

### `lib/features/search/presentation/search_page.dart`

หน้า Search เป็น `ConsumerStatefulWidget` เพราะมี local interaction state:

```text
selected genre
movies result
loading
roulette result
```

`load()` เลือก operation ตาม query:

```text
query ว่าง     → discoverByGenre()
query ไม่ว่าง  → search()
```

`_preset()` รองรับ:

```text
Trending
Top Rated
Upcoming
Now Playing
```

Genre list มาจาก `genresProvider(language)`

Movie Roulette เลือก random movie จาก result list ปัจจุบัน:

```dart
roulette = movies[Random().nextInt(movies.length)];
```

มี `mounted` guard หลัง async operation เพื่อป้องกัน `setState()` หลัง widget ถูก dispose

### จุดที่ควรพัฒนาต่อ

Search ปัจจุบันใช้ `onSubmitted` จึงยังไม่มี debounce/latest-request-wins และไม่มี cancellation token หากเพิ่ม search-as-you-type ควรเพิ่ม request cancellation หรือ request generation guard เพื่อป้องกันผลลัพธ์เก่าทับผลลัพธ์ใหม่

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Search ใช้ repository abstraction เดียวกับ Home แต่เก็บ transient interaction state ไว้ใน StatefulWidget เพราะ state เหล่านี้เป็น page-local และยังไม่จำเป็นต้องแชร์ข้ามหน้า

---

## 14. Movie Detail Flow

### `lib/features/movie_detail/presentation/movie_detail_page.dart`

รับ `movieId` จาก router แล้วสร้าง provider key:

```dart
MovieDetailArg(movieId, language)
```

จากนั้น watch:

```dart
movieDetailProvider(...)
```

UI map state ด้วย `AsyncValue.when()`

เมื่อโหลดสำเร็จ `_content()` แสดง:

- backdrop
- title
- rating/year/runtime chips
- genres
- rating distribution chart
- budget/revenue/vote count/language
- overview
- cast
- YouTube trailer
- Watchlist actions
- Similar Movies

ปุ่ม Add to Watchlist เปิด modal เพื่อสร้าง `WatchlistItem`

ปุ่ม Watched บันทึกสถานะผ่าน `watchlistControllerProvider.notifier`

การ generate local id ใช้ `Uuid`

### จุดที่ควรพัฒนาต่อ

Cast UI ปัจจุบันยังแสดง generic person icon แม้ model รองรับ `profilePath` แล้ว และ Similar Movies card ปัจจุบันยังไม่มี navigation tap ไป detail ของหนัง similar

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Detail page เป็นจุดเชื่อม remote detail data กับ local user action โดยข้อมูลหนังมาจาก Movie provider ส่วนการบันทึกสถานะส่งไป Watchlist controller

---

## 15. Watchlist Persistence

### `lib/features/watchlist/domain/watchlist_item.dart`

`WatchlistItem` เป็น local domain model

ข้อมูลสำคัญ:

```text
id
movieId
title
posterPath
backdropPath
status
personalRating
addedAt
watchedAt
notes
runtimeMinutes
genre
```

`toMap()` และ `fromMap()` ทำ serialization เป็น JSON-compatible map สำหรับ Hive

เหตุผลที่ไม่ใช้ generated Hive adapter ใน demo นี้คือช่วยลด code generation และ migration overhead แต่แลกกับ type safety ที่น้อยกว่า typed Hive object

### `lib/features/watchlist/data/watchlist_local_data_source.dart`

มี operation หลัก:

```text
getAll()
save()
delete()
```

`getAll()` sort `addedAt` ใหม่ไปเก่า ก่อนคืนค่าให้ UI

### `lib/features/watchlist/presentation/watchlist_controller.dart`

`WatchlistController` เป็น Riverpod `Notifier<List<WatchlistItem>>`

`build()` โหลด initial state จาก Hive

เมื่อ `save()` หรือ `delete()` สำเร็จ จะอ่าน `getAll()` ใหม่แล้ว assign ให้ `state`

ทำให้ widget ที่ `ref.watch(watchlistControllerProvider)` rebuild อัตโนมัติ

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> Hive เป็น persistence mechanism ส่วน `WatchlistController` เป็น observable state owner ของ presentation ทั้งสองส่วนแยกกัน ทำให้ persistence test และ controller test ทำได้แยกอิสระ

---

## 16. Watchlist Statistics

### `lib/features/watchlist/presentation/watchlist_page.dart`

หน้า Watchlist derive statistics จากรายการที่มีสถานะ `watched`

คำนวณ:

```text
Total Movies Watched
Total Hours
Average Rating
Favorite Genre
```

ตัวอย่าง Total Hours:

```text
sum(runtimeMinutes) / 60
```

Average Rating จะใช้เฉพาะ watched items ที่มี `personalRating`

Favorite Genre นับ frequency แล้ว sort จากมากไปน้อย

นี่เป็น derived UI state จึงยังคำนวณใน widget โดยตรงได้สำหรับ data volume ขนาดเล็ก แต่ถ้า logic ซับซ้อนขึ้นควรย้ายเป็น selector/provider หรือ domain service เพื่อให้ test แยกง่ายขึ้น

---

## 17. Localization

Source of truth คือ:

```text
assets/langs/langs.csv
```

รองรับ:

```text
key,en,th
```

UI เรียกข้อความผ่าน:

```dart
'searchHint'.tr()
```

และ placeholder ใช้ named args เช่น:

```dart
'welcome'.tr(namedArgs: {'name': 'Dexter'})
```

TMDB language code ถูกแปลงจาก app locale ผ่าน `apiLanguage()`

### Localization Test

`test/localization/localization_csv_test.dart` ตรวจ:

- file exists
- header เป็น `key,en,th`
- ทุก row มี 3 columns
- ไม่มี blank value
- key ไม่ซ้ำ
- normalize LF/CRLF ก่อน parse

Test นี้ป้องกัน regression ที่เคยทำให้ CSV loader อ่านข้อมูลผิดและกระทบ startup

### สรุปสั้น ๆ สำหรับ Code Walkthrough

> CSV เป็น single source of truth ของข้อความ UI และมี structural test เพื่อจับ malformed localization file ตั้งแต่ test phase แทนที่จะพบตอน runtime

---

## 18. Testing Strategy

Test suite ถูกแบ่งตาม responsibility

### Model / Mapping Tests

ตรวจ JSON → Domain mapping และ default values

```text
test/features/movies/data/models/movie_model_test.dart
```

### Repository Tests

ตรวจ remote success และ mock fallback policy

```text
test/features/movies/data/movie_repository_impl_test.dart
```

### Network Tests

ตรวจ 429 retry behavior

```text
test/core/network/rate_limit_interceptor_test.dart
```

### Persistence Tests

ตรวจ Hive data source save/delete/sort

```text
test/features/watchlist/data/watchlist_local_data_source_test.dart
```

### Riverpod Controller Tests

ตรวจ initial state และ state refresh หลัง save/delete

```text
test/features/watchlist/presentation/watchlist_controller_test.dart
```

### Localization Validation

```text
test/localization/localization_csv_test.dart
```

### Widget Tests

ตรวจ shared components เช่น `ClayCard` และ poster fallback

```text
test/widgets/
```

### Golden Tests

ตรวจ visual regression ของ Cinematic Dark components

```text
test/goldens/
```

Golden test ถูกแยกออกจาก default run เพื่อไม่ให้ test suite ปกติ fail ก่อนมี committed baseline

สร้าง/update baseline ด้วย:

```bash
make golden-update
```

ตรวจ baseline ด้วย:

```bash
make golden
```

รายละเอียดเพิ่มเติมดู `docs/TESTING.md`

---

## 19. Makefile Workflow

คำสั่งหลัก:

```bash
make get
make format
make format-check
make analyze
make test
make test-unit
make test-widget
make golden-update
make golden
make coverage
make check
```

Workflow แนะนำก่อน commit:

```bash
make format
make check
```

`make check` ทำ:

```text
format-check
    ↓
analyze
    ↓
test
```

Golden test ต้องรันแยก เพราะ baseline images เป็น visual artifact ที่ควร update โดยตั้งใจเท่านั้น

---

## 20. Known Limitations / Technical Debt

สิ่งที่ควรทราบจาก implementation ปัจจุบัน:

1. `AppTheme.light` ใช้ dark theme จริง ชื่อควรถูกปรับให้ตรงกับ behavior
2. Repository fallback จับ exception ทุกชนิด ทำให้ production diagnostics ไม่ละเอียด
3. Home Watch Stats ยังเป็น static demo data
4. Search ยังไม่มี debounce/cancellation/latest-request-wins
5. Cast avatar ยังไม่ได้ render `profilePath`
6. Similar Movies ยังไม่มี tap navigation ไป detail
7. Watchlist statistics อยู่ใน widget และอาจย้ายเป็น provider/domain logic เมื่อซับซ้อนขึ้น
8. ไม่มี authentication หรือ cloud sync ข้อมูล Watchlist เป็น local-only
9. Golden baseline ต้อง generate และ commit จาก environment ที่ใช้ Flutter จริง

---

# End-to-End Flow สรุป

## เปิด Home

```text
HomePage
  ↓ ref.watch
trendingProvider(language)
  ↓
movieRepositoryProvider
  ↓
MovieRepositoryImpl
  ↓
TmdbRemoteDataSource
  ↓
Dio + RateLimitInterceptor
  ↓
TMDB
  ↓
MovieModel.fromJson
  ↓
List<Movie>
  ↓
AsyncValue<List<Movie>>
  ↓
Home UI
```

ถ้า TMDB fail:

```text
TMDB exception
  ↓
MovieRepositoryImpl._fallback()
  ↓
mockMovies
  ↓
Home UI ยังคงแสดงผลได้
```

## เพิ่มหนังเข้า Watchlist

```text
MovieDetailPage
  ↓
สร้าง WatchlistItem
  ↓
WatchlistController.save()
  ↓
WatchlistLocalDataSource.save()
  ↓
Hive Box
  ↓
Controller โหลด getAll() ใหม่
  ↓
state เปลี่ยน
  ↓
Home / Watchlist ที่ watch provider rebuild
```

---

# สรุปสำหรับ Reviewer

โปรเจกต์นี้เน้น separation of concerns ที่ชัดเจนโดยไม่เพิ่ม abstraction เกินความจำเป็นสำหรับ demo app:

- Dio และ retry logic อยู่ใน Network layer
- TMDB endpoint knowledge อยู่ใน Remote Data Source
- JSON normalization อยู่ใน Model mapper
- fallback policy อยู่ใน Repository
- state/dependency composition อยู่ใน Riverpod
- persistence อยู่ใน Hive Data Source
- reusable visual rules อยู่ใน Shared Widgets และ Theme
- critical behavior ถูกแยกทดสอบด้วย unit, controller, persistence, widget, localization และ golden tests

แนวทางนี้ทำให้สามารถเปลี่ยน API implementation, เพิ่ม backend sync, ขยาย test coverage หรือย้าย derived logic ออกจาก UI ได้โดยไม่ต้อง rewrite โครงสร้างหลักของแอป
