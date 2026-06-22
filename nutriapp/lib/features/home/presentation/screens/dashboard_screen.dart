import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../widgets/ai_suggestion_card.dart';
import '../../../../features/chatbot/presentation/views/ai_chat_view.dart';
import '../../../foods/presentation/screens/foods_screen.dart';

import '../widgets/home_header.dart';
import '../widgets/meal_card.dart';


class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTab = 0;
  late final String _userName;

  @override
  void initState() {
    super.initState();
    _userName = widget.user?['name'] ?? 'Usuario';
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // surface per DESIGN.md
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildHomeTab(),
                  FoodsScreen(user: widget.user), // Foods tab
                  const AiChatView(),      // AI tab
                  const SizedBox.shrink(), // Progress tab blank
                  const SizedBox.shrink(), // Profile tab blank
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

  // ----------------------------------------------------
  // PESTAÑA INICIO (HOME)
  // ----------------------------------------------------
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hola $_userName',
            style: const TextStyle(
              color: Color(0xFF2C2F31), // on_surface
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          
          // Tarjeta: Pregúntale a la IA qué comer
          AiSuggestionCard(
            onTap: () => _onTabSelected(2),
          ),
          
          const SizedBox(height: 32),
          
          // Comidas de hoy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Comidas de hoy',
                style: TextStyle(
                  color: Color(0xFF2C2F31), // on_surface
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Ver historial',
                style: TextStyle(
                  color: Color(0xFF0A6B3F),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
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
          

          const SizedBox(height: 32), // Padding inferior
        ],
      ),
    );
  }
}
