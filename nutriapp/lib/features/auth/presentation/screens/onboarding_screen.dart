import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),

          child: Column(
            children: [
              // Espacio superior
              const SizedBox(height: 56),

              const SizedBox(height: 24),



              // =========================
              // Imagen principal
              // =========================
              Container(
                width: 320,
                height: 340,

                decoration: BoxDecoration(
                  color: const Color(0xFFCFECC7),

                  borderRadius: BorderRadius.circular(48),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),

                  child: Image.asset(
                    'assets/images/nutria.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),

              // =========================
              // Título principal
              // =========================
              const Text(
                'IA nutricional\npersonalizada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 16),

              // =========================
              // Descripción
              // =========================
              const Text(
                'Tu asistente nutricional inteligente te ayuda a mejorar tu alimentación según tus objetivos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Espacio inferior
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}
