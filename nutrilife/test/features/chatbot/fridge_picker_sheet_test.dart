import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/fridge_picker_sheet.dart';
import 'package:nutrilife/features/nutrition/data/fridge_repository.dart';

/// Devuelve siempre la misma nevera canned, sin tocar la red.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FridgeRepository fridgeWith(List<Map<String, Object>> items) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = _FakeAdapter({
      'success': true,
      'data': {'fridgeId': 1, 'items': items},
    });
  return FridgeRepository(dio: dio);
}

Future<void> pumpSheet(WidgetTester tester, FridgeRepository repository) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: FridgePickerSheet(repository: repository)),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra las calorías y la unidad base del alimento',
      (tester) async {
    await pumpSheet(
      tester,
      fridgeWith([
        {
          'fridgeItemId': 1,
          'foodId': 11,
          'name': 'banana',
          'quantity': 2,
          'unit': 'unidad',
          'caloriesPerUnit': 89,
          'baseUnit': '100 g',
        }
      ]),
    );

    expect(find.text('89 kcal · 100 g'), findsOneWidget);
  });

  testWidgets('muestra la cantidad que hay en la nevera', (tester) async {
    await pumpSheet(
      tester,
      fridgeWith([
        {
          'fridgeItemId': 1,
          'name': 'arroz',
          'quantity': 200,
          'unit': 'g',
          'caloriesPerUnit': 130,
          'baseUnit': '100 g',
        }
      ]),
    );

    expect(find.text('200 g'), findsOneWidget);
  });

  testWidgets('avisa cuando el alimento no tiene cantidad registrada',
      (tester) async {
    await pumpSheet(
      tester,
      fridgeWith([
        {
          'fridgeItemId': 1,
          'name': 'pera',
          'quantity': 0,
          'unit': 'unidad',
          'caloriesPerUnit': 57,
          'baseUnit': '100 g',
        }
      ]),
    );

    expect(find.text('Sin cantidad'), findsOneWidget);
  });

  testWidgets('omite las calorías cuando el backend no las envía',
      (tester) async {
    await pumpSheet(
      tester,
      fridgeWith([
        {
          'fridgeItemId': 1,
          'name': 'pera',
          'quantity': 0,
          'unit': 'unidad',
        }
      ]),
    );

    expect(find.textContaining('kcal'), findsNothing);
  });
}
