import 'package:flutter/material.dart';

import '../../../core/storage/app_preferences.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeOnboardingScreen extends StatefulWidget {
  const PracticeOnboardingScreen({super.key});

  @override
  State<PracticeOnboardingScreen> createState() =>
      _PracticeOnboardingScreenState();
}

class _PracticeOnboardingScreenState extends State<PracticeOnboardingScreen> {
  int _step = 0;
  int? _selected;
  int _goalXp = 20;

  /// Günlük hedef adımı (sondan bir önceki).
  bool get _isGoalStep => _step == _steps.length - 2;

  late final List<_OnboardingStep> _steps = [
    const _OnboardingStep(
      speech: 'Selamlar! Benim adım Lingo.',
      options: [],
      primaryLabel: 'DEVAM ET',
      centeredIntro: true,
    ),
    const _OnboardingStep(
      speech: 'Ne öğrenmek istersin?',
      sectionTitle: 'Türkçe bilenler için',
      secondSectionTitle: 'For English speakers',
      options: [
        _Option(Icons.flag_rounded, 'İngilizce', practiceBlue),
        _Option(Icons.flag_rounded, 'Almanca', Color(0xFF4B4B4B)),
        _Option(Icons.flag_rounded, 'Rusca', Color(0xFF7DD7FF)),
        _Option(Icons.flag_rounded, 'Spanish', Color(0xFFFF4B4B), group: 1),
        _Option(Icons.flag_rounded, 'French', practicePurple, group: 1),
      ],
    ),
    const _OnboardingStep(
      speech: 'Bizi nereden duydun?',
      options: [
        _Option(Icons.camera_alt_rounded, 'Facebook / Instagram', practiceBlue),
        _Option(Icons.tv_rounded, 'Televizyon', Color(0xFF4B4B4B)),
        _Option(Icons.groups_rounded, 'Arkadaş / Aile', practiceOrange),
        _Option(
            Icons.article_rounded, 'Haber / Makale / Blog', Color(0xFFBDBDBD)),
        _Option(Icons.search_rounded, 'Google Aramasi', Color(0xFF4285F4)),
        _Option(Icons.play_arrow_rounded, 'YouTube', Color(0xFFFF0000)),
      ],
    ),
    const _OnboardingStep(
      speech: 'Dili ne kadar biliyorsun?',
      options: [
        _Option(Icons.bar_chart_rounded, 'İngilizce dilinde yeniyim',
            Color(0xFFBDEBFA)),
        _Option(Icons.bar_chart_rounded, 'Bazi kelimeleri biliyorum',
            Color(0xFF7DD7FF)),
        _Option(Icons.bar_chart_rounded, 'Basit konuşmalar yapabiliyorum',
            practiceBlue),
        _Option(Icons.bar_chart_rounded, 'Orta veya ileri biliyorum',
            Color(0xFF0693D1)),
      ],
    ),
    const _OnboardingStep(
      speech: 'Neden İngilizce dilini öğreniyorsun?',
      options: [
        _Option(Icons.menu_book_rounded, 'Eğitimimi desteklemek için',
            Color(0xFF9167D8)),
        _Option(Icons.celebration_rounded, 'Eglencesine', Color(0xFFFF7AC8)),
        _Option(Icons.flight_takeoff_rounded, 'Seyahate hazırlanmak için',
            practiceBlue),
        _Option(
            Icons.groups_rounded, 'Bağlantı olusturmak için', practiceOrange),
        _Option(Icons.psychology_rounded, 'Daha uretken olmak için',
            Color(0xFFFF9FD1)),
        _Option(Icons.work_rounded, 'Kariyerimi güçlendirmek için',
            Color(0xFFB26A2C)),
      ],
    ),
    const _OnboardingStep(
      speech: 'Asagida elde edebileceklerin!',
      benefits: true,
      options: [],
      primaryLabel: 'DEVAM ET',
    ),
    const _OnboardingStep(
      speech: 'Günlük öğrenme hedefin ne?',
      options: [
        _Option(Icons.timer_rounded, 'Gunde 3 dakika', practiceMuted,
            trailing: 'Rahat'),
        _Option(Icons.timer_rounded, 'Gunde 10 dakika', practiceMuted,
            trailing: 'Orta'),
        _Option(Icons.timer_rounded, 'Gunde 15 dakika', practiceMuted,
            trailing: 'Ciddi'),
        _Option(Icons.timer_rounded, 'Gunde 30 dakika', practiceMuted,
            trailing: 'Yogun'),
      ],
    ),
    const _OnboardingStep(
      speech: 'Şimdi, başlaman gereken yeri bulalim!',
      options: [
        _Option(Icons.looks_one_rounded,
            'İngilizce öğrenmeye yeni mi başlıyorsun?', practiceYellow,
            subtitle: 'Sil baştan başla'),
        _Option(Icons.explore_rounded, 'Zaten biraz İngilizce biliyor musun?',
            practiceBlue,
            subtitle: 'Duzeyini belirlememiz için birkac soru yanitla.'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final canContinue =
        _isGoalStep || step.options.isEmpty || _selected != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopProgress(
              step: _step,
              total: _steps.length,
              onBack: _back,
            ),
            Expanded(
              child: step.centeredIntro
                  ? _CenteredIntro(step: step)
                  : _isGoalStep
                      ? _GoalStep(
                          speech: step.speech,
                          selectedGoal: _goalXp,
                          onSelect: (xp) => setState(() => _goalXp = xp),
                        )
                      : _ChoiceStep(
                          step: step,
                          selected: _selected,
                          onSelected: (index) =>
                              setState(() => _selected = index),
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: practiceLine)),
              ),
              child: PracticePrimaryButton(
                label: step.primaryLabel ?? 'DEVAM ET',
                onPressed: canContinue ? _continue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() {
      _step--;
      _selected = null;
    });
  }

  Future<void> _continue() async {
    // Günlük hedef adımı: seçilen XP hedefini kaydet.
    if (_isGoalStep) {
      await AppPreferences.setDailyGoalXp(_goalXp);
      await const PracticeApiService().updateSettings({
        'daily_goal_xp': _goalXp,
      });
    }
    if (!mounted) return;
    if (_step == _steps.length - 1) {
      Navigator.pushReplacementNamed(
        context,
        _selected == 1 ? '/practice/placement' : '/practice',
      );
      return;
    }
    setState(() {
      _step++;
      _selected = null;
    });
  }
}

class _TopProgress extends StatelessWidget {
  const _TopProgress({
    required this.step,
    required this.total,
    required this.onBack,
  });

  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon:
                const Icon(Icons.arrow_back_rounded, color: Color(0xFF9AA0A6)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (step + 1) / total,
                backgroundColor: const Color(0xFFE5E5E5),
                valueColor: const AlwaysStoppedAnimation<Color>(practiceGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.speech,
    required this.selectedGoal,
    required this.onSelect,
  });

  final String speech;
  final int selectedGoal;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PracticeMascot(size: 84, mood: PracticeMascotMood.thinking),
              const SizedBox(width: 12),
              Expanded(child: PracticeSpeechBubble(text: speech)),
            ],
          ),
          const SizedBox(height: 22),
          PracticeXpGoalSelector(
            selectedGoal: selectedGoal,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _CenteredIntro extends StatelessWidget {
  const _CenteredIntro({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 68),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PracticeSpeechBubble(text: step.speech, alignLeftTail: false),
            const SizedBox(height: 26),
            const PracticeMascot(size: 140),
          ],
        ),
      ),
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.step,
    required this.selected,
    required this.onSelected,
  });

  final _OnboardingStep step;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PracticeMascot(size: 112, mood: PracticeMascotMood.wink),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: PracticeSpeechBubble(text: step.speech),
              ),
            ),
          ],
        ),
        if (step.benefits) ...[
          const SizedBox(height: 38),
          const _BenefitRow(
            icon: Icons.forum_rounded,
            color: Color(0xFFD898FF),
            title: 'Korkusuzca konuşma',
            subtitle: '31.700+ stressiz interaktif alistirma',
          ),
          const _BenefitRow(
            icon: Icons.style_rounded,
            color: practiceBlue,
            title: 'Kelime hazneni genisletme',
            subtitle: '1.900+ kullanisli kelime ve ifadeler',
          ),
          const _BenefitRow(
            icon: Icons.watch_later_rounded,
            color: practiceOrange,
            title: 'Ogrenim aliskanligi edinme',
            subtitle:
                'Akilli bildirimler, eglenceli mucadeleler ve daha fazlasi',
          ),
        ],
        if (step.sectionTitle != null) ...[
          const SizedBox(height: 24),
          Text(
            step.sectionTitle!,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < step.options.length; i++) ...[
          if (step.secondSectionTitle != null &&
              i > 0 &&
              step.options[i].group != step.options[i - 1].group) ...[
            const SizedBox(height: 14),
            Text(
              step.secondSectionTitle!,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _OnboardingChoice(
            option: step.options[i],
            selected: selected == i,
            onTap: () => onSelected(i),
          ),
        ],
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Row(
        children: [
          Icon(icon, color: color, size: 38),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingChoice extends StatelessWidget {
  const _OnboardingChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: option.subtitle == null ? 17 : 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? practiceGreen : const Color(0xFFE2E2E2),
              width: selected ? 3 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFE2E2E2),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(option.icon, color: option.color, size: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        color: practiceInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        option.subtitle!,
                        style: const TextStyle(
                          color: practiceMuted,
                          fontSize: 16,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (option.trailing != null)
                Text(
                  option.trailing!,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.speech,
    required this.options,
    this.sectionTitle,
    this.secondSectionTitle,
    this.primaryLabel,
    this.centeredIntro = false,
    this.benefits = false,
  });

  final String speech;
  final String? sectionTitle;
  final String? secondSectionTitle;
  final String? primaryLabel;
  final bool centeredIntro;
  final bool benefits;
  final List<_Option> options;
}

class _Option {
  const _Option(
    this.icon,
    this.title,
    this.color, {
    this.trailing,
    this.subtitle,
    this.group = 0,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String? trailing;
  final String? subtitle;
  final int group;
}
