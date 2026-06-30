import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../practice_api_service.dart';
import '../practice_repository.dart';
import 'practice_visuals.dart';

class PracticeCefrScoreScreen extends StatefulWidget {
  const PracticeCefrScoreScreen({super.key});

  @override
  State<PracticeCefrScoreScreen> createState() =>
      _PracticeCefrScoreScreenState();
}

class _PracticeCefrScoreScreenState extends State<PracticeCefrScoreScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  final PracticeApiService _api = const PracticeApiService();

  PracticeStats _stats = _repository.loadStats();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await _api.getStats();
    if (!mounted || data == null) return;
    setState(() => _stats = _repository.parseStats(data['stats']));
  }

  String _levelForXp(int xp) {
    if (xp >= 25000) return 'C2';
    if (xp >= 10000) return 'C1';
    if (xp >= 4000) return 'B2';
    if (xp >= 1500) return 'B1';
    if (xp >= 500) return 'A2';
    return 'A1';
  }

  int _nextXp(int xp) {
    if (xp < 500) return 500;
    if (xp < 1500) return 1500;
    if (xp < 4000) return 4000;
    if (xp < 10000) return 10000;
    if (xp < 25000) return 25000;
    return 25000;
  }

  String _shareText() {
    final level = _levelForXp(_stats.xp);
    final next = _nextXp(_stats.xp);
    final score = (10 + (_stats.xp / next).clamp(0.0, 1.0) * 150).round();
    final isTr = AppStrings.code == 'tr';
    return isTr
        ? 'Lingufranca İngilizce pratiğinde tahmini seviyem: $level (CEFR) · Skor $score/160 🎓\nSen de dene 👉 https://www.lingufranca.com'
        : 'My estimated English level on Lingufranca: $level (CEFR) · Score $score/160 🎓\nTry it 👉 https://www.lingufranca.com';
  }

  /// Sistem paylaşım sayfası: seviye metni + bağlantı (LinkedIn, WhatsApp, X…
  /// hepsi için çalışır; mobilde LinkedIn seçilince metin de gider).
  Future<void> _shareScore() async {
    final isTr = AppStrings.code == 'tr';
    await SharePlus.instance.share(
      ShareParams(
        subject: isTr ? 'CEFR seviyem' : 'My CEFR level',
        text: _shareText(),
      ),
    );
  }

  /// LinkedIn paylaşım kısayolu. Açılamazsa sistem paylaşımına düşer.
  Future<void> _shareLinkedIn() async {
    final uri = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url='
      '${Uri.encodeComponent('https://www.lingufranca.com')}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) await _shareScore();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final stats = _stats;
    final level = _levelForXp(stats.xp);
    final next = _nextXp(stats.xp);
    final ratio = (stats.xp / next).clamp(0.0, 1.0);
    final score = (10 + ratio * 150).round();

    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        title: Text(isTr ? 'CEFR skoru' : 'CEFR score'),
        backgroundColor: practiceKraft,
        foregroundColor: practiceInk,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E7C6B), Color(0xFF0A5C50)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Tahmini seviyen' : 'Estimated level',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.school_rounded,
                        color: Colors.white, size: 58),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$score/160 - ${stats.xp}/$next XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 220.ms).scale(
                begin: const Offset(.96, .96),
                end: const Offset(1, 1),
              ),
          const SizedBox(height: 14),
          // Paylaşım — seviyeyi LinkedIn/diğer kanallarda paylaş (tanıtım).
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _shareLinkedIn,
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text(
                isTr ? 'LinkedIn\'de paylaş' : 'Share on LinkedIn',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: .4),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _shareScore,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(
                isTr ? 'Skorumu paylaş' : 'Share my score',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.info_rounded,
            title: isTr ? 'Bu skor nasil hesaplanir?' : 'How is it calculated?',
            text: isTr
                ? 'XP, ders tamamlama ve doğruluk verilerinden mobil tahmin uretir. Resmi sınav yerine gecmez.'
                : 'It estimates your level from XP, lesson completion and accuracy. It does not replace an official exam.',
          ),
          _InfoCard(
            icon: Icons.assignment_rounded,
            title: isTr ? 'Daha net sonuc' : 'More accurate result',
            text: isTr
                ? 'Seviye belirleme testini ve speaking pratiklerini tamamladıkca skor iyilesir.'
                : 'The score improves as you complete placement and speaking practice.',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: practiceBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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
