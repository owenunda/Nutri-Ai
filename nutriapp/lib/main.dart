import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_flow_navigator.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';
import 'core/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final session = await SessionService.restore();

  Widget home;
  if (!hasSeenOnboarding) {
    home = const AuthFlowNavigator();
  } else if (session != null) {
    home = DashboardScreen(user: session.user);
  } else {
    home = const LoginScreen();
  }

  runApp(MainApp(home: home));
}

class MainApp extends StatelessWidget {
  final Widget home;
  const MainApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Nutri AI",
      theme: AppTheme.lightTheme,
      home: home,
    );
  }
}
