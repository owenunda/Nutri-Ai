import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String path) {
  final map = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return map.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('app_en.arb tiene exactamente las mismas claves que app_es.arb', () {
    final es = _keys('lib/l10n/app_es.arb');
    final en = _keys('lib/l10n/app_en.arb');

    expect(es.difference(en), isEmpty, reason: 'Faltan en inglés');
    expect(en.difference(es), isEmpty, reason: 'Sobran en inglés');
  });

  test('ningún texto está vacío', () {
    for (final path in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final map = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      for (final entry in map.entries.where((e) => !e.key.startsWith('@'))) {
        expect((entry.value as String).trim(), isNotEmpty, reason: '${entry.key} en $path');
      }
    }
  });
}
