import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/features/legal/data/legal_documents.dart';
import 'package:nutrilife/features/legal/presentation/screens/legal_document_screen.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('la fecha de actualización sale en español', (tester) async {
    await tester.pumpWidget(
      l10nApp(LegalDocumentScreen(document: LegalDocumentsEs.terms)),
    );
    expect(find.text('Términos y Condiciones'), findsOneWidget);
    expect(find.text('Última actualización: $kLegalUpdatedAtEs'), findsOneWidget);
  });

  testWidgets('la fecha de actualización sale en inglés', (tester) async {
    await tester.pumpWidget(
      l10nApp(
        LegalDocumentScreen(document: LegalDocumentsEn.terms),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('Last updated: $kLegalUpdatedAtEn'), findsOneWidget);
  });
}
