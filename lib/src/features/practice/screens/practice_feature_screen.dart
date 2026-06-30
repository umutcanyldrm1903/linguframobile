import 'package:flutter/material.dart';

import '../practice_repository.dart';
import 'practice_visuals.dart';

class PracticeFeatureScreen extends StatelessWidget {
  const PracticeFeatureScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  static const PracticeRepository _repository = PracticeRepository();

  @override
  Widget build(BuildContext context) {
    final stats = _repository.loadStats();
    final spec = _featureSpec(title, subtitle, icon);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: Text(
          spec.navTitle,
          style: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _FeatureTopHud(stats: stats),
                  const SizedBox(height: 18),
                  _MascotPrompt(spec: spec),
                  const SizedBox(height: 22),
                  _FeatureProgressCard(spec: spec),
                  const SizedBox(height: 18),
                  for (final item in spec.items)
                    _LargeOptionCard(
                      item: item,
                      accent: spec.color,
                      onTap: () => _openAction(context, item.route),
                    ),
                  const SizedBox(height: 16),
                  _RewardBox(spec: spec),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: PracticePrimaryButton(
                label: spec.buttonLabel,
                color: spec.buttonColor,
                onPressed: () => _openAction(context, spec.primaryRoute),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  void _openAction(BuildContext context, String route) {
    if (route.isEmpty) return;
    Navigator.pushNamed(context, route);
  }
}

class _FeatureSpec {
  const _FeatureSpec({
    required this.navTitle,
    required this.prompt,
    required this.color,
    required this.buttonColor,
    required this.icon,
    required this.items,
    required this.reward,
    required this.progressLabel,
    required this.progressValue,
    required this.buttonLabel,
    required this.primaryRoute,
  });

  final String navTitle;
  final String prompt;
  final Color color;
  final Color buttonColor;
  final IconData icon;
  final List<_FeatureItem> items;
  final String reward;
  final String progressLabel;
  final double progressValue;
  final String buttonLabel;
  final String primaryRoute;
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.route,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final String route;
  final bool locked;
}

_FeatureSpec _featureSpec(
    String title, String subtitle, IconData fallbackIcon) {
  final key = title.toLowerCase();
  if (key.contains('hub')) {
    return _spec(
      title,
      'Bugün hangi alani güçlendirmek istersin?',
      practiceBlue,
      practiceGreen,
      Icons.explore_rounded,
      [
        _item(
            Icons.error_rounded,
            'Hatalarımı çalış',
            'Yanlış yaptığın soruları tekrar çöz.',
            '+5 XP',
            '/practice/mistakes'),
        _item(
            Icons.style_rounded,
            'Zayıf kelimeler',
            'Unuttugun kelimeleri kartlarla yenile.',
            'SRS',
            '/practice/weak-words'),
        _item(Icons.mic_rounded, 'Konuşma pratiği',
            'Cümleyi söyle, skorunu gör.', 'STT', '/practice/speaking'),
      ],
      'Tekrar merkezi her gün zayıf alanlarını öne çıkarır.',
      'Kisisel tekrar ilerlemesi',
      .58,
      'PRATİĞE BAŞLA',
      '/practice/mode',
    );
  }
  if (key.contains('mistake')) {
    return _spec(
      title,
      'Hatalarini birlikte kapatalım.',
      const Color(0xFFFF5964),
      practiceGreen,
      Icons.error_rounded,
      [
        _item(Icons.translate_rounded, 'Yanlış ceviri',
            'Doğru cevabı seçip hatayi kapat.', '+5 XP', '/practice/lesson'),
        _item(
            Icons.title_rounded,
            'Cümle sirasi',
            'Kelime sıralama sorularini tekrar et.',
            '+5 XP',
            '/practice/lesson'),
        _item(Icons.check_circle_rounded, 'Mastery hedefi',
            '3 doğru cevapla mastered yap.', '0/3', '/practice/lesson'),
      ],
      'Tüm hatalar bitince bonus sandik açılır.',
      'Cozulen hata',
      .35,
      'HATALARI COZ',
      '/practice/lesson',
    );
  }
  if (key.contains('weak')) {
    return _spec(
      title,
      'Zayıf kelimeleri bugün güçlendirelim.',
      practiceBlue,
      practiceGreen,
      Icons.style_rounded,
      [
        _item(Icons.flash_on_rounded, 'Flashcard', 'Kelimeyi gör, anlamı seç.',
            '+10 XP', '/practice/mode'),
        _item(Icons.repeat_rounded, 'Aralıklı tekrar',
            'Zor kelimeler daha şık gelir.', 'SRS', '/practice/mode'),
        _item(Icons.volume_up_rounded, 'Dinle ve seç',
            'Kelimeyi dinleyip doğru anlamı bul.', 'Ses', '/practice/mode'),
      ],
      'Doğru tekrarlar mastery puanini yukseltir.',
      'Bugünkü kelime hedefi',
      .72,
      'KELIME TEKRARI',
      '/practice/mode',
    );
  }
  if (key.contains('energy')) {
    return _spec(
      title,
      'Enerjini takip et.',
      practicePurple,
      practiceBlue,
      Icons.battery_charging_full_rounded,
      [
        _item(Icons.bolt_rounded, '72 / 100 enerji',
            'Egzersizler enerji kullanir.', '72', ''),
        _item(Icons.auto_awesome_rounded, 'Combo bonus',
            '3 doğru cevap enerji kazandırir.', '+5', '/practice/lesson'),
        _item(Icons.timer_rounded, 'Yenilenme', 'Enerji zamanla geri dolar.',
            'Aktif', ''),
      ],
      'Energy modu backend ayarına göre açılıp kapanır.',
      'Enerji dolumu',
      .72,
      'DERSE BAŞLA',
      '/practice/lesson',
    );
  }
  if (key.contains('premium')) {
    return _spec(
      title,
      'Premium ile pratiği hızlandır.',
      practiceBlue,
      practiceBlue,
      Icons.workspace_premium_rounded,
      [
        _item(Icons.block_rounded, 'Reklamsiz pratik',
            'Ders sonrasi reklam gosterilmez.', 'Pro', ''),
        _item(Icons.favorite_rounded, 'Sınırsız can',
            'Yanlış yapsan da devam et.', 'Pro', '/practice/hearts'),
        _item(Icons.smart_toy_rounded, 'AI açıklama',
            'Yanlış cevabı ayrintili anlatir.', 'AI', '/practice/ai-coach'),
      ],
      'Satin alma sonucu backend tarafindan doğrulanir.',
      'Premium avantaj',
      .84,
      'PREMIUM SEC',
      '/practice/premium-compare',
    );
  }
  if (key.contains('speaking') ||
      key.contains('character') ||
      key.contains('ai')) {
    return _spec(
      title,
      'Konuşma görevine hazır misin?',
      practiceGreen,
      practiceGreen,
      Icons.mic_rounded,
      [
        _item(Icons.record_voice_over_rounded, 'Tekrar et',
            'Cümleyi söyle ve skor al.', 'STT', '/practice/speaking'),
        _item(Icons.chat_bubble_rounded, 'Roleplay',
            'Restoran ve seyahat senaryolari.', 'AI', '/practice/ai-coach'),
        _item(
            Icons.videocam_rounded,
            'Karakter görüşmesi',
            'Yazili/sesli karakter sohbeti.',
            'Pro',
            '/practice/character-call'),
      ],
      'Gelistirilmis telaffuz analizi AI servisine baglanabilir.',
      'Konuşma akiciligi',
      .44,
      'KONUŞMAYA BAŞLA',
      '/practice/speaking',
    );
  }
  if (key.contains('story') ||
      key.contains('radio') ||
      key.contains('special') ||
      key.contains('adventure')) {
    return _spec(
      title,
      'Bugün kısa bir bölüm açalım.',
      practiceOrange,
      practiceBlue,
      Icons.auto_stories_rounded,
      [
        _item(Icons.menu_book_rounded, 'Hikaye dersi',
            'Oku, dinle ve anlama sorusu çöz.', '+15 XP', '/practice/story'),
        _item(Icons.radio_rounded, 'Radio ders', 'Transcript ve yavaş dinleme.',
            '+15 XP', '/practice/radio'),
        _item(Icons.explore_rounded, 'Macera sahnesi', 'Doğru aksiyonu seç.',
            '+20 XP', '/practice/adventure'),
      ],
      'Tamamlanan özel dersler hub içinde tekrar edilir.',
      'Özel içerik',
      .48,
      'BÖLÜME BAŞLA',
      '/practice/story',
    );
  }
  if (key.contains('challenge')) {
    return _spec(
      title,
      'Süreli meydan okumaya gir.',
      practicePurple,
      practiceBlue,
      Icons.timer_rounded,
      [
        _item(Icons.speed_rounded, '1 dakika hız',
            'Süre bitmeden maksimum doğru.', 'Hazır', '/practice/challenge'),
        _item(Icons.link_rounded, 'Match Madness', 'Kelimeleri hızlı eşleştir.',
            '+30 XP', '/practice/match-madness'),
        _item(Icons.military_tech_rounded, 'Boss soru', 'Ünite sonu zor soru.',
            'Kilitli', '/practice/legendary',
            locked: true),
      ],
      'Combo serisi XP carpani kazandırir.',
      'Challenge hazırligi',
      .35,
      'CHALLENGE BAŞLA',
      '/practice/match-madness',
    );
  }
  if (key.contains('notification') || key.contains('settings')) {
    return _spec(
      title,
      'Hatırlatıcılarini ayarla.',
      const Color(0xFF64748B),
      practiceBlue,
      Icons.notifications_rounded,
      [
        _item(Icons.alarm_rounded, 'Günlük hatırlatıcı',
            'Her gün seçilen saatte uyar.', '20:30', ''),
        _item(Icons.local_fire_department_rounded, 'Streak uyarisi',
            'Seri bozulmadan önce bildirir.', 'Açık', '/practice/streak'),
        _item(Icons.volume_up_rounded, 'Ses efektleri',
            'Doğru, yanlış ve ödül sesleri.', 'Açık', ''),
      ],
      'Bildirim izinleri cihaz ayarına bağlıdir.',
      'Ayar ilerlemesi',
      .80,
      'KAYDET',
      '/practice',
    );
  }
  if (key.contains('history')) {
    return _spec(
      title,
      'Son kazanımlarını gör.',
      const Color(0xFF14B8A6),
      practiceBlue,
      Icons.history_rounded,
      [
        _item(Icons.check_circle_rounded, 'Ders tamamlandı',
            'Temel kelimeler dersi bitti.', '+20 XP', '/practice/result'),
        _item(Icons.diamond_rounded, 'Coin kazanildi',
            'Günlük görev ödülü alındı.', '+5', '/practice/shop'),
        _item(Icons.favorite_rounded, 'Seri korundu', 'Bugün pratik yapıldı.',
            '12 gün', '/practice/streak'),
      ],
      'XP ve coin loglari backend tarafinda tutulur.',
      'Haftalık XP',
      .64,
      'YOLA DÖN',
      '/practice',
    );
  }
  if (key.contains('weekly')) {
    return _spec(
      title,
      'Haftalık sandığı aç.',
      practicePurple,
      practiceBlue,
      Icons.calendar_month_rounded,
      [
        _item(Icons.bolt_rounded, '300 XP kazan', 'Haftalık toplam XP hedefi.',
            '128/300', '/practice/lesson'),
        _item(Icons.school_rounded, '10 ders tamamla', 'Kısa pratikleri bitir.',
            '3/10', '/practice/path'),
        _item(Icons.local_fire_department_rounded, '5 gün seri',
            'Hafta boyunca aktif kal.', '2/5', '/practice/streak'),
      ],
      'Haftalık görevler daha büyük sandik verir.',
      'Haftalık hedef',
      .42,
      'GÖREVE BAŞLA',
      '/practice/lesson',
    );
  }
  return _spec(
    title,
    subtitle.isEmpty ? 'Bugünkü pratiği seç.' : subtitle,
    practiceBlue,
    practiceGreen,
    fallbackIcon,
    [
      _item(fallbackIcon, title, 'Modül pratik akışına bağlı.', '+10 XP',
          '/practice/lesson'),
      _item(Icons.card_giftcard_rounded, 'Ödül hedefi',
          'Tamamlayınca coin ve XP kazan.', 'Ödül', '/practice/shop'),
      _item(Icons.lock_open_rounded, 'Sonraki adım',
          'Ilerledikce yeni içerikler açılır.', 'Yeni', '/practice/path'),
    ],
    'Bu ekran pratik modülünun oyunlaştırılmış akışına bağlı.',
    'Pratik ilerlemesi',
    .56,
    'DEVAM ET',
    '/practice/lesson',
  );
}

_FeatureSpec _spec(
  String navTitle,
  String prompt,
  Color color,
  Color buttonColor,
  IconData icon,
  List<_FeatureItem> items,
  String reward,
  String progressLabel,
  double progressValue,
  String buttonLabel,
  String primaryRoute,
) {
  return _FeatureSpec(
    navTitle: navTitle,
    prompt: prompt,
    color: color,
    buttonColor: buttonColor,
    icon: icon,
    items: items,
    reward: reward,
    progressLabel: progressLabel,
    progressValue: progressValue,
    buttonLabel: buttonLabel,
    primaryRoute: primaryRoute,
  );
}

_FeatureItem _item(
  IconData icon,
  String title,
  String subtitle,
  String badge,
  String route, {
  bool locked = false,
}) {
  return _FeatureItem(
    icon: icon,
    title: title,
    subtitle: subtitle,
    badge: badge,
    route: route,
    locked: locked,
  );
}

class _FeatureTopHud extends StatelessWidget {
  const _FeatureTopHud({required this.stats});

  final PracticeStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HudChip(
            icon: Icons.local_fire_department_rounded,
            value: '${stats.streak}',
            color: practiceOrange),
        const SizedBox(width: 10),
        _HudChip(
            icon: Icons.diamond_rounded,
            value: '${stats.coins}',
            color: practiceBlue),
        const SizedBox(width: 10),
        _HudChip(
            icon: Icons.favorite_rounded,
            value: '${stats.hearts}',
            color: const Color(0xFFFF4B70)),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/practice/settings'),
          icon: const Icon(Icons.settings_rounded, color: practiceBlue),
        ),
      ],
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE8F7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: practiceInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotPrompt extends StatelessWidget {
  const _MascotPrompt({required this.spec});

  final _FeatureSpec spec;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PracticeMascot(size: 108, mood: PracticeMascotMood.proud),
        const SizedBox(width: 12),
        Expanded(child: PracticeSpeechBubble(text: spec.prompt)),
      ],
    );
  }
}

class _FeatureProgressCard extends StatelessWidget {
  const _FeatureProgressCard({required this.spec});

  final _FeatureSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(spec.icon, color: spec.color, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.progressLabel,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 16,
                    value: spec.progressValue.clamp(0, 1),
                    backgroundColor: const Color(0xFFE5E5E5),
                    valueColor: AlwaysStoppedAnimation<Color>(spec.color),
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

class _LargeOptionCard extends StatelessWidget {
  const _LargeOptionCard({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  final _FeatureItem item;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.locked ? .48 : 1,
      child: InkWell(
        onTap: item.locked ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: practiceLine, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.locked ? Icons.lock_rounded : item.icon,
                  color: accent,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: practiceInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: practiceMuted,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badge,
                  style: const TextStyle(
                    color: Color(0xFFC58B00),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBox extends StatelessWidget {
  const _RewardBox({required this.spec});

  final _FeatureSpec spec;

  @override
  Widget build(BuildContext context) {
    return PracticeConfettiOverlay(
      active: spec.progressValue >= .75,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE08A), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: practiceYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: practiceOrange,
                size: 31,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                spec.reward,
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
