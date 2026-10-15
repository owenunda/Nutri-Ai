import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_actions_model.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_message_model.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/answer_actions.dart';

import '../../helpers/l10n_app.dart';

class _RoutingAdapter implements HttpClientAdapter {
  _RoutingAdapter(this.routes);

  final Map<String, Object> routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = routes['${options.method} ${options.path}'];
    return ResponseBody.fromString(
      jsonEncode({'success': data != null, 'data': data}),
      data == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatRepository _repo(Map<String, Object> routes) => ChatRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = _RoutingAdapter(routes),
    );

const _recipeMap = {
  'title': 'Ensalada de banana y pera',
  'summary': 'Fresca',
  'chef_reason': 'Te recomiendo esta ensalada',
  'preparation_time_minutes': 5,
  'tips': ['Agrega limón'],
  'steps': [
    {'step': 1, 'description': 'Lava la pera'},
    {'step': 2, 'description': 'Pela la banana'},
    {'step': 3, 'description': 'Mezcla todo'},
  ],
  'ingredients_used': [],
};

final _recipe = RecipeModel.fromMap(_recipeMap);

Map<String, Object?> _msg(String role, String content, [Object? metadata]) => {
      'role': role,
      'content': content,
      'metadata': metadata,
      'createdAt': '2026-10-12T12:00:00.000Z',
    };

void main() {
  group('ChatActions.fromMap', () {
    test('lee paso a paso, paso destacado y tip', () {
      final a = ChatActions.fromMap({
        'steps': {'focus_step': 3},
        'tip': 'Agrega limón',
      })!;

      expect(a.showSteps, isTrue);
      expect(a.focusStep, 3);
      expect(a.tip, 'Agrega limón');
    });

    test('sin nada que mostrar devuelve null', () {
      expect(ChatActions.fromMap(null), isNull);
      expect(ChatActions.fromMap({'steps': null, 'tip': '  '}), isNull);
    });
  });

  group('respuestas con acciones', () {
    test('sendMessage trae las acciones del envelope', () async {
      final repo = _repo({
        'POST /n8n/chat': {
          'type': 'ANSWER',
          'message': '¡Claro! Aquí tienes el paso a paso 👇',
          'recipe': null,
          'actions': {
            'steps': {'focus_step': null},
            'tip': 'Agrega limón',
          },
        },
      });

      final reply = await repo.sendMessage('explícame la receta');

      expect(reply.actions?.showSteps, isTrue);
      expect(reply.actions?.focusStep, isNull);
      expect(reply.actions?.tip, 'Agrega limón');
    });

    test('el historial repinta las acciones guardadas en metadata', () async {
      final repo = _repo({
        'GET /chat/sessions/4/messages': {
          'session': {
            'conversationState': {'recipe': _recipeMap},
          },
          'messages': [
            _msg('USER', 'una ensalada'),
            _msg('ASSISTANT', 'Te recomiendo esta ensalada', {'type': 'RECIPE'}),
            _msg('USER', 'explícame el paso 2'),
            _msg('ASSISTANT', 'En el paso 2...', {
              'type': 'ANSWER',
              'actions': {
                'steps': {'focus_step': 2},
                'tip': null,
              },
            }),
          ],
        },
      });

      final messages = await repo.getSessionMessages(4);

      expect(messages[3].actions?.focusStep, 2);
      // La tarjeta de receta va en el mensaje que la generó, no en la
      // respuesta que vino después.
      expect(messages[1].recipeData?.title, 'Ensalada de banana y pera');
      expect(messages[3].recipeData, isNull);
    });
  });

  group('ChatViewModel.recipeFor', () {
    test('usa la receta más reciente anterior al mensaje', () {
      final vm = ChatViewModel(repository: _repo({}));
      addTearDown(vm.dispose);

      final messages = [
        ChatMessageModel(
          text: 'Te recomiendo',
          isUser: false,
          timestamp: DateTime(2026),
          recipeData: _recipe,
        ),
        ChatMessageModel(text: 'Claro', isUser: false, timestamp: DateTime(2026)),
      ];

      expect(ChatViewModel.recipeBefore(messages, 1)?.title, _recipe.title);
    });

    test('si no hay receta antes usa la última de la conversación', () {
      final messages = [
        ChatMessageModel(text: 'Claro', isUser: false, timestamp: DateTime(2026)),
        ChatMessageModel(
          text: 'Listo',
          isUser: false,
          timestamp: DateTime(2026),
          recipeData: _recipe,
        ),
      ];

      expect(ChatViewModel.recipeBefore(messages, 0)?.title, _recipe.title);
    });
  });

  group('AnswerActions', () {
    Future<void> pump(WidgetTester tester, ChatActions actions,
        {RecipeModel? recipe}) {
      return tester.pumpWidget(l10nApp(
        Scaffold(body: AnswerActions(actions: actions, recipe: recipe)),
      ));
    }

    testWidgets('el paso a paso se abre en el paso que se preguntó',
        (tester) async {
      await pump(
        tester,
        const ChatActions(showSteps: true, focusStep: 2),
        recipe: _recipe,
      );

      await tester.tap(find.text('Ver paso a paso'));
      await tester.pumpAndSettle();

      expect(find.text('Paso 2 de 3'), findsOneWidget);
      expect(find.text('Pela la banana'), findsOneWidget);
    });

    testWidgets('sin paso concreto arranca en el primero', (tester) async {
      await pump(tester, const ChatActions(showSteps: true), recipe: _recipe);

      await tester.tap(find.text('Ver paso a paso'));
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 3'), findsOneWidget);
    });

    testWidgets('muestra el tip', (tester) async {
      await pump(tester, const ChatActions(tip: 'Agrega limón'));

      expect(find.text('Agrega limón'), findsOneWidget);
    });

    testWidgets('sin receta no ofrece el paso a paso', (tester) async {
      await pump(tester, const ChatActions(showSteps: true, tip: 'Agrega limón'));

      expect(find.text('Ver paso a paso'), findsNothing);
      expect(find.text('Agrega limón'), findsOneWidget);
    });
  });
}
