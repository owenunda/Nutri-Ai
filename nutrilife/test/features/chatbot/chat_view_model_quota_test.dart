import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/chatbot/data/chat_repository.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_quota_model.dart';
import 'package:nutrilife/features/chatbot/presentation/controllers/chat_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepoFalso extends ChatRepository {
  _RepoFalso() : super(dio: Dio());

  ChatQuota? quotaInicial;
  Object? errorAlEnviar;
  ChatResponse respuesta =
      const ChatResponse(type: ChatResponseType.chat, text: 'listo');

  @override
  Future<ChatQuota?> getQuota() async => quotaInicial;

  @override
  Future<ChatResponse> sendMessage(String message,
      {List<int> fridgeItemIds = const [], List<int> foodIds = const []}) async {
    if (errorAlEnviar != null) throw errorAlEnviar!;
    return respuesta;
  }
}

const _dosDeTres = ChatQuota(unlimited: false, limit: 3, used: 1, remaining: 2);
const _agotada =
    ChatQuota(unlimited: false, limit: 3, used: 3, remaining: 0, exhausted: true);
const _usoJusto = ChatQuota(unlimited: true, exhausted: true);

void main() {
  late _RepoFalso repo;
  late ChatViewModel vm;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleState.instance.setPreference(LanguagePreference.es);
    repo = _RepoFalso();
    vm = ChatViewModel(repository: repo);
  });

  tearDown(() => vm.dispose());

  test('loadQuota guarda la cuota del backend', () async {
    repo.quotaInicial = _dosDeTres;

    await vm.loadQuota();

    expect(vm.quota?.remaining, 2);
    expect(vm.isQuotaExhausted, isFalse);
  });

  test('sin cuota del backend no hay bloqueo', () async {
    await vm.loadQuota();

    expect(vm.quota, isNull);
    expect(vm.isQuotaExhausted, isFalse);
  });

  test('cada respuesta actualiza la cuota', () async {
    repo.respuesta = const ChatResponse(
      type: ChatResponseType.chat,
      text: 'listo',
      quota: _agotada,
    );

    await vm.sendMessage('hola');

    expect(vm.quota?.remaining, 0);
    expect(vm.isQuotaExhausted, isTrue);
  });

  test('el límite del día bloquea y el bot lo explica', () async {
    repo.errorAlEnviar = const ChatQuotaExceededException(_agotada);

    await vm.sendMessage('hola');

    expect(vm.isQuotaExhausted, isTrue);
    expect(vm.errorMessage, isNull);
    expect(vm.messages.last.isUser, isFalse);
    expect(vm.messages.last.fullText, startsWith('Por hoy ya usaste tus mensajes'));
  });

  test('el tope de uso justo usa su propio texto', () async {
    repo.errorAlEnviar = const ChatQuotaExceededException(_usoJusto);

    await vm.sendMessage('hola');

    expect(vm.isQuotaExhausted, isTrue);
    expect(vm.messages.last.fullText, startsWith('Hoy hablamos muchísimo'));
  });

  group('cambio de día', () {
    final resetAt = DateTime(2026, 10, 18);
    final agotadaHastaMedianoche = ChatQuota(
      unlimited: false,
      limit: 3,
      used: 3,
      remaining: 0,
      resetAt: resetAt,
      exhausted: true,
    );

    test('pasada la hora de reinicio ya no está bloqueado', () async {
      final despues = ChatViewModel(
        repository: repo,
        now: () => resetAt.add(const Duration(minutes: 1)),
      );
      addTearDown(despues.dispose);
      repo.quotaInicial = agotadaHastaMedianoche;

      await despues.loadQuota();

      expect(despues.quota?.exhausted, isTrue);
      expect(despues.isQuotaExhausted, isFalse);
    });

    test('antes de la hora de reinicio sigue bloqueado', () async {
      final antes = ChatViewModel(
        repository: repo,
        now: () => resetAt.subtract(const Duration(minutes: 1)),
      );
      addTearDown(antes.dispose);
      repo.quotaInicial = agotadaHastaMedianoche;

      await antes.loadQuota();

      expect(antes.isQuotaExhausted, isTrue);
    });
  });
}
