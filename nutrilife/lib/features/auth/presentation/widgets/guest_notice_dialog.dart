import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';

/// Explica la cuenta de invitado antes de crearla. true si eligió entrar.
Future<bool> showGuestNoticeDialog(BuildContext context) async {
  final l10n = context.l10n;
  final points = [
    l10n.authGuestDialogSample,
    l10n.authGuestDialogExpires,
    l10n.authGuestDialogFree,
    l10n.authGuestDialogCreateAccount,
  ];

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.authGuestDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $point'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.authGuestDialogConfirm),
        ),
      ],
    ),
  );
  return confirmed == true;
}
