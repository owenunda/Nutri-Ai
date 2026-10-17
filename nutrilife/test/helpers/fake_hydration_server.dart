import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Backend de hidratación en memoria, con las mismas reglas que el real:
/// tope de 4 vasos, borrar el día al deshacer el último e import que se
/// queda con el mayor valor. Lo que no es /hydration se pasa a [fallback].
class FakeHydrationServer implements HttpClientAdapter {
  FakeHydrationServer({this.fallback});

  static const int goal = 4;

  final HttpClientAdapter? fallback;
  final Map<String, int> history = {};
  final List<RequestOptions> requests = [];

  /// Si es true, todas las rutas de hidratación responden 500.
  bool failing = false;

  /// Si no es null, /hydration/import responde con este estado de error.
  int? importStatus;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!options.path.startsWith('/hydration')) {
      final next = fallback;
      if (next == null) return _json(404, {'success': false, 'message': 'not found'});
      return next.fetch(options, requestStream, cancelFuture);
    }
    requests.add(options);
    if (failing) return _json(500, {'success': false, 'message': 'boom'});

    final body = options.data is Map ? options.data as Map : const {};
    switch ((options.method, options.path)) {
      case ('GET', '/hydration'):
        return _ok({'goal': goal, 'history': history});
      case ('POST', '/hydration/glass'):
        final date = body['date'] as String;
        history[date] = ((history[date] ?? 0) + 1).clamp(1, goal);
        return _ok({'date': date, 'glasses': history[date]});
      case ('POST', '/hydration/glass/undo'):
        final date = body['date'] as String;
        final left = (history[date] ?? 0) - 1;
        if (left <= 0) {
          history.remove(date);
        } else {
          history[date] = left;
        }
        return _ok({'date': date, 'glasses': left < 0 ? 0 : left});
      case ('POST', '/hydration/import'):
        final rejected = importStatus;
        if (rejected != null) {
          return _json(rejected, {'success': false, 'message': 'rejected'});
        }
        final incoming = (body['history'] as Map).cast<String, int>();
        for (final entry in incoming.entries) {
          final value = entry.value.clamp(1, goal);
          final current = history[entry.key] ?? 0;
          history[entry.key] = value > current ? value : current;
        }
        return _ok({'imported': incoming.length});
    }
    return _json(404, {'success': false, 'message': 'not found'});
  }

  ResponseBody _ok(Object data) => _json(200, {'success': true, 'data': data});

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
