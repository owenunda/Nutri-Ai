import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/fridge_picker_sheet.dart';
import 'package:nutrilife/features/nutrition/data/food_repository.dart';
import 'package:nutrilife/features/nutrition/data/fridge_repository.dart';
import 'package:nutrilife/features/nutrition/data/models/food_model.dart';
import 'package:nutrilife/features/nutrition/data/models/fridge_item_model.dart';

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

class _Catalogo extends FoodRepository {
  _Catalogo(this.foods);
  final List<FoodModel> foods;

  @override
  Future<List<FoodModel>> getFoods() async => foods;
}

FoodModel _food(int id, String name, {bool global = true}) => FoodModel(
      foodId: id,
      name: name,
      caloriesPerUnit: 100,
      baseUnit: '100 G',
      isGlobal: global,
      isActive: true,
    );

Future<void> pumpSheet(
  WidgetTester tester,
  FridgeRepository repository, {
  List<FoodModel> catalog = const [],
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: FridgePickerSheet(
        repository: repository,
        foodRepository: _Catalogo(catalog),
      ),
    ),
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

  group('pestañas nevera / comunes', () {
    final banana = {
      'fridgeItemId': 1,
      'foodId': 11,
      'name': 'Banana',
      'quantity': 1,
      'unit': 'unidad',
    };

    testWidgets('abre en la nevera y los comunes van en su pestaña',
        (tester) async {
      await pumpSheet(tester, fridgeWith([banana]), catalog: [
        _food(11, 'Banana'),
        _food(20, 'Tilapia'),
        _food(21, 'Mi batido', global: false),
      ]);

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Tilapia'), findsNothing);

      await tester.tap(find.text('Comunes'));
      await tester.pumpAndSettle();

      expect(find.text('Tilapia'), findsOneWidget);
      // Ni repetidos de la nevera ni alimentos propios.
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Mi batido'), findsNothing);
    });

    testWidgets('con la nevera vacía abre en comunes', (tester) async {
      await pumpSheet(tester, fridgeWith([]), catalog: [_food(20, 'Tilapia')]);

      expect(find.text('Tilapia'), findsOneWidget);
    });

    testWidgets('si no está en esta pestaña ofrece la otra', (tester) async {
      await pumpSheet(tester, fridgeWith([banana]),
          catalog: [_food(20, 'Tilapia'), _food(22, 'Arroz')]);

      await tester.enterText(find.byType(TextField), 'tila');
      // Espera a que la hoja termine de acomodar su alto.
      await tester.pumpAndSettle();
      expect(find.text('No encontramos "tila" en tu nevera.'), findsOneWidget);

      await tester.tap(find.text('Ver en Comunes (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Tilapia'), findsOneWidget);
      expect(find.text('Arroz'), findsNothing);
    });

    testWidgets('devuelve la selección mezclando nevera y comunes',
        (tester) async {
      List<FridgeItemModel>? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await FridgePickerSheet.show(
                context,
                repository: fridgeWith([banana]),
                foodRepository: _Catalogo([_food(20, 'Tilapia')]),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.tap(find.text('Comunes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tilapia'));
      await tester.pump();

      // Cada pestaña cuenta lo suyo.
      expect(find.descendant(of: find.byType(Row), matching: find.text('1')),
          findsNWidgets(2));
      await tester.tap(find.text('Agregar 2 al mensaje'));
      await tester.pumpAndSettle();

      expect(result!.map((f) => (f.name, f.isFromFridge)),
          [('Banana', true), ('Tilapia', false)]);
      expect(result![1].foodId, 20);
    });

    testWidgets('si el catálogo falla sigue mostrando la nevera',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FridgePickerSheet(
            repository: fridgeWith([banana]),
            foodRepository: _CatalogoRoto(),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      await tester.tap(find.text('Comunes'));
      await tester.pumpAndSettle();
      expect(find.text('Sin alimentos comunes'), findsOneWidget);
    });
  });
}

class _CatalogoRoto extends FoodRepository {
  @override
  Future<List<FoodModel>> getFoods() async => throw Exception('sin red');
}
