import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/core/state/bot_mood_state.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/chatbot/data/chat_repository.dart';
import 'package:nutriapp/features/chatbot/presentation/controllers/chat_view_model.dart';

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
}

void main() {
  setUp(() => BotMoodState.instance.hold(BotMood.idle));

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
}
