import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

/// Deterministic in-memory translations for widget tests.
///
/// Widget tests should verify UI behavior rather than depend on the CSV asset
/// loading channel. The production CSV itself is validated separately by
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
