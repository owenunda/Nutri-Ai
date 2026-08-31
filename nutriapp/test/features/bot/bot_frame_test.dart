import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/features/bot/domain/bot_frame.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';

void main() {
  test('pleased y surprised son transitorios; el resto sostenidos', () {
    expect(BotMood.pleased.isTransient, isTrue);
    expect(BotMood.surprised.isTransient, isTrue);
    expect(BotMood.idle.isTransient, isFalse);
    expect(BotMood.thinking.isTransient, isFalse);
    expect(BotMood.sleeping.isTransient, isFalse);
  });

  test('dos BotFrame con los mismos valores son iguales', () {
    BotFrame make() => BotFrame(
          radii: const [1.0, 1.0, 1.0, 1.0],
          rot: 0.5,
          cx: 0,
          cy: 0,
          sx: 1,
          sy: 1,
          bodyAlpha: 1,
          eyes: const [EyeSpec(cx: -0.2, cy: 0, rx: 0.07, ry: 0.17)],
          dots: const [],
        );
    expect(make(), equals(make()));
    expect(make().hashCode, equals(make().hashCode));
  });

  test('un BotFrame con distinto bodyAlpha no es igual', () {
    const a = BotFrame(radii: [1.0], rot: 0, cx: 0, cy: 0, sx: 1, sy: 1, bodyAlpha: 1, eyes: [], dots: []);
    const b = BotFrame(radii: [1.0], rot: 0, cx: 0, cy: 0, sx: 1, sy: 1, bodyAlpha: 0.5, eyes: [], dots: []);
    expect(a, isNot(equals(b)));
  });
}
