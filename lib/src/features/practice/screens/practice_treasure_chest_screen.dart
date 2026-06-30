import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization/app_strings.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Sürpriz ödül kutusu (her 5 derste bir). Backend `/practice/treasure-chest`.
class PracticeTreasureChestScreen extends StatefulWidget {
  const PracticeTreasureChestScreen({super.key});

  @override
  State<PracticeTreasureChestScreen> createState() =>
      _PracticeTreasureChestScreenState();
}

class _PracticeTreasureChestScreenState
    extends State<PracticeTreasureChestScreen> with TickerProviderStateMixin {
  final PracticeApiService _api = const PracticeApiService();
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 5));
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);
  late final AnimationController _openCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  bool _opened = false;
  bool _loading = false;
  Map<String, dynamic>? _reward;

  bool get _isTr => AppStrings.code == 'tr';

  @override
  void dispose() {
    _confetti.dispose();
    _shakeCtrl.dispose();
    _openCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChest() async {
    if (_loading || _opened) return;
    setState(() => _loading = true);
    await PracticeSoundService.onTap();
    _shakeCtrl.stop();
    final result = await _api.openTreasureChest();
    if (!mounted) return;
    if (result != null) {
      final reward = result['reward'];
      setState(() {
        _opened = true;
        _reward = reward is Map ? Map<String, dynamic>.from(reward) : null;
        _loading = false;
      });
      _openCtrl.forward();
      _confetti.play();
      await PracticeSoundService.onBadgeEarned();
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StarfieldPainter())),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              colors: const [
                practiceGreen,
                practiceYellow,
                practiceBlue,
                practiceOrange,
                Color(0xFFFF5964),
              ],
              gravity: 0.3,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text(
                  _isTr ? '🎁 ÖDÜL KUTUSU' : '🎁 REWARD CHEST',
                  style: const TextStyle(
                    color: practiceYellow,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
                const SizedBox(height: 8),
                Text(
                  _isTr ? '5 ders tamamladın!' : 'You completed 5 lessons!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const Spacer(),
                GestureDetector(
                  onTap: _opened ? null : _openChest,
                  child: _opened ? _buildOpenedChest() : _buildClosedChest(),
                ),
                const Spacer(),
                if (_reward != null) _buildRewardCard(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Practice3DButton(
                    label: _opened
                        ? (_isTr ? 'HARIKA! DEVAM ET' : 'AWESOME! CONTINUE')
                        : (_isTr ? 'KUTUYU AÇ' : 'OPEN CHEST'),
                    color: _opened ? practiceGreen : practiceYellow,
                    onPressed: _opened
                        ? () => Navigator.pop(context)
                        : (_loading ? null : _openChest),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedChest() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) => Transform.rotate(
        angle: (_shakeCtrl.value - 0.5) * 0.06,
        child: child,
      ),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: practiceYellow.withValues(alpha: 0.4),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
            const PracticeTreasure(size: 180),
            Positioned(
              bottom: 8,
              child: Text(
                _isTr ? 'DOKUN' : 'TAP',
                style: const TextStyle(
                  color: practiceYellow,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
          duration: 800.ms,
        );
  }

  Widget _buildOpenedChest() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _openCtrl, curve: Curves.elasticOut),
      ),
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: practiceYellow.withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: practiceYellow.withValues(alpha: 0.5),
              blurRadius: 60,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            Text(_rewardIcon(), style: const TextStyle(fontSize: 48)),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard() {
    final reward = _reward!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: practiceYellow.withValues(alpha: 0.4), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_rewardIcon(), style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+${reward['amount']} ${reward['label']}',
                style: const TextStyle(
                  color: practiceYellow,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _isTr ? 'Kazandın!' : 'You earned it!',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.3);
  }

  String _rewardIcon() {
    switch (_reward?['type']) {
      case 'coins':
        return '💎';
      case 'xp':
        return '⚡';
      case 'streak_freeze':
        return '🧊';
      case 'xp_boost':
        return '🚀';
      default:
        return '🎁';
    }
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width <= 1 ? 1 : size.width.toInt();
    final h = size.height <= 1 ? 1 : size.height.toInt();
    for (var i = 0; i < 80; i++) {
      final x = (i * 113 % w).toDouble();
      final y = (i * 73 % h).toDouble();
      final radius = i % 3 == 0 ? 2.0 : 1.0;
      paint.color = Colors.white.withValues(alpha: i % 4 == 0 ? 0.6 : 0.3);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
