import 'package:intl/intl.dart';

String _clean(String value) => value.replaceAll('.', '');

/// "Lun", "Mar", "Mié" / "Mon", "Tue": abreviatura con mayúscula y sin punto,
/// como las que usaban las tarjetas de la semana.
String shortWeekday(DateTime date, String languageCode) {
  final raw = _clean(DateFormat.E(languageCode).format(date));
  return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
}

/// "ene", "oct" / "Jan", "Oct": en español queda en minúscula como antes.
String shortMonth(DateTime date, String languageCode) {
  final raw = _clean(DateFormat.MMM(languageCode).format(date));
  // intl abrevia septiembre como "sept"; la app siempre mostró "sep".
  return languageCode == 'es' && raw == 'sept' ? 'sep' : raw;
}
