import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/network/dio_client.dart';
import 'package:nutrilife/core/network/rate_limit_state.dart';
import 'package:nutrilife/core/state/bot_mood_state.dart';
import 'package:nutrilife/features/bot/domain/bot_mood.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';

/// Doble que nos deja controlar cuando "responde" la IA.
class _RepoFalso extends ChatRepository {
  final Completer<ChatResponse> completer = Completer<ChatResponse>();

  @override
  Future<ChatResponse> sendMessage(String message,
      {List<int> fridgeItemIds = const []}) {
    return completer.future;
  }

  void responde(String texto) => completer.complete(
        ChatResponse(type: ChatResponseType.chat, text: texto),
      );

  void falla() =>
      completer.completeError(Exception('boom'), StackTrace.empty);

  /// Simula el 429: la rama de RateLimitException no asigna _errorMessage,
  /// por eso hace falta la otra mitad de la guarda en el finally.
  void agotaLimite() => completer.completeError(
        RateLimitException(retryAfterSeconds: 60, limit: 5),
        StackTrace.empty,
      );
}

void main() {
  setUp(() => BotMoodState.instance.hold(BotMood.idle));

  // DioClient.rateLimit es un singleton estático: si un test lo deja
  // agotado, contamina los demás tests del proceso. Lo restauramos siempre,
  // pase lo que pase con el test (incluso si una expectativa falla a mitad).
  tearDown(() {
    DioClient.rateLimit.update(limit: 5, remaining: 5, resetSeconds: 60);
  });

  test('mientras espera la respuesta, el bot piensa', () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    final envio = vm.sendMessage('hola');
    expect(BotMoodState.instance.mood, equals(BotMood.thinking));

    repo.responde('que tal');
    await envio;
    vm.dispose();
  });

  test('al llegar la respuesta deja de pensar y guina', () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    final envio = vm.sendMessage('hola');
    repo.responde('que tal');
    await envio;

    expect(BotMoodState.instance.mood, equals(BotMood.idle));
    expect(BotMoodState.instance.pulseMood, equals(BotMood.pleased));
    vm.dispose();
  });

  test('si el envio falla, deja de pensar pero NO guina', () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    // Singleton compartido entre tests: el token de partida puede no ser null.
    final antes = BotMoodState.instance.pulseToken;
    final envio = vm.sendMessage('hola');
    repo.falla();
    await envio;

    expect(BotMoodState.instance.mood, equals(BotMood.idle));
    expect(BotMoodState.instance.pulseToken, equals(antes));
    vm.dispose();
  });

  test('si se agota el limite de peticiones, deja de pensar pero NO guina',
      () async {
    final repo = _RepoFalso();
    final vm = ChatViewModel(repository: repo);

    // Agotamos el limite compartido ANTES de enviar: es la condicion real
    // que activa la segunda mitad de la guarda del finally.
    DioClient.rateLimit.update(limit: 5, remaining: 0, resetSeconds: 60);
    expect(DioClient.rateLimit.isExhausted, isTrue);

    // Singleton compartido entre tests: el token de partida puede no ser null.
    final antes = BotMoodState.instance.pulseToken;
    final envio = vm.sendMessage('hola');
    repo.agotaLimite();
    await envio;

    // La rama de RateLimitException no asigna _errorMessage, asi que sin la
    // guarda del rate limit el bot guinaria contento justo al dormirse.
    expect(BotMoodState.instance.mood, equals(BotMood.idle));
    expect(BotMoodState.instance.pulseToken, equals(antes));
    vm.dispose();
  });
}
