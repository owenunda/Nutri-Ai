import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/home/presentation/widgets/water_streak_home_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('abre el reto al tocar la tarjeta de Inicio', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      l10nApp(
        Scaffold(
          body: WaterStreakHomeCard(
            accountId: 'user@example.com',
            onTap: () async {
              opened = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('water-streak-home-card')));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.textContaining('0/4 vasos hoy'), findsOneWidget);
  });
}
