import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriapp/core/state/bot_mood_state.dart';
import 'package:nutriapp/core/widgets/custom_bottom_nav_bar.dart';
import 'package:nutriapp/features/bot/domain/bot_mood.dart';
import 'package:nutriapp/features/bot/presentation/bot_avatar.dart';

Widget _app({required void Function(int) onTab}) => MaterialApp(
      home: Scaffold(
        bottomNavigationBar: CustomBottomNavBar(selectedIndex: 2, onTabSelected: onTab),
      ),
    );

void main() {
  setUp(() {
    BotMoodState.instance.hold(BotMood.idle);
  });

  testWidgets('el boton IA pinta un BotAvatar en vez del icono', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    expect(find.byType(BotAvatar), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
  });

  testWidgets('los otros cuatro tabs conservan sus iconos', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('tocar el boton IA sigue notificando el indice 2', (tester) async {
    int? tocado;
    await tester.pumpWidget(_app(onTab: (i) => tocado = i));
    await tester.tap(find.byType(BotAvatar));
    await tester.pump();
    expect(tocado, equals(2));
  });

  testWidgets('tocar el boton IA dispara un pulse de sorpresa', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    // BotMoodState.instance es un singleton que sobrevive entre tests del
    // fichero, asi que comparamos el token antes/despues en vez de asumir null.
    final antes = BotMoodState.instance.pulseToken;
    await tester.tap(find.byType(BotAvatar));
    await tester.pump();
    expect(BotMoodState.instance.pulseToken, isNot(equals(antes)));
    expect(BotMoodState.instance.pulseMood, equals(BotMood.surprised));
  });

  testWidgets('el avatar refleja el mood del estado compartido', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    BotMoodState.instance.hold(BotMood.thinking);
    await tester.pump();
    expect(tester.widget<BotAvatar>(find.byType(BotAvatar)).mood, equals(BotMood.thinking));
  });

  testWidgets('el avatar mide 39 para dejar el margen del blob dentro del circulo', (tester) async {
    await tester.pumpWidget(_app(onTab: (_) {}));
    // 39, no 50: el blob deja un margen de kRestBallFraction (1/1.15) dentro
    // de su lienzo, asi que la bola visible mide 39 * 0.8696 = 33.9px dentro
    // del circulo de 50. Con 50 el blob taparia el gradiente entero.
    expect(tester.widget<BotAvatar>(find.byType(BotAvatar)).size, equals(39));
  });
}
