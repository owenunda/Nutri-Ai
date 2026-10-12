import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';

class _RepoFalso extends ChatRepository {
  _RepoFalso(this.texto);

  final String texto;

  @override
  Future<ChatResponse> sendMessage(String message,
      {List<int> fridgeItemIds = const []}) async {
    return ChatResponse(type: ChatResponseType.chat, text: texto);
  }
}

/// Un surrogate alto sin su pareja es lo que Flutter rechaza al pintar.
bool _terminaEnMedioEmoji(String s) {
  if (s.isEmpty) return false;
  final last = s.codeUnitAt(s.length - 1);
  return last >= 0xD800 && last <= 0xDBFF;
}

void main() {
  test('el efecto de escritura nunca corta un emoji por la mitad', () async {
    // El emoji arranca en posición impar: con saltos de 2 unidades UTF-16
    // el corte cae justo entre sus dos mitades.
    const respuesta = '¡Hola! Soy NutriLife 👋 ¿qué cocinamos? 🍳🥑';
    final vm = ChatViewModel(repository: _RepoFalso(respuesta));
    addTearDown(vm.dispose);

    final vistos = <String>[];
    vm.addListener(() {
      if (vm.messages.length > 1) vistos.add(vm.messages.last.text);
    });

    await vm.sendMessage('hola');
    await Future<void>.delayed(const Duration(milliseconds: 800));

    expect(vistos.where(_terminaEnMedioEmoji), isEmpty);
    expect(vm.messages.last.text, respuesta);
  });
}
