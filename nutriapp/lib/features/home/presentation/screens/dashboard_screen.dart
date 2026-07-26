import 'package:flutter/material.dart';

import '../../../../core/services/session_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../features/chatbot/presentation/screens/ai_chat_view.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../nutrition/presentation/screens/foods_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/home_header.dart';
import '../widgets/meal_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.user});

  final Map<String, dynamic>? user;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  int _progressRefreshToken = 0;
  late final String _userName;

  @override
  void initState() {
    super.initState();
    _userName = widget.user?['name'] ?? 'Usuario';
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
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
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
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN',
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hola $_userName',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: AppTheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          AiSuggestionCard(
            onTap: () => _onTabSelected(2),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comidas de hoy',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Ver historial',
                style: TextStyle(
                  color: AppTheme.primaryStart,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MealCard(
            emoji: '🥑',
            title: 'Desayuno',
            description: 'Tostada de aguacate • 420 kcal',
            isLogged: true,
          ),
          const SizedBox(height: 12),
          const MealCard(
            emoji: '🥗',
            title: 'Almuerzo',
            description: 'Ensalada de pollo asado • 540 kcal',
            isLogged: true,
          ),
          const SizedBox(height: 12),
          const MealCard(
            emoji: '🍽️',
            title: 'Cena',
            description: 'Aún no registrada',
            isLogged: false,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return ProfileScreen(
      userName: _userName,
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
