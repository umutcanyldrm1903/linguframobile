import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../practice_api_service.dart';
import '../practice_sound_service.dart';
import 'practice_visuals.dart';

/// Lig haftası töreni: sıra + terfi/koruma/düşme bölgesi + konfeti.
class PracticeLeagueResultScreen extends StatefulWidget {
  const PracticeLeagueResultScreen({super.key});

  @override
  State<PracticeLeagueResultScreen> createState() =>
      _PracticeLeagueResultScreenState();
}

class _PracticeLeagueResultScreenState
    extends State<PracticeLeagueResultScreen> {
  final PracticeApiService _api = const PracticeApiService();
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 3));

  bool _loading = true;
  String _league = 'Bronz';
  int _rank = 0;
  String _zone = 'safe';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _api.getLeaderboard();
    if (!mounted) return;
    final league = data?['league'];
    setState(() {
      _rank = _asInt(data?['my_rank'] ??
          (league is Map ? league['my_rank'] : null) ??
          4);
      _zone = '${(league is Map ? league['my_zone'] : null) ?? data?['zone'] ?? _zoneForRank(_rank)}';
      _league = '${(league is Map ? league['name'] : null) ?? 'Bronz'}';
      _loading = false;
    });
    if (_zone == 'promotion') {
      _confetti.play();
      unawaited(PracticeSoundService.playStreak());
    } else {
      unawaited(PracticeSoundService.playComplete());
    }
  }

  String _zoneForRank(int rank) {
    if (rank > 0 && rank <= 3) return 'promotion';
    if (rank >= 13) return 'demotion';
    return 'safe';
  }

  ({String title, String subtitle, Color color, IconData icon}) get _spec {
    final isTr = AppStrings.code == 'tr';
    switch (_zone) {
      case 'promotion':
        return (
          title: isTr ? 'Terfi ettin!' : 'You got promoted!',
          subtitle: isTr
              ? 'Bir üst lige yükseldin. Harika gidiyorsun!'
              : 'You moved up a league. Great job!',
          color: practiceGreen,
          icon: Icons.trending_up_rounded,
        );
      case 'demotion':
        return (
          title: isTr ? 'Bu hafta düştün' : 'You dropped this week',
          subtitle: isTr
              ? 'Önemli değil, bu hafta tekrar yüksel!'
              : 'No worries, climb back up this week!',
          color: const Color(0xFFFF5964),
          icon: Icons.trending_down_rounded,
        );
      default:
        return (
          title: isTr ? 'Ligde kaldın' : 'You held your league',
          subtitle: isTr
              ? 'Yerini korudun. Terfi için biraz daha XP!'
              : 'You kept your spot. A bit more XP to promote!',
          color: practiceBlue,
          icon: Icons.shield_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final isTr = AppStrings.code == 'tr';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: practiceInk,
        centerTitle: true,
        title: Text(isTr ? 'Hafta sonucu' : 'Weekly result',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? Center(
              child: MascotLoading(
                  message: isTr ? 'Lig hesaplaniyor...' : 'Calculating...'))
          : Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 28,
                    colors: const [
                      practiceGreen,
                      practiceYellow,
                      practiceBlue,
                      practiceOrange,
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      // 🎉 Terfi ise PracticeLeagueTransition ile tam animasyon
                      if (_zone == 'promotion' || _zone == 'demotion')
                        SizedBox(
                          height: 340,
                          child: PracticeLeagueTransition(
                            isPromotion: _zone == 'promotion',
                            leagueName: _league,
                            leagueColor: spec.color,
                          ),
                        )
                      else
                        Column(
                          children: [
                            Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                color: spec.color.withValues(alpha: .14),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: spec.color, width: 4),
                              ),
                              child: Icon(spec.icon,
                                  color: spec.color, size: 68),
                            )
                                .animate()
                                .scaleXY(
                                    begin: .4,
                                    end: 1,
                                    duration: 500.ms,
                                    curve: Curves.elasticOut),
                            const SizedBox(height: 20),
                            Text(
                              spec.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: spec.color,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isTr
                                  ? '$_league ligi · ${_rank > 0 ? '$_rank. sıra' : 'Sıralanmadı'}'
                                  : '$_league league · ${_rank > 0 ? 'rank $_rank' : 'Unranked'}',
                              style: const TextStyle(
                                color: practiceInk,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              spec.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: practiceMuted,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      PracticePrimaryButton(
                        label: isTr ? 'DEVAM ET' : 'CONTINUE',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
