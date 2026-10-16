import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/network/rate_limit_state.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_actions_model.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_session_model.dart';
import 'package:nutrilife/features/chatbot/data/models/recipe_model.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/answer_actions.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/attached_food_chips.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/chat_history_drawer.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/chat_welcome_header.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/rate_limit_chip.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/recipe_card_widget.dart';
import 'package:nutrilife/features/nutrition/data/models/fridge_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

/// Responde siempre con el mismo error (o con un cuerpo vacío).
class _FailingAdapter implements HttpClientAdapter {
  _FailingAdapter({this.throwing, this.body = const {}});

  final DioException? throwing;
  final Object body;

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

ChatRepository _repo(_FailingAdapter adapter) => ChatRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://test.local'))
        ..httpClientAdapter = adapter,
    );

const _recipe = RecipeModel(
  title: 'Avena con banano',
  summary: 'Un desayuno rápido.',
  chefReason: 'Porque tienes avena.',
  mealType: 'desayuno',
  difficulty: 'Fácil',
  preparationTimeMinutes: 10,
  servings: 2,
  estimatedCalories: 320,
  tips: [],
  steps: [
    RecipeStep(step: 1, description: 'Cocina la avena.'),
    RecipeStep(step: 2, description: 'Agrega el banano.'),
    RecipeStep(step: 3, description: 'Sirve.'),
  ],
  ingredients: [],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => LocaleState.instance.setPreference(LanguagePreference.system));

  group('ChatRepository en inglés', () {
    setUp(() => LocaleState.instance.setPreference(LanguagePreference.en));

    test('el timeout sale en inglés', () async {
      final repo = _repo(_FailingAdapter(
        throwing: DioException.receiveTimeout(
          timeout: const Duration(seconds: 90),
          requestOptions: RequestOptions(path: '/n8n/chat'),
        ),
      ));

      await expectLater(
        repo.sendMessage('x'),
        throwsA(predicate((e) => e.toString().contains('taking a while'))),
      );
    });

    test('una respuesta sin data sale en inglés', () async {
      final repo = _repo(_FailingAdapter(body: {'success': false}));

      await expectLater(
        repo.sendMessage('x'),
        throwsA(predicate((e) => e.toString().contains('Unexpected response'))),
      );
    });

    test('un message vacío cae en "No reply"', () async {
      final repo = _repo(_FailingAdapter(body: {
        'success': true,
        'data': {'type': 'CHAT', 'message': ' ', 'recipe': null},
      }));

      expect((await repo.sendMessage('x')).text, 'No reply');
    });

    test('sin mensaje del backend, el historial falla en inglés', () async {
      final repo = _repo(_FailingAdapter(
        throwing: DioException.connectionError(
          requestOptions: RequestOptions(path: '/chat/sessions'),
          reason: 'sin red',
        ),
      ));

      await expectLater(
        repo.getSessions(),
        throwsA(predicate((e) => e.toString().contains("Couldn't load your history"))),
      );
    });
  });

  group('ChatViewModel', () {
    ChatViewModel viewModelFailingWith(Object error) {
      final repo = _repo(_FailingAdapter(
        throwing: DioException(
          requestOptions: RequestOptions(path: '/n8n/chat'),
          error: error,
        ),
      ));
      final vm = ChatViewModel(repository: repo);
      addTearDown(vm.dispose);
      return vm;
    }

    test('el aviso del límite de mensajes sale en inglés', () async {
      await LocaleState.instance.setPreference(LanguagePreference.en);
      final vm = viewModelFailingWith(
        RateLimitException(retryAfterSeconds: 150, limit: 10),
      );

      await vm.sendMessage('hola');
      // Espera a que termine el efecto de escritura.
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(
        vm.messages.last.text,
        "You've hit the message limit. Please wait about 3 minutes.",
      );
    });

    test('el aviso del límite de mensajes sigue en español', () async {
      await LocaleState.instance.setPreference(LanguagePreference.es);
      final vm = viewModelFailingWith(
        RateLimitException(retryAfterSeconds: 150, limit: 10),
      );

      await vm.sendMessage('hola');
      // Espera a que termine el efecto de escritura.
      await Future<void>.delayed(const Duration(seconds: 1));

      expect(
        vm.messages.last.text,
        'Espera unos 3 minutos, alcanzaste el límite de mensajes',
      );
    });
  });

  group('widgets del chat', () {
    Future<void> pumpIn(WidgetTester tester, Widget child, String lang) =>
        tester.pumpWidget(l10nApp(Scaffold(body: child), locale: Locale(lang)));

    testWidgets('las etiquetas de alimentos adjuntos traducen la unidad',
        (tester) async {
      const foods = [
        FridgeItemModel(
          fridgeItemId: 4,
          foodId: 11,
          name: 'Banana',
          quantity: 2,
          unit: 'unidad',
          caloriesPerUnit: 89,
          baseUnit: '100 G',
        ),
        FridgeItemModel(
          fridgeItemId: 5,
          foodId: 12,
          name: 'Arroz',
          quantity: 200,
          unit: 'g',
          caloriesPerUnit: 130,
          baseUnit: '100 G',
        ),
      ];

      await pumpIn(tester, const AttachedFoodChips(foods: foods), 'en');
      expect(find.text('Banana · 2 units'), findsOneWidget);
      expect(find.text('Arroz · 200 g'), findsOneWidget);

      await pumpIn(tester, const AttachedFoodChips(foods: foods), 'es');
      expect(find.text('Banana · 2 unidades'), findsOneWidget);
    });

    testWidgets('el historial usa mes corto e idioma del usuario',
        (tester) async {
      final sessions = [
        ChatSessionModel(
          sessionId: 1,
          active: true,
          createdAt: DateTime.now(),
          preview: 'Hola',
        ),
        ChatSessionModel(
          sessionId: 2,
          active: false,
          createdAt: DateTime(2020, 1, 5, 9, 30),
        ),
      ];
      Widget drawer() => ChatHistoryDrawer(
            sessions: sessions,
            isLoading: false,
            onClose: () {},
            onSelect: (_) {},
          );

      await pumpIn(tester, drawer(), 'en');
      expect(find.text('Conversations'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Conversation'), findsOneWidget);
      expect(find.textContaining('Today, '), findsOneWidget);
      expect(find.text('Jan 5'), findsOneWidget);

      await pumpIn(tester, drawer(), 'es');
      expect(find.text('Conversaciones'), findsOneWidget);
      expect(find.textContaining('Hoy, '), findsOneWidget);
      expect(find.text('5 ene'), findsOneWidget);
    });

    testWidgets('la bienvenida sale en inglés', (tester) async {
      await pumpIn(tester, const ChatWelcomeHeader(), 'en');

      expect(find.text('How can I help you today?'), findsOneWidget);
    });

    testWidgets('el chip del límite concuerda en singular y en inglés',
        (tester) async {
      addTearDown(() => DioClient.rateLimit
          .update(limit: null, remaining: null, resetSeconds: null));
      DioClient.rateLimit.update(limit: 10, remaining: 1, resetSeconds: 30);

      await pumpIn(tester, const RateLimitChip(), 'es');
      expect(find.text('Te queda 1 mensaje este minuto'), findsOneWidget);

      await pumpIn(tester, const RateLimitChip(), 'en');
      expect(find.text('You have 1 message left this minute'), findsOneWidget);

      DioClient.rateLimit.update(limit: 10, remaining: 0, resetSeconds: 30);
      await tester.pump();
      expect(find.text('Limit reached · try again in 30s'), findsOneWidget);
    });

    testWidgets('las acciones bajo la respuesta salen en inglés',
        (tester) async {
      await pumpIn(
        tester,
        const AnswerActions(
          actions: ChatActions(showSteps: true, tip: 'Usa fuego bajo'),
          recipe: _recipe,
        ),
        'en',
      );

      expect(find.text('Step by step'), findsOneWidget);
      expect(find.text('Avena con banano · 3 steps · 10 min'), findsOneWidget);
      expect(find.text('See step by step'), findsOneWidget);
      expect(find.text("Chef's tip"), findsOneWidget);
    });

    testWidgets('la tarjeta de receta traduce el tipo de comida y las porciones',
        (tester) async {
      await pumpIn(tester, const RecipeCardWidget(recipe: _recipe), 'en');
      expect(find.text('BREAKFAST'), findsOneWidget);
      expect(find.text('2 SERV.'), findsOneWidget);
      expect(find.text('2 servings'), findsOneWidget);
      expect(find.text('View full recipe'), findsOneWidget);
      // La dificultad la escribe la IA en el idioma del usuario: no se toca.
      expect(find.text('FÁCIL'), findsOneWidget);

      await pumpIn(tester, const RecipeCardWidget(recipe: _recipe), 'es');
      expect(find.text('DESAYUNO'), findsOneWidget);
      expect(find.text('2 PORC.'), findsOneWidget);
      expect(find.text('2 porciones'), findsOneWidget);
    });

    testWidgets('el paso a paso sale en inglés', (tester) async {
      await tester.pumpWidget(l10nApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showRecipeStepsSheet(context, _recipe),
            child: const Text('abrir'),
          ),
        ),
        locale: const Locale('en'),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Swipe to continue'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });
}
