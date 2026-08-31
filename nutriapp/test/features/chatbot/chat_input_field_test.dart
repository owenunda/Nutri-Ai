import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/chatbot/presentation/widgets/chat_input_field.dart';
import 'package:nutriapp/features/nutrition/data/fridge_repository.dart';
import 'package:nutriapp/features/nutrition/data/models/fridge_item_model.dart';

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

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final arroz = {
    'fridgeItemId': 1,
    'name': 'arroz',
    'quantity': 200,
    'unit': 'g',
  };

  testWidgets('manda el texto limpio y los alimentos elegidos por separado',
      (tester) async {
    String? sentMessage;
    List<FridgeItemModel>? sentFoods;

    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (message, foods) async {
        sentMessage = message;
        sentFoods = foods;
      },
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hazme una cena');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(sentMessage, 'Hazme una cena');
    expect(sentFoods!.single.name, 'arroz');
  });

  testWidgets('muestra un chip por cada alimento adjunto', (tester) async {
    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (_, _) async {},
      fridgeRepository: fridgeWith([arroz]),
    )));

    expect(find.text('arroz'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    expect(find.text('arroz'), findsOneWidget);
  });

  testWidgets('limpia los alimentos adjuntos después de enviar',
      (tester) async {
    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (_, _) async {},
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hazme una cena');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('arroz'), findsNothing);
  });

  testWidgets('envía solo los alimentos cuando no se escribe texto',
      (tester) async {
    String? sentMessage;
    List<FridgeItemModel>? sentFoods;

    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (message, foods) async {
        sentMessage = message;
        sentFoods = foods;
      },
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(sentMessage, '');
    expect(sentFoods!.single.name, 'arroz');
  });

  testWidgets('no envía nada cuando no hay texto ni alimentos',
      (tester) async {
    var calls = 0;

    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (_, _) async => calls++,
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('quita un alimento adjunto al tocar su chip', (tester) async {
    await tester.pumpWidget(wrap(ChatInputField(
      onSend: (_, _) async {},
      fridgeRepository: fridgeWith([arroz]),
    )));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('arroz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar 1 al mensaje'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('arroz'), findsNothing);
  });
}
