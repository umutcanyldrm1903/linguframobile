import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import 'auth_visuals.dart';

/// Oyunlaştırılmış auth iskeleti: animasyonlu dil-temalı zemin, üstte tepki
/// veren akıllı kalem maskotu + konuşma balonu, altta beyaz form kartı.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.mascot,
    this.bubbleText,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Ekrana özel reaktif maskot (login/register kendi durumunu sürer).
  final Widget? mascot;
  final String? bubbleText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandDeep,
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      // Geri butonu
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Navigator.pushReplacementNamed(
                                      context, '/app-home');
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.arrow_back_rounded,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Maskot + konuşma balonu
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        child: Column(
                          children: [
                            if (bubbleText != null && bubbleText!.isNotEmpty)
                              _SpeechBubble(text: bubbleText!)
                                  .animate()
                                  .fadeIn(
                                      duration:
                                          const Duration(milliseconds: 450),
                                      delay:
                                          const Duration(milliseconds: 250))
                                  .slideY(begin: 0.4, end: 0),
                            const SizedBox(height: 4),
                            (mascot ?? const AuthMascot(size: 128))
                                .animate()
                                .fadeIn(
                                    duration:
                                        const Duration(milliseconds: 500))
                                .scale(
                                  begin: const Offset(0.6, 0.6),
                                  end: const Offset(1, 1),
                                  curve: Curves.elasticOut,
                                  duration:
                                      const Duration(milliseconds: 900),
                                ),
                          ],
                        ),
                      ),

                      // Form kartı
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(34),
                            topRight: Radius.circular(34),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 30,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                            ),
                            const SizedBox(height: 22),
                            child,
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(milliseconds: 150))
                          .slideY(
                              begin: 0.12,
                              end: 0,
                              curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Maskotun üstündeki küçük beyaz konuşma balonu.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ),
        // Küçük üçgen kuyruk
        Transform.translate(
          offset: const Offset(0, -1),
          child: ClipPath(
            clipper: _TriangleClipper(),
            child: Container(width: 16, height: 8, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
