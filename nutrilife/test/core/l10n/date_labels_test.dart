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

  test('español: los 12 meses cortos coinciden con las listas de la app', () {
    final months = [
      for (var m = 1; m <= 12; m++) shortMonth(DateTime(2026, m, 5), 'es'),
    ];
    expect(months, [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ]);
  });

  test('español: los 7 días cortos coinciden con las listas de la app', () {
    // 12 de octubre de 2026 es lunes.
    final days = [
      for (var d = 12; d <= 18; d++) shortWeekday(DateTime(2026, 10, d), 'es'),
    ];
    expect(days, ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']);
  });

  test('inglés: meses y días tal como los da intl', () {
    final months = [
      for (var m = 1; m <= 12; m++) shortMonth(DateTime(2026, m, 5), 'en'),
    ];
    expect(months, [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ]);
    final days = [
      for (var d = 12; d <= 18; d++) shortWeekday(DateTime(2026, 10, d), 'en'),
    ];
    expect(days, ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
  });
}
