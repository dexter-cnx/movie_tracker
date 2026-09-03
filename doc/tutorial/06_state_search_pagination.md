# 06 — Riverpod, Search, Debounce และ Pagination

บทนี้ต่อจาก repository layer แล้วนำข้อมูลขึ้น UI ด้วย Riverpod พร้อมทำ search-as-you-type ที่ไม่ยิง request ถี่เกินไป และป้องกัน response เก่าทับ response ใหม่

## 1. Provider สำหรับ Repository

Riverpod ใช้เป็น composition root:

```dart
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(
    TmdbRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(movieCacheDataSourceProvider),
  );
});
```

UI ไม่ควรสร้าง repository เองด้วย `MovieRepositoryImpl(...)`

## 2. FutureProvider สำหรับ read-only request

Trending เหมาะกับ `FutureProvider.family`:

```dart
final trendingFeedProvider =
    FutureProvider.family<MovieLoadResult, String>(
  (ref, language) {
    return ref.watch(movieRepositoryProvider).getTrendingFeed(language);
  },
);
```

หน้า Home:

```dart
final language = apiLanguage(context.locale.languageCode);
final trending = ref.watch(trendingFeedProvider(language));
```

แล้ว render:

```dart
trending.when(
  data: (result) => TrendingList(result.movies),
  loading: () => const CircularProgressIndicator(),
  error: (error, stack) => RetryView(...),
)
```

## 3. เมื่อ State ซับซ้อนให้ใช้ Controller

Search มี state มากกว่า list ธรรมดา:

```text
query
genreId
movies
page
totalPages
isInitialLoading
isLoadingMore
failure
```

จึงควรสร้าง state object และ controller แทน FutureProvider หลายตัวที่ sync กันยาก

ตัวอย่าง state:

```dart
class MovieSearchState {
  const MovieSearchState({
    this.query = '',
    this.movies = const [],
    this.page = 0,
    this.totalPages = 1,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.failure,
  });

  final String query;
  final List<Movie> movies;
  final int page;
  final int totalPages;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final AppFailure? failure;

  bool get hasMore => page < totalPages;
}
```

ในโปรเจกต์จริง state อาจมี fields เพิ่มตาม discover/genre/preset flow

## 4. ปัญหา Search-as-you-type

สมมติผู้ใช้พิมพ์:

```text
b
ba
bat
batm
batman
```

หากยิง API ทุก keystroke จะเกิด request มากเกิน และ response อาจกลับไม่เรียงลำดับ

ตัวอย่าง:

```text
request "bat"   ───────────────→ response ช้า
request "batman" ─────→ response เร็ว
```

ถ้า response `bat` กลับทีหลังและเขียน state ทับ `batman` UI จะแสดงผลผิด

## 5. DebouncedLatestTask

สร้าง coordinator กลาง:

```text
Timer
_generation
_disposed
```

ทุก `run()`:

1. cancel timer เดิม
2. complete future เดิมที่ถูก supersede
3. เพิ่ม generation
4. รอ debounce duration
5. เรียก operation
6. publish เฉพาะเมื่อ generation ยังเป็น latest

แนวคิด:

```dart
final result = await debouncer.run(() {
  return repository.searchPage(query, language, 1);
});

if (result == null) return; // superseded
```

## 6. ทำไม Future เก่าต้อง Complete

การ `Timer.cancel()` อย่างเดียวไม่พอ หาก Future เก่ารอ completer ที่ callback ของ timer จะเป็นคน complete

ถ้า callback ไม่เกิด Future จะ pending ตลอด

ดังนั้นเมื่อ supersede/cancel/dispose ต้อง complete Future เก่าด้วย

นี่เป็น bug class ที่ควรมี deterministic unit test

## 7. Query Changed

Controller:

```dart
Future<void> queryChanged(String value) async {
  final query = value.trim();
  state = state.copyWith(query: query);

  if (query.isEmpty) {
    await discover();
    return;
  }

  final result = await _debouncer.run(
    () => repository.searchPage(query, language, 1),
  );

  if (result == null) return;

  state = state.copyWith(
    movies: result.items,
    page: result.page,
    totalPages: result.totalPages,
  );
}
```

## 8. Pagination

Domain object:

```dart
class PagedMovies {
  const PagedMovies({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Movie> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
```

Controller `loadMore()` ต้อง guard:

```dart
if (state.isLoadingMore) return;
if (!state.hasMore) return;
if (state.movies.isEmpty) return;
```

แล้ว request:

```dart
final next = await repository.searchPage(
  state.query,
  language,
  state.page + 1,
);
```

append:

```dart
state = state.copyWith(
  movies: [...state.movies, ...next.items],
  page: next.page,
  totalPages: next.totalPages,
);
```

## 9. Trigger Load More จาก Scroll

ใน `SearchPage`:

```dart
void _onScroll() {
  if (!_scrollController.hasClients) return;

  final position = _scrollController.position;
  if (position.extentAfter > 600) return;

  ref
      .read(movieSearchControllerProvider(language).notifier)
      .loadMore();
}
```

ไม่ต้องรอให้ถึง bottom 0 px เพราะผู้ใช้จะเห็น loading ช้า

## 10. รักษาข้อมูลเก่าเมื่อ load-more fail

ถ้า page 3 fail ไม่ควรล้าง page 1–2

UI ควรเป็น:

```text
existing movies
existing movies
existing movies
----------------
load more failed [Retry]
```

ไม่ใช่เปลี่ยนทั้งหน้าเป็น blocking error

## 11. Pull-to-refresh

ใช้ `RefreshIndicator`:

```dart
RefreshIndicator(
  onRefresh: controller.retry,
  child: CustomScrollView(...),
)
```

`retry()` ต้องรู้ context ปัจจุบันว่าเป็น query, genre หรือ preset ใด

## 12. Tests ที่ควรมี

```text
queryChanged debounce แล้วเรียกเฉพาะ latest query
superseded Future ต้อง complete
loadMore เรียก page + 1
loadMore ซ้ำระหว่าง loading ต้องถูก ignore
page append ไม่ลบ old items
loadMore error ยังเก็บ old items
empty query กลับ discover mode
```

## เป้าหมายหลังจบบท

Search ต้องพิมพ์ลื่น, ไม่มี stale response ทับ query ล่าสุด, scroll ต่อหน้าได้ และ error ของหน้าถัดไปไม่ทำลายข้อมูลที่โหลดมาแล้ว
