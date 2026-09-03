import 'package:flutter/material.dart';

import '../../features/bot/domain/bot_mood.dart';
import '../../features/bot/presentation/bot_avatar.dart';
import '../state/bot_mood_state.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Inicio'),
          _buildNavItem(1, Icons.restaurant_menu_rounded, 'Alimentos'),
          _buildCenterItem(2, 'IA'),
          _buildNavItem(3, Icons.bar_chart_rounded, 'Progreso'),
          _buildNavItem(4, Icons.person_rounded, 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(18),
              )
            : const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0A6B3F) : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0A6B3F) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterItem(int index, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        BotMoodState.instance.pulse(BotMood.surprised);
        onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0A6B3F), Color(0xFF1E56F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              // El blob va metido dentro del circulo, no a ras: a 50px llenaria
              // el boton entero de blanco y taparia el gradiente de marca.
              child: Center(
                child: ListenableBuilder(
                  listenable: BotMoodState.instance,
                  builder: (context, _) {
                    final s = BotMoodState.instance;
                    return BotAvatar(
                      mood: s.mood,
                      pulseToken: s.pulseToken,
                      pulseMood: s.pulseMood,
                      // 39, no 34: el blob deja un margen de 1/1.15 dentro de
                      // su lienzo (ver kRestBallFraction), asi que la bola
                      // visible mide 39 * 0.8696 = 33.9px. Ese margen es lo que
                      // evita que `surprised` (escala 1.06) se recorte.
                      size: 39,
                    );
                  },
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E56F5) : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
