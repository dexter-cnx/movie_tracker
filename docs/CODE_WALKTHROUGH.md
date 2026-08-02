# Code Walkthrough — Popcorn Movie Tracker & Watchlist

เอกสารนี้อธิบาย source code ของ branch `feat/production-phase-1` แบบ file-by-file และ flow-by-flow สำหรับใช้ review architecture, เตรียมสัมภาษณ์งาน และอธิบายเหตุผลเชิงวิศวกรรมของระบบ

เนื้อหาครอบคลุมตั้งแต่ application startup, dependency composition, navigation, REST API, JSON mapping, retry, typed failures, Hive cache, stale fallback, Riverpod state, responsive layout ที่ตัดสินใจจากอัตราส่วนหน้าจอ, Profile/Settings, Watchlist, localization, unit/widget/golden/integration tests และ GitHub Actions CI

> เอกสารนี้อธิบาย implementation ปัจจุบันตาม source จริง ไม่ได้อ้างว่าเป็น Clean Architecture เต็มรูปแบบทุกจุด โปรเจกต์ใช้แนวทาง lightweight และจงใจลด abstraction บางส่วนเพื่อไม่ให้ demo application มี boilerplate มากเกินไป

---

# 1. ภาพรวมระบบ

Popcorn เป็นแอป Flutter สำหรับ:

- สำรวจภาพยนตร์จาก TMDB
- แสดง Trending, Popular, Top Rated, Upcoming และ Now Playing
- ค้นหาภาพยนตร์และกรองตาม Genre
- ดูรายละเอียดภาพยนตร์, Cast, Trailer และ Similar Movies
- บันทึก Want to Watch, Watched และ Favorite ลง Hive
- เก็บ Personal Rating, Notes และ Watched Date
- สร้าง Profile และตั้งค่าภาษา
- ใช้งานข้อมูลจาก cache เมื่อ network ไม่เสถียร
- fallback เป็น mock data เมื่อไม่มีทั้ง network และ cache

โครงสร้างข้อมูลหลัก:

```text
Flutter UI
    ↓
Riverpod Provider / Controller
    ↓
Domain Repository Contract
    ↓
Repository Implementation
    ↓
Remote Data Source / Local Data Source
    ↓
Dio / Hive
    ↓
TMDB API / Device Storage
```

ระบบแบ่ง concern ออกเป็น:

```text
core/
  network, errors, layout, theme

features/movies/
  data, domain, presentation

features/watchlist/
  data, domain, presentation

features/profile/
  data, domain, presentation

features/home, search, movie_detail, calendar/
  presentation screens

shared/widgets/
  reusable UI components
```

---

# 2. Application Startup

## ไฟล์: `lib/main.dart`

`main()` เป็น composition root ระดับ application มีหน้าที่ initialize dependency ที่ต้องพร้อมก่อนสร้าง widget tree

ลำดับการทำงาน:

```text
WidgetsFlutterBinding.ensureInitialized()
        ↓
EasyLocalization.ensureInitialized()
        ↓
dotenv.load('assets/.env')
        ↓
Hive.initFlutter()
        ↓
เปิด Hive boxes พร้อมกัน
        ↓
ProviderScope
        ↓
EasyLocalization
        ↓
PopcornApp
```

Hive boxes ที่เปิดใน Phase 1:

```text
watchlist_items
user_preferences
movie_cache
```

การใช้ `Future.wait()` ทำให้เปิด boxes ที่ไม่ขึ้นต่อกันพร้อมกัน แทนการ await ทีละ box

เหตุผลที่ต้องเปิด Hive ก่อน `runApp()`:

- Provider ของ Watchlist ใช้ `Hive.box<Map>()`
- Provider ของ Profile ใช้ preferences box
- Movie Repository ใช้ cache box
- หาก box ยังไม่เปิด การสร้าง provider อาจ throw ตั้งแต่หน้าแรก

`ProviderScope` เป็น root container ของ Riverpod ส่วน `EasyLocalization` เป็น root localization scope

สิ่งที่ app startup ยังควรพัฒนาต่อใน production:

- แยก bootstrap error screen
- รองรับ `.env` ที่ไม่มีไฟล์โดยไม่ crash
- global error reporting
- migration version ของ Hive
- startup performance trace

---

# 3. Application Routing

## ไฟล์: `lib/app.dart`

แอปใช้ `GoRouter` และ `ShellRoute`

เส้นทางหลัก:

```text
/
/explore
/watchlist
/profile
/calendar
/movie/:id
```

Main navigation routes อยู่ภายใน `ShellRoute` เพื่อแชร์ `AppShell`

```text
ShellRoute
 ├── Home
 ├── Explore
 ├── Watchlist
 └── Profile
```

`/calendar` และ `/movie/:id` เป็นเส้นทางที่เปิดเป็นหน้าระดับบน ทำให้ไม่ต้องแสดง bottom navigation ในทุกกรณี

Movie Detail รับ ID จาก path parameter:

```dart
movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0
```

จุดแข็ง:

- Deep-link-friendly route
- Shell navigation ไม่ผูกกับแต่ละ page
- Detail page แยกจาก main tabs
- route สามารถทดสอบแยกได้

จุดที่ควรพัฒนาต่อ:

- invalid movie ID route
- typed route generation
- authentication redirect
- route restoration

---

# 4. App Shell และ Bottom Navigation

## ไฟล์: `lib/shared/widgets/app_shell.dart`

`AppShell` ทำหน้าที่:

- ครอบ page ปัจจุบันด้วย `Scaffold`
- แสดง bottom navigation
- คำนวณ selected index จาก URI
- route ไป Home, Explore, Watchlist และ Profile
- แสดง Floating Action Button สำหรับเปิด Search

การเลือก tab ไม่ใช้ local index state แต่ derive จาก route location จึงลดปัญหา tab state กับ URL ไม่ตรงกัน

```text
URI ปัจจุบัน
   ↓
_index(location)
   ↓
selected bottom-navigation item
```

แนวทางนี้เหมาะกับ declarative navigation มากกว่าการเก็บ selected index แยกใน StatefulWidget

---

# 5. Theme และ Design System

## ไฟล์: `lib/core/theme/app_theme.dart`

`AppColors` เป็น semantic tokens เช่น:

```text
background
surface
card
cardAlt
text
secondary
muted
divider
orange
green
button
onButton
```

ข้อดีของ semantic token:

- ลด hard-coded color ใน screen
- เปลี่ยน visual direction จากจุดกลาง
- Golden test มีความเสถียรกว่า
- รองรับ theme variant ในอนาคต

โปรเจกต์ใช้ Cinematic Dark UI:

- dark background
- high-contrast white text
- orange accent
- rounded cards/posters
- floating navigation
- soft borders/shadows

Technical debt ปัจจุบันคือ property ชื่อ `AppTheme.light` แต่ implementation เป็น dark theme ควร rename เป็น `AppTheme.dark` หรือ `AppTheme.cinematicDark`

---

# 6. Shared Widgets

## ไฟล์: `lib/shared/widgets/clay_widgets.dart`

Reusable components หลัก:

### `ClayCard`

รวม decoration, border radius, padding และ shadow ไว้จุดเดียว

### `ClayIconButton`

สร้าง icon action ที่มี visual language เดียวกับ card

### `Poster`

รับ:

```text
posterPath
title
width
height
```

กรณีมี TMDB path จะสร้าง URL รูป

```text
https://image.tmdb.org/t/p/w500{posterPath}
```

fallback behavior:

```text
posterPath ไม่มี
    ↓
แสดง placeholder

network image error
    ↓
แสดง movie icon / fallback content
```

Widget เหล่านี้มีทั้ง widget tests และ golden test เพื่อป้องกัน visual regression

---

# 7. Dio Configuration

## ไฟล์: `lib/core/network/dio_provider.dart`

`dioProvider` สร้าง Dio instance กลาง

ค่าหลัก:

```text
baseUrl        https://api.themoviedb.org/3
connectTimeout 10 seconds
receiveTimeout 12 seconds
accept         application/json
```

Token อ่านจาก:

```dart
dotenv.env['TMDB_BEARER_TOKEN']
```

และเพิ่ม header เมื่อ token ไม่ว่าง:

```http
Authorization: Bearer <token>
```

การสร้าง Dio ผ่าน Riverpod ช่วยให้:

- override ใน test ได้
- ไม่สร้าง instance ซ้ำตาม screen
- interceptor ใช้ร่วมกัน
- dependency chain มองเห็นได้ชัด

TMDB token ในโปรเจกต์นี้เป็น application credential ไม่ใช่ user authentication token ดังนั้นยังไม่ถือเป็น implementation ของ login/refresh-token flow

---

# 8. HTTP 429 Retry

## ไฟล์: `lib/core/network/rate_limit_interceptor.dart`

`RateLimitInterceptor` ดัก `DioException` ที่ status code เป็น 429

Flow:

```text
Request fail
   ↓
status == 429 ?
   ├── No  → handler.next(error)
   └── Yes
        ↓
อ่าน retryCount จาก RequestOptions.extra
        ↓
retryCount >= maxRetries ?
   ├── Yes → ส่ง error ต่อ
   └── No
        ↓
อ่าน Retry-After
        ↓
ถ้าไม่มี ใช้ exponential delay
        ↓
เพิ่ม retryCount
        ↓
dio.fetch(requestOptions)
```

Delay โดยประมาณ:

```text
1 second
2 seconds
4 seconds
```

จุดสำคัญคือ retry count ถูกเก็บใน request metadata ทำให้แต่ละ request มี state ของตัวเอง

Tests ครอบคลุม:

- non-429 ไม่ retry
- 429 retry แล้วสำเร็จ
- retry ถึง limit แล้วหยุด

---

# 9. Typed Failure Mapping

## ไฟล์: `lib/core/errors/app_failure.dart`

Phase 1 เพิ่ม failure hierarchy เพื่อไม่ให้ UI ต้องวิเคราะห์ `DioException` โดยตรง

Failure types:

```text
NetworkFailure
TimeoutFailure
UnauthorizedFailure
RateLimitFailure
ServerFailure
ParsingFailure
UnknownFailure
```

Mapper แปลง technical exception เป็น application-level error

ตัวอย่างแนวคิด:

```text
DioException.connectionTimeout
    ↓
TimeoutFailure

HTTP 401
    ↓
UnauthorizedFailure

HTTP 429
    ↓
RateLimitFailure

HTTP 500+
    ↓
ServerFailure
```

ประโยชน์:

- Presentation ไม่ขึ้นกับ Dio
- localized error message ทำได้ง่ายขึ้น
- test error state แบบ deterministic
- backend/client concern แยกชัดเจน

Phase 1 ยังไม่ได้ทำ global error reporter หรือ crash analytics

---

# 10. Movie Domain Entity

## ไฟล์: `lib/features/movies/domain/entities/movie.dart`

`Movie` เป็น entity ที่ UI และ repository contract ใช้ร่วมกัน

ข้อมูลสำคัญ:

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

`releaseYear` เป็น computed property ทำให้ UI ไม่ต้อง parse date ซ้ำ

`CastMember` แยกข้อมูล actor ออกจาก raw JSON

Domain entity ไม่ import Dio, Hive หรือ Flutter widget package

---

# 11. TMDB JSON Mapping

## ไฟล์: `lib/features/movies/data/models/movie_model.dart`

`MovieModel.fromJson()` เป็น anti-corruption boundary ระหว่าง external API shape กับ domain entity

หน้าที่:

- อ่าน primitive fields
- normalize missing/null values
- map genre IDs
- map genre objects
- map credits/cast
- เลือก YouTube Trailer/Teaser
- map similar movies

ตัวอย่าง default:

```text
missing id            → 0
missing title         → Untitled
missing overview      → empty string
missing vote_average  → 0
missing arrays        → empty list
```

UI จึงไม่ต้องตรวจ raw map หรือ cast type ซ้ำทุกหน้า

Tests ตรวจทั้ง valid JSON และ incomplete JSON

---

# 12. TMDB Remote Data Source

## ไฟล์: `lib/features/movies/data/tmdb_remote_data_source.dart`

Data Source เป็นชั้นเดียวที่รู้ endpoint และ query parameter ของ TMDB

Endpoints:

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

ทำให้ detail, cast, videos และ similar movies ถูกดึงใน request เดียว

Data Source ไม่ควรตัดสินใจว่าจะใช้ cache หรือ mock เพราะ policy นั้นเป็นหน้าที่ของ Repository

---

# 13. Hive Movie Cache

## ไฟล์: `lib/features/movies/data/movie_cache_local_data_source.dart`

`MovieCacheLocalDataSource` เก็บ response list เป็น `Box<Map>`

โครงสร้าง record:

```text
cache key
  ├── cachedAt
  └── items[]
```

`CachedMovieList` มี:

```dart
final List<Movie> movies;
final DateTime cachedAt;
```

และ method:

```dart
bool isFresh(Duration ttl, DateTime now)
```

Cache key แยกตาม use case และภาษา เช่น:

```text
trending:en-US
trending:th-TH
```

เหตุผลที่ต้องรวมภาษาใน key:

- title/overview จาก TMDB อาจ localized
- ห้ามนำ cache ภาษาอังกฤษไปแสดงแทนภาษาไทยโดยไม่ตั้งใจ

Serialization เก็บ Movie เป็น map และ rebuild entity ตอนอ่าน

Local data source คืน `null` เมื่อ:

- ไม่มี key
- schema ไม่ถูกต้อง
- date parse ไม่ได้
- item structure เสีย

แนวทางนี้ทำให้ corrupt cache ไม่ทำให้แอป crash แต่ repository จะไป network หรือ fallback ต่อ

---

# 14. Cache Policy ใน Repository

## ไฟล์: `lib/features/movies/data/movie_repository_impl.dart`

Phase 1 เปลี่ยนจาก mock fallback ตรง ๆ เป็น cache-aware policy

Flow หลัก:

```text
Repository request
      ↓
อ่าน cache
      ↓
cache fresh และไม่ได้ force refresh ?
   ├── Yes → คืน fresh cache
   └── No
        ↓
เรียก remote API
        ↓
สำเร็จ ?
   ├── Yes → เขียน cache → คืน network data
   └── No
        ↓
มี stale cache ?
   ├── Yes → คืน stale cache พร้อม failure metadata
   └── No  → คืน mock data พร้อม failure metadata
```

TTL เริ่มต้น:

```text
30 minutes
```

Repository inject `now` function ได้เพื่อให้ test cache expiry โดยไม่พึ่งเวลาจริง

Force refresh มีไว้สำหรับ:

- pull-to-refresh
- retry button
- QA validation
- bypass fresh cache เมื่อผู้ใช้ร้องขอข้อมูลใหม่

สิ่งที่ repository รับผิดชอบ:

- cache policy
- remote fallback policy
- source metadata
- failure mapping

สิ่งที่ repository ไม่ควรรับผิดชอบ:

- widget rendering
- localized message
- navigation

---

# 15. Movie Load Result Metadata

## ไฟล์: `lib/features/movies/domain/entities/movie_load_result.dart`

เพื่อให้ UI รู้ว่าข้อมูลมาจากไหน ระบบไม่ได้คืนเพียง `List<Movie>` แต่ใช้ result object

Data source metadata:

```text
network
freshCache
staleCache
mock
```

Result ประกอบด้วย:

```text
movies
source
failure (optional)
```

ตัวอย่าง:

```text
movies มีข้อมูล
source = staleCache
failure = TimeoutFailure
```

UI สามารถยังแสดง content พร้อม offline banner แทนการแทนทั้งหน้าด้วย error screen

นี่เป็นหลักการสำคัญของ resilient UX:

> data availability และ request success ไม่ใช่สถานะเดียวกันเสมอไป

---

# 16. Riverpod Providers

## ไฟล์: `lib/features/movies/presentation/movie_providers.dart`

Dependency composition:

```text
dioProvider
    ↓
TmdbRemoteDataSource
    ↓
MovieCacheLocalDataSource
    ↓
MovieRepositoryImpl
    ↓
movieRepositoryProvider
```

Providers หลัก:

```text
trendingResultProvider
trendingProvider
movieDetailProvider
genresProvider
```

`trendingResultProvider` expose metadata ครบ ส่วน compatibility provider สามารถ expose เฉพาะ movie list ให้ UI เดิม

`apiLanguage()` map locale:

```text
th → th-TH
อื่น ๆ → en-US
```

`MovieDetailArg` override equality/hashCode เพราะใช้เป็น family key

หากไม่มี equality ที่ถูกต้อง Riverpod อาจมอง argument ที่มีค่าเท่ากันเป็นคนละ request key

---

# 17. Home Screen Resilient UX

## ไฟล์: `lib/features/home/presentation/home_page.dart`

Home watch:

```text
trendingResultProvider(language)
watchlistControllerProvider
```

UI แยกสถานะ:

### Network / Fresh Cache

แสดง movie content ตามปกติ

### Stale Cache

แสดง content เดิมต่อ พร้อม banner ว่ากำลังใช้ cached data และมี Retry

### Mock Data

แสดง demo content พร้อม notice ชัดเจน

### No Usable Data

แสดง blocking error state พร้อม Retry

Retry ใช้ force-refresh path ไม่ใช่เพียง rebuild widget แบบเดิม

จุดนี้ดีกว่า silent fallback เพราะผู้ใช้รู้ความสดของข้อมูลโดยไม่เสีย content ที่ยังมีประโยชน์

Home ยังรวม Watchlist preview จาก local state

Watch Stats chart ปัจจุบันยังเป็น static demo data ไม่ได้ derive จาก watch history จริง

---

# 18. Search Error Handling

## ไฟล์: `lib/features/search/presentation/search_page.dart`

Search page ใช้ local state สำหรับ:

```text
selected genre
movie results
loading
failure
roulette result
```

Flow:

```text
query ว่าง
  → discoverByGenre

query มีข้อความ
  → search
```

เมื่อ request fail:

- ถ้ามี fallback result สามารถแสดงรายการได้
- ถ้าไม่มี usable result แสดง error card
- มี Retry action

ยังมี `mounted` guard ก่อน `setState()` หลัง async operation

สิ่งที่ยังไม่ได้ทำใน Phase 1:

- debounce
- Dio CancelToken
- latest-request-wins
- search pagination

---

# 19. Responsive Layout ด้วย Screen Ratio

## ไฟล์: `lib/core/layout/responsive_layout.dart`

ตามข้อกำหนด Phase 1 การเลือก layout **ไม่ใช้ absolute width breakpoint** แต่ใช้:

```text
ratio = screenWidth / screenHeight
```

Classification:

```text
ratio < 0.62          tallPortrait
0.62 <= ratio < 0.90 portrait
0.90 <= ratio < 1.35 balanced
ratio >= 1.35         wide
```

Grid policy:

```text
tallPortrait → 2 columns
portrait     → 3 columns
balanced     → 4 columns
wide         → 5 columns
```

Adaptive properties:

- grid columns
- horizontal padding
- card child aspect ratio
- section spacing
- stats grid

ใช้กับ:

```text
HomePage
SearchPage
WatchlistPage
```

ข้อดี:

- การหมุน device เปลี่ยน layout ตาม available shape
- phone/tablet ที่มี ratio ใกล้กันได้ composition เดียวกัน
- wide landscape ได้ density มากขึ้น

ข้อจำกัดที่ต้องเข้าใจ:

- ratio อย่างเดียวไม่รับประกัน physical space เพียงพอ
- หน้าจอเล็กและจอใหญ่มากที่ ratio เท่ากันจะได้ column count เท่ากัน
- production adaptive layout มักใช้ทั้ง ratio, constraints, text scale และ minimum card extent

โปรเจกต์ใช้ ratio ตาม requirement โดยตั้งใจ และมี test ยืนยันว่า layout ไม่ตัดสินใจจาก width เพียงค่าเดียว

---

# 20. Watchlist Domain และ Persistence

## ไฟล์: `lib/features/watchlist/domain/watchlist_item.dart`

`WatchlistItem` เก็บ:

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

Statuses:

```text
wantToWatch
watched
favorite
```

`toMap()` และ `fromMap()` ทำให้ model เก็บใน Hive `Box<Map>` ได้โดยไม่ใช้ generated adapter

ข้อดี:

- setup ง่าย
- schema อ่านได้ตรง
- test serialization ง่าย

ข้อเสีย:

- compile-time type safety ต่ำกว่า typed adapter
- migration ต้องดูแลเอง

## ไฟล์: `lib/features/watchlist/data/watchlist_local_data_source.dart`

Operations:

```text
getAll
save
delete
```

`getAll()` sort จาก `addedAt` ใหม่ไปเก่า

## ไฟล์: `lib/features/watchlist/presentation/watchlist_controller.dart`

Riverpod Notifier เป็น state owner

```text
build() → load initial Hive data
save()  → persist → reload → update state
delete()→ persist → reload → update state
```

UI ที่ watch provider จะ rebuild หลัง persistence สำเร็จ

---

# 21. Watchlist Screen และ Derived Statistics

## ไฟล์: `lib/features/watchlist/presentation/watchlist_page.dart`

คำนวณ:

```text
Total Movies Watched
Total Hours
Average Personal Rating
Favorite Genre
```

Total Hours:

```text
sum(runtimeMinutes) / 60
```

Average Rating ใช้เฉพาะ item ที่มี personal rating

Favorite Genre นับ frequency และเลือกค่ามากที่สุด

Responsive layout ใช้ ratio class สำหรับ:

- stats columns
- movie columns
- card aspect ratio
- horizontal padding

ปัจจุบัน derived statistics อยู่ใน widget เหมาะกับ data volume เล็ก แต่ควรย้ายเป็น provider/domain service หาก business rules ซับซ้อนขึ้น

---

# 22. Movie Detail และ Watchlist Flow

## ไฟล์: `lib/features/movie_detail/presentation/movie_detail_page.dart`

รับ `movieId` จาก router และ watch `movieDetailProvider`

สถานะ:

```text
loading → progress
error   → localized error
success → detail content
```

ข้อมูลที่แสดง:

- backdrop
- title
- rating
- release year
- runtime
- genres
- rating chart
- budget
- revenue
- vote count
- original language
- overview
- cast
- trailer
- similar movies

Add-to-Watchlist modal เก็บ:

- status
- personal rating
- notes
- watched date

เมื่อ Save:

```text
MovieDetailPage
    ↓
สร้าง WatchlistItem
    ↓
WatchlistController.save()
    ↓
WatchlistLocalDataSource.save()
    ↓
Hive
    ↓
reload state
```

Integration test ใช้ flow นี้เพื่อยืนยัน end-to-end behavior ระหว่าง UI, Riverpod และ Hive

---

# 23. Profile และ Settings

## ไฟล์: `lib/features/profile/domain/user_preferences.dart`

เก็บ:

```text
displayName
email
favoriteGenre
languageCode
notificationsEnabled
autoplayTrailers
```

มี default values, `copyWith`, `toMap()` และ `fromMap()`

## ไฟล์: `lib/features/profile/data/user_preferences_local_data_source.dart`

เก็บ preferences หนึ่ง record ใน Hive key `current`

```text
user_preferences box
    ↓
current
    ↓
UserPreferences map
```

## ไฟล์: `lib/features/profile/presentation/profile_controller.dart`

Controller รองรับ:

```text
updateProfile
setLanguage
setNotificationsEnabled
setAutoplayTrailers
```

ทุก operation update state และ persist ลง Hive

## ไฟล์: `lib/features/profile/presentation/profile_page.dart`

UI มี:

- profile card
- edit dialog
- language selector
- notification switch
- autoplay switch
- calendar shortcut
- about/version

การเปลี่ยนภาษา:

```text
เลือก locale
   ↓
context.setLocale()
   ↓
ProfileController.setLanguage()
   ↓
Hive persistence
```

Integration test ตรวจทั้ง profile update และ runtime locale change

Notification/Autoplay ใน Phase 1 เป็น persisted preference เท่านั้น ยังไม่ได้เชื่อม native notification scheduler หรือ actual trailer autoplay behavior

---

# 24. Localization

## ไฟล์: `assets/langs/langs.csv`

CSV เป็น single source of truth:

```csv
key,en,th
```

UI ใช้:

```dart
'key'.tr()
```

Named arguments:

```dart
'welcome'.tr(namedArgs: {'name': displayName})
```

Phase 1 เพิ่มข้อความสำหรับ:

- cache banner
- offline state
- retry
- profile/settings

## Test: `test/localization/localization_csv_test.dart`

ตรวจ:

- file exists
- header ถูกต้อง
- row มี 3 columns
- ไม่มี blank value
- key ไม่ซ้ำ
- normalize LF/CRLF

Test นี้ป้องกัน startup crash จาก malformed CSV

---

# 25. Unit Testing Strategy

## Model Tests

ตรวจ JSON mapping และ normalization

```text
test/features/movies/data/models/movie_model_test.dart
```

## Failure Tests

```text
test/core/errors/app_failure_test.dart
```

ตรวจ Dio error → typed failure

## Ratio Policy Tests

```text
test/core/layout/responsive_layout_test.dart
```

ตรวจ:

- ratio classifications
- grid columns
- same ratio / different size ให้ผลเดียวกัน
- boundary values

## Cache Data Source Tests

```text
test/features/movies/data/movie_cache_local_data_source_test.dart
```

ตรวจ:

- serialization round-trip
- timestamp
- freshness
- corrupt data fallback
- clear cache

## Cache Policy Tests

```text
test/features/movies/data/movie_cache_policy_test.dart
```

ตรวจ:

- fresh cache ไม่เรียก remote
- expired cache เรียก remote
- network success เขียน cache
- network fail ใช้ stale cache
- ไม่มี stale cache ใช้ mock
- force refresh bypass fresh cache

## Controller Tests

ตรวจ Watchlist และ Profile controller update/persistence

---

# 26. Widget Tests

Widget tests ครอบคลุม:

- shared cards/posters
- Profile page rendering
- Home offline/stale banner
- Retry action
- Watchlist ratio-responsive grid

Responsive widget test กำหนด `tester.view.physicalSize` แล้วตรวจจำนวน cell/layout behavior

ควร reset:

```dart
tester.view.resetPhysicalSize();
tester.view.resetDevicePixelRatio();
```

ใน teardown เพื่อไม่ให้ test ถัดไปได้รับ viewport เดิม

---

# 27. Golden Tests

## ไฟล์: `test/goldens/clay_components_golden_test.dart`

Golden test ตรวจ visual regression ของ Cinematic Dark components

Default suite skip golden ผ่าน compile-time flag:

```dart
const _runGoldens = bool.fromEnvironment('RUN_GOLDENS');
```

สร้าง/update baseline:

```bash
make golden-update
```

ตรวจ baseline:

```bash
make golden
```

Golden baseline ควร generate ใน environment ที่ทีมกำหนดร่วมกันเพื่อลด font/rendering differences

---

# 28. Integration Tests

## `integration_test/watchlist_flow_test.dart`

Flow:

```text
Launch app
→ Open Movie Detail
→ Add to Watchlist
→ Save
→ Navigate to Watchlist
→ Verify persisted movie/status
```

## `integration_test/profile_settings_flow_test.dart`

Flow:

```text
Launch app
→ Open Profile
→ Edit display name/email/genre
→ Save
→ Change language to Thai
→ Verify state and translated UI
```

Tests override dependencies/fake remote data เพื่อให้ deterministic และไม่ขึ้นกับ TMDB availability

รัน:

```bash
flutter devices
make integration DEVICE=<device-id>
```

Integration test ต้องใช้ emulator/simulator/device ไม่รวมใน host `flutter test` ปกติ

---

# 29. Makefile

Commands:

```bash
make help
make get
make clean
make format
make format-check
make analyze
make test
make test-unit
make test-widget
make golden
make golden-update
make integration DEVICE=<id>
make coverage
make check
make ci
```

Formatter ครอบคลุม:

```text
lib/
test/
integration_test/
```

Workflow ก่อน commit:

```bash
make format
make check
```

Full local validation:

```bash
make format
make check
make golden
make integration DEVICE=<device-id>
```

---

# 30. GitHub Actions CI

## ไฟล์: `.github/workflows/flutter_ci.yml`

Trigger:

```text
push main
pull_request main
```

Steps:

```text
Checkout
→ Setup Flutter stable
→ Create empty assets/.env when missing
→ flutter pub get
→ format check
→ flutter analyze
→ flutter test --coverage
→ upload lcov artifact
```

CI ไม่ใส่ real TMDB token และ test ไม่ควรพึ่ง external API

สิ่งที่ CI ยังไม่ได้ทำ:

- integration tests บน emulator
- golden tests
- coverage threshold
- release build
- dependency/security scan

---

# 31. End-to-End Flow: Trending Data

```text
HomePage
  ↓ ref.watch
trendingResultProvider(language)
  ↓
MovieRepositoryImpl.getTrendingResult()
  ↓
MovieCacheLocalDataSource.read(cacheKey)
  ↓
Fresh cache?
  ├── Yes → MovieLoadResult(freshCache)
  └── No
       ↓
TmdbRemoteDataSource.trending()
       ↓
Dio + RateLimitInterceptor
       ↓
TMDB
       ↓
MovieModel.fromJson()
       ↓
cache.write()
       ↓
MovieLoadResult(network)
       ↓
Home UI
```

เมื่อ network fail:

```text
Exception
  ↓
AppFailureMapper
  ↓
Stale cache exists?
  ├── Yes → stale data + failure + offline banner
  └── No  → mock data + failure + demo notice
```

---

# 32. End-to-End Flow: Profile Persistence

```text
ProfilePage
  ↓
ProfileController.updateProfile()
  ↓
UserPreferences.copyWith()
  ↓
UserPreferencesLocalDataSource.save()
  ↓
Hive user_preferences box
  ↓
Riverpod state update
  ↓
ProfilePage rebuild
```

เปลี่ยนภาษา:

```text
Language sheet
  ↓
context.setLocale(Locale)
  ↓
EasyLocalization rebuild
  ↓
ProfileController persists languageCode
```

---

# 33. End-to-End Flow: Watchlist

```text
MovieDetailPage
  ↓
WatchlistItem
  ↓
WatchlistController.save()
  ↓
WatchlistLocalDataSource.save()
  ↓
Hive watchlist_items
  ↓
Controller reloads getAll()
  ↓
Home and Watchlist rebuild
```

---

# 34. สิ่งที่ Phase 1 แสดงต่อผู้สัมภาษณ์ได้

Phase 1 ใช้เป็นหลักฐานสำหรับ:

- REST API integration
- JSON mapping
- Repository pattern
- Riverpod dependency injection/state management
- Hive local persistence
- real cache policy
- stale-data UX
- typed error handling
- timeout/rate-limit retry
- navigation
- runtime localization
- ratio-based adaptive UI
- unit/widget/golden/integration tests
- CI workflow
- technical documentation

---

# 35. Known Limitations หลัง Phase 1

1. ยังไม่มี user authentication และ refresh token
2. ยังไม่มี Flutter Secure Storage
3. Search ยังไม่มี debounce/cancellation/latest-request-wins
4. ยังไม่มี connectivity stream
5. ยังไม่มี pagination
6. ยังไม่มี crash reporting/analytics
7. ยังไม่มี app lifecycle handling ของ video
8. Notification toggle ยังไม่ schedule native notification
9. Autoplay preference ยังไม่ผูก YoutubePlayer behavior
10. Watch Stats ยังเป็น static data
11. ratio-only responsive policy มีข้อจำกัดบน device ต่างขนาดที่ ratio เท่ากัน
12. CI ยังไม่รัน integration/golden/release build
13. ยังไม่มี flavors/signing/release pipeline
14. ยังไม่มี coverage threshold

---

# 36. Reviewer Checklist

ก่อน merge:

```bash
make format
make check
make golden
flutter devices
make integration DEVICE=<device-id>
```

ตรวจด้วยตนเอง:

- ลบ/ปิด network แล้ว Home ใช้ stale cache
- ไม่มี cache แล้วเห็น mock-data notice
- Retry เรียก force refresh
- เปลี่ยนภาษาแล้ว UI เปลี่ยนและจำค่าได้
- เพิ่ม Watchlist แล้ว restart app ข้อมูลยังอยู่
- หมุน portrait/landscape แล้ว grid เปลี่ยนตาม ratio
- test และ CI ผ่าน

---

# 37. สรุป Architecture Decision

โปรเจกต์เลือก lightweight Clean Architecture เพราะต้องการรักษา boundary ที่สำคัญโดยไม่สร้าง class ซ้ำเกินขนาดระบบ

Boundary ที่รักษาไว้:

```text
UI ไม่เรียก Dio โดยตรง
UI ไม่อ่าน Hive โดยตรง
Remote Data Source ไม่ตัดสิน cache policy
Local Data Source ไม่ตัดสิน UI state
Repository ไม่ render widget
Domain entity ไม่ขึ้นกับ Flutter UI
```

Riverpod ทำหน้าที่สองส่วน:

```text
Dependency composition
State exposure
```

Repository เป็น policy boundary สำหรับ:

```text
network
cache freshness
stale fallback
mock fallback
failure metadata
```

ผลลัพธ์คือ source สามารถทดสอบแยกชั้นและอธิบาย production concern ได้ชัดเจนกว่าการให้ screen เรียก API/Hive โดยตรง
