import 'package:flutter/material.dart';

import '../../core/analytics/app_event_logger.dart';
import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../student/instructors/student_instructors_screen.dart';
import 'screens/practice_visuals.dart';

class PracticeTrialLessonLauncher {
  const PracticeTrialLessonLauncher._();

  static const _trialBookingIntentKey = 'trial_booking_intent_v1';

  static Future<void> open(
    BuildContext context, {
    String source = 'practice',
  }) async {
    await AppEventLogger.instance.log(
      'trial_cta_clicked',
      properties: {'source': source},
    );
    final token = await SecureStorage.getToken();
    if (!context.mounted) return;

    if (token == null || token.isEmpty) {
      await SecureStorage.setValue(_trialBookingIntentKey, 'practice');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deneme dersi oluşturmak için önce giriş yap.'),
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    final role = await SecureStorage.getRole();
    if (!context.mounted) return;

    if (role == 'instructor') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('Student Login'))),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StudentInstructorsScreen(standalone: true),
      ),
    );
    await AppEventLogger.instance.log(
      'instructor_opened',
      properties: {'source': source},
    );
  }
}

class PracticeTrialLessonCta extends StatefulWidget {
  const PracticeTrialLessonCta({
    super.key,
    this.compact = false,
    this.sourceLabel,
    this.source = 'practice',
    this.maxDailyImpressions = 2,
  });

  final bool compact;
  final String? sourceLabel;
  final String source;
  final int maxDailyImpressions;

  @override
  State<PracticeTrialLessonCta> createState() => _PracticeTrialLessonCtaState();
}

class _PracticeTrialLessonCtaState extends State<PracticeTrialLessonCta> {
  static const _impressionKey = 'practice_trial_cta_impressions_v1';

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final today = _todayKey();
    final raw = (await SecureStorage.getValue(_impressionKey) ?? '').trim();
    final parts = raw.split('|');
    final savedDate = parts.isNotEmpty ? parts.first : '';
    final savedCount =
        parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    final count = savedDate == today ? savedCount : 0;
    if (count >= widget.maxDailyImpressions) return;

    await SecureStorage.setValue(_impressionKey, '$today|${count + 1}');
    await AppEventLogger.instance.log(
      'trial_cta_seen',
      properties: {
        'source': widget.source,
        'compact': widget.compact ? '1' : '0',
      },
    );
    if (mounted) setState(() => _visible = true);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final title = widget.sourceLabel == null
        ? 'Gerçek hoca ile dene'
        : '${widget.sourceLabel} gerçek derse taşı';
    final subtitle = widget.compact
        ? 'Pratiğini ücretsiz deneme dersinde konuşarak pekiştir.'
        : 'Bugünkü pratiğini 15 dakikalık ücretsiz deneme dersinde canlı öğretmenle pekiştir.';

    return Container(
      padding: EdgeInsets.all(widget.compact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7ECFF), width: 2),
        boxShadow: [
          BoxShadow(
            color: practiceBlue.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: widget.compact ? 44 : 52,
                height: widget.compact ? 44 : 52,
                decoration: const BoxDecoration(
                  color: practiceBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: practiceInk,
                        fontSize: widget.compact ? 17 : 19,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: practiceMuted,
                        fontSize: widget.compact ? 12 : 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TrialBadge(icon: Icons.mic_rounded, label: 'Konuşma'),
                _TrialBadge(
                    icon: Icons.event_available_rounded, label: 'Rezervasyon'),
                _TrialBadge(
                    icon: Icons.workspace_premium_rounded, label: 'Ücretsiz'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          PracticePrimaryButton(
            label: widget.compact ? 'DENEME DERSİ' : 'DENEME DERSİ PLANLA',
            color: practiceBlue,
            onPressed: () => PracticeTrialLessonLauncher.open(
              context,
              source: widget.source,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrialBadge extends StatelessWidget {
  const _TrialBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7ECFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: practiceBlue, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
