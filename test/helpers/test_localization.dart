import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Deterministic in-memory translations for widget tests.
///
/// Widget tests verify UI behavior without depending on the production CSV
/// loader. The production CSV is validated separately by
/// `test/localization/localization_csv_test.dart`.
class TestLocalizationLoader extends AssetLoader {
  const TestLocalizationLoader();

  static const Map<String, String> _en = {
    'appName': 'Popcorn',
    'welcome': 'Welcome {name}',
    'hotToday': "Here's what's hot today",
    'searchHint': 'Search movie, actor, genre...',
    'watchStats': 'Your Watch Stats',
    'checkNow': 'Check now',
    'trendingNow': 'Trending Now',
    'myWatchlist': 'My Watchlist',
    'seeAll': 'See all',
    'upcoming': 'Upcoming',
    'watched': 'Watched',
    'today': 'Today',
    'staleCacheNotice': 'Showing previously cached movies',
    'retry': 'Retry',
    'myList': 'My List',
    'totalMoviesWatched': 'Total Movies Watched',
    'totalHours': 'Total Hours',
    'averageRating': 'Average Rating',
    'favoriteGenre': 'Favorite Genre',
    'wantToWatch': 'Want to Watch',
    'noMovies': 'No movies found',
    'profile': 'Profile',
    'editProfile': 'Edit profile',
    'account': 'Account',
    'signIn': 'Sign in',
    'demoAuthenticationDescription':
        'Uses secure storage and synchronized token refresh without requiring a real backend.',
    'settings': 'Settings',
    'language': 'Language',
    'english': 'English',
    'notifications': 'Notifications',
    'notificationsDescription': 'Release reminders and watchlist updates',
    'autoplayTrailers': 'Autoplay trailers',
    'autoplayTrailersDescription':
        'Play trailers automatically on movie details',
    'more': 'More',
    'releaseCalendar': 'Release Calendar',
    'aboutApp': 'About Popcorn',
    'appVersion': 'Version {}',
  };

  static const Map<String, String> _th = {
    'appName': 'ป๊อปคอร์น',
    'profile': 'โปรไฟล์',
  };

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return Map<String, dynamic>.from(
      locale.languageCode == 'th' ? _th : _en,
    );
  }
}

/// Builds a MaterialApp that actually installs EasyLocalization delegates.
///
/// Merely placing a MaterialApp below EasyLocalization is not sufficient in
/// widget tests: the app must request the localization delegates so the asset
/// loader is executed and `.tr()` can resolve values.
Widget testLocalizedApp({required Widget home}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('th')],
    path: 'unused-in-widget-tests',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    saveLocale: false,
    useOnlyLangCode: true,
    assetLoader: const TestLocalizationLoader(),
    child: Builder(
      builder: (context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: home),
        );
      },
    ),
  );
}
