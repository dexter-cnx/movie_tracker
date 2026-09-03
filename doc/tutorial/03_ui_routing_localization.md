# 03 — UI, Routing, Theme และ Localization

บทนี้สร้าง shell ของแอปให้มี Home, Explore, Watchlist, Profile และ Movie Detail พร้อม Material 3, GoRouter และ localization ภาษาอังกฤษ/ไทย

## 1. Theme กลาง

สร้าง `lib/core/theme/app_theme.dart` แล้วเก็บ design token ที่ใช้ซ้ำ เช่นสีพื้นหลัง card, accent, text และ button

แนวคิดสำคัญคืออย่ากระจายสี literal ไปทั่ว widget เช่น:

```dart
Container(color: const Color(0xFF171717))
```

ให้รวมเป็น:

```dart
class AppColors {
  static const background = Color(0xFF0B0B0B);
  static const card = Color(0xFF171717);
  static const cardAlt = Color(0xFF222222);
  static const orange = Color(0xFFFF8A3D);
  static const text = Colors.white;
}
```

จากนั้นสร้าง `ThemeData` ผ่าน Material 3

## 2. Shared Widgets

โปรเจกต์ใช้ shared widget เช่น:

```text
ClayCard
ClayIconButton
Poster
AppImage
AppShell
```

หลักการคือ shared widget ควรเป็น primitive ที่ reusable จริง ไม่ใช่เอา widget เฉพาะหน้าไปย้ายไว้ `shared/` เพียงเพราะไฟล์ยาว

## 3. GoRouter

สร้าง route หลัก:

```text
/
/explore
/watchlist
/profile
```

และ top-level routes:

```text
/login
/calendar
/movie/:id
```

ใช้ `ShellRoute` สำหรับ main tabs:

```dart
final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/explore', builder: (_, __) => const SearchPage()),
        GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      ],
    ),
    GoRoute(
      path: '/movie/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        return MovieDetailPage(movieId: id ?? 0);
      },
    ),
  ],
);
```

## 4. `go()` กับ `push()`

ใช้ `go()` เมื่อเป็น navigation state หลัก เช่นเปลี่ยน tab:

```dart
context.go('/watchlist');
```

ใช้ `push()` เมื่อเป็นหน้าที่ควรย้อนกลับด้วย back stack เช่น detail:

```dart
context.push('/movie/${movie.id}');
```

## 5. App Shell

`AppShell` รับ child จาก ShellRoute แล้วแสดง bottom navigation

```text
Home
Explore
Watchlist
Profile
```

ต้องคำนึงถึง SafeArea และความสูงจริงของ navigation bar เพื่อไม่ให้ label overflow บนอุปกรณ์ที่มี system inset ต่างกัน

## 6. Localization แบบ CSV-first

สร้าง source of truth:

```text
assets/langs/langs.csv
```

ตัวอย่าง:

```csv
key,en,th
welcome,Welcome {name},สวัสดี {name}
trendingNow,Trending Now,กำลังมาแรง
myWatchlist,My Watchlist,รายการของฉัน
searchHint,Search movies,ค้นหาภาพยนตร์
retry,Retry,ลองอีกครั้ง
```

ใช้ `easy_localization_loader` อ่าน CSV หรือ generate resource ตาม workflow ที่โปรเจกต์กำหนด

ข้อดีของ CSV-first:

- translator เปิดแก้ได้ง่าย
- เห็นภาษาเทียบกันในแถวเดียว
- review missing translation ง่าย
- ลด key drift ระหว่างไฟล์ภาษา

## 7. เรียก translation ใน Widget

```dart
Text('trendingNow'.tr())
```

placeholder:

```dart
Text(
  'welcome'.tr(
    namedArgs: {'name': profile.displayName},
  ),
)
```

อย่า hard-code ชื่อ `Dexter` ใน UI ถ้ามี profile state อยู่แล้ว

## 8. API Language

ภาษา UI กับภาษา TMDB มี format ต่างกัน

```dart
String apiLanguage(String localeCode) {
  return localeCode == 'th' ? 'th-TH' : 'en-US';
}
```

จากนั้นส่งเข้า repository/provider ทุก request ที่ต้อง localized response

## 9. Responsive Layout

อย่าตัดสิน layout จาก width อย่างเดียวเสมอไป เพราะ tablet landscape กับ phone landscape อาจมี width ใกล้กันแต่ ratio ต่างกัน

สร้าง helper เช่น:

```text
ResponsiveLayout.classOf(size)
ResponsiveLayout.gridColumns(size)
ResponsiveLayout.horizontalPadding(size)
```

ใช้กำหนด:

- จำนวนคอลัมน์ใน movie grid
- horizontal padding
- childAspectRatio
- stats grid

## 10. Accessibility ขั้นพื้นฐาน

Movie card ที่กดได้ควรมี semantics:

```dart
Semantics(
  button: true,
  label: movie.title,
  child: InkWell(...),
)
```

ข้อความที่ยาวต้องมี:

```dart
maxLines: 1,
overflow: TextOverflow.ellipsis,
```

เพื่อรองรับทั้งภาษาไทย/อังกฤษและหน้าจอเล็ก

## เป้าหมายหลังจบบท

แอปควรมี navigation shell, theme, localization และ responsive foundation พร้อมก่อนเชื่อม API จริง
