import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:popcorn_movie_tracker/app.dart';
import 'package:popcorn_movie_tracker/features/watchlist/data/watchlist_local_data_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  await Hive.initFlutter();
  await Hive.openBox<Map>(WatchlistLocalDataSource.boxName);

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
