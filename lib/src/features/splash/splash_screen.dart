import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/ui/ui.dart';
import '../auth/auth_visuals.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2138D9),
      body: AuthBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Maskot — elastik zıplama ile girer
                const AuthMascot(size: 150, mood: AuthMascotMood.cheer)
                    .animate()
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: const Duration(milliseconds: 1000),
                    ),
                const SizedBox(height: 18),

                // Marka adı
                const Text(
                  'LinguFranca',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(
                        delay: const Duration(milliseconds: 250),
                        duration: const Duration(milliseconds: 500))
                    .slideY(begin: 0.4, end: 0),
                const SizedBox(height: 8),
                const Text(
                  'Konuşarak İngilizce öğren',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 450),
                    duration: const Duration(milliseconds: 500)),
                const SizedBox(height: 22),

                // Canlı sosyal kanıt sayacı
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: AppPalette.gold, size: 18),
                        const SizedBox(width: 8),
                        const AnimatedCounter(
                          value: 500,
                          suffix: '+',
                          duration: Duration(milliseconds: 1400),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'öğrenci bugün burada',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 600)),

                const Spacer(flex: 3),

                // Başla
                AppButton(
                  label: 'BAŞLA',
                  tone: AppButtonTone.gold,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                ).animate().fadeIn(
                    delay: const Duration(milliseconds: 900),
                    duration: const Duration(milliseconds: 500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
