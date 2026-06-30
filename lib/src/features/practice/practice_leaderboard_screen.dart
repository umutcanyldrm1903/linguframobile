import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/motion/app_motion.dart';
import 'practice_api_service.dart';
import 'screens/practice_visuals.dart';

class PracticeLeaderboardScreen extends StatefulWidget {
  const PracticeLeaderboardScreen({super.key});

  @override
  State<PracticeLeaderboardScreen> createState() =>
      _PracticeLeaderboardScreenState();
}

class _PracticeLeaderboardScreenState
    extends State<PracticeLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final PracticeApiService _api = const PracticeApiService();
  late TabController _tab;
  List<Map<String, dynamic>> _global = [];
  List<Map<String, dynamic>> _friends = [];
  Map<String, dynamic>? _me;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final g = await _api.getLeaderboard();
    final f = await _api.getFriendLeaderboard();
    if (!mounted) return;
    setState(() {
      final gList = _asList(g?['entries'] ?? g?['leaderboard']);
      final fList = _asList(f?['entries'] ?? f?['leaderboard']);
      // Veri yoksa SAHTE liste gösterme; boş kalır, dürüst boş durum çıkar.
      _global = gList;
      _friends = fList;
      _me = _asMap(g?['me']);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            forceElevated: true,
            shadowColor: practiceLine,
            surfaceTintColor: Colors.white,
            foregroundColor: practiceInk,
            centerTitle: true,
            title: const Text(
              'Puan Tablosu',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Hafta sonucu',
                onPressed: () =>
                    Navigator.pushNamed(context, '/practice/league-result'),
                icon: const Icon(Icons.emoji_events_rounded,
                    color: practiceYellow),
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              labelColor: practiceBlue,
              unselectedLabelColor: practiceMuted,
              indicatorColor: practiceBlue,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              tabs: const [
                Tab(text: 'Genel'),
                Tab(text: 'Arkadaşlar'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: MascotLoading(message: 'Sıralama yükleniyor...'))
            : TabBarView(
                controller: _tab,
                children: [
                  _LeaderList(entries: _global, me: _me),
                  _LeaderList(entries: _friends, me: _me),
                ],
              ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_me != null) _MyRankBar(me: _me!),
          const PracticeBottomTabs(selected: 1),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

}

class _LeaderList extends StatelessWidget {
  const _LeaderList({required this.entries, required this.me});
  final List<Map<String, dynamic>> entries;
  final Map<String, dynamic>? me;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        children: const [
          Icon(Icons.emoji_events_outlined,
              size: 64, color: practiceLine),
          SizedBox(height: 14),
          Text(
            'Henüz sıralama yok',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: practiceInk),
          ),
          SizedBox(height: 6),
          Text(
            'İlk dersini tamamla, XP kazan ve tabloda yerini al!',
            textAlign: TextAlign.center,
            style: TextStyle(color: practiceMuted),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          final rank = (entry['rank'] as num?)?.toInt() ?? (i + 1);
          final isMe = entry['is_me'] == true;
          return _LeaderCard(
            rank: rank,
            name: '${entry['name'] ?? entry['username'] ?? 'Oyuncu'}',
            xp: (entry['weekly_xp'] as num?)?.toInt() ??
                (entry['xp'] as num?)?.toInt() ?? 0,
            avatarUrl: entry['avatar_url'] as String?,
            isMe: isMe,
          );
        },
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  const _LeaderCard({
    required this.rank,
    required this.name,
    required this.xp,
    required this.isMe,
    this.avatarUrl,
  });
  final int rank;
  final String name;
  final int xp;
  final bool isMe;
  final String? avatarUrl;

  static const _bronze = Color(0xFFCD7F32);
  static const _silver = Color(0xFF9E9E9E);
  static const _gold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? _gold
        : rank == 2
            ? _silver
            : rank == 3
                ? _bronze
                : practiceMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? practiceBlue : practiceLine,
          width: isMe ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Icon(
                    rank == 1
                        ? Icons.emoji_events_rounded
                        : Icons.emoji_events_outlined,
                    color: rankColor,
                    size: 28,
                  )
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: practiceBlue.withValues(alpha: 0.12),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: practiceBlue,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: practiceInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    decoration:
                        isMe ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
                Text(
                  isMe ? 'Sen' : '',
                  style: const TextStyle(
                    color: practiceBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.compact().format(xp),
                style: const TextStyle(
                  color: practiceOrange,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Text(
                'XP',
                style: TextStyle(
                  color: practiceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyRankBar extends StatelessWidget {
  const _MyRankBar({required this.me});
  final Map<String, dynamic> me;

  @override
  Widget build(BuildContext context) {
    final rank = (me['rank'] as num?)?.toInt() ?? 0;
    final xp = (me['weekly_xp'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9FF),
        border: Border(
          top: BorderSide(color: practiceBlue, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Sıralamam: #$rank',
            style: const TextStyle(
              color: practiceBlue,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            '$xp XP bu hafta',
            style: const TextStyle(
              color: practiceOrange,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
