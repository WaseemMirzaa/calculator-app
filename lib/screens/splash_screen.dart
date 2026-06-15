import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'calculator_screen.dart';

/// Branded launch screen. Fades the logo in, then routes to the calculator.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _navTimer = Timer(const Duration(milliseconds: 2200), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const CalculatorScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand logo on a glassy, elevated, 20pt-rounded card.
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                      boxShadow: const [
                        // Elevation.
                        BoxShadow(
                          color: AppColors.black50,
                          blurRadius: 30,
                          offset: Offset(0, 12),
                        ),
                        // Soft gold halo.
                        BoxShadow(
                          color: AppColors.goldGlow,
                          blurRadius: 30,
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/images/logo.png',
                              fit: BoxFit.cover),
                          // Glassy diagonal sheen across the logo.
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0x33FFFFFF),
                                  Color(0x00FFFFFF),
                                  Color(0x14FFFFFF),
                                ],
                                stops: [0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Metallic-gold wordmark.
                  ShaderMask(
                    shaderCallback: (rect) =>
                        AppGradients.goldMetallic.createShader(rect),
                    blendMode: BlendMode.srcIn,
                    child: const Column(
                      children: [
                        Text(
                          'GOLDEN GRAIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'CALCULATOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'inch fraction golden ratio tool',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
