# 04 — TMDB API ด้วย Dio + Retrofit + Freezed

บทนี้เป็นแกนของ data layer ปัจจุบัน โดยเปลี่ยนจาก `dio.get<Map<String, dynamic>>()` และ manual JSON mapping ไปเป็น typed client + generated serialization

## 1. ทำไมต้องใช้ทั้ง Dio, Retrofit และ Freezed

หน้าที่แต่ละตัวไม่ซ้ำกัน:

```text
Dio
  → HTTP transport, timeout, interceptor, retry, header

Retrofit
  → ประกาศ endpoint แบบ typed และ generate implementation

Freezed + json_serializable
  → immutable DTO, equality, copyWith และ JSON serialization
```

โครงสร้าง:

```text
TmdbRemoteDataSource
    ↓
TmdbApiClient (Retrofit)
    ↓
Dio
    ↓
TMDB
```

และ response:

```text
JSON
 ↓
TmdbMovieDto
 ↓
toDomain()
 ↓
Movie
```

## 2. ตั้งค่า Dio

สร้าง `lib/core/network/dio_provider.dart`

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Authorization': 'Bearer $tmdbToken',
        'Accept': 'application/json',
      },
    ),
  );

  return dio;
});
```

Production project ควรมี interceptor สำหรับ logging/redaction และ 429 retry แยกจาก endpoint declaration

## 3. สร้าง Retrofit Client

ไฟล์:

```text
lib/features/movies/data/tmdb_api_client.dart
```

```dart
@RestApi()
abstract class TmdbApiClient {
  factory TmdbApiClient(Dio dio, {String? baseUrl}) = _TmdbApiClient;

  @GET('/movie/popular')
  Future<TmdbMoviePageDto> popular(
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
    @Query('page') int page,
  );

  @GET('/movie/{id}')
  Future<TmdbMovieDto> details(
    @Path('id') int id,
    @Query('language') String language,
    @Query('include_image_language') String imageLanguages,
    @Query('include_video_language') String videoLanguages,
    @Query('append_to_response') String appendToResponse,
  );
}
```

ข้อดีคือ endpoint, path parameter และ query parameter อ่านจาก declaration ได้ทันที

## 4. Freezed DTO

สร้าง:

```text
lib/features/movies/data/models/tmdb_dto.dart
```

ตัวอย่าง page response:

```dart
@freezed
class TmdbMoviePageDto with _$TmdbMoviePageDto {
  const factory TmdbMoviePageDto({
    @Default(<TmdbMovieDto>[]) List<TmdbMovieDto> results,
    @Default(1) int page,
    @JsonKey(name: 'total_pages') @Default(1) int totalPages,
  }) = _TmdbMoviePageDto;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbMoviePageDtoFromJson(json);
}
```

Movie DTO:

```dart
@freezed
class TmdbMovieDto with _$TmdbMovieDto {
  const TmdbMovieDto._();

  const factory TmdbMovieDto({
    @Default(0) int id,
    @Default('') String title,
    @Default('') String overview,
    @JsonKey(name: 'poster_path') String? posterPath,
    @JsonKey(name: 'backdrop_path') String? backdropPath,
    @JsonKey(name: 'release_date') @Default('') String releaseDate,
    @JsonKey(name: 'vote_average') @Default(0) double voteAverage,
  }) = _TmdbMovieDto;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) =>
      _$TmdbMovieDtoFromJson(json);
}
```

## 5. Nested response ของ Movie Detail

TMDB detail ใช้:

```text
append_to_response=credits,videos,similar
```

ดังนั้น DTO ต้องมี nested object:

```dart
TmdbCreditsDto? credits,
TmdbVideosDto? videos,
TmdbMoviePageDto? similar,
```

ข้อดีคือ detail screen ใช้ request เดียวแทน 3–4 request แยก

## 6. Map DTO → Domain

ใส่ method ใน DTO extension/private constructor:

```dart
Movie toDomain() {
  return Movie(
    id: id,
    title: title.trim().isEmpty ? 'Untitled' : title.trim(),
    overview: overview,
    posterPath: posterPath,
    backdropPath: backdropPath,
    releaseDate: releaseDate,
    voteAverage: voteAverage,
  );
}
```

สำหรับ trailer:

```text
videos.results
  ↓
site == YouTube
  ↓
type == Trailer || Teaser
  ↓
เลือก key แรก
```

สำหรับ cast จำกัดเช่น 12 คน เพื่อไม่ส่งข้อมูลเกินที่ UI ใช้

## 7. Remote Data Source

`TmdbRemoteDataSource` ไม่ parse JSON แล้ว แต่ orchestration ผ่าน typed client

```dart
class TmdbRemoteDataSource {
  TmdbRemoteDataSource(Dio dio) : api = TmdbApiClient(dio);

  TmdbRemoteDataSource.withClient(this.api);

  final TmdbApiClient api;

  Future<List<Movie>> trending(String language) async {
    final page = await api.trending(
      language,
      'th,en,null',
      'th,en',
    );

    return page.results.map((dto) => dto.toDomain()).toList();
  }
}
```

`withClient()` มีประโยชน์ต่อ unit test เพราะสามารถ mock API client โดยไม่ต้อง mock Dio transport

## 8. Code Generation

รัน:

```bash
dart run build_runner build --delete-conflicting-outputs
```

หรือในโปรเจกต์:

```bash
make codegen
```

watch mode:

```bash
make codegen-watch
```

Generated files เช่น:

```text
tmdb_api_client.g.dart
tmdb_dto.freezed.dart
tmdb_dto.g.dart
```

โปรเจกต์เลือก regenerate ใน CI ดังนั้น generated file ถูก ignore ได้ แต่ต้องมั่นใจว่า CI รัน codegen ก่อน analyze/test

## 9. Search Pagination

Retrofit endpoint:

```dart
@GET('/search/movie')
Future<TmdbMoviePageDto> search(
  @Query('query') String query,
  @Query('language') String language,
  @Query('include_image_language') String imageLanguages,
  @Query('include_video_language') String videoLanguages,
  @Query('page') int page,
);
```

แล้ว map:

```dart
return PagedMovies(
  items: response.results.map((e) => e.toDomain()).toList(),
  page: response.page,
  totalPages: response.totalPages,
);
```

## 10. Error boundary

Retrofit/Dio exception ยังต้องถูก map เป็น `AppFailure` ที่ repository boundary

อย่าให้ UI depend on `DioException`

## 11. Test DTO โดยไม่เรียก API

ตัวอย่าง:

```dart
test('maps TMDB detail response to domain movie', () {
  final dto = TmdbMovieDto.fromJson({
    'id': 10,
    'title': 'Example',
    'vote_average': 8.2,
  });

  final movie = dto.toDomain();

  expect(movie.id, 10);
  expect(movie.title, 'Example');
  expect(movie.voteAverage, 8.2);
});
```

ควร test missing/null values ด้วย เพื่อให้ mapping resilient ต่อ API response ที่ไม่สมบูรณ์

## เป้าหมายหลังจบบท

Network layer ควรไม่มี manual parsing กระจายหลาย endpoint และ presentation ไม่ควรเห็น JSON key จาก TMDB เลย
