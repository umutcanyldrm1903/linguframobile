import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'practice_assistant_overlay.dart';
import 'practice_api_service.dart';
import 'screens/practice_visuals.dart';

enum PracticePremiumTrigger {
  home,
  hearts,
  lessonResult,
  aiExplain,
  roleplay,
  speaking,
  characterCall,
}

class PracticePremiumOfferService {
  PracticePremiumOfferService._();

  static final PracticePremiumOfferService instance =
      PracticePremiumOfferService._();

  static const _homeVisitKey = 'practice_premium_home_visits_v1';
  static const _lastAutomaticOfferKey =
      'practice_premium_last_automatic_offer_v1';

  final PracticeApiService _api = const PracticeApiService();

  Future<bool?> premiumState() async {
    final status = await _api.getPremiumStatus();
    if (status == null) return null;
    final nested = status['premium'];
    return status['is_premium'] == true ||
        (nested is Map && nested['is_premium'] == true);
  }

  Future<void> maybeShowHomeOffer(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final visits = (prefs.getInt(_homeVisitKey) ?? 0) + 1;
    await prefs.setInt(_homeVisitKey, visits);

    // Kullanıcı önce ürünü görsün. İkinci pratik ziyaretinden itibaren teklif
    // gösterilir ve otomatik teklif aynı gün tekrar açılmaz.
    if (visits < 2) return;
    final today = _dateKey(DateTime.now());
    if (prefs.getString(_lastAutomaticOfferKey) == today) return;

    final premium = await premiumState();
    if (premium != false || !context.mounted) return;

    await prefs.setString(_lastAutomaticOfferKey, today);
    if (!context.mounted) return;
    await showOffer(
      context,
      trigger: PracticePremiumTrigger.home,
      checkPremium: false,
    );
  }

  Future<void> showOffer(
    BuildContext context, {
    required PracticePremiumTrigger trigger,
    bool checkPremium = true,
  }) async {
    if (checkPremium) {
      final premium = await premiumState();
      if (premium == true || !context.mounted) return;
    }

    final offer = _offerFor(trigger);
    practiceAssistantSuppressions.value++;
    bool? openPaywall;
    try {
      openPaywall = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _PremiumOfferSheet(offer: offer),
      );
    } finally {
      practiceAssistantSuppressions.value =
          (practiceAssistantSuppressions.value - 1).clamp(0, 999).toInt();
    }
    if (openPaywall != true || !context.mounted) return;

    await Navigator.pushNamed(
      context,
      '/practice/premium',
      arguments: {
        'trigger': trigger.name,
        'title': offer.title,
        'subtitle': offer.subtitle,
      },
    );
  }

  Future<void> openPremiumPage(
    BuildContext context, {
    required PracticePremiumTrigger trigger,
  }) async {
    final premium = await premiumState();
    if (premium == true || !context.mounted) return;
    final offer = _offerFor(trigger);
    await Navigator.pushNamed(
      context,
      '/practice/premium',
      arguments: {
        'trigger': trigger.name,
        'title': offer.title,
        'subtitle': offer.subtitle,
      },
    );
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  _PracticePremiumOffer _offerFor(PracticePremiumTrigger trigger) {
    return switch (trigger) {
      PracticePremiumTrigger.hearts => const _PracticePremiumOffer(
          icon: Icons.favorite_rounded,
          color: Color(0xFFFF4B70),
          title: 'Can beklemeden devam et',
          subtitle:
              'Premium ile yanlış cevaplarda dersin durmaz ve canların sınırsız olur.',
          benefit: 'Sınırsız can',
        ),
      PracticePremiumTrigger.lessonResult => const _PracticePremiumOffer(
          icon: Icons.auto_awesome_rounded,
          color: practiceYellow,
          title: 'Pratiğini kesintisiz sürdür',
          subtitle:
              'Reklamları kaldır, sınırsız canla ilerle ve gelişmiş tekrar araçlarını aç.',
          benefit: 'Reklamsız ve kesintisiz pratik',
        ),
      PracticePremiumTrigger.aiExplain => const _PracticePremiumOffer(
          icon: Icons.psychology_rounded,
          color: practiceBlue,
          title: 'Her hatanın nedenini öğren',
          subtitle:
              'Premium ile Gemini açıklamalarını daha fazla kullan ve doğru kalıbı anında gör.',
          benefit: 'Gelişmiş AI açıklamaları',
        ),
      PracticePremiumTrigger.roleplay => const _PracticePremiumOffer(
          icon: Icons.forum_rounded,
          color: practiceGreen,
          title: 'Konuşmayı yarıda bırakma',
          subtitle:
              'Premium ile daha uzun roleplay oturumları ve daha fazla konuşma senaryosu açılır.',
          benefit: 'Uzun AI roleplay oturumları',
        ),
      PracticePremiumTrigger.speaking => const _PracticePremiumOffer(
          icon: Icons.mic_rounded,
          color: practiceBlue,
          title: 'Telaffuzunu daha ayrıntılı geliştir',
          subtitle:
              'Kelime bazlı geri bildirim ve gelişmiş konuşma analizlerine eriş.',
          benefit: 'Gelişmiş konuşma analizi',
        ),
      PracticePremiumTrigger.characterCall => const _PracticePremiumOffer(
          icon: Icons.video_call_rounded,
          color: practiceOrange,
          title: 'Karakterle konuşmaya devam et',
          subtitle:
              'Premium ile karakter görüşmelerindeki günlük sınırları genişlet.',
          benefit: 'Daha uzun karakter görüşmeleri',
        ),
      PracticePremiumTrigger.home => const _PracticePremiumOffer(
          icon: Icons.workspace_premium_rounded,
          color: practiceBlue,
          title: 'Daha hızlı ve kesintisiz ilerle',
          subtitle:
              'Sınırsız can, reklamsız pratik, gelişmiş AI ve kişisel tekrar araçları tek pakette.',
          benefit: 'Tüm Premium avantajları',
        ),
    };
  }
}

class _PracticePremiumOffer {
  const _PracticePremiumOffer({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.benefit,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String benefit;
}

class _PremiumOfferSheet extends StatelessWidget {
  const _PremiumOfferSheet({required this.offer});

  final _PracticePremiumOffer offer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: practiceLine,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PracticeMascot(
                  size: 104,
                  mood: PracticeMascotMood.excited,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: offer.color.withValues(alpha: .14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(offer.icon, color: offer.color, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        offer.title,
                        style: const TextStyle(
                          color: practiceInk,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              offer.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: practiceMuted,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: practiceLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: practiceGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      offer.benefit,
                      style: const TextStyle(
                        color: practiceInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PracticePrimaryButton(
              label: 'PREMIUM\'U İNCELE',
              color: practiceBlue,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ŞİMDİ DEĞİL'),
            ),
          ],
        ),
      ),
    );
  }
}
