import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilife/core/state/locale_state.dart';
import 'package:nutrilife/features/legal/data/legal_documents.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('los documentos salen en el idioma activo', () async {
    await LocaleState.instance.setPreference(LanguagePreference.es);
    final esTerms = LegalDocuments.terms.title;

    await LocaleState.instance.setPreference(LanguagePreference.en);
    final enTerms = LegalDocuments.terms.title;
    final enPrivacy = LegalDocuments.privacy.title;

    expect(enTerms, isNot(esTerms));
    expect(enTerms, 'Terms and Conditions');
    expect(enPrivacy, 'Privacy Policy');
  });

  test('las dos versiones tienen las mismas secciones', () {
    expect(LegalDocumentsEn.terms.sections.length, LegalDocumentsEs.terms.sections.length);
    expect(LegalDocumentsEn.privacy.sections.length, LegalDocumentsEs.privacy.sections.length);
  });

  test('las dos versiones tienen la misma estructura de bloques', () {
    String shape(LegalBlock b) => switch (b) {
          LegalParagraph() => 'p',
          LegalNote() => 'n',
          LegalBullets(:final items) => 'b${items.length}',
        };

    String shapeOf(LegalDocument d) => [
          d.intro.map(shape).join(','),
          for (final s in d.sections) s.blocks.map(shape).join(','),
        ].join('|');

    expect(shapeOf(LegalDocumentsEn.terms), shapeOf(LegalDocumentsEs.terms));
    expect(shapeOf(LegalDocumentsEn.privacy), shapeOf(LegalDocumentsEs.privacy));
  });
}
