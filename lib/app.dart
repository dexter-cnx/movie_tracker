import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/calendar/presentation/release_calendar_page.dart';
import 'package:popcorn_movie_tracker/features/home/presentation/home_page.dart';
import 'package:popcorn_movie_tracker/features/movie_detail/presentation/movie_detail_page.dart';
import 'package:popcorn_movie_tracker/features/profile/presentation/profile_page.dart';
import 'package:popcorn_movie_tracker/features/search/presentation/search_page.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_page.dart';
import 'package:popcorn_movie_tracker/shared/widgets/app_shell.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(path: '/explore', builder: (_, __) => const SearchPage()),
        GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      ],
    ),
    GoRoute(
      path: '/calendar',
      builder: (_, __) => const ReleaseCalendarPage(),
    ),
    GoRoute(
      path: '/movie/:id',
      builder: (_, state) => MovieDetailPage(
        movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
      ),
    ),
  ],
);

class PopcornApp extends StatelessWidget {
  const PopcornApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'appName'.tr(),
      theme: AppTheme.light,
      routerConfig: _router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
