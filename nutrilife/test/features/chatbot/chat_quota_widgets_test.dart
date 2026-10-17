import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/chatbot/data/models/chat_quota_model.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/chat_quota_blocked_card.dart';
import 'package:nutrilife/features/chatbot/presentation/widgets/chat_quota_chip.dart';

import '../../helpers/l10n_app.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('es')}) =>
    l10nApp(Scaffold(body: Center(child: child)), locale: locale);

void main() {
  group('ChatQuotaChip', () {
    testWidgets('muestra cuántos mensajes quedan', (tester) async {
      await tester.pumpWidget(_wrap(const ChatQuotaChip(
        quota: ChatQuota(unlimited: false, limit: 3, used: 1, remaining: 2),
      )));

      expect(find.text('2 de 3 mensajes hoy'), findsOneWidget);
    });

    testWidgets('en inglés', (tester) async {
      await tester.pumpWidget(_wrap(
        const ChatQuotaChip(
          quota: ChatQuota(unlimited: false, limit: 3, used: 2, remaining: 1),
        ),
        locale: const Locale('en'),
      ));

      expect(find.text('1 of 3 messages today'), findsOneWidget);
    });

    testWidgets('PRO no ve el contador', (tester) async {
      await tester.pumpWidget(
          _wrap(const ChatQuotaChip(quota: ChatQuota(unlimited: true))));

      expect(find.byKey(const ValueKey('chat-quota-chip')), findsNothing);
    });

    testWidgets('sin cuota no hay contador', (tester) async {
      await tester.pumpWidget(_wrap(const ChatQuotaChip(quota: null)));

      expect(find.byKey(const ValueKey('chat-quota-chip')), findsNothing);
    });
  });

  group('ChatQuotaBlockedCard', () {
    final resetAt = DateTime(2026, 10, 18);

    testWidgets('FREE: título, hora de reinicio y botón a Premium',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(ChatQuotaBlockedCard(
        quota: ChatQuota(
          unlimited: false,
          limit: 3,
          used: 3,
          remaining: 0,
          resetAt: resetAt,
          exhausted: true,
        ),
        onGoPremium: () => taps++,
      )));

      expect(find.text('Usaste tus 3 mensajes de hoy'), findsOneWidget);
      expect(find.textContaining('Se reinician a las'), findsOneWidget);
      await tester.tap(find.text('Hazte Premium'));
      expect(taps, 1);
    });

    testWidgets('PRO en el tope: uso justo y sin botón', (tester) async {
      await tester.pumpWidget(_wrap(ChatQuotaBlockedCard(
        quota: ChatQuota(unlimited: true, resetAt: resetAt, exhausted: true),
      )));

      expect(find.text('Llegaste al límite de uso justo de hoy'), findsOneWidget);
      expect(find.text('Hazte Premium'), findsNothing);
    });
  });
}
