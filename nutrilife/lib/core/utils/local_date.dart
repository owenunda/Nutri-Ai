/// Fecha local del dispositivo como YYYY-MM-DD. El backend la usa para que
/// lo que se come de noche no caiga en el día siguiente (UTC).
String localDateString([DateTime? now]) {
  final d = now ?? DateTime.now();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}
