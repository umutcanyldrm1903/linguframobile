import 'package:flutter/material.dart';

import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

class PracticeNotificationsScreen extends StatefulWidget {
  const PracticeNotificationsScreen({super.key});

  @override
  State<PracticeNotificationsScreen> createState() =>
      _PracticeNotificationsScreenState();
}

class _PracticeNotificationsScreenState
    extends State<PracticeNotificationsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getNotifications();
    final raw = data?['notifications'] ?? data?['items'];
    if (!mounted) return;
    setState(() {
      _items = _asList(raw);
      _loading = false;
    });
  }

  Future<void> _readAll() async {
    // Görünen okunmamış bildirimleri toplu olarak okundu işaretle.
    final ids = _items
        .map((n) => _asInt(n['id']))
        .where((id) => id > 0)
        .toList(growable: false);
    if (ids.isNotEmpty) {
      await _api.readNotifications(ids);
    } else {
      await _api.readAllNotifications();
    }
    await _load();
  }

  Future<void> _readOne(Map<String, dynamic> item) async {
    final id = _asInt(item['id']);
    if (id > 0) await _api.readNotification(id);
    final data = item['data'];
    final rawRoute = data is Map ? data['route'] : item['route'];
    final route = _normalizeRoute(rawRoute);
    if (!mounted) return;
    if (route is String && route.startsWith('/practice')) {
      Navigator.pushNamed(context, route);
    } else {
      await _load();
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
          'Bildirimler',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/practice/notification-settings',
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: MascotLoading(message: 'Bildirimler yükleniyor...'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bulten',
                          style: TextStyle(
                            color: practiceInk,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _readAll(),
                        child: const Text('HEPSINI OKU'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'Henüz bildirimin yok.',
                          style: TextStyle(
                            color: practiceMuted,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  for (final item in _items)
                    _NotificationCard(
                      item: item,
                      onTap: () => _readOne(item),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 4),
    );
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String? _normalizeRoute(Object? value) {
    if (value is! String || !value.startsWith('/practice')) return null;
    const aliases = {
      '/practice-leaderboard': '/practice/leaderboard',
      '/practice-friends': '/practice/friends',
      '/practice-quests': '/practice/daily-quests',
    };
    return aliases[value] ?? value;
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = item['read'] != true;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread ? const Color(0xFF84D8FF) : practiceLine,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 118,
              decoration: BoxDecoration(
                color: _color('${item['type'] ?? ''}'),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: PracticeMascot(
                  size: 118,
                  mood: unread
                      ? PracticeMascotMood.excited
                      : PracticeMascotMood.happy,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['title'] ?? 'Bildirim'}',
                    style: const TextStyle(
                      color: practiceInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item['body'] ?? item['message'] ?? ''}',
                    style: const TextStyle(
                      color: practiceMuted,
                      height: 1.35,
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

  Color _color(String type) {
    if (type.contains('streak')) return const Color(0xFFFF9800);
    if (type.contains('friend')) return practiceBlue;
    if (type.contains('quest')) return practicePurple;
    return const Color(0xFFFFF4CF);
  }
}
