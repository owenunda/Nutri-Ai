import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_session_model.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';

/// Responde según "MÉTODO /ruta" y anota cada request que pasa.
class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.routes);

  final Map<String, Object> routes;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    calls.add(key);
    final data = routes[key];
    if (data == null) {
      return ResponseBody.fromString(
        jsonEncode({'success': false, 'message': 'No se encontró la sesión'}),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
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
  'tips': [],
  'steps': [],
  'ingredients_used': [],
};

Map<String, Object> _sessionWithMessages({
  required int id,
  Map<String, Object?>? recipe,
  Map<String, Object?>? media,
  List<Map<String, Object>> messages = const [],
}) => {
  'session': {
    'sessionId': id,
    'active': true,
    'conversationState': {'recipe': recipe, 'media': media},
    'createdAt': '2026-10-10T12:00:00.000Z',
  },
  'messages': messages,
};

Map<String, Object> _msg(String role, String content, {String at = '12:00'}) =>
    {
      'messageId': content.hashCode,
      'role': role,
      'content': content,
      'createdAt': '2026-10-10T$at:00.000Z',
    };

(ChatRepository, _RoutingAdapter) _repoWith(Map<String, Object> routes) {
  final adapter = _RoutingAdapter(routes);
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  return (ChatRepository(dio: dio), adapter);
}

void main() {
  group('ChatSessionModel', () {
    test('lee el preview para los chats sin receta', () {
      final session = ChatSessionModel.fromMap({
        'sessionId': 3,
        'active': false,
        'createdAt': '2026-10-10T12:00:00.000Z',
        'conversationState': {'recipe': null},
        'preview': '¿Qué ceno hoy?',
      });

      expect(session.recipeTitle, isNull);
      expect(session.preview, '¿Qué ceno hoy?');
    });
  });

  group('getSessionMessages', () {
    test('convierte los mensajes en orden y marca quién habla', () async {
      final (repo, _) = _repoWith({
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          messages: [
            _msg('USER', 'hola', at: '12:00'),
            _msg('ASSISTANT', '¡Hola! ¿Qué cocinamos?', at: '12:01'),
          ],
        ),
      });

      final messages = await repo.getSessionMessages(7);

      expect(messages.map((m) => m.text), ['hola', '¡Hola! ¿Qué cocinamos?']);
      expect(messages.map((m) => m.isUser), [true, false]);
    });

    test('pega la receta de la sesión al último mensaje del bot', () async {
      final (repo, _) = _repoWith({
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          recipe: _recipe,
          messages: [
            _msg('USER', 'algo con huevo'),
            _msg('ASSISTANT', 'Te propongo una tortilla'),
            _msg('USER', 'hazla para 2'),
            _msg('ASSISTANT', 'Listo, para 2'),
          ],
        ),
      });

      final messages = await repo.getSessionMessages(7);

      expect(messages[1].recipeData, isNull);
      expect(messages[3].recipeData?.title, 'Tortilla de cebolla');
    });

    test('sin receta en la sesión ningún mensaje lleva tarjeta', () async {
      final (repo, _) = _repoWith({
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          messages: [_msg('USER', 'hola'), _msg('ASSISTANT', 'hola')],
        ),
      });

      final messages = await repo.getSessionMessages(7);

      expect(messages.any((m) => m.isRecipe), isFalse);
    });

    test('recupera el video de youtube guardado en media', () async {
      final (repo, _) = _repoWith({
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          recipe: _recipe,
          media: {
            'youtube': {
              'video_id': 'abc123',
              'title': 'Tortilla fácil',
              'url': 'https://www.youtube.com/watch?v=abc123',
              'thumbnail': 'https://i.ytimg.com/vi/abc123/hqdefault.jpg',
            },
          },
          messages: [_msg('ASSISTANT', 'Tortilla')],
        ),
      });

      final messages = await repo.getSessionMessages(7);

      expect(messages.single.recipeData?.youtubeVideo?.videoId, 'abc123');
    });

    test('una sesión ajena o inexistente da un error entendible', () async {
      final (repo, _) = _repoWith({});

      expect(
        repo.getSessionMessages(99),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensaje',
            contains('No se encontró la sesión'),
          ),
        ),
      );
    });
  });

  group('getActiveSessionId', () {
    test('devuelve el id cuando hay sesión activa', () async {
      final (repo, _) = _repoWith({
        'GET /chat/session': {
          'hasActiveSession': true,
          'session': {'sessionId': 5},
        },
      });

      expect(await repo.getActiveSessionId(), 5);
    });

    test('devuelve null cuando no hay sesión activa', () async {
      final (repo, _) = _repoWith({
        'GET /chat/session': {'hasActiveSession': false},
      });

      expect(await repo.getActiveSessionId(), isNull);
    });
  });

  group('ChatViewModel.openSession', () {
    test('activa la sesión antes de cargar sus mensajes', () async {
      final (repo, adapter) = _repoWith({
        'PUT /chat/sessions/7/activate': {'sessionId': 7, 'active': true},
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          messages: [_msg('USER', 'hola')],
        ),
      });
      final vm = ChatViewModel(repository: repo);
      addTearDown(vm.dispose);

      await vm.openSession(7);

      expect(adapter.calls, [
        'PUT /chat/sessions/7/activate',
        'GET /chat/sessions/7/messages',
      ]);
      expect(vm.messages.single.text, 'hola');
      expect(vm.currentSessionId, 7);
    });

    test('reemplaza los mensajes del chat anterior', () async {
      final (repo, _) = _repoWith({
        'PUT /chat/sessions/7/activate': {'sessionId': 7},
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          messages: [_msg('USER', 'chat siete')],
        ),
        'PUT /chat/sessions/8/activate': {'sessionId': 8},
        'GET /chat/sessions/8/messages': _sessionWithMessages(
          id: 8,
          messages: [_msg('USER', 'chat ocho')],
        ),
      });
      final vm = ChatViewModel(repository: repo);
      addTearDown(vm.dispose);

      await vm.openSession(7);
      await vm.openSession(8);

      expect(vm.messages.map((m) => m.text), ['chat ocho']);
    });

    test('si falla deja el chat actual intacto y expone el error', () async {
      final (repo, _) = _repoWith({
        'PUT /chat/sessions/7/activate': {'sessionId': 7},
        'GET /chat/sessions/7/messages': _sessionWithMessages(
          id: 7,
          messages: [_msg('USER', 'chat siete')],
        ),
      });
      final vm = ChatViewModel(repository: repo);
      addTearDown(vm.dispose);
      await vm.openSession(7);

      await vm.openSession(99);

      expect(vm.messages.single.text, 'chat siete');
      expect(vm.currentSessionId, 7);
      expect(vm.errorMessage, contains('No se encontró la sesión'));
    });
  });

  group('ChatViewModel.loadActiveSession', () {
    test('al abrir el chat repinta la conversación activa', () async {
      final (repo, adapter) = _repoWith({
        'GET /chat/session': {
          'hasActiveSession': true,
          'session': {'sessionId': 5},
        },
        'GET /chat/sessions/5/messages': _sessionWithMessages(
          id: 5,
          messages: [_msg('USER', 'seguimos')],
        ),
      });
      final vm = ChatViewModel(repository: repo);
      addTearDown(vm.dispose);

      await vm.loadActiveSession();

      expect(vm.messages.single.text, 'seguimos');
      expect(vm.currentSessionId, 5);
      // Es la sesión que ya está activa: no hace falta reactivarla.
      expect(adapter.calls, isNot(contains('PUT /chat/sessions/5/activate')));
    });

    test('sin sesión activa deja el chat vacío', () async {
      final (repo, _) = _repoWith({
        'GET /chat/session': {'hasActiveSession': false},
      });
      final vm = ChatViewModel(repository: repo);
      addTearDown(vm.dispose);

      await vm.loadActiveSession();

      expect(vm.messages, isEmpty);
      expect(vm.currentSessionId, isNull);
    });
  });

  test('deleteChat olvida la sesión actual', () async {
    final (repo, _) = _repoWith({
      'PUT /chat/sessions/7/activate': {'sessionId': 7},
      'GET /chat/sessions/7/messages': _sessionWithMessages(
        id: 7,
        messages: [_msg('USER', 'hola')],
      ),
      'PUT /chat/session/close': {'sessionId': 7, 'active': false},
    });
    final vm = ChatViewModel(repository: repo);
    addTearDown(vm.dispose);
    await vm.openSession(7);

    await vm.deleteChat();

    expect(vm.messages, isEmpty);
    expect(vm.currentSessionId, isNull);
  });
}
