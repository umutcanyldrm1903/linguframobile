import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_game_widgets.dart';
import 'practice_visuals.dart';

class PracticeFriendsScreen extends StatefulWidget {
  const PracticeFriendsScreen({super.key});

  @override
  State<PracticeFriendsScreen> createState() => _PracticeFriendsScreenState();
}

class _PracticeFriendsScreenState extends State<PracticeFriendsScreen> {
  final PracticeApiService _api = const PracticeApiService();
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _quests = [];
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _streakBest;
  int _myStreak = 0;
  bool _loading = true;
  bool _searching = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// "Arkadaş ekle" → arkadaş sekmesine geç ve arama kutusuna odaklan
  /// (uygulama içi ekleme).
  void _focusSearch() {
    if (_tab != 1) setState(() => _tab = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final friends = await _api.getFriends();
    final quests = await _api.getFriendQuests();
    final streak = await _api.getFriendStreak();
    if (!mounted) return;
    setState(() {
      _friends = _asList(friends?['friends']);
      _requests = _asList(friends?['requests']);
      _quests = _asList(quests?['quests']);
      final best = streak?['best'];
      _streakBest = best is Map ? Map<String, dynamic>.from(best) : null;
      _myStreak = _asInt(streak?['my_streak']);
      _loading = false;
    });
  }

  Future<void> _shareInvite() async {
    final data = await _api.getFriendInvite();
    final text = '${data?['message'] ?? 'Benimle pratik yap, XP kazan ve serini koru.'}'
        '${data?['invite_url'] != null ? '\n${data!['invite_url']}' : ''}';
    await SharePlus.instance.share(
      ShareParams(subject: 'Pratik daveti', text: text),
    );
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final data = await _api.searchFriends(q);
    if (!mounted) return;
    setState(() {
      _results = _asList(data?['users']);
      _searching = false;
    });
  }

  Future<void> _request(Map<String, dynamic> user) async {
    final id = _asInt(user['id']);
    if (id <= 0) return;
    final result = await _api.requestFriend(id);
    if (!mounted) return;
    if (result != null) {
      final name = '${user['name'] ?? 'Kullanıcı'}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.code == 'tr'
              ? '$name için istek gönderildi.'
              : 'Request sent to $name.'),
        ),
      );
      setState(() => _results.remove(user));
    }
  }

  Future<void> _accept(Map<String, dynamic> request) async {
    final id = _asInt(request['request_id'] ?? request['id']);
    if (id <= 0) return;
    final data = await _api.acceptFriend(id);
    if (data != null) {
      await PracticeSoundService.playComplete();
      await _load();
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final id = _asInt(item['request_id'] ?? item['id']);
    if (id <= 0) return;
    final data = await _api.removeFriend(id);
    if (data != null) await _load();
  }

  Future<void> _claimQuest(Map<String, dynamic> quest) async {
    final key = '${quest['key'] ?? ''}';
    if (key.isEmpty) return;
    final result = await _api.claimFriendQuest(key);
    if (result != null) {
      await PracticeSoundService.playComplete();
      if (mounted) {
        await showRewardPopup(
          context,
          title: AppStrings.code == 'tr'
              ? 'Ortak görev tamam!'
              : 'Friend quest done!',
          xp: _asInt(quest['reward_xp']),
          coins: _asInt(quest['reward_coins']),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: practiceKraft,
      appBar: AppBar(
        backgroundColor: practiceKraft,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.code == 'tr' ? 'Arkadaşlar' : 'Friends',
          style: const TextStyle(
            color: practiceInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: _FriendsTabs(
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _tab == 0
                  ? _BulletinList(
                      key: const ValueKey('bulletin'),
                      onAdd: _focusSearch,
                      onShare: _shareInvite,
                    )
                  : _buildFriendsTab(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PracticeBottomTabs(selected: 4),
    );
  }

  Widget _buildFriendsTab() {
    if (_loading) {
      return Center(
        key: const ValueKey('friends-loading'),
        child: MascotLoading(
          message: AppStrings.code == 'tr'
              ? 'Arkadaşlar yükleniyor...'
              : 'Loading friends...',
        ),
      );
    }
    return RefreshIndicator(
      key: const ValueKey('friends'),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
        children: [
          _InviteCard(onAdd: _focusSearch, onShare: _shareInvite),
          const SizedBox(height: 18),
          if (_friends.isNotEmpty) ...[
            _FriendStreakCard(
              friends: _friends,
              best: _streakBest,
              myStreak: _myStreak,
            ),
            const SizedBox(height: 18),
          ],
          // Arama
          TextField(
            controller: _search,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onChanged: (v) {
              if (v.trim().length >= 2) _runSearch(v);
            },
            onSubmitted: _runSearch,
            decoration: InputDecoration(
              hintText: AppStrings.code == 'tr'
                  ? 'İsim ile arkadaş ara...'
                  : 'Search friends by name...',
              prefixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              filled: true,
              fillColor: practicePaper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: practiceLine, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: practiceLine, width: 1.5),
              ),
            ),
          ),
          for (final user in _results)
            _PersonRow(
              name: '${user['name'] ?? 'Kullanıcı'}',
              subtitle: '${user['total_xp'] ?? 0} XP',
              actionLabel: AppStrings.code == 'tr' ? 'EKLE' : 'ADD',
              actionColor: practiceBlue,
              onAction: () => _request(user),
            ),
          if (_requests.isNotEmpty) ...[
            _SectionTitle(
                AppStrings.code == 'tr' ? 'İstekler' : 'Requests'),
            for (final req in _requests)
              _PersonRow(
                name: '${req['name'] ?? 'Kullanıcı'}',
                subtitle: '${req['total_xp'] ?? 0} XP',
                actionLabel: AppStrings.code == 'tr' ? 'KABUL' : 'ACCEPT',
                actionColor: practiceGreen,
                onAction: () => _accept(req),
                secondaryLabel: AppStrings.code == 'tr' ? 'SIL' : 'REMOVE',
                onSecondary: () => _remove(req),
              ),
          ],
          _SectionTitle(
              AppStrings.code == 'tr' ? 'Arkadaşlarin' : 'Your friends'),
          if (_friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppStrings.code == 'tr'
                    ? 'Henüz arkadaşın yok. Yukarıdan arayarak ekleyebilirsin.'
                    : 'No friends yet. Search above to add.',
                style: const TextStyle(
                    color: practiceMuted, fontWeight: FontWeight.w700),
              ),
            )
          else
            for (final friend in _friends)
              _PersonRow(
                name: '${friend['name'] ?? 'Arkadaş'}',
                subtitle: AppStrings.code == 'tr'
                    ? '${friend['weekly_xp'] ?? 0} XP · ${friend['streak_days'] ?? 0} gün seri'
                    : '${friend['weekly_xp'] ?? 0} XP · ${friend['streak_days'] ?? 0} day streak',
                actionLabel: AppStrings.code == 'tr' ? 'SIL' : 'REMOVE',
                actionColor: practiceRed,
                onAction: () => _remove(friend),
              ),
          if (_quests.isNotEmpty) ...[
            _SectionTitle(
                AppStrings.code == 'tr' ? 'Ortak görevler' : 'Friend quests'),
            for (final quest in _quests)
              _FriendQuestCard(quest: quest, onClaim: () => _claimQuest(quest)),
          ],
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

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class _FriendStreakCard extends StatelessWidget {
  const _FriendStreakCard({
    required this.friends,
    this.best,
    this.myStreak = 0,
  });

  final List<Map<String, dynamic>> friends;

  /// `/practice/friend-streak` endpoint'inden gelen en iyi ortak seri.
  final Map<String, dynamic>? best;
  final int myStreak;

  int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';

    int days;
    String name;
    final bestStreak = best != null ? _asInt(best!['friend_streak']) : 0;
    if (best != null && bestStreak > 0) {
      // Sunucudan gelen ortak (mutual) seri.
      days = bestStreak;
      name = '${best!['name'] ?? (isTr ? 'Arkadaşın' : 'a friend')}';
    } else {
      // Fallback: en uzun seriye sahip arkadaşı vurgula (ortak = min ikimiz).
      Map<String, dynamic>? top;
      var b = 0;
      for (final f in friends) {
        final s = _asInt(f['streak_days']);
        if (s > b) {
          b = s;
          top = f;
        }
      }
      days = (myStreak > 0 && myStreak < b) ? myStreak : b;
      name = '${top?['name'] ?? (isTr ? 'Arkadaşın' : 'a friend')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: practiceOrange.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(color: practiceOrange, width: 2),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: practiceOrange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr
                      ? '$days günlük arkadaş serisi'
                      : '$days-day friend streak',
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTr
                      ? '$name ile birlikte pratik yaparak seriyi büyütün!'
                      : 'Practice with $name to grow your streak!',
                  style: const TextStyle(
                    color: practiceMuted,
                    height: 1.3,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: practiceInk,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.subtitle,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String name;
  final String subtitle;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
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
                  name,
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
          if (secondaryLabel != null)
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: const TextStyle(
                    color: practiceRed, fontWeight: FontWeight.w800),
              ),
            ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(color: actionColor, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendQuestCard extends StatelessWidget {
  const _FriendQuestCard({required this.quest, required this.onClaim});

  final Map<String, dynamic> quest;
  final VoidCallback onClaim;

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _asInt(quest['progress']);
    final target = _asInt(quest['target'], fallback: 1);
    final completed = quest['completed'] == true || progress >= target;
    final claimed = quest['claimed'] == true;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: practiceBlue, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${quest['title'] ?? 'Ortak görev'}',
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '+${quest['reward_xp'] ?? 0} XP',
                style: const TextStyle(
                  color: practiceOrange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PracticeProgressBar(
            value: (progress / target).clamp(0.0, 1.0),
            height: 10,
          ),
          Row(
            children: [
              Text(
                '$progress / $target',
                style: const TextStyle(
                  color: practiceMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: completed && !claimed ? onClaim : null,
                child: Text(claimed
                    ? (AppStrings.code == 'tr' ? 'ALINDI' : 'CLAIMED')
                    : (AppStrings.code == 'tr' ? 'ÖDÜL AL' : 'CLAIM')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendsTabs extends StatelessWidget {
  const _FriendsTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: practiceLine, width: 1.5)),
      ),
      child: Row(
        children: [
          _FriendTabButton(
            label: AppStrings.code == 'tr' ? 'BÜLTEN' : 'BULLETIN',
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
          _FriendTabButton(
            label: AppStrings.code == 'tr' ? 'ARKADAŞLAR' : 'FRIENDS',
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _FriendTabButton extends StatelessWidget {
  const _FriendTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? practiceInk : practiceMuted,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: 54,
              decoration: BoxDecoration(
                color: selected ? practiceOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletinList extends StatelessWidget {
  const _BulletinList({
    super.key,
    required this.onAdd,
    required this.onShare,
  });

  final VoidCallback onAdd;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 100),
      children: [
        _InviteCard(onAdd: onAdd, onShare: onShare),
        const SizedBox(height: 20),
        _BulletinCard(
          accent: practiceBlue,
          age: AppStrings.code == 'tr' ? '1 dakika' : '1 minute',
          title: AppStrings.code == 'tr'
              ? 'Bültenine hoş geldin! Burada arkadaşlarının başarılarını kutlayabilir, ipuçlarına ve duyurulara ulaşabilirsin.'
              : 'Welcome to your bulletin! Celebrate your friends\' wins and find tips and updates here.',
          mascot: true,
        ),
        _BulletinCard(
          accent: practiceOrange,
          age: AppStrings.code == 'tr' ? '1 dakika' : '1 minute',
          title: AppStrings.code == 'tr'
              ? 'Serini devam ettirmek için her gün bir ders tamamla!'
              : 'Complete a lesson every day to keep your streak!',
          fire: true,
          action: AppStrings.code == 'tr' ? 'DERSE BAŞLA' : 'START LESSON',
        ),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.onAdd, required this.onShare});

  /// Uygulama içi ekleme (arama kutusuna odaklanır).
  final VoidCallback onAdd;

  /// Davet linkini sistem paylaşımıyla gönderir.
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr
                      ? 'Arkadaşlarınla\nbaşarılarını paylaş'
                      : 'Share your wins\nwith friends',
                  style: const TextStyle(
                    color: practiceInk,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                    label: Text(
                      isTr ? 'ARKADAŞ EKLE' : 'ADD FRIEND',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(
                    isTr ? 'Davet linki paylaş' : 'Share invite link',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const PracticeMascot(size: 84, mood: PracticeMascotMood.proud),
        ],
      ),
    );
  }
}

class _BulletinCard extends StatelessWidget {
  const _BulletinCard({
    required this.accent,
    required this.age,
    required this.title,
    this.mascot = false,
    this.fire = false,
    this.action,
  });

  /// Sol "cilt payı" şeridi + ikon rengi.
  final Color accent;
  final String age;
  final String title;
  final bool mascot;
  final bool fire;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: practicePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: practiceLine, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Defter cilt payı (sol aksan şeridi)
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            fire
                                ? Icons.local_fire_department_rounded
                                : Icons.campaign_rounded,
                            color: accent,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            age,
                            style: const TextStyle(
                              color: practiceMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: practiceInk,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/practice/lesson'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: practiceBlue,
                            side: const BorderSide(
                                color: practiceLine, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                          ),
                          child: Text(
                            action!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (mascot)
                const Padding(
                  padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
                  child: Align(
                    alignment: Alignment.center,
                    child: PracticeMascot(
                        size: 72, mood: PracticeMascotMood.proud),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
