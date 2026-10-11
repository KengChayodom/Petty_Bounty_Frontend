// Layer boundaries from frontend_coding_guidelines.md, checked by reading the
// source: presentation talks to providers in domain/, never to data/. A screen
// that imports a repository or a DTO directly fails here instead of in review.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _dataImport = RegExp(r'''^\s*import\s+['"][^'"]*/data/''', multiLine: true);
final _dbQuery = RegExp(r'''\.from\(\s*['"]''');

Iterable<File> _dartFiles(String dir) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  test('presentation never imports from a data/ folder', () {
    final offenders = [
      for (final f in _dartFiles('lib/src/features'))
        if (f.path.contains('/presentation/') &&
            _dataImport.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('no table query reaches Supabase from the app (FastAPI owns the DB)', () {
    // Storage is allowed (`storage.from(bucket)`), a table query is not.
    final offenders = [
      for (final f in _dartFiles('lib'))
        for (final line in f.readAsLinesSync())
          if (_dbQuery.hasMatch(line) && !line.contains('storage'))
            '${f.path}: ${line.trim()}',
    ];
    expect(offenders, isEmpty);
  });
}
