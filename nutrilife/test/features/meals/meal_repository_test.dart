import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/meals/data/meal_repository.dart';
import 'package:nutrilife/features/meals/domain/meal_type.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.routes);
  final Map<String, Object> routes;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add(o);
    final data = routes['${o.method} ${o.path}'];
    return ResponseBody.fromString(
      jsonEncode(data == null
          ? {'success': false, 'message': 'Ítem no encontrado'}
          : {'success': true, 'data': data}),
      data == null ? 404 : 200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

(MealRepository, _Adapter) _repo(Map<String, Object> routes) {
  final adapter = _Adapter(routes);
  return (
    MealRepository(dio: Dio(BaseOptions(baseUrl: 'https://t.local'))..httpClientAdapter = adapter),
    adapter,
  );
}

void main() {
  test('addFood crea el registro del día local y agrega con meal_type', () async {
    final (repo, adapter) = _repo({
      'POST /meals': {'mealRecordId': 9},
      'POST /meals/9/items': [
        {'detailId': 41, 'foodId': 3, 'quantity': 1.5, 'mealType': 'LUNCH'}
      ],
    });

    final id = await repo.addFood(
      foodId: 3,
      portions: 1.5,
      type: MealType.lunch,
      now: DateTime(2026, 10, 12, 23, 30),
    );

    expect(id, 41);
    expect(adapter.requests[0].data, {'date': '2026-10-12'});
    expect(adapter.requests[1].data, [
      {'food_id': 3, 'quantity': 1.5, 'meal_type': 'LUNCH'}
    ]);
  });

  test('getDay arma los grupos y el resumen', () async {
    final (repo, adapter) = _repo({
      'GET /meals/day': {
        'date': '2026-10-12',
        'totalCalories': 240,
        'meals': {
          'BREAKFAST': {'totalCalories': 0, 'items': []},
          'LUNCH': {
            'totalCalories': 240,
            'items': [
              {'detailId': 1, 'foodId': 3, 'name': 'Tilapia', 'baseUnit': '100 G', 'quantity': 1.5, 'calories': 144},
              {'detailId': 2, 'foodId': 5, 'name': 'Arroz', 'baseUnit': '100 G', 'quantity': 1, 'calories': 96},
            ]
          },
          'DINNER': {'totalCalories': 0, 'items': []},
          'SNACK': {'totalCalories': 0, 'items': []},
        }
      },
    });

    final day = await repo.getDay('2026-10-12');

    expect(adapter.requests.single.queryParameters, {'date': '2026-10-12'});
    expect(day.totalCalories, 240);
    expect(day.of(MealType.lunch).summary, 'Tilapia, Arroz • 240 kcal');
    expect(day.of(MealType.breakfast).isEmpty, isTrue);
  });

  test('deleteItem propaga el mensaje del backend', () async {
    final (repo, _) = _repo({});
    expect(
      repo.deleteItem(7),
      throwsA(isA<Exception>().having((e) => '$e', 'msg', contains('Ítem no encontrado'))),
    );
  });
}
