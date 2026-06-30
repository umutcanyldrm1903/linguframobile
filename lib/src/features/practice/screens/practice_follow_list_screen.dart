import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import 'practice_visuals.dart';

/// Takip / Takipçi listesi. Backend follow grafiği olmadığından arkadaş
/// verisini yeniden kullanır (following = arkadaşlar, followers = istekler).
class PracticeFollowListScreen extends StatefulWidget {
  const PracticeFollowListScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<PracticeFollowListScreen> createState() =>
      _PracticeFollowListScreenState();
}

class _PracticeFollowListScreenState extends State<PracticeFollowListScreen> {
  final PracticeApiService _api = const PracticeApiService();
  List<Map<String, dynamic>> _following = [];
  List<Map<String, dynamic>> _followers = [];
  bool _loading = true;
  late int _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getFriends();
    if (!mounted) return;
    setState(() {
      _following = _asList(data?['friends']);
      _followers = _asList(data?['requests']);
      if (_followers.isEmpty) _followers = _following;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _tab == 0 ? _following : _followers;
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: Text(isTr ? 'Topluluk' : 'Community',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: Row(
              children: [
                _Tab(
                  label:
                      '${isTr ? 'TAKIP' : 'FOLLOWING'} (${_following.length})',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 10),
                _Tab(
                  label:
                      '${isTr ? 'TAKIPCI' : 'FOLLOWERS'} (${_followers.length})',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: MascotLoading(
                        message: isTr ? 'Yükleniyor...' : 'Loading...'))
                : list.isEmpty
                    ? Center(
                        child: Text(
                          isTr ? 'Henüz kimse yok.' : 'No öne here yet.',
                          style: const TextStyle(
                              color: practiceMuted, fontWeight: FontWeight.w700),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                        children: [
                          for (final user in list) _UserRow(user: user),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? practiceBlue : const Color(0xFFF3F7FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? practiceBlue : const Color(0xFFDDE8F7),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : practiceInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: practiceBlue.withValues(alpha: .16),
            child: const Icon(Icons.person_rounded, color: practiceBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['name'] ?? 'Kullanıcı'}',
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${user['total_xp'] ?? 0} XP',
                  style: const TextStyle(
                    color: practiceMuted,
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
