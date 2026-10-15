import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/legal_documents.dart';

Future<void> openLegalDocument(BuildContext context, LegalDocument document) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => LegalDocumentScreen(document: document)),
  );
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LegalColors.background,
      appBar: AppBar(
        backgroundColor: _LegalColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.onSurface,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            Text(
              document.title,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppTheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.legalLastUpdated(
                Localizations.localeOf(context).languageCode == 'en'
                    ? kLegalUpdatedAtEn
                    : kLegalUpdatedAtEs,
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            for (final block in document.intro) _LegalBlockView(block: block),
            for (final section in document.sections) ...[
              const SizedBox(height: 18),
              Text(
                section.title,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              for (final block in section.blocks) _LegalBlockView(block: block),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalBlockView extends StatelessWidget {
  const _LegalBlockView({required this.block});

  final LegalBlock block;

  static const _bodyStyle = TextStyle(
    fontFamily: 'Inter',
    color: AppTheme.onSurface,
    fontSize: 15,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: switch (block) {
        LegalParagraph(:final text) => Text(text, style: _bodyStyle),
        LegalBullets(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 9, right: 10, left: 2),
                      child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: AppTheme.primaryStart,
                      ),
                    ),
                    Expanded(child: Text(item, style: _bodyStyle)),
                  ],
                ),
              ),
          ],
        ),
        LegalNote(:final text) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _LegalColors.note,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: _bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      },
    );
  }
}

class _LegalColors {
  const _LegalColors._();

  static const Color background = Color(0xFFF5F7F9);
  static const Color note = Color(0xFFDCFCE7);
}
