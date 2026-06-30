import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_repository.dart';
import '../practice_sound_service.dart';
import '../practice_widget_service.dart';
import 'practice_visuals.dart';

class PracticeSettingsScreen extends StatefulWidget {
  const PracticeSettingsScreen({super.key});

  @override
  State<PracticeSettingsScreen> createState() => _PracticeSettingsScreenState();
}

class _PracticeSettingsScreenState extends State<PracticeSettingsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final PracticeRepository _repository = const PracticeRepository();
  bool _sound = true;
  bool _streak = true;
  bool _friends = true;
  bool _league = true;
  TimeOfDay _reminder = const TimeOfDay(hour: 20, minute: 30);
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final remote = await _api.getSettings();
    final notificationRemote = await _api.getNotificationSettings();
    final rawSettings = remote?['settings'];
    final settings = rawSettings is Map
        ? Map<String, dynamic>.from(rawSettings)
        : <String, dynamic>{};
    final rawNotifications = notificationRemote?['settings'];
    final notifications = rawNotifications is Map
        ? Map<String, dynamic>.from(rawNotifications)
        : <String, dynamic>{};
    if (!mounted) return;
    setState(() {
      _sound = settings['sound_enabled'] as bool? ??
          prefs.getBool('practice.sound.enabled') ??
          true;
      _streak = notifications['streak_enabled'] != false;
      _friends = notifications['friend_enabled'] != false;
      _league = notifications['league_enabled'] != false;
      _reminder = switch ('${notifications['reminder_window'] ?? 'evening'}') {
        'morning' => const TimeOfDay(hour: 9, minute: 0),
        'afternoon' => const TimeOfDay(hour: 14, minute: 0),
        _ => const TimeOfDay(hour: 20, minute: 30),
      };
      _loading = false;
    });
    PracticeSoundService.setEnabled(_sound);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('practice.sound.enabled', _sound);
    PracticeSoundService.setEnabled(_sound);
    await Future.wait([
      _api.updateSettings({'sound_enabled': _sound}),
      _api.updateNotificationSettings({
        'daily_practice_enabled': true,
        'streak_enabled': _streak,
        'friend_enabled': _friends,
        'league_enabled': _league,
        'reminder_window': _reminder.hour < 12
            ? 'morning'
            : (_reminder.hour < 18 ? 'afternoon' : 'evening'),
      }),
    ]);
    final stats = await _repository.fetchStats();
    await PracticeWidgetService.update(
      streak: stats.streak,
      xp: stats.xp,
      hearts: stats.hearts,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pratik ayarları kaydedildi.')),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminder,
    );
    if (picked != null && mounted) {
      setState(() => _reminder = picked);
    }
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
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: MascotLoading(message: 'Ayarlar yükleniyor...'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Row(
                  children: [
                    const PracticeMascot(
                      size: 104,
                      mood: PracticeMascotMood.thinking,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PracticeSpeechBubble(
                        text:
                            'Ses, bildirim, offline ve widget ayarlarini buradan yönet.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SwitchCard(
                  icon: Icons.volume_up_rounded,
                  title: 'Ses efektleri',
                  subtitle: 'Doğru, yanlış, XP ve ödül seslerini cal.',
                  value: _sound,
                  onChanged: (value) => setState(() => _sound = value),
                ),
                _SwitchCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak uyarilari',
                  subtitle: 'Seri bozulmadan önce hatırlat.',
                  value: _streak,
                  onChanged: (value) => setState(() => _streak = value),
                ),
                _SwitchCard(
                  icon: Icons.people_rounded,
                  title: 'Arkadaş bildirimleri',
                  subtitle: 'Arkadaş isteği ve tebrikleri göster.',
                  value: _friends,
                  onChanged: (value) => setState(() => _friends = value),
                ),
                _SwitchCard(
                  icon: Icons.leaderboard_rounded,
                  title: 'Lig bildirimleri',
                  subtitle: 'Yukselme/dusme bolgesi uyarilarini al.',
                  value: _league,
                  onChanged: (value) => setState(() => _league = value),
                ),
                _ActionCard(
                  icon: Icons.alarm_rounded,
                  title: 'Hatirlatma saati',
                  subtitle:
                      '${_reminder.hour.toString().padLeft(2, '0')}:${_reminder.minute.toString().padLeft(2, '0')}',
                  action: 'SEC',
                  onTap: () => _pickTime(),
                ),
                _ActionCard(
                  icon: Icons.offline_bolt_rounded,
                  title: 'Offline pratik paketi',
                  subtitle: 'Dersleri indir, internet yokken çalış.',
                  action: 'AC',
                  onTap: () =>
                      Navigator.pushNamed(context, '/practice/offline'),
                ),
                _ActionCard(
                  icon: Icons.analytics_rounded,
                  title: 'Analitik dashboard',
                  subtitle: 'Adaptif öğrenme ve performans raporu.',
                  action: 'GOR',
                  onTap: () =>
                      Navigator.pushNamed(context, '/practice/analytics'),
                ),
                const SizedBox(height: 16),
                PracticePrimaryButton(
                  label: _saving ? 'KAYDEDILIYOR' : 'KAYDET',
                  color: practiceGreen,
                  onPressed: _saving ? null : () => _save(),
                ),
              ],
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 0),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: practiceBlue, size: 32),
          const SizedBox(width: 14),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: practiceOrange, size: 32),
          const SizedBox(width: 14),
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
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}
