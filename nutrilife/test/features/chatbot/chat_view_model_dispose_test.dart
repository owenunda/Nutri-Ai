import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_message_model.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';

/// Repositorio que responde solo cuando el test lo decide.
class _RepoLento extends ChatRepository {
  final reply = Completer<ChatResponse>();
  final activeId = Completer<int?>();
  final history = Completer<List<ChatMessageModel>>();

  @override
  Future<ChatResponse> sendMessage(String message,
          {List<int> fridgeItemIds = const []}) =>
      reply.future;

  @override
  Future<int?> getActiveSessionId() => activeId.future;

  @override
  Future<List<ChatMessageModel>> getSessionMessages(int sessionId) =>
      history.future;

  @override
  Future<void> activateSession(int sessionId) async {}
}

void main() {
  // Pasa cuando un 401 manda al login con la respuesta del bot en camino:
  // la pantalla del chat se destruye antes de que llegue.
  test('la respuesta que llega después de cerrar el chat no revienta',
      () async {
    final repo = _RepoLento();
    final vm = ChatViewModel(repository: repo);

    final pending = vm.sendMessage('explícame la receta');
    vm.dispose();
    repo.reply.complete(
      const ChatResponse(type: ChatResponseType.answer, text: '¡Claro! 👇'),
    );

    await expectLater(pending, completes);
    // El efecto de escritura no debe quedar corriendo tras el dispose.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('un error que llega después de cerrar el chat no revienta', () async {
    final repo = _RepoLento();
    final vm = ChatViewModel(repository: repo);

    final pending = vm.sendMessage('hola');
    vm.dispose();
    repo.reply.completeError(Exception('401'), StackTrace.empty);

    await expectLater(pending, completes);
  });

  test('cargar la sesión activa después de cerrar el chat no revienta',
      () async {
    final repo = _RepoLento();
    final vm = ChatViewModel(repository: repo);

    final pending = vm.loadActiveSession();
    vm.dispose();
    repo.activeId.complete(5);
    repo.history.complete([]);

    await expectLater(pending, completes);
  });

  test('abrir un chat del historial después de cerrar no revienta', () async {
    final repo = _RepoLento();
    final vm = ChatViewModel(repository: repo);

    final pending = vm.openSession(7);
    vm.dispose();
    repo.history.complete([]);

    await expectLater(pending, completes);
  });
}
