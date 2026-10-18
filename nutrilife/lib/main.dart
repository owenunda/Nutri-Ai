import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ads/ads_service.dart';
import 'core/l10n/l10n.dart';
import 'core/state/locale_state.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/navigator_key.dart';
import 'features/auth/presentation/screens/auth_flow_navigator.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';
import 'core/services/purchase_service.dart';
import 'core/services/session_service.dart';
import 'core/widgets/dismiss_keyboard_on_tap.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleState.instance.load();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  await PurchaseService.instance.init();
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

  // Después del primer frame: el formulario de consentimiento y el aviso de
  // seguimiento de iOS necesitan la app ya en pantalla.
  WidgetsBinding.instance.addPostFrameCallback((_) => AdsService.instance.init());
}

class MainApp extends StatelessWidget {
  final Widget home;
  const MainApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleState.instance,
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.lightTheme,
        locale: LocaleState.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        // Con "Sistema" y un teléfono en un idioma sin traducción: inglés.
        localeResolutionCallback: (device, supported) => supported.firstWhere(
          (l) => l.languageCode == device?.languageCode,
          orElse: () => const Locale('en'),
        ),
        builder: (context, child) => DismissKeyboardOnTap(child: child!),
        home: home,
      ),
    );
  }
}
