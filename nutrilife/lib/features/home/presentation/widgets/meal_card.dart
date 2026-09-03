import 'package:flutter/material.dart';

class MealCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final bool isLogged;

  const MealCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isLogged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLogged ? Colors.white : const Color(0xFFF1F5F9), // surface_container_lowest vs surface_container_low
        borderRadius: BorderRadius.circular(24),
        boxShadow: isLogged
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLogged ? const Color(0xFFFFF7ED) : const Color(0xFFE2E8F0),
              boxShadow: isLogged ? [
                 BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 28, color: isLogged ? null : const Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2C2F31),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLogged ? Colors.white : const Color(0xFF0A6B3F),
              // No-line rule: Instead of border, use shadow for logged state
              boxShadow: isLogged ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Icon(
              Icons.add_rounded,
              color: isLogged ? const Color(0xFF0A6B3F) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
