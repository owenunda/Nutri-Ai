import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/nutrition/data/fridge_repository.dart';

/// Devuelve siempre la misma respuesta canned, sin tocar la red.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.statusCode = 200, this.requests});

  final Object body;
  final int statusCode;
  final List<RequestOptions>? requests;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests?.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FridgeRepository repoReturning(Object body, {int statusCode = 200}) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://test.local',
    validateStatus: (_) => true,
  ))..httpClientAdapter = _FakeAdapter(body, statusCode: statusCode);
  return FridgeRepository(dio: dio);
}

void main() {
  group('FridgeRepository.getFridgeItems', () {
    test('mapea los items que devuelve el backend', () async {
      final repo = repoReturning({
        'success': true,
        'data': {
          'fridgeId': 7,
          'items': [
            {'fridgeItemId': 1, 'name': 'arroz', 'quantity': 200, 'unit': 'g'},
            {'fridgeItemId': 2, 'name': 'huevo', 'quantity': 3, 'unit': 'unidad'},
          ],
        },
      });

      final items = await repo.getFridgeItems();

      expect(items, hasLength(2));
      expect(items.first.fridgeItemId, 1);
      expect(items.first.name, 'arroz');
      expect(items.first.quantity, 200);
      expect(items.first.unit, 'g');
    });

    test('devuelve lista vacía cuando la nevera no tiene items', () async {
      final repo = repoReturning({
        'success': true,
        'data': {'fridgeId': 7, 'items': []},
      });

      expect(await repo.getFridgeItems(), isEmpty);
    });

    test('lee cantidades que llegan como texto', () async {
      final repo = repoReturning({
        'success': true,
        'data': {
          'items': [
            {'fridgeItemId': 1, 'name': 'leche', 'quantity': '1.5', 'unit': 'l'},
          ],
        },
      });

      final items = await repo.getFridgeItems();

      expect(items.single.quantity, 1.5);
    });

    test('lanza el mensaje del backend cuando la respuesta no es exitosa', () async {
      final repo = repoReturning(
        {'success': false, 'message': 'No se encontró la nevera'},
        statusCode: 404,
      );

      expect(
        repo.getFridgeItems(),
        throwsA(predicate((e) => e.toString().contains('No se encontró la nevera'))),
      );
    });
  });

  group('FridgeRepository fridge item changes', () {
    test('updates the item quantity with PUT', () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(
        baseUrl: 'https://test.local',
        validateStatus: (_) => true,
      ))
        ..httpClientAdapter = _FakeAdapter(
          {'success': true, 'data': {}},
          requests: requests,
        );
      final repo = FridgeRepository(dio: dio);

      await repo.updateItem(fridgeItemId: 12, quantity: 4.5);

      expect(requests.single.method, 'PUT');
      expect(requests.single.path, '/fridge/items/12');
      expect(requests.single.data, {'quantity': 4.5});
    });

    test('deletes the fridge item by its id', () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(
        baseUrl: 'https://test.local',
        validateStatus: (_) => true,
      ))
        ..httpClientAdapter = _FakeAdapter(
          {'success': true, 'data': {}},
          requests: requests,
        );
      final repo = FridgeRepository(dio: dio);

      await repo.deleteItem(fridgeItemId: 12);

      expect(requests.single.method, 'DELETE');
      expect(requests.single.path, '/fridge/items/12');
    });

    test('propagates the backend error when updating fails', () async {
      final repo = repoReturning({
        'success': false,
        'message': 'No se pudo actualizar',
      });

      expect(
        repo.updateItem(fridgeItemId: 12, quantity: 4),
        throwsA(predicate((error) => error.toString().contains('No se pudo actualizar'))),
      );
    });
  });
}
