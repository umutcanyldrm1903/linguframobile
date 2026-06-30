import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeNotificationSettingsScreen extends StatefulWidget {
  const PracticeNotificationSettingsScreen({super.key});

  @override
  State<PracticeNotificationSettingsScreen> createState() =>
      _PracticeNotificationSettingsScreenState();
}

class _PracticeNotificationSettingsScreenState
    extends State<PracticeNotificationSettingsScreen> {
  final PracticeApiService _api = const PracticeApiService();

  bool _loading = true;
  bool _saving = false;

  bool _dailyPractice = true;
  bool _streak = true;
  bool _league = true;
  bool _friend = true;
  bool _assistant = true;
  bool _assistantPush = true;
  bool _assistantAi = true;
  String _reminderWindow = 'morning';

  static const _windows = <String, String>{
    'morning': 'Sabah',
    'afternoon': 'Öğleden sonra',
    'evening': 'Akşam',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _api.getNotificationSettings(),
      _api.getAssistantPreferences(),
    ]);
    final settings = results[0]?['settings'];
    final assistantPreferences = results[1]?['preferences'];
    if (!mounted) return;

    setState(() {
      if (settings is Map) {
        _dailyPractice = settings['daily_practice_enabled'] != false;
        _streak = settings['streak_enabled'] != false;
        _league = settings['league_enabled'] != false;
        _friend = settings['friend_enabled'] != false;
        final window = '${settings['reminder_window'] ?? 'morning'}';
        if (_windows.containsKey(window)) _reminderWindow = window;
      }
      if (assistantPreferences is Map) {
        _assistant = assistantPreferences['assistant_enabled'] != false;
        _assistantPush =
            assistantPreferences['assistant_push_enabled'] != false;
        _assistantAi = assistantPreferences['assistant_ai_enabled'] != false;
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final results = await Future.wait([
      _api.updateNotificationSettings({
        'daily_practice_enabled': _dailyPractice,
        'streak_enabled': _streak,
        'league_enabled': _league,
        'friend_enabled': _friend,
        'reminder_window': _reminderWindow,
      }),
      _api.updateAssistantPreferences({
        'assistant_enabled': _assistant,
        'assistant_push_enabled': _assistant && _assistantPush,
        'assistant_ai_enabled': _assistant && _assistantAi,
      }),
    ]);
    if (!mounted) return;

    setState(() => _saving = false);
    final saved = results.every((result) => result != null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'Bildirim ayarları kaydedildi.' : 'Ayarlar kaydedilemedi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: const Text(
          'Bildirim ayarları',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Ayarlar yükleniyor...'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _ToggleTile(
                  icon: Icons.school_rounded,
                  title: 'Günlük pratik hatırlatması',
                  subtitle:
                      'Can dolumu, yarım ders, günlük hedef ve tekrar önerileri.',
                  value: _dailyPractice,
                  onChanged: (value) => setState(() => _dailyPractice = value),
                ),
                _ToggleTile(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Seri uyarıları',
                  subtitle: 'Serin tehlikedeyken haber ver.',
                  value: _streak,
                  onChanged: (value) => setState(() => _streak = value),
                ),
                _ToggleTile(
                  icon: Icons.emoji_events_rounded,
                  title: 'Lig bildirimleri',
                  subtitle: 'Lig sırası ve terfi durumları.',
                  value: _league,
                  onChanged: (value) => setState(() => _league = value),
                ),
                _ToggleTile(
                  icon: Icons.group_rounded,
                  title: 'Arkadaş bildirimleri',
                  subtitle: 'İstek ve ortak görev güncellemeleri.',
                  value: _friend,
                  onChanged: (value) => setState(() => _friend = value),
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Akıllı Kalem'),
                const SizedBox(height: 10),
                _ToggleTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Öğrenme asistanı',
                  subtitle:
                      'Uygulamadaki ilerlemene göre kısa öneriler gösterir.',
                  value: _assistant,
                  onChanged: (value) {
                    setState(() {
                      _assistant = value;
                      if (!value) {
                        _assistantPush = false;
                        _assistantAi = false;
                      }
                    });
                  },
                ),
                _ToggleTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Kişisel asistan bildirimleri',
                  subtitle: 'Uzun ara verdiğinde uygun bir çalışma önerir.',
                  value: _assistant && _assistantPush,
                  onChanged: _assistant
                      ? (value) => setState(() => _assistantPush = value)
                      : null,
                ),
                _ToggleTile(
                  icon: Icons.psychology_alt_rounded,
                  title: 'Gemini destekli metinler',
                  subtitle:
                      'Önerilerin Gemini ile daha doğal yazılmasını sağlar.',
                  value: _assistant && _assistantAi,
                  onChanged: _assistant
                      ? (value) => setState(() => _assistantAi = value)
                      : null,
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Hatırlatma zamanı'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final entry in _windows.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _reminderWindow == entry.key,
                        onSelected: (_) =>
                            setState(() => _reminderWindow = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                PracticePrimaryButton(
                  label: _saving ? 'KAYDEDİLİYOR...' : 'KAYDET',
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: practiceInk,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: practiceBlue, size: 28),
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
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: practiceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
