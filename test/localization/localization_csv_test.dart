import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('langs.csv has valid header, no blank rows, and unique keys', () {
    final file = File('assets/langs/langs.csv');
    expect(file.existsSync(), isTrue, reason: 'assets/langs/langs.csv must exist');

    final rows = const CsvToListConverter(shouldParseNumbers: false).convert(file.readAsStringSync());
    expect(rows, isNotEmpty);
    expect(rows.first, ['key', 'en', 'th']);

    final keys = <String>{};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      expect(row.length, 3, reason: 'Invalid column count at CSV row ${i + 1}: $row');
      expect(row.every((cell) => cell.toString().trim().isNotEmpty), isTrue,
          reason: 'Blank localization value at CSV row ${i + 1}: $row');
      final key = row.first.toString();
      expect(keys.add(key), isTrue, reason: 'Duplicate localization key: $key');
    }
  });
}
