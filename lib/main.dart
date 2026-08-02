import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:popcorn_movie_tracker/app.dart';
import 'package:popcorn_movie_tracker/core/crash/crash_reporter.dart';
import 'package:popcorn_movie_tracker/core/logging/app_logger.dart';
import 'package:popcorn_movie_tracker/features/movies/data/movie_cache_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/profile/data/user_preferences_local_data_source.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const logger = DeveloperAppLogger();
  const crashReporter = LoggingCrashReporter(logger);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashReporter.record(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: false,
      reason: details.context?.toDescription(),
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashReporter.record(
      error,
      stackTrace,
      fatal: true,
      reason: 'Uncaught platform-dispatcher error',
    );
    return true;
  };

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox<Map>(WatchlistLocalDataSource.boxName),
    Hive.openBox<Map>(UserPreferencesLocalDataSource.boxName),
    Hive.openBox<Map>(MovieCacheLocalDataSource.boxName),
  ]);

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('th')],
        path: 'assets/langs/langs.csv',
        fallbackLocale: const Locale('en'),
        assetLoader: CsvAssetLoader(),
        child: const PopcornApp(),
      ),
    ),
  );
}
