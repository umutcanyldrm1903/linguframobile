import 'package:flutter/material.dart';

import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

enum PracticeContentKind { story, radio, adventure, challenge }

class PracticeContentPlayScreen extends StatefulWidget {
  const PracticeContentPlayScreen({
    required this.kind,
    super.key,
  });

  final PracticeContentKind kind;

  @override
  State<PracticeContentPlayScreen> createState() =>
      _PracticeContentPlayScreenState();
}

class _PracticeContentPlayScreenState extends State<PracticeContentPlayScreen> {
  final PracticeApiService _api = const PracticeApiService();
  bool _loading = true;
  bool _completing = false;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _detail;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final data = await _listCall();
    final rawItems = data?['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false)
        : _fallbackItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      _detail = null;
    });
  }

  Future<void> _openItem(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id <= 0) {
      setState(() => _detail = _fallbackDetail(item));
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    final response = await _detailCall(id);
    if (!mounted) return;
    final rawItem = response?['item'];
    final detail =
        rawItem is Map ? Map<String, dynamic>.from(rawItem) : response;
    setState(() {
      _detail = detail ?? _fallbackDetail(item);
      _loading = false;
    });
  }

  Future<void> _completeCurrent() async {
    final id = _asInt(_detail?['id']);
    if (id <= 0) {
      setState(() => _message = 'Bu örnek içerik tamamlandı.');
      PracticeSoundService.playComplete();
      return;
    }
    setState(() => _completing = true);
    final response = await _completeCall(id);
    if (!mounted) return;
    setState(() {
      _completing = false;
      _message = response == null
          ? 'Tamamlama kaydı için bağlantı bekleniyor.'
          : '+${_asInt(response['xp_awarded'])} XP kaydedildi.';
    });
    PracticeSoundService.playComplete();
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec(widget.kind);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF9AA0A6),
        centerTitle: true,
        title: Text(
          spec.title,
          style: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: PracticeMascot(size: 110))
            : _detail == null
                ? _buildList(spec)
                : _buildDetail(spec),
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }

  Widget _buildList(_ContentSpec spec) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PracticeMascot(size: 104, mood: spec.mood),
                  const SizedBox(width: 12),
                  Expanded(child: PracticeSpeechBubble(text: spec.prompt)),
                ],
              ),
              const SizedBox(height: 20),
              for (final item in _items)
                _ContentCard(
                  color: spec.color,
                  icon: spec.icon,
                  title: '${item['title'] ?? spec.title}',
                  subtitle:
                      '${item['description'] ?? item['subtitle'] ?? spec.subtitle}',
                  badge: '${item['xp_reward'] ?? item['xp'] ?? spec.xp} XP',
                  onTap: () => _openItem(item),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: PracticePrimaryButton(
            label: 'YENILE',
            color: spec.buttonColor,
            onPressed: () => _loadList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(_ContentSpec spec) {
    final title = '${_detail?['title'] ?? spec.title}';
    final description = '${_detail?['description'] ?? spec.subtitle}';
    final content = _detail?['content'];
    final parts = _partsFromDetail();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PracticeMascot(size: 100, mood: spec.mood),
                  const SizedBox(width: 12),
                  Expanded(child: PracticeSpeechBubble(text: title)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                description,
                style: const TextStyle(
                  color: practiceInk,
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (content is Map && content['transcript'] != null)
                _TextPanel(
                  icon: Icons.article_rounded,
                  title: 'Transcript',
                  body: '${content['transcript']}',
                  color: spec.color,
                ),
              for (final part in parts)
                _TextPanel(
                  icon: spec.icon,
                  title: '${part['speaker'] ?? part['title'] ?? 'Bölüm'}',
                  body:
                      '${part['text'] ?? part['line'] ?? part['content'] ?? part['description'] ?? ''}',
                  color: spec.color,
                ),
              if (parts.isEmpty)
                _TextPanel(
                  icon: spec.icon,
                  title: 'Pratik akışı',
                  body:
                      '${content is Map ? content['body'] ?? content['prompt'] ?? spec.detailFallback : spec.detailFallback}',
                  color: spec.color,
                ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                PracticeConfettiOverlay(
                  active: true,
                  child: _TextPanel(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Ödül',
                    body: _message!,
                    color: practiceYellow,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: PracticePrimaryButton(
                  label: 'GERI',
                  color: const Color(0xFFB7B7B7),
                  onPressed:
                      _completing ? null : () => setState(() => _detail = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PracticePrimaryButton(
                  label: _completing ? 'KAYIT...' : 'BITIR',
                  color: spec.buttonColor,
                  onPressed: _completing ? null : () => _completeCurrent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>?> _listCall() {
    return switch (widget.kind) {
      PracticeContentKind.story => _api.getStories(),
      PracticeContentKind.radio => _api.getRadio(),
      PracticeContentKind.adventure => _api.getAdventures(),
      PracticeContentKind.challenge => _api.getChallenges(),
    };
  }

  Future<Map<String, dynamic>?> _detailCall(int id) {
    return switch (widget.kind) {
      PracticeContentKind.story => _api.getStory(id),
      PracticeContentKind.radio => _api.getRadioLesson(id),
      PracticeContentKind.adventure => _api.getAdventure(id),
      PracticeContentKind.challenge => _api.getChallenge(id),
    };
  }

  Future<Map<String, dynamic>?> _completeCall(int id) {
    return switch (widget.kind) {
      PracticeContentKind.story => _api.completeStory(id),
      PracticeContentKind.radio => _api.completeRadio(id),
      PracticeContentKind.adventure => _api.completeAdventure(id),
      PracticeContentKind.challenge => _api.completeChallenge(id),
    };
  }

  List<Map<String, dynamic>> _partsFromDetail() {
    final candidates = [
      _detail?['parts'],
      _detail?['questions'],
      _detail?['scenes'],
      _detail?['items'],
    ];
    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }
    final content = _detail?['content'];
    if (content is Map) {
      for (final key in ['parts', 'questions', 'scenes', 'items']) {
        final value = content[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
        }
      }
    }
    return const [];
  }

  // Sahte içerik gösterme — içerik API'den gelir, yoksa boş (dürüst).
  List<Map<String, dynamic>> _fallbackItems() => const [];

  Map<String, dynamic> _fallbackDetail(Map<String, dynamic> item) {
    final spec = _spec(widget.kind);
    return {
      'id': item['id'] ?? 0,
      'title': item['title'] ?? spec.title,
      'description': item['description'] ?? spec.subtitle,
      'content': {'body': spec.detailFallback},
    };
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class _ContentSpec {
  const _ContentSpec({
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.detailFallback,
    required this.icon,
    required this.color,
    required this.buttonColor,
    required this.mood,
    required this.xp,
  });

  final String title;
  final String subtitle;
  final String prompt;
  final String detailFallback;
  final IconData icon;
  final Color color;
  final Color buttonColor;
  final PracticeMascotMood mood;
  final int xp;
}

_ContentSpec _spec(PracticeContentKind kind) {
  return switch (kind) {
    PracticeContentKind.story => const _ContentSpec(
        title: 'Hikaye',
        subtitle: 'Oku, dinle ve anlama sorularini cevapla.',
        prompt: 'Kısa bir hikaye bölümü açalım.',
        detailFallback:
            'Karakterleri dinle, ana fikri yakala ve bölüm sonunda soruyu cevapla.',
        icon: Icons.menu_book_rounded,
        color: practicePurple,
        buttonColor: practiceBlue,
        mood: PracticeMascotMood.proud,
        xp: 15,
      ),
    PracticeContentKind.radio => const _ContentSpec(
        title: 'Radio',
        subtitle: 'Yavaş dinleme, transcript ve anlama pratiği.',
        prompt: 'Kulağını bugünkü mini yayınla çalıştıralım.',
        detailFallback:
            'Önce normal hizda dinle, sonra transcript uzerinden ana kelimeleri tekrar et.',
        icon: Icons.radio_rounded,
        color: practiceBlue,
        buttonColor: practiceBlue,
        mood: PracticeMascotMood.happy,
        xp: 15,
      ),
    PracticeContentKind.adventure => const _ContentSpec(
        title: 'Macera',
        subtitle: 'Gerçek hayat senaryosunda doğru aksiyonu seç.',
        prompt: 'Senaryoya gir ve doğru cümleyi seç.',
        detailFallback:
            'Restoran, otel veya seyahat sahnesinde en doğal cevabı kullan.',
        icon: Icons.explore_rounded,
        color: practiceOrange,
        buttonColor: practiceGreen,
        mood: PracticeMascotMood.excited,
        xp: 20,
      ),
    PracticeContentKind.challenge => const _ContentSpec(
        title: 'Challenge',
        subtitle: 'Süreli ve bonuslu oyun pratiği.',
        prompt: 'Süre başlamadan hedefini seç.',
        detailFallback: 'Combo yap, hatasiz ilerle ve bonus XP sandığını aç.',
        icon: Icons.timer_rounded,
        color: practiceGreen,
        buttonColor: practiceGreen,
        mood: PracticeMascotMood.excited,
        xp: 25,
      ),
  };
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 31),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
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
            const SizedBox(width: 8),
            Text(
              badge,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontSize: 15,
                    height: 1.35,
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
