import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/storage/app_preferences.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

bool get _isTr => AppStrings.code == 'tr';

/// App bar'da can sayacı. [hearts] değişince kırılma/sallanma animasyonu oynar.
class HeartsCounter extends StatelessWidget {
  const HeartsCounter({required this.hearts, this.max = 5, super.key});

  final int hearts;
  final int max;

  @override
  Widget build(BuildContext context) {
    final empty = hearts <= 0;
    return Container(
      key: ValueKey(hearts),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD2DC), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            empty ? Icons.heart_broken_rounded : Icons.favorite_rounded,
            color: const Color(0xFFFF4B70),
            size: 20,
          ),
          const SizedBox(width: 5),
          Text(
            '$hearts',
            style: const TextStyle(
              color: Color(0xFFFF4B70),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(hearts)).shake(hz: 4, rotation: .04).scaleXY(
          begin: 1.25,
          end: 1,
          duration: 260.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Ders içi combo sayacı. [count] >= 2 olunca yükselen övgüyle belirir.
class ComboBadge extends StatelessWidget {
  const ComboBadge({required this.count, super.key});

  final int count;

  String get _praise {
    if (count >= 15) return _isTr ? 'EFSANE SERİ!' : 'LEGENDARY!';
    if (count >= 10) return _isTr ? 'DURDURULAMAZ!' : 'UNSTOPPABLE!';
    if (count >= 5) return _isTr ? 'HARIKA SERI!' : 'GREAT STREAK!';
    return _isTr ? 'GÜZEL!' : 'NICE!';
  }

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: practiceOrange, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: practiceOrange, size: 20),
          const SizedBox(width: 6),
          Text(
            '$count · $_praise',
            style: const TextStyle(
              color: practiceOrange,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    )
        .animate(key: ValueKey(count))
        .scaleXY(begin: .4, end: 1, duration: 320.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 160.ms);
  }
}

/// Doğru cevapta yukarı süzülüp kaybolan "+N XP".
class XpFloater extends StatelessWidget {
  const XpFloater({required this.amount, required this.trigger, super.key});

  final int amount;

  /// Her artışta animasyonu yeniden tetikler.
  final int trigger;

  @override
  Widget build(BuildContext context) {
    if (trigger == 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: practiceYellow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '+$amount XP',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      )
          .animate(key: ValueKey(trigger))
          .moveY(begin: 0, end: -54, duration: 900.ms, curve: Curves.easeOut)
          .fadeIn(duration: 120.ms)
          .then(delay: 350.ms)
          .fadeOut(duration: 420.ms),
    );
  }
}

/// Oyunlaştırılmış alt geri bildirim paneli: büyük zıplayan ✓/✗ + Devam butonu.
class AnswerFeedbackBar extends StatelessWidget {
  const AnswerFeedbackBar({
    required this.correct,
    required this.message,
    required this.correctAnswer,
    required this.explanation,
    required this.onContinue,
    required this.continueLabel,
    super.key,
  });

  final bool correct;
  final String message;
  final String correctAnswer;
  final String explanation;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final color = correct ? practiceGreen : const Color(0xFFFF4B4B);
    final bg = correct ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  correct ? Icons.check_rounded : Icons.close_rounded,
                  color: color,
                  size: 30,
                ),
              ).animate(key: ValueKey('$correct$message')).scaleXY(
                  begin: .2,
                  end: 1,
                  duration: 380.ms,
                  curve: Curves.elasticOut),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          if (!correct && correctAnswer.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _isTr
                  ? 'Doğru cevap: $correctAnswer'
                  : 'Correct answer: $correctAnswer',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation,
              style: const TextStyle(color: practiceInk, height: 1.3),
            ),
          ],
          const SizedBox(height: 14),
          Practice3DButton(
            label: continueLabel,
            color: color,
            onPressed: onContinue,
          ),
        ],
      ),
    ).animate().slideY(
          begin: 1,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Can bittiğinde çıkan kilitleyen modal. 'refill' / 'exit' döndürür.
Future<String?> showOutOfHeartsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PracticeMascot(size: 110, mood: PracticeMascotMood.sad),
              const SizedBox(height: 12),
              Text(
                _isTr ? 'Canlarin bitti!' : 'You ran out of hearts!',
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isTr
                    ? 'Devam etmek için canlarını doldur ya da daha sonra tekrar dene.'
                    : 'Refill your hearts to continue, or try again later.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Practice3DButton(
                label: _isTr ? 'SINIRSIZ CAN' : 'UNLIMITED HEARTS',
                color: practiceBlue,
                onPressed: () => Navigator.pop(context, 'premium'),
              ),
              const SizedBox(height: 10),
              Practice3DButton(
                label: _isTr ? 'PRATIKLE 1 CAN KAZAN' : 'PRACTICE FOR 1 HEART',
                color: practiceGreen,
                onPressed: () => Navigator.pop(context, 'practice'),
              ),
              const SizedBox(height: 10),
              Practice3DButton(
                label: _isTr ? 'CANLARI DOLDUR' : 'REFILL HEARTS',
                color: const Color(0xFFFF4B70),
                onPressed: () => Navigator.pop(context, 'refill'),
              ),
              const SizedBox(height: 10),
              Practice3DButton(
                label: _isTr ? 'DERSTEN CIK' : 'QUIT LESSON',
                color: practiceGreen,
                outlined: true,
                onPressed: () => Navigator.pop(context, 'exit'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Sandık + mücevher/XP/coin ödül kutlaması.
Future<void> showRewardPopup(
  BuildContext context, {
  required String title,
  int xp = 0,
  int coins = 0,
  int gems = 0,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _RewardDialog(
      title: title,
      xp: xp,
      coins: coins,
      gems: gems,
    ),
  );
}

class _RewardDialog extends StatelessWidget {
  const _RewardDialog({
    required this.title,
    required this.xp,
    required this.coins,
    required this.gems,
  });

  final String title;
  final int xp;
  final int coins;
  final int gems;

  @override
  Widget build(BuildContext context) {
    final rewards = <Widget>[
      if (xp > 0)
        _RewardChip(icon: Icons.bolt_rounded, value: xp, color: practiceYellow),
      if (coins > 0)
        _RewardChip(
            icon: Icons.monetization_on_rounded,
            value: coins,
            color: practiceOrange),
      if (gems > 0)
        _RewardChip(
            icon: Icons.diamond_rounded, value: gems, color: practiceBlue),
    ];
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: PracticeConfettiOverlay(
        active: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PracticeTreasure(size: 130)
                  .animate()
                  .scaleXY(
                      begin: .4,
                      end: 1,
                      duration: 500.ms,
                      curve: Curves.elasticOut)
                  .then()
                  .shake(hz: 3, rotation: .02),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < rewards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    rewards[i],
                  ],
                ],
              ),
              const SizedBox(height: 22),
              Practice3DButton(
                label: _isTr ? 'DEVAM ET' : 'CONTINUE',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// 0'dan [value]'ya sayan rakam.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    this.style,
    this.prefix = '',
    this.duration = const Duration(milliseconds: 900),
    super.key,
  });

  final int value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => Text('$prefix$current', style: style),
    );
  }
}

/// Combo milestone'larında seri sesi çalar (5/10/15...).
void playComboSound(int combo) {
  if (combo == 5 || combo == 10 || combo % 15 == 0 && combo > 0) {
    PracticeSoundService.playStreak();
  }
}

/// Seviye atlama kutlaması.
Future<void> showLevelUpPopup(BuildContext context, {required int level}) {
  // 🔊 Seviye atlama fanfarını çal
  PracticeSoundService.onLevelUp();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: PracticeConfettiOverlay(
        active: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: practiceYellow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
                  .animate()
                  .scaleXY(
                      begin: .3,
                      end: 1,
                      duration: 520.ms,
                      curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 900.ms),
              const SizedBox(height: 16),
              Text(
                _isTr ? 'Seviye atladin!' : 'Level up!',
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isTr
                    ? 'Artik $level. seviyedesin. Harika gidiyorsun!'
                    : 'You reached level $level. Keep it up!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Practice3DButton(
                label: _isTr ? 'DEVAM ET' : 'CONTINUE',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Günlük XP hedefi halkası. Kendi verisini çeker;
/// hedef dokunarak değiştirilir, hedefe ulaşınca bir kez kutlanır.
class PracticeDailyGoalCard extends StatefulWidget {
  const PracticeDailyGoalCard({super.key});

  @override
  State<PracticeDailyGoalCard> createState() => _PracticeDailyGoalCardState();
}

class _PracticeDailyGoalCardState extends State<PracticeDailyGoalCard> {
  final PracticeApiService _api = const PracticeApiService();
  static const _goals = [10, 20, 30, 50];

  int _goalIndex = 1; // 20 XP
  int _todayXp = 0;
  bool _celebrated = false;

  int get _goal => _goals[_goalIndex];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final savedGoal = await AppPreferences.dailyGoalXp();
    final idx = _goals.indexOf(savedGoal);
    if (mounted && idx >= 0) setState(() => _goalIndex = idx);
    await _load();
  }

  Future<void> _load() async {
    final data = await _api.getActivity(days: 7);
    if (!mounted) return;
    final days = data?['days'];
    var xp = 0;
    if (days is List && days.isNotEmpty) {
      final last = days.last;
      if (last is Map) xp = _asInt(last['xp']);
    } else {
      final summary = data?['summary'];
      if (summary is Map) xp = _asInt(summary['total_xp']);
    }
    setState(() => _todayXp = xp);
    _maybeCelebrate();
  }

  void _cycleGoal() {
    setState(() {
      _goalIndex = (_goalIndex + 1) % _goals.length;
      _celebrated = false;
    });
    AppPreferences.setDailyGoalXp(_goal);
    _maybeCelebrate();
  }

  void _maybeCelebrate() {
    if (!_celebrated && _todayXp >= _goal && _goal > 0) {
      _celebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PracticeSoundService.playComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (_todayXp / _goal).clamp(0.0, 1.0);
    final met = _todayXp >= _goal;
    return GestureDetector(
      onTap: _cycleGoal,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: practiceLine, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: ratio == 0 ? 0.001 : ratio,
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFFEDEFF2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        met ? practiceGreen : practiceOrange,
                      ),
                    ),
                  ),
                  Icon(
                    met ? Icons.check_rounded : Icons.bolt_rounded,
                    color: met ? practiceGreen : practiceOrange,
                    size: 26,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    met
                        ? (_isTr
                            ? 'Günlük hedef tamam! 🎉'
                            : 'Daily goal met! 🎉')
                        : (_isTr ? 'Günlük hedef' : 'Daily goal'),
                    style: const TextStyle(
                      color: practiceInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isTr
                        ? '$_todayXp / $_goal XP · değiştirmek için dokun'
                        : '$_todayXp / $_goal XP · tap to change',
                    style: const TextStyle(
                      color: practiceMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
