import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [

              const Text(
                'NutriAI',
                style: TextStyle(
                  color: Color(0xFF0A6B3F),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF64748B),
            size: 28,
          ),
        ],
      ),
    );
  }
}
