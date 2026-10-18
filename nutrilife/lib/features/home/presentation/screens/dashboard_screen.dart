import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../../../core/ads/ads_service.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/state/bot_mood_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../features/chatbot/presentation/screens/ai_chat_view.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';
import '../../../hydration/presentation/screens/water_streak_screen.dart';
import '../../../meals/presentation/screens/meal_history_screen.dart';
import '../../../nutrition/presentation/screens/foods_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/guest_banner.dart';
import '../widgets/home_header.dart';
import '../widgets/today_meals_section.dart';
import '../widgets/water_streak_home_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

const _tabsWithBanner = {0, 1, 3};

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  int _progressRefreshToken = 0;
  late final String _userName;
  late final String _hydrationAccountId;

  @override
  void initState() {
    super.initState();
    _userName = widget.user?['name'] ?? currentL10n.commonUser;
    final email = widget.user?['email']?.toString().trim();
    final id = widget.user?['id']?.toString().trim();
    _hydrationAccountId = email != null && email.isNotEmpty
        ? email.toLowerCase()
        : id != null && id.isNotEmpty
        ? id
        : 'default';
    AdsService.instance.setPlan(widget.user?['plan']?.toString());
  }

  void _onTabSelected(int index) {
    setState(() {
      if (index == 3) {
        _progressRefreshToken++;
      }

      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      // Listener FUERA del SafeArea: si estuviera dentro, los taps en la
      // zona del home indicator (zona reservada inferior) no llegarian y
      // los ojos se quedarian en la pose de reposo mirando hacia arriba.
      // HitTestBehavior.translucent: el evento llega al listener pero NO
      // bloquea a los hijos, asi un tap en una tarjeta sigue abriendo la
      // tarjeta Y ademas apunta los ojos hacia ahi.
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onScreenPointer,
        onPointerMove: _onScreenPointer,
        child: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              if (SessionService.isGuest &&
                  SessionService.guestExpiresAt != null)
                GuestBanner(
                  expiresAt: SessionService.guestExpiresAt!,
                  onCreateAccount: _createAccountFromGuest,
                ),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    _buildHomeTab(),
                    FoodsScreen(user: widget.user),
                    const AiChatView(),
                    ProgressScreen(
                      user: widget.user,
                      refreshToken: _progressRefreshToken,
                    ),
                    _buildProfileTab(),
                  ],
                ),
              ),
              // Banner solo en Inicio, Alimentos y Progreso: en el chat
              // taparía el campo de escribir. Se mantiene montado al ocultarlo
              // para no pedir un anuncio nuevo en cada cambio de pestaña.
              Visibility(
                visible: _tabsWithBanner.contains(_currentTab),
                maintainState: true,
                child: const AdBanner(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  Future<void> _openWaterTracker() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WaterStreakScreen(accountId: _hydrationAccountId),
      ),
    );
  }

  /// Convierte un puntero en pantalla (down o move) en coordenadas
  /// normalizadas del bot (1.0 = radio de la bola) y lo empuja a
  /// BotMoodState. El centro del bot se calcula desde MediaQuery segun la
  /// geometria hardcodeada de CustomBottomNavBar: el icono central es la
  /// columna 2 de 5, esta elevado 8px (Transform.translate(0,-8)) y vive
  /// en una nav bar de 76px con 16px de margen inferior. Si esa geometria
  /// cambia, este calculo tambien.
  void _onScreenPointer(PointerEvent e) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final centerX = size.width / 2;
    final centerY = size.height - mq.padding.bottom - 16 - 38 - 8;
    // El radio dibujado por el painter es size.shortestSide/2 * 1/1.15
    // (ver kRestBallFraction en bot_path.dart) sobre el tamano del BotAvatar
    // (39 en custom_bottom_nav_bar). Para el gaze nos sirve cualquier
    // escala: el motor clamp-a a _kMaxGaze. Usamos el radio fisico en
    // pixeles solo para traducir la posicion del puntero a un vector sin
    // unidades exoticas.
    final r0 = 39 * (1 / 1.15) / 2;
    final dx = (e.position.dx - centerX) / r0;
    final dy = (e.position.dy - centerY) / r0;
    // Si el puntero cae casi encima del bot, anulamos el gaze en vez de
    // mandar un vector casi-cero que se queda "mirando al lado equivocado"
    // por el redondeo.
    if (math.sqrt(dx * dx + dy * dy) < 0.1) {
      BotMoodState.instance.setGaze(0, 0);
      return;
    }
    BotMoodState.instance.setGaze(dx, dy);
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.homeSummaryLabel,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.homeGreeting(_userName),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: AppTheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          WaterStreakHomeCard(
            accountId: _hydrationAccountId,
            onTap: _openWaterTracker,
          ),
          const SizedBox(height: 24),
          AiSuggestionCard(onTap: () => _onTabSelected(2)),
          const SizedBox(height: 28),
          TodayMealsSection(
            onOpenHistory: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Sale del invitado y abre el registro encima del login. La cuenta de
  /// invitado se queda hasta que venza; sus datos no pasan a la nueva.
  Future<void> _createAccountFromGuest() async {
    await SessionService.clear();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    navigator.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  Widget _buildProfileTab() {
    return ProfileScreen(
      userName: _userName,
      accountId: _hydrationAccountId,
      onLogout: () async {
        await SessionService.clear();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
    );
  }
}
