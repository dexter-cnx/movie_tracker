import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';

void main() {
  group('apiLanguage', () {
    test('maps Thai locale to th-TH', () {
      expect(apiLanguage('th'), 'th-TH');
    });

    test('maps every other locale to en-US', () {
      expect(apiLanguage('en'), 'en-US');
      expect(apiLanguage('unknown'), 'en-US');
    });
  });

  test('MovieDetailArg equality includes id and language', () {
    const first = MovieDetailArg(1, 'en-US');
    const same = MovieDetailArg(1, 'en-US');
    const differentLanguage = MovieDetailArg(1, 'th-TH');

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(differentLanguage));
  });
}
