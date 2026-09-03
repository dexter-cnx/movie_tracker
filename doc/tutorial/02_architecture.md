# 02 — Architecture, Domain และ Dependency Flow

บทนี้อธิบายว่าทำไม Popcorn Movie Tracker ใช้ lightweight Clean Architecture แทนการวางทุกอย่างไว้ใน Widget หรือสร้าง layer จำนวนมากเกินความจำเป็น

## 1. เป้าหมายของ Architecture

เราต้องการให้ระบบตอบคำถามเหล่านี้ได้ง่าย:

- UI เปลี่ยนโดยไม่กระทบ network ได้ไหม
- TMDB API เปลี่ยน shape แล้วแก้ที่จุดเดียวได้ไหม
- สลับ remote data เป็น mock/cache ได้ไหม
- test controller โดยไม่เรียก API จริงได้ไหม
- error จาก Dio หลุดขึ้น UI หรือไม่

Architecture ปลายทาง:

```text
Presentation
    ↓
Domain contract
    ↓
Data implementation
    ↓
Remote / Local source
```

ในโปรเจกต์นี้ Riverpod ทำหน้าที่ composition root เชื่อม implementation เข้าหากัน

## 2. Domain Entity

สร้าง `Movie` ให้เป็นข้อมูลที่ UI ต้องการจริง ไม่ใช่สำเนา JSON จาก TMDB

ตัวอย่างแนวคิด:

```dart
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    this.posterPath,
    this.backdropPath,
    this.runtime,
  });

  final int id;
  final String title;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final String? posterPath;
  final String? backdropPath;
  final int? runtime;
}
```

Domain entity ไม่ควร import:

```text
Dio
Retrofit
Hive
Flutter Widget
```

เพราะ domain ควรอยู่รอดแม้ technology ด้านนอกเปลี่ยน

## 3. Repository Contract

สร้าง interface เช่น:

```dart
abstract interface class MovieRepository {
  Future<List<Movie>> getTrending(String language);
  Future<Movie> getDetails(int id, String language);
  Future<PagedMovies> searchPage(
    String query,
    String language,
    int page,
  );
}
```

Presentation รู้จักแค่ contract นี้

ข้อดีคือ test สามารถใช้ fake/mock implementation ได้โดยไม่ต้องสร้าง Dio instance

## 4. Repository Implementation

Data layer เป็นผู้ตัดสินใจว่า data มาจากไหน

```text
MovieRepositoryImpl
 ├── TmdbRemoteDataSource
 └── MovieCacheLocalDataSource
```

เช่น trending:

```text
read cache
 ↓
fresh?
 ├── yes → return cache
 └── no → call network
             ↓
          success?
          ├── yes → save cache → return
          └── no → stale cache / fallback
```

จุดสำคัญคือ UI ไม่ต้องรู้ว่าข้อมูลมาจาก network หรือ cache

## 5. DTO ไม่ใช่ Domain Entity

เมื่อใช้ Retrofit + Freezed ให้มี DTO แยก เช่น:

```text
TmdbMovieDto
TmdbMoviePageDto
TmdbGenreDto
TmdbCreditsDto
```

แล้ว map:

```dart
Movie toDomain() {
  return Movie(
    id: id,
    title: title.trim().isEmpty ? 'Untitled' : title.trim(),
    overview: overview,
    releaseDate: releaseDate,
    voteAverage: voteAverage,
    posterPath: posterPath,
    backdropPath: backdropPath,
  );
}
```

ข้อดีคือ JSON key เช่น `poster_path` ไม่แพร่เข้า domain และ presentation

## 6. Typed Failure

ไม่ควรให้ UI เช็ก:

```dart
if (error is DioException && error.response?.statusCode == 429) ...
```

ให้ Data/Repository map เป็น application failure:

```text
NetworkFailure
TimeoutFailure
UnauthorizedFailure
RateLimitFailure
ServerFailure
ParsingFailure
UnknownFailure
```

Presentation จึงรู้ semantics ของแอป ไม่ต้องรู้ library implementation

## 7. Riverpod เป็น Composition Root

ตัวอย่าง dependency flow:

```dart
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(
    TmdbRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(movieCacheDataSourceProvider),
  );
});
```

จากนั้น feature provider ใช้ repository:

```dart
final trendingProvider = FutureProvider.family<List<Movie>, String>(
  (ref, language) =>
      ref.watch(movieRepositoryProvider).getTrending(language),
);
```

ข้อดีคือ constructor ของ class ยังเป็น Dart ปกติ ไม่ผูก class ทั้งระบบเข้ากับ Riverpod

## 8. ทำไมไม่มี UseCase ทุก operation

ในโปรเจกต์นี้ operation เช่น:

```text
getTrending
getDetails
getGenres
```

ส่วนใหญ่เป็น orchestration บาง ๆ ระหว่าง UI กับ repository หากสร้าง:

```text
GetTrendingUseCase
GetMovieDetailUseCase
GetGenresUseCase
```

แต่ไม่มี business rule เพิ่ม จะกลายเป็น pass-through boilerplate

ควรเพิ่ม UseCase เมื่อมี rule จริง เช่น:

```text
GeneratePersonalRecommendation
CalculateWatchStatistics
SyncOfflineWatchlist
```

## 9. Rule สำหรับ dependency direction

จำง่าย ๆ:

```text
Presentation → Domain ← Data
```

Domain ไม่ import Data

Data สามารถ import Domain เพื่อ implement contract และ map DTO เป็น entity

Presentation ไม่ควร import DTO

## 10. Exercise

ลองสร้าง feature เล็กชื่อ `favorites` โดยมี:

```text
features/favorites/domain/favorite_repository.dart
features/favorites/data/favorite_repository_impl.dart
features/favorites/presentation/favorite_controller.dart
```

จากนั้นตอบให้ได้ว่า:

1. Hive ควรอยู่ layer ไหน
2. Widget ควรรู้ key ที่เก็บใน Hive หรือไม่
3. Controller ควรรับ `Box` โดยตรงหรือรับ repository

คำตอบที่ architecture ปัจจุบันต้องการคือ:

```text
Hive → data layer
Widget → ไม่ควรรู้ storage detail
Controller → depend on repository/domain-facing abstraction
```
