import 'dart:async';

import 'package:flutter/material.dart';

import '../practice_ad_service.dart';
import '../practice_api_service.dart';
import '../practice_premium_offer_service.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

class PracticeHeartsScreen extends StatefulWidget {
  const PracticeHeartsScreen({super.key});

  @override
  State<PracticeHeartsScreen> createState() => _PracticeHeartsScreenState();
}

class _PracticeHeartsScreenState extends State<PracticeHeartsScreen> {
  static const PracticeRepository _repository = PracticeRepository();
  final PracticeAdService _ads = PracticeAdService();
  final PracticeApiService _api = const PracticeApiService();
  late PracticeStats _stats;
  bool _refilling = false;
  bool _rewarding = false;

  @override
  void initState() {
    super.initState();
    _stats = _repository.loadStats();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getHearts();
    if (!mounted || data == null) return;
    setState(() => _stats = _repository.parseStats(data['stats']));
  }

  Future<void> _refill() async {
    if (_refilling) return;
    setState(() => _refilling = true);
    final data = await _api.refillHearts();
    if (!mounted) return;
    setState(() {
      _refilling = false;
      if (data != null) {
        _stats = _repository.parseStats(data['stats']);
      }
    });
    if (data != null) {
      unawaited(PracticeSoundService.playComplete());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Can doldurulamadı. Coin yetersiz olabilir.')),
      );
    }
  }

  Future<void> _watchAdForHeart() async {
    if (_rewarding) return;
    setState(() => _rewarding = true);
    final premium = await PracticePremiumOfferService.instance.premiumState();
    final ok = await _ads.showRewarded(
      rewardType: 'hearts',
      premium: premium == true,
      placement: 'practice_hearts',
    );
    if (!mounted) return;
    setState(() => _rewarding = false);
    if (ok) {
      unawaited(PracticeSoundService.playComplete());
      await _load();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Reklam ödülüyle 1 can eklendi.'
              : 'Reklam gösterilemedi veya Premium aktif.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_stats.hearts / 5).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Canlar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
        children: [
          Center(
            child: PracticeMascot(
              size: 120,
              mood: _stats.hearts > 0
                  ? PracticeMascotMood.proud
                  : PracticeMascotMood.sad,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_stats.hearts} / 5',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: practiceInk,
              fontSize: 44,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yanlış cevaplarda can kaybedersin. Canlar zamanla yenilenir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: practiceMuted,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 26),
          _HeartMeter(progress: progress),
          const SizedBox(height: 18),
          // Sabit/sahte geri sayım yerine dürüst durum (backend net bir sonraki
          // dolum zamanı vermiyor).
          _TimerCard(
            clock: _stats.hearts >= 5 ? 'Dolu' : 'Otomatik',
            label: _stats.hearts >= 5
                ? 'Tüm canların dolu'
                : 'Canlar zamanla otomatik yenilenir',
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.diamond_rounded,
            title: 'Coin ile doldur',
            subtitle: '50 coin harca ve tüm canları hemen geri al.',
            action: _refilling ? '...' : 'DOLDUR',
            onTap: _refilling ? () {} : _refill,
          ),
          _ActionCard(
            icon: Icons.ondemand_video_rounded,
            title: 'Reklam izle',
            subtitle: 'Kısa bir reklam izle ve 1 can kazan.',
            action: _rewarding ? '...' : 'İZLE',
            onTap: _rewarding ? () {} : _watchAdForHeart,
          ),
          _ActionCard(
            icon: Icons.workspace_premium_rounded,
            title: 'Premium can avantajı',
            subtitle: 'Premium ile sınırsız can ve reklamsız pratik.',
            action: 'PREMIUM',
            onTap: () => PracticePremiumOfferService.instance.showOffer(
              context,
              trigger: PracticePremiumTrigger.hearts,
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }
}

class _HeartMeter extends StatelessWidget {
  const _HeartMeter({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD2DC), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.favorite_rounded,
                  color: index < (progress * 5).round()
                      ? const Color(0xFFFF4B70)
                      : const Color(0xFFE3E3E3),
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 16,
              value: progress,
              backgroundColor: const Color(0xFFE3E3E3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF4B70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.clock, required this.label});

  final String clock;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: practiceRed, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: practiceInk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            clock,
            style: const TextStyle(
              color: practiceBlue,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: practiceBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: practiceMuted,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
