import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/chatbot/data/chat_repository.dart';
import 'package:nutriapp/features/chatbot/presentation/controllers/chat_view_model.dart';
import 'package:nutriapp/features/nutrition/data/models/fridge_item_model.dart';

/// Responde siempre un CHAT vacío y recuerda el body recibido.
class _CapturingAdapter implements HttpClientAdapter {
  Object? capturedBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    capturedBody = options.data;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {'type': 'CHAT', 'message': 'listo', 'recipe': null},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _banana = FridgeItemModel(
  fridgeItemId: 4,
  foodId: 11,
  name: 'Banana',
  quantity: 0,
  unit: 'unidad',
  caloriesPerUnit: 89,
  baseUnit: '100 G',
);

void main() {
  late _CapturingAdapter adapter;
  late ChatViewModel viewModel;

  setUp(() {
    adapter = _CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
      ..httpClientAdapter = adapter;
    viewModel = ChatViewModel(repository: ChatRepository(dio: dio));
  });

  tearDown(() => viewModel.dispose());

  test('guarda los alimentos adjuntos en el mensaje del usuario', () async {
    await viewModel.sendMessage('necesito un desayuno', foods: [_banana]);

    expect(viewModel.messages.first.attachedFoods.single.name, 'Banana');
  });

  test('no mete los alimentos dentro del texto del mensaje', () async {
    await viewModel.sendMessage('necesito un desayuno', foods: [_banana]);

    expect(viewModel.messages.first.text, 'necesito un desayuno');
  });

  test('manda los ids de los adjuntos al repositorio', () async {
    await viewModel.sendMessage('necesito un desayuno', foods: [_banana]);

    expect((adapter.capturedBody as Map)['fridgeItemIds'], [4]);
  });

  test('envía aunque el texto venga vacío si hay alimentos', () async {
    await viewModel.sendMessage('  ', foods: [_banana]);

    expect(viewModel.messages, isNotEmpty);
  });

  test('no envía nada sin texto ni alimentos', () async {
    await viewModel.sendMessage('   ');

    expect(viewModel.messages, isEmpty);
  });
}
