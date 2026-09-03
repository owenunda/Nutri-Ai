import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/core/state/bot_mood_state.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';

void main() {
  test('arranca en idle', () {
    expect(BotMoodState().mood, equals(BotMood.idle));
  });

  test('hold notifica solo cuando el valor cambia', () {
    final s = BotMoodState();
    var avisos = 0;
    s.addListener(() => avisos++);

    s.hold(BotMood.thinking);
    expect(avisos, equals(1));

    s.hold(BotMood.thinking); // mismo valor: no debe notificar
    expect(avisos, equals(1));

    s.hold(BotMood.idle);
    expect(avisos, equals(2));
  });

  test('hold ignora los moods transitorios', () {
    final s = BotMoodState();
    s.hold(BotMood.pleased);
    expect(s.mood, equals(BotMood.idle));
  });

  test('pulse cambia el token en cada llamada', () {
    final s = BotMoodState();
    s.pulse(BotMood.pleased);
    final t1 = s.pulseToken;
    s.pulse(BotMood.pleased);
    expect(s.pulseToken, isNot(equals(t1)));
    expect(s.pulseMood, equals(BotMood.pleased));
  });

  test('pulse ignora los moods sostenidos', () {
    final s = BotMoodState();
    s.pulse(BotMood.thinking);
    expect(s.pulseToken, isNull);
  });

  test('pulse no altera el mood sostenido', () {
    final s = BotMoodState()..hold(BotMood.thinking);
    s.pulse(BotMood.pleased);
    expect(s.mood, equals(BotMood.thinking));
  });

  test('hold no borra el token de pulse', () {
    final s = BotMoodState()..pulse(BotMood.pleased);
    final token = s.pulseToken;
    s.hold(BotMood.thinking);
    expect(s.pulseToken, equals(token));
    expect(s.pulseMood, equals(BotMood.pleased));
  });

  test('instance comparte estado entre referencias', () {
    // El singleton debería compartir estado
    BotMoodState.instance.hold(BotMood.thinking);

    // Obtener una referencia nueva al mismo singleton
    final ref2 = BotMoodState.instance;
    expect(ref2.mood, equals(BotMood.thinking));

    // Una instancia suelta NO se ve afectada
    final suelto = BotMoodState();
    expect(suelto.mood, equals(BotMood.idle));

    // Limpiar para no afectar otros tests
    BotMoodState.instance.hold(BotMood.idle);
  });
}
