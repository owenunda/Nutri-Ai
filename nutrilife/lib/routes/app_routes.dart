import '../features/auth/auth_routes.dart';
import '../features/home/home_routes.dart';

class AppRoutes {
  static const String initial = AuthRoutes.login;

  static const String login = AuthRoutes.login;
  static const String register = AuthRoutes.register;
  static const String forgotPassword = AuthRoutes.forgotPassword;
  static const String home = HomeRoutes.home;
}
