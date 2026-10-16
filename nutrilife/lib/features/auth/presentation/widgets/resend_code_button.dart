import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import 'auth_form_widgets.dart';

/// "Reenviar código" con cuenta regresiva: el backend acepta uno por minuto, y
/// al abrir la pantalla ya se acaba de enviar uno.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.onResend,
    this.enabled = true,
  });

  /// Pide otro código. Si lanza, la cuenta regresiva no se reinicia.
  final Future<void> Function() onResend;
  final bool enabled;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  static const _cooldownSeconds = 60;

  int _secondsLeft = _cooldownSeconds;
  bool _sending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await widget.onResend();
      if (mounted) _startCountdown();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _secondsLeft > 0;
    return TextButton(
      onPressed: waiting || _sending || !widget.enabled ? null : _resend,
      child: Text(
        waiting
            ? context.l10n.authResendCodeIn(_secondsLeft)
            : context.l10n.authResendCode,
        style: TextStyle(
          color: waiting ? AuthPalette.hint : AuthPalette.primary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
