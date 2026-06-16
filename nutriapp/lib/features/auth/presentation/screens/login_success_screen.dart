import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';

class LoginSuccessScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const LoginSuccessScreen({super.key, this.user});

  @override
  State<LoginSuccessScreen> createState() => _LoginSuccessScreenState();
}

class _LoginSuccessScreenState extends State<LoginSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Redirección automática al Dashboard después de 1.5 segundos, pasando el usuario
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: widget.user),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryStart,
                  size: 96,
                ),
                SizedBox(height: 24),
                Text(
                  'Iniciaste sesión con éxito',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1E2A24),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Bienvenido de nuevo. Has ingresado correctamente a tu cuenta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF595C5E),
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
