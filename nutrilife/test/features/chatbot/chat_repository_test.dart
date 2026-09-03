import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';

/// Devuelve siempre la misma respuesta canned, sin tocar la red.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.throwing});

  final Object body;
  final DioException? throwing;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwing != null) throw throwing!;
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

ChatRepository repoReturning(Object envelope) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = _FakeAdapter({
      'success': true,
      'message': 'Mensaje enviado correctamente a n8n',
      'data': envelope,
    });
  return ChatRepository(dio: dio);
}

const _recipe = {
  'title': 'Tortilla de cebolla',
  'summary': 'Rápida y proteica',
  'chef_reason': 'Aprovecha tus huevos',
  'meal_type': 'desayuno',
  'difficulty': 'Fácil',
  'preparation_time_minutes': 15,
  'servings': 2,
  'estimated_calories': 250,
  'tips': ['Fuego bajo'],
  'steps': [
    {'step': 1, 'description': 'Bate los huevos'},
    {'step': 2, 'description': 'Sofríe la cebolla'},
  ],
  'ingredients_used': [
    {'food_id': 11, 'quantity': 3},
  ],
  'available_foods': [
    {'foodId': 11, 'name': 'huevo'},
  ],
};

void main() {
  group('envelope sin receta', () {
    test('CHAT no revienta aunque la clave recipe exista en null', () async {
      // Regresión: isNestedRecipeMap usaba containsKey, así que
      // "recipe": null entraba a la rama de receta y casteaba null a Map.
      final repo = repoReturning({
        'type': 'CHAT',
        'message': '¡Hola! Soy NutriLife, tu ayudante de cocina.',
        'recipe': null,
        'media': null,
        'session': {'sessionId': 13, 'version': 1},
      });

      final reply = await repo.sendMessage('hola');

      expect(reply.type, ChatResponseType.chat);
      expect(reply.recipe, isNull);
      expect(reply.text, '¡Hola! Soy NutriLife, tu ayudante de cocina.');
    });

    test('ANSWER devuelve el texto sin receta', () async {
      final repo = repoReturning({
        'type': 'ANSWER',
        'message': 'Dorar es cocinar a fuego medio hasta que tome color.',
        'recipe': null,
        'media': null,
        'session': {'sessionId': 13, 'version': 2},
      });

      final reply = await repo.sendMessage('¿qué es dorar?');

      expect(reply.type, ChatResponseType.answer);
      expect(reply.recipe, isNull);
      expect(reply.isModification, isFalse);
      expect(reply.text, contains('fuego medio'));
    });

    test('message vacío cae en un texto por defecto', () async {
      final repo = repoReturning({
        'type': 'CHAT',
        'message': '   ',
        'recipe': null,
        'media': null,
      });

      expect((await repo.sendMessage('x')).text, 'Sin respuesta');
    });
  });

  group('envelope con receta', () {
    test('RECIPE con video parsea receta y youtube', () async {
      final repo = repoReturning({
        'type': 'RECIPE',
        'message': 'Aprovecha tus huevos',
        'recipe': _recipe,
        'media': {
          'youtube': {
            'video_id': 'xyz123',
            'title': 'Cómo hacer tortilla',
            'channel': 'Cocina Fácil',
            'thumbnail': 'https://img/t.jpg',
            'url': 'https://www.youtube.com/watch?v=xyz123',
          }
        },
        'session': {'sessionId': 13, 'version': 2},
      });

      final reply = await repo.sendMessage('tengo huevos');

      expect(reply.type, ChatResponseType.recipe);
      expect(reply.recipe!.title, 'Tortilla de cebolla');
      expect(reply.recipe!.servings, 2);
      expect(reply.recipe!.steps, hasLength(2));
      expect(reply.recipe!.steps.last.description, 'Sofríe la cebolla');
      expect(reply.recipe!.ingredients.single.foodId, 11);
      expect(reply.recipe!.youtubeVideo!.videoId, 'xyz123');
    });

    test('RECIPE sin video deja youtubeVideo en null', () async {
      // Pasa cuando YouTube se queda sin cuota: la receta debe llegar igual.
      final repo = repoReturning({
        'type': 'RECIPE',
        'message': 'Aprovecha tus huevos',
        'recipe': _recipe,
        'media': null,
        'session': {'sessionId': 13, 'version': 2},
      });

      final reply = await repo.sendMessage('tengo huevos');

      expect(reply.recipe, isNotNull);
      expect(reply.recipe!.youtubeVideo, isNull);
    });

    test('RECIPE_MODIFIED se distingue de una receta nueva', () async {
      final repo = repoReturning({
        'type': 'RECIPE_MODIFIED',
        'message': 'Dupliqué las cantidades',
        'recipe': {..._recipe, 'servings': 4},
        'media': null,
        'session': {'sessionId': 13, 'version': 3},
      });

      final reply = await repo.sendMessage('hazla para 4');

      expect(reply.type, ChatResponseType.recipeModified);
      expect(reply.isModification, isTrue);
      expect(reply.recipe!.servings, 4);
      expect(reply.text, 'Dupliqué las cantidades');
    });

    test('pasos e ingredientes malformados no tumban el parseo', () async {
      final repo = repoReturning({
        'type': 'RECIPE',
        'message': 'Listo',
        'recipe': {
          ..._recipe,
          'steps': [
            {'description': 'Sin número de paso'},
            'un string suelto',
            {'step': 3, 'description': 'Ok'},
          ],
          'ingredients_used': [
            {'food_id': 11, 'quantity': 3},
            'basura',
          ],
        },
        'media': null,
      });

      final reply = await repo.sendMessage('x');

      expect(reply.recipe!.steps, hasLength(2));
      expect(reply.recipe!.steps.first.step, 1, reason: 'usa el índice como fallback');
      expect(reply.recipe!.ingredients, hasLength(1));
    });
  });

  group('errores', () {
    test('un tipo desconocido cae en chat en vez de reventar', () async {
      final repo = repoReturning({
        'type': 'ALGO_NUEVO',
        'message': 'texto',
        'recipe': null,
      });

      expect((await repo.sendMessage('x')).type, ChatResponseType.chat);
    });

    test('el timeout da un mensaje entendible', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = _FakeAdapter(
          {},
          throwing: DioException.receiveTimeout(
            timeout: const Duration(seconds: 90),
            requestOptions: RequestOptions(path: '/n8n/chat'),
          ),
        );

      await expectLater(
        ChatRepository(dio: dio).sendMessage('x'),
        throwsA(predicate(
          (e) => e.toString().contains('tomando su tiempo'),
        )),
      );
    });

    test('una respuesta sin data se reporta como inesperada', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = _FakeAdapter({'success': false});

      await expectLater(
        ChatRepository(dio: dio).sendMessage('x'),
        throwsA(predicate(
          (e) => e.toString().contains('Respuesta inesperada'),
        )),
      );
    });
  });

  group('sendMessage con alimentos adjuntos', () {
    late _CapturingAdapter adapter;
    late ChatRepository repo;

    setUp(() {
      adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter;
      repo = ChatRepository(dio: dio);
    });

    test('manda los ids de los alimentos adjuntos', () async {
      await repo.sendMessage('necesito un desayuno', fridgeItemIds: [4, 7]);

      expect((adapter.capturedBody as Map)['fridgeItemIds'], [4, 7]);
    });

    test('omite el campo cuando no hay adjuntos', () async {
      await repo.sendMessage('hola');

      expect((adapter.capturedBody as Map).containsKey('fridgeItemIds'), isFalse);
    });

    test('sigue mandando el mensaje tal cual', () async {
      await repo.sendMessage('necesito un desayuno', fridgeItemIds: [4]);

      expect((adapter.capturedBody as Map)['message'], 'necesito un desayuno');
    });
  });
}

/// Captura el body de la peticion para poder afirmar sobre lo que se envia.
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
        'data': {'type': 'CHAT', 'message': 'hola', 'recipe': null},
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
