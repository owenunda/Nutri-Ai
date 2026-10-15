import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nutrilife/core/l10n/date_labels.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('en');
  });

  // 13 de octubre de 2026 es martes.
  final date = DateTime(2026, 10, 13);

  test('día de la semana corto, con mayúscula y sin punto', () {
    expect(shortWeekday(date, 'es'), 'Mar');
    expect(shortWeekday(date, 'en'), 'Tue');
    expect(shortWeekday(DateTime(2026, 10, 14), 'es'), 'Mié');
  });

  test('mes corto en minúscula en español, como antes', () {
    expect(shortMonth(date, 'es'), 'oct');
    expect(shortMonth(DateTime(2026, 1, 5), 'es'), 'ene');
    expect(shortMonth(date, 'en'), 'Oct');
  });
}
