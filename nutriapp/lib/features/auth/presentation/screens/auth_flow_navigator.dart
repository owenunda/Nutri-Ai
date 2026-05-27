import 'package:flutter/material.dart';
import '../../../../core/widgets/primary_button.dart';
import 'discover_foods_screen.dart';
import 'onboarding_screen.dart';
import 'analyze_progress_screen.dart';
import 'login_screen.dart';

class AuthFlowNavigator extends StatefulWidget {
  const AuthFlowNavigator({super.key});

  @override
  State<AuthFlowNavigator> createState() => _AuthFlowNavigatorState();
}

class _AuthFlowNavigatorState extends State<AuthFlowNavigator> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Cálculos de dots indicadores interactivos basados en el swipe exacto
    final t1 = (1.0 - _currentPage).clamp(0.0, 1.0);
    final t2 = (1.0 - (_currentPage - 1.0).abs()).clamp(0.0, 1.0);
    final t3 = (_currentPage - 1.0).clamp(0.0, 1.0);

    final dot1Width = 8.0 + (16.0 * t1);
    final dot2Width = 8.0 + (16.0 * t2);
    final dot3Width = 8.0 + (16.0 * t3);

    final dot1Color = Color.lerp(
      const Color(0xFFCBD5E1),
      const Color(0xFF0A6B3F),
      t1,
    )!;

    final dot2Color = Color.lerp(
      const Color(0xFFCBD5E1),
      const Color(0xFF0A6B3F),
      t2,
    )!;

    final dot3Color = Color.lerp(
      const Color(0xFFCBD5E1),
      const Color(0xFF0A6B3F),
      t3,
    )!;

    // 2. Determinar texto y acción del botón principal de forma dinámica
    final int roundedPage = _currentPage.round();
    String buttonText = 'Siguiente paso';
    VoidCallback buttonAction = _nextPage;

    if (roundedPage == 1) {
      buttonText = 'Continuar';
      buttonAction = _nextPage;
    } else if (roundedPage == 2) {
      buttonText = 'Comenzar';
      buttonAction = () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      };
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // LUZ DE FONDO SUPERIOR
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: const Color(0xFF0A6B3F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // El PageView solo contendrá la sección ilustrativa y los textos
          PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: const [
              DiscoverFoodsScreen(),
              OnboardingScreen(),
              AnalyzeProgressScreen(),
            ],
          ),
          
          // Header Global Fijo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NutriAI',
                    style: TextStyle(
                      color: Color(0xFF0A6B3F),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _currentPage >= 1.5 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _currentPage >= 1.5,
                      child: TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOutCubic,
                          );
                        },
                        child: const Text(
                          'SALTAR',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Global Fijo Unificado
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
                top: 32.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF8FAFC).withValues(alpha: 0.9),
                    const Color(0xFFF8FAFC).withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots interactivos con animación fluida
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration.zero,
                          width: dot1Width,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot1Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: Duration.zero,
                          width: dot2Width,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot2Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: Duration.zero,
                          width: dot3Width,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot3Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón Principal Unificado con transición fluida (AnimatedSwitcher)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.15),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: PrimaryButton(
                        key: ValueKey<String>(buttonText),
                        textButton: buttonText,
                        width: double.infinity,
                        onPressed: buttonAction,
                      ),
                    ),
                    
                    // Texto REVISAR TÉRMINOS animado (aparece al final)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        height: _currentPage >= 1.5 ? 44.0 : 0.0,
                        child: AnimatedOpacity(
                          opacity: _currentPage >= 1.5 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: IgnorePointer(
                            ignoring: _currentPage < 1.5,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'REVISAR TÉRMINOS',
                                  style: TextStyle(
                                    color: Color(0xFF595C5E),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
