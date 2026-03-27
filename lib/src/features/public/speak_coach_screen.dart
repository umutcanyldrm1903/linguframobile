import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../shared/content_preview_launcher.dart';
import '../student/instructors/instructor_repository.dart';
import '../student/instructors/student_instructors_screen.dart';
import 'public_footer.dart';
import 'public_header.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';
import 'speak_coach_repository.dart';

class SpeakCoachScreen extends StatefulWidget {
  const SpeakCoachScreen({super.key});

  @override
  State<SpeakCoachScreen> createState() => _SpeakCoachScreenState();
}

class _SpeakCoachScreenState extends State<SpeakCoachScreen> {
  final SpeakCoachRepository _repository = SpeakCoachRepository();
  final SpeechToText _speech = SpeechToText();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _practiceController = TextEditingController();
  final GlobalKey _assessmentKey = GlobalKey();
  final GlobalKey _missionsKey = GlobalKey();
  final GlobalKey _practiceKey = GlobalKey();
  final GlobalKey _matchesKey = GlobalKey();
  final GlobalKey _libraryKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  late final Future<SpeakCoachBootstrap> _bootstrapFuture = _repository.load();

  SpeakCoachBootstrap? _bootstrap;
  SpeakCoachLocalState _localState = SpeakCoachLocalState.initial();
  bool _stateApplied = false;

  Timer? _assessmentTimer;
  bool _speechReady = false;
  bool _speechSupported = true;
  String? _speechHint;
  bool _assessmentListening = false;
  bool _practiceListening = false;
  int _assessmentElapsedSeconds = 0;
  double _soundLevel = 0;
  String _assessmentTranscript = '';
  _AssessmentReport? _assessmentReport;
  int _activeScenarioIndex = 0;
  List<_PracticeMessage> _practiceMessages = const [];
  List<_TutorMatchViewModel> _matches = const [];
  Map<int, InstructorAvailabilitySnapshot> _availabilityById =
      const <int, InstructorAvailabilitySnapshot>{};
  bool _loadingMatches = false;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture.then((value) {
      if (!mounted) return;
      _applyBootstrap(value);
    });
    _initSpeech();
  }

  @override
  void dispose() {
    _assessmentTimer?.cancel();
    _practiceController.dispose();
    _scrollController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final ready = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
      );
      if (!mounted) return;
      setState(() {
        _speechReady = ready;
        _speechSupported = ready;
        if (!ready) {
          _speechHint = _copy(
            'Bu cihazda ses tanima hazir degil. Yine de yazili prova kullanabilirsin.',
            'Speech recognition is not ready on this device. You can still use typed practice.',
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechSupported = false;
        _speechHint = _copy(
          'Ses tanima baslatilamadi. Yine de yazili prova kullanabilirsin.',
          'Speech recognition could not start. You can still use typed practice.',
        );
      });
    }
  }

  void _applyBootstrap(SpeakCoachBootstrap bootstrap) {
    if (_stateApplied) return;
    _stateApplied = true;
    _bootstrap = bootstrap;
    _localState = bootstrap.localState;
    _resetPracticeConversation();
    _refreshMatches();
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if ((status == 'done' || status == 'notListening') &&
        _assessmentListening) {
      _stopAssessment();
      return;
    }
    if ((status == 'done' || status == 'notListening') && _practiceListening) {
      setState(() {
        _practiceListening = false;
      });
      return;
    }
    setState(() {
      _speechHint = status;
    });
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _assessmentListening = false;
      _practiceListening = false;
      _speechHint = error.errorMsg;
    });
  }

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  _CoachChoice get _selectedGoal =>
      _goalChoices.firstWhere((item) => item.id == _localState.goalId);

  _CoachChoice get _selectedAccent =>
      _accentChoices.firstWhere((item) => item.id == _localState.accentId);

  _CoachChoice get _selectedSchedule =>
      _scheduleChoices.firstWhere((item) => item.id == _localState.scheduleId);

  List<_CoachChoice> get _goalChoices => [
        _CoachChoice(
          id: 'speaking',
          title: _copy('Konusma', 'Speaking'),
          subtitle: _copy('Gunluk iletisim ve akicilik', 'Daily fluency'),
          icon: Icons.record_voice_over_rounded,
        ),
        _CoachChoice(
          id: 'business',
          title: _copy('Is Ingilizcesi', 'Business'),
          subtitle:
              _copy('Toplanti ve sunum dili', 'Meetings and presentations'),
          icon: Icons.work_outline_rounded,
        ),
        _CoachChoice(
          id: 'ielts',
          title: 'IELTS / TOEFL',
          subtitle: _copy('Sinav ve akademik ifade', 'Exam-ready speaking'),
          icon: Icons.verified_outlined,
        ),
        _CoachChoice(
          id: 'kids',
          title: _copy('Cocuklar', 'Kids'),
          subtitle: _copy(
              'Yasina uygun akici giris', 'Confidence for young learners'),
          icon: Icons.child_care_outlined,
        ),
        _CoachChoice(
          id: 'travel',
          title: _copy('Yurt disi', 'Travel'),
          subtitle: _copy('Seyahat ve tasinma dili', 'Travel and relocation'),
          icon: Icons.flight_takeoff_rounded,
        ),
      ];

  List<_CoachChoice> get _accentChoices => [
        _CoachChoice(
          id: 'foreign',
          title: _copy('Yabanci egitmen', 'Foreign tutor'),
          subtitle: _copy('Dogal aksan ve speaking odagi',
              'Natural accent and speaking focus'),
          icon: Icons.public_rounded,
        ),
        _CoachChoice(
          id: 'turkish',
          title: _copy('Turk egitmen', 'Turkish tutor'),
          subtitle: _copy('Hizli aciklama ve net takip',
              'Fast explanations and guided support'),
          icon: Icons.flag_circle_outlined,
        ),
      ];

  List<_CoachChoice> get _budgetChoices => [
        _CoachChoice(
          id: 'starter',
          title: _copy('Baslangic', 'Starter'),
          subtitle: _copy('Butce dostu duzen', 'Budget-friendly'),
          icon: Icons.savings_outlined,
        ),
        _CoachChoice(
          id: 'balanced',
          title: _copy('Dengeli', 'Balanced'),
          subtitle: _copy('Fiyat ve kalite dengesi', 'Best value mix'),
          icon: Icons.balance_rounded,
        ),
        _CoachChoice(
          id: 'premium',
          title: _copy('Premium', 'Premium'),
          subtitle: _copy('Hizli ivme ve yakin takip', 'Faster progress'),
          icon: Icons.workspace_premium_outlined,
        ),
      ];

  List<_CoachChoice> get _scheduleChoices => [
        _CoachChoice(
          id: 'morning',
          title: _copy('Sabah', 'Morning'),
          subtitle: '07:00 - 12:00',
          icon: Icons.wb_sunny_outlined,
        ),
        _CoachChoice(
          id: 'evening',
          title: _copy('Aksam', 'Evening'),
          subtitle: '18:00 - 23:00',
          icon: Icons.nights_stay_outlined,
        ),
        _CoachChoice(
          id: 'weekend',
          title: _copy('Hafta sonu', 'Weekend'),
          subtitle: _copy('Cumartesi ve pazar', 'Saturday and Sunday'),
          icon: Icons.event_available_outlined,
        ),
      ];

  List<_DailyMission> get _missions {
    final goal = _localState.goalId;
    if (goal == 'business') {
      return [
        _DailyMission(
          id: 'biz-warmup',
          title:
              _copy('1 dakikalik toplanti acilisi', '1-minute meeting opener'),
          detail: _copy('Kendini, rolunu ve toplantinin amacini anlat.',
              'Introduce yourself, your role, and the meeting goal.'),
          durationLabel: '5 min',
          icon: Icons.meeting_room_outlined,
        ),
        _DailyMission(
          id: 'biz-vocab',
          title: _copy('Bugunun 6 is kelimesi', 'Today\'s 6 business phrases'),
          detail: _copy(
              'Deadline, follow-up, agenda gibi kelimeleri cümlede kullan.',
              'Use deadline, follow-up, and agenda in full sentences.'),
          durationLabel: '4 min',
          icon: Icons.topic_outlined,
        ),
        _DailyMission(
          id: 'biz-shadow',
          title: _copy('Sunum provasi', 'Presentation drill'),
          detail: _copy('Bir fikri 30 saniyede net sekilde ozetle.',
              'Summarize one idea clearly in 30 seconds.'),
          durationLabel: '5 min',
          icon: Icons.campaign_outlined,
        ),
      ];
    }

    if (goal == 'ielts') {
      return [
        _DailyMission(
          id: 'exam-part1',
          title: _copy('Part 1 hizli cevap', 'Part 1 quick answer'),
          detail: _copy('Kisa soruya en az 3 cumlelik cevap ver.',
              'Answer a short prompt with at least 3 sentences.'),
          durationLabel: '5 min',
          icon: Icons.quiz_outlined,
        ),
        _DailyMission(
          id: 'exam-part2',
          title: _copy('40 saniye tek konu anlatimi', '40-second topic talk'),
          detail: _copy('Bir deneyimini zaman, yer ve detayla anlat.',
              'Describe an experience with time, place, and detail.'),
          durationLabel: '5 min',
          icon: Icons.timer_outlined,
        ),
        _DailyMission(
          id: 'exam-linkers',
          title: _copy('Baglayici calismasi', 'Linking words drill'),
          detail: _copy('Because, however, therefore ile 3 cümle kur.',
              'Build 3 sentences with because, however, and therefore.'),
          durationLabel: '4 min',
          icon: Icons.link_outlined,
        ),
      ];
    }

    if (goal == 'travel') {
      return [
        _DailyMission(
          id: 'travel-checkin',
          title: _copy('Otel check-in provasi', 'Hotel check-in practice'),
          detail: _copy('Rezervasyon, pasaport ve oda istegini anlat.',
              'Explain your booking, passport, and room request.'),
          durationLabel: '5 min',
          icon: Icons.hotel_outlined,
        ),
        _DailyMission(
          id: 'travel-directions',
          title: _copy('Yol tarifi al', 'Ask for directions'),
          detail: _copy('Metro, durak ve transfer cümleleri kur.',
              'Practice metro, stop, and transfer questions.'),
          durationLabel: '4 min',
          icon: Icons.map_outlined,
        ),
        _DailyMission(
          id: 'travel-emergency',
          title: _copy('Acil durum cümleleri', 'Emergency sentences'),
          detail: _copy('Doktor, polis ve kayip esya cumleleri tekrar et.',
              'Repeat doctor, police, and lost-item phrases.'),
          durationLabel: '4 min',
          icon: Icons.local_hospital_outlined,
        ),
      ];
    }

    return [
      _DailyMission(
        id: 'speaking-shadow',
        title: _copy('30 saniyelik tanisma', '30-second self-introduction'),
        detail: _copy('Adini, hedefini ve neden İngilizce istedigini anlat.',
            'Say your name, goal, and why you want English.'),
        durationLabel: '5 min',
        icon: Icons.person_outline_rounded,
      ),
      _DailyMission(
        id: 'speaking-vocab',
        title: _copy('Gunluk 6 kelime', 'Daily 6-word boost'),
        detail: _copy('Bugunun kelimeleriyle 3 kisa cumle kur.',
            'Use today\'s words in 3 short sentences.'),
        durationLabel: '4 min',
        icon: Icons.bolt_outlined,
      ),
      _DailyMission(
        id: 'speaking-mini',
        title: _copy('Mini diyalog', 'Mini dialogue'),
        detail: _copy('Bir cafede siparis veya kısa bir sohbet provasi yap.',
            'Practice ordering at a cafe or a short conversation.'),
        durationLabel: '5 min',
        icon: Icons.forum_outlined,
      ),
    ];
  }

  List<_ScenarioSpec> get _scenarios {
    if (_localState.goalId == 'business') {
      return [
        _ScenarioSpec(
          title: _copy('Toplanti acilisi', 'Meeting opener'),
          hook: _copy('Ekibi kisa bir acilisla toplantıya hazirla.',
              'Open a team meeting with a calm intro.'),
          prompt: _copy(
            'Kendini tanit, gundemi soyle ve ilk maddeden bahset.',
            'Introduce yourself, mention the agenda, and move to the first item.',
          ),
          followUp: _copy(
            'Simdi bir gecikme riski ve cozum onerin.',
            'Now explain one delivery risk and your solution.',
          ),
          keywords: const ['agenda', 'deadline', 'team', 'update', 'solution'],
          icon: Icons.meeting_room_outlined,
        ),
        _ScenarioSpec(
          title: _copy('Mulakat', 'Interview'),
          hook: _copy('Ozgecmisinden guclu bir ornek sec.',
              'Pick a strong example from your background.'),
          prompt: _copy(
            'Neden bu role uygun oldugunu 45 saniyede anlat.',
            'Explain why you are a good fit for this role in 45 seconds.',
          ),
          followUp: _copy(
            'Bir basari hikayesi ekle ve sonucu sayiyla netlestir.',
            'Add one success story and quantify the result.',
          ),
          keywords: const ['experience', 'project', 'team', 'result', 'skills'],
          icon: Icons.badge_outlined,
        ),
      ];
    }

    if (_localState.goalId == 'travel') {
      return [
        _ScenarioSpec(
          title: _copy('Havalimani', 'Airport'),
          hook: _copy('Kisa ve net seyahat cumleleri kur.',
              'Use short and clear travel language.'),
          prompt: _copy(
            'Pasaport kontrolunde nereye gittigini ve neden gittigini anlat.',
            'Explain where you are going and why at passport control.',
          ),
          followUp: _copy(
            'Simdi baglantili ucus ve bavul sorunu ekle.',
            'Now add a connecting flight and baggage issue.',
          ),
          keywords: const ['flight', 'passport', 'booking', 'hotel', 'bag'],
          icon: Icons.flight_takeoff_outlined,
        ),
        _ScenarioSpec(
          title: _copy('Cafe ve restoran', 'Cafe and restaurant'),
          hook: _copy('Siparis verirken nazik kaliplar kullan.',
              'Use polite phrases while ordering.'),
          prompt: _copy(
            'Masa iste, siparis ver ve bir degisiklik rica et.',
            'Ask for a table, place an order, and request one change.',
          ),
          followUp: _copy(
            'Simdi hesap ve kart odemesini sor.',
            'Now ask for the bill and card payment.',
          ),
          keywords: const ['table', 'menu', 'order', 'bill', 'please'],
          icon: Icons.restaurant_menu_outlined,
        ),
      ];
    }

    return [
      _ScenarioSpec(
        title: _copy('Kendini tanit', 'Introduce yourself'),
        hook: _copy('Ilk izlenim burada olusur.',
            'This is where first impressions start.'),
        prompt: _copy(
          'Adini, ne yaptigini ve neden İngilizce calistigini anlat.',
          'Say your name, what you do, and why you are learning English.',
        ),
        followUp: _copy(
          'Simdi hedefini ve ne kadar sure ayirabildigini ekle.',
          'Now add your goal and how much time you can study each week.',
        ),
        keywords: const ['name', 'work', 'study', 'goal', 'english'],
        icon: Icons.person_outline_rounded,
      ),
      _ScenarioSpec(
        title: _copy('Gunluk sohbet', 'Daily conversation'),
        hook: _copy('Kisa cevap degil, akici cevap hedefle.',
            'Aim for flowing answers, not one-liners.'),
        prompt: _copy(
          'Bos zamaninda neler yaptigini ve neden sevdigini anlat.',
          'Describe what you do in your free time and why you enjoy it.',
        ),
        followUp: _copy(
          'Bir arkadasina bunu neden onerirdin?',
          'Why would you recommend it to a friend?',
        ),
        keywords: const ['weekend', 'like', 'because', 'usually', 'friends'],
        icon: Icons.favorite_border_rounded,
      ),
    ];
  }

  List<String> get _completedMissionIdsToday =>
      _localState.completedMissionIdsByDate[_todayKey] ?? const <String>[];

  int get _weeklyCompletedDays {
    final now = DateTime.now();
    return _localState.activeDates.where((value) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return false;
      return now.difference(parsed).inDays <= 6;
    }).length;
  }

  int get _currentStreak {
    final active = _localState.activeDates
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    final today = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 365; i++) {
      final target = DateTime(today.year, today.month, today.day - i);
      if (active.contains(target)) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _persistState() async {
    await _repository.saveLocalState(_localState);
  }

  Future<void> _updateState(SpeakCoachLocalState state) async {
    setState(() {
      _localState = state;
    });
    await _persistState();
  }

  Future<void> _updateGoal(String goalId) async {
    await _updateState(_localState.copyWith(goalId: goalId));
    _activeScenarioIndex = 0;
    _assessmentReport = null;
    _assessmentTranscript = '';
    _resetPracticeConversation();
    await _refreshMatches();
  }

  Future<void> _toggleMission(_DailyMission mission) async {
    final completed = _completedMissionIdsToday.toSet();
    if (completed.contains(mission.id)) {
      completed.remove(mission.id);
    } else {
      completed.add(mission.id);
    }

    final updatedMissions = Map<String, List<String>>.from(
      _localState.completedMissionIdsByDate,
    );
    if (completed.isEmpty) {
      updatedMissions.remove(_todayKey);
    } else {
      updatedMissions[_todayKey] = completed.toList()..sort();
    }

    final updatedDates = _localState.activeDates.toSet();
    if (completed.isEmpty) {
      updatedDates.remove(_todayKey);
    } else {
      updatedDates.add(_todayKey);
    }

    await _updateState(
      _localState.copyWith(
        activeDates: updatedDates.toList()..sort(),
        completedMissionIdsByDate: updatedMissions,
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _startAssessment() async {
    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _speechHint ??
                _copy('Ses tanima hazir degil.', 'Speech is not ready.'),
          ),
        ),
      );
      return;
    }

    await _speech.cancel();
    _assessmentTimer?.cancel();

    setState(() {
      _assessmentTranscript = '';
      _assessmentReport = null;
      _assessmentElapsedSeconds = 0;
      _assessmentListening = true;
      _soundLevel = 0;
      _speechHint = _copy(
        '90 saniye boyunca rahatca konus. Kisa duraklamalar normal.',
        'Speak naturally for 90 seconds. Short pauses are fine.',
      );
    });

    _assessmentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = _assessmentElapsedSeconds + 1;
      setState(() {
        _assessmentElapsedSeconds = next;
      });
      if (next >= 90) {
        _stopAssessment();
      }
    });

    await _speech.listen(
      onResult: _handleAssessmentResult,
      listenFor: const Duration(seconds: 95),
      pauseFor: const Duration(seconds: 6),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = level;
        });
      },
    );
  }

  void _handleAssessmentResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _assessmentTranscript = result.recognizedWords.trim();
    });
    if (result.finalResult && _assessmentListening) {
      _stopAssessment();
    }
  }

  Future<void> _stopAssessment() async {
    if (!_assessmentListening) return;
    _assessmentTimer?.cancel();
    await _speech.stop();

    final transcript = _assessmentTranscript.trim();
    final report = _buildAssessmentReport(transcript);

    if (!mounted) return;
    setState(() {
      _assessmentListening = false;
      _soundLevel = 0;
      _assessmentReport = report;
    });
  }

  _AssessmentReport _buildAssessmentReport(String transcript) {
    final cleaned = transcript.trim();
    final words = cleaned
        .split(RegExp(r'\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final normalized = words
        .map((item) => item.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final uniqueWords = normalized.toSet().length;
    final connectors = {
      'because',
      'but',
      'so',
      'when',
      'after',
      'before',
      'however',
      'although',
      'therefore',
      'also',
      'then',
      'if',
    };
    final connectorCount =
        normalized.where((item) => connectors.contains(item)).length;
    final sentenceCount = cleaned
        .split(RegExp(r'[.!?]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .length;
    final keywords = _scenarios.expand((item) => item.keywords).toSet();
    final keywordHits =
        normalized.where((item) => keywords.contains(item)).length;
    final wordCount = words.length;
    final rawScore = 20 +
        wordCount +
        (uniqueWords * 2 ~/ 3) +
        (sentenceCount * 7) +
        (connectorCount * 8) +
        (keywordHits * 5);
    final score = math.max(8, math.min(96, rawScore));

    final level = score < 44
        ? 'A2'
        : score < 73
            ? 'B1'
            : 'B2';

    final strengths = <String>[];
    final focusAreas = <String>[];

    if (wordCount >= 35) {
      strengths
          .add(_copy('Akisli cevap verdin', 'You kept the answer flowing'));
    } else {
      focusAreas.add(_copy(
          'Cevaplarini biraz daha uzat', 'Stretch your answers a little more'));
    }

    if (connectorCount >= 2) {
      strengths.add(_copy(
          'Fikirleri birbirine baglayabildin', 'You linked ideas together'));
    } else {
      focusAreas.add(_copy('Because, but, however gibi baglayicilar ekle',
          'Add linkers like because, but, and however'));
    }

    if (uniqueWords >= 24) {
      strengths.add(_copy(
          'Kelime cesidin iyi gidiyor', 'Vocabulary variety is moving well'));
    } else {
      focusAreas.add(_copy('Ayni kelimeleri daha az tekrar et',
          'Repeat the same words less often'));
    }

    if (sentenceCount >= 3) {
      strengths.add(_copy('Cumle yapin tek kelimelik kalmadi',
          'Your answer moved beyond one-liners'));
    } else {
      focusAreas.add(_copy(
          'Ornek verip cevabi gelistir', 'Develop the answer with an example'));
    }

    if (strengths.isEmpty) {
      strengths.add(_copy('Temel cevap kurulumun var',
          'You already have a usable speaking base'));
    }
    if (focusAreas.isEmpty) {
      focusAreas.add(_copy('Bir ust seviyeye gecmek icin daha fazla detay ekle',
          'Add more detail to reach the next level'));
    }

    final coachNote = switch (_localState.goalId) {
      'business' => _copy(
          'Is Ingilizcesi icin bir sonraki adim; daha net sonuc cümleleri ve toplanti dili.',
          'For business English, the next step is clearer outcome language and meeting phrasing.',
        ),
      'travel' => _copy(
          'Seyahat odaginda net istek ve soru cümlelerini hizlandir.',
          'For travel, sharpen clear requests and question forms.',
        ),
      _ => _copy(
          'Gunluk konusmada bir ust basamak icin daha uzun cevap ve baglayici kullanimi yeterli.',
          'For daily speaking, longer answers and more linking words are enough for the next step.',
        ),
    };

    return _AssessmentReport(
      level: level,
      score: score,
      wordCount: wordCount,
      sentenceCount: sentenceCount,
      strengths: strengths,
      focusAreas: focusAreas,
      transcript: cleaned,
      coachNote: coachNote,
    );
  }

  Future<void> _togglePracticeDictation() async {
    if (_practiceListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _practiceListening = false);
      return;
    }

    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) return;

    setState(() => _practiceListening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        _practiceController.text = result.recognizedWords;
        _practiceController.selection = TextSelection.fromPosition(
          TextPosition(offset: _practiceController.text.length),
        );
        if (result.finalResult && _practiceListening) {
          setState(() => _practiceListening = false);
        }
      },
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 4),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _resetPracticeConversation() {
    if (_scenarios.isEmpty) {
      _practiceMessages = const [];
      return;
    }
    final safeIndex = _activeScenarioIndex.clamp(0, _scenarios.length - 1);
    final scenario = _scenarios[safeIndex];
    _practiceMessages = [
      _PracticeMessage(
        role: _PracticeRole.coach,
        text: scenario.prompt,
        chips: [scenario.hook],
      ),
    ];
    if (mounted) {
      setState(() {});
    }
  }

  void _changeScenario(int index) {
    setState(() {
      _activeScenarioIndex = index;
    });
    _resetPracticeConversation();
  }

  void _submitPractice() {
    final value = _practiceController.text.trim();
    if (value.isEmpty) return;

    final scenario = _scenarios[_activeScenarioIndex];
    final feedback = _evaluatePractice(value, scenario);
    setState(() {
      _practiceMessages = [
        ..._practiceMessages,
        _PracticeMessage(role: _PracticeRole.user, text: value),
        _PracticeMessage(
          role: _PracticeRole.coach,
          text: feedback.reply,
          chips: feedback.tips,
        ),
      ];
      _practiceController.clear();
    });
  }

  _PracticeFeedback _evaluatePractice(String response, _ScenarioSpec scenario) {
    final normalized = response
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final keywordHits =
        normalized.where((item) => scenario.keywords.contains(item)).length;
    final wordCount = normalized.length;
    final hasReasoning = normalized.contains('because') ||
        normalized.contains('so') ||
        normalized.contains('however');

    final tips = <String>[];
    if (wordCount >= 18) {
      tips.add(_copy('Uzun cevap', 'Longer answer'));
    } else {
      tips.add(_copy('1 cumle daha ekle', 'Add one more sentence'));
    }
    if (keywordHits >= 2) {
      tips.add(_copy('Konu uyumu iyi', 'Good topic coverage'));
    } else {
      tips.add(_copy('Prompta daha yakin kal', 'Stay closer to the prompt'));
    }
    if (hasReasoning) {
      tips.add(_copy('Baglayici kullandin', 'You used linkers'));
    } else {
      tips.add(_copy('Because/so ekle', 'Add because/so'));
    }

    final reply = _copy(
      'Guclu taraf: ${tips.first}. Simdi bir tur daha yap ve sunu da ekle: ${scenario.followUp}',
      'Strong point: ${tips.first}. Do one more round and add this: ${scenario.followUp}',
    );

    return _PracticeFeedback(reply: reply, tips: tips);
  }

  Future<void> _refreshMatches() async {
    final bootstrap = _bootstrap;
    if (bootstrap == null) return;
    if (bootstrap.instructors.isEmpty) {
      setState(() {
        _matches = const [];
        _availabilityById = const {};
      });
      return;
    }

    setState(() => _loadingMatches = true);

    final scored = bootstrap.instructors.map((instructor) {
      var score = instructor.avgRating * 18;
      score += math.min(instructor.courseCount.toDouble(), 24);
      final reasons = <String>[];
      final tags = instructor.tags.map((item) => item.toLowerCase()).toList();
      final bio =
          '${instructor.jobTitle} ${instructor.shortBio} ${instructor.bio}'
              .toLowerCase();

      bool matchesAny(List<String> terms) {
        return tags.any((tag) => terms.any((term) => tag.contains(term))) ||
            terms.any((term) => bio.contains(term));
      }

      switch (_localState.goalId) {
        case 'business':
          if (matchesAny(['business', 'meeting'])) {
            score += 22;
            reasons.add(_copy('Is odagi', 'Business focus'));
          }
          break;
        case 'ielts':
          if (matchesAny(['ielts', 'toefl'])) {
            score += 22;
            reasons.add(_copy('Sinav deneyimi', 'Exam experience'));
          }
          break;
        case 'travel':
          if (matchesAny(['speaking', 'conversation', 'travel'])) {
            score += 20;
            reasons.add(_copy('Konusma pratiği', 'Speaking practice'));
          }
          break;
        default:
          if (matchesAny(['speaking', 'conversation'])) {
            score += 22;
            reasons.add(_copy('Speaking odagi', 'Speaking focus'));
          }
      }

      if (_localState.accentId == 'turkish' && matchesAny(['turkish'])) {
        score += 16;
        reasons.add(_copy('Turk egitmen tercihi', 'Turkish tutor preference'));
      }
      if (_localState.accentId == 'foreign' && !matchesAny(['turkish'])) {
        score += 16;
        reasons
            .add(_copy('Yabanci egitmen tercihi', 'Foreign tutor preference'));
      }

      if (_localState.budgetId == 'premium' && instructor.avgRating >= 4.6) {
        score += 10;
        reasons.add(_copy('Yuksek puan', 'High rating'));
      }
      if (_localState.budgetId == 'starter' && instructor.avgRating >= 4.2) {
        score += 6;
        reasons.add(_copy('Butce dengesi', 'Budget fit'));
      }

      return _TutorMatchViewModel(
        instructor: instructor,
        matchScore: score,
        reasons:
            reasons.isEmpty ? [_copy('Genel uyum', 'Overall fit')] : reasons,
      );
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    final topMatches = scored.take(3).map((item) {
      final normalized = math.min(98, math.max(62, item.matchScore.round()));
      return item.copyWith(matchPercent: normalized);
    }).toList(growable: false);

    final availabilityResults = await Future.wait(
      topMatches.map(
        (item) => _repository.fetchAvailability(item.instructor.id),
      ),
    );

    final availabilityMap = <int, InstructorAvailabilitySnapshot>{};
    for (var i = 0; i < topMatches.length; i++) {
      final availability = availabilityResults[i];
      if (availability != null) {
        availabilityMap[topMatches[i].instructor.id] = availability;
      }
    }

    if (!mounted) return;
    setState(() {
      _matches = topMatches;
      _availabilityById = availabilityMap;
      _loadingMatches = false;
    });
  }

  Future<void> _openWhatsAppLead({String? contextLabel}) async {
    final phone = (_bootstrap?.settings?.whatsappLeadPhone ?? '')
        .replaceAll(RegExp(r'\D+'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'WhatsApp hatti ayarlanmamis. Iletisim ekranina yonlendiriyorum.',
              'WhatsApp lead line is missing. Opening contact instead.',
            ),
          ),
        ),
      );
      Navigator.pushNamed(context, '/contact');
      return;
    }

    final message = Uri.encodeComponent(
      _copy(
        'Merhaba, uygulamadaki ${contextLabel ?? 'start speaking'} akisindan geldim. Hedefim ${_selectedGoal.title.toLowerCase()}. ${_assessmentReport != null ? 'Su an tahmini seviyem ${_assessmentReport!.level}.' : ''} Ucretsiz deneme dersi ve uygun egitmen eslesmesi icin bilgi alabilir miyim?',
        'Hi, I came from the ${contextLabel ?? 'start speaking'} flow in the app. My goal is ${_selectedGoal.title.toLowerCase()}. ${_assessmentReport != null ? 'My current estimated level is ${_assessmentReport!.level}.' : ''} Can I get details for a free trial lesson and tutor matching?',
      ),
    );

    final url = 'https://wa.me/$phone?text=$message';
    await openContentPreview(
      context,
      title: 'WhatsApp',
      rawUrl: url,
      browserActionLabel: AppStrings.t('Open Externally'),
    );
  }

  String _availabilityLabel(int instructorId) {
    final availability = _availabilityById[instructorId];
    if (availability == null) {
      return _copy('Takvim profilde gorunur', 'Schedule is visible in profile');
    }

    if (availability.todayAvailableCount > 0) {
      return _copy(
        'Bugun ${availability.todayAvailableCount} bos slot',
        '${availability.todayAvailableCount} open slot(s) today',
      );
    }

    final nextDate = availability.nextAvailableDate;
    if (nextDate == null || nextDate.trim().isEmpty) {
      return _copy('Yeni saatler bekleniyor', 'Waiting for new times');
    }

    final parsed = DateTime.tryParse(nextDate);
    final dateLabel = parsed == null
        ? nextDate
        : DateFormat(
            'dd MMM',
            AppStrings.code == 'tr' ? 'tr_TR' : 'en_US',
          ).format(parsed);
    return _copy('Ilk uygun saat: $dateLabel', 'Next opening: $dateLabel');
  }

  List<_TestimonialCardData> _testimonialCards() {
    final remote = _bootstrap?.home?.testimonials ?? const <TestimonialItem>[];
    if (remote.isNotEmpty) {
      return remote
          .take(3)
          .map(
            (item) => _TestimonialCardData(
              name: item.name.isNotEmpty ? item.name : 'LinguFranca Student',
              title: item.designation.isNotEmpty
                  ? item.designation
                  : _copy('Ogrenci', 'Student'),
              comment: item.comment,
              rating: item.rating > 0 ? item.rating.round() : 5,
            ),
          )
          .toList(growable: false);
    }

    return [
      _TestimonialCardData(
        name: 'Derya T.',
        title: _copy('Urun Yoneticisi', 'Product Manager'),
        comment: _copy(
          'Speaking korkum vardi. Once demo challenge yaptim, sonra bana uygun egitmenle 3 haftada daha rahat konusmaya basladim.',
          'I had speaking anxiety. I started with the demo challenge and felt more comfortable within 3 weeks with the matched tutor.',
        ),
        rating: 5,
      ),
      _TestimonialCardData(
        name: 'Onur K.',
        title: _copy('Yazilim Muhendisi', 'Software Engineer'),
        comment: _copy(
          'Is Ingilizcesi ve toplanti dili icin net, olculebilir bir akis kurdu.',
          'It created a clear, measurable path for business English and meetings.',
        ),
        rating: 5,
      ),
      _TestimonialCardData(
        name: 'Mina S.',
        title: 'IELTS',
        comment: _copy(
          'Gunluk 5 dakikalik gorevler duzeni sagladi. Bu sayede speaking tarafim hizlandi.',
          'The daily 5-minute missions gave me rhythm. My speaking improved much faster.',
        ),
        rating: 5,
      ),
    ];
  }

  String _counterValue(String key, String fallback) {
    final raw = _bootstrap?.home?.counter?.global[key];
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  int get _estimatedCompletedLessons {
    final total = _bootstrap?.instructors.fold<int>(
          0,
          (sum, item) => sum + item.courseCount,
        ) ??
        0;
    return total > 0 ? total : 12000;
  }

  List<_MiniContentItem> get _miniContent => [
        _MiniContentItem(
          title: _copy('Ilk konusma dersi', 'First conversation lesson'),
          subtitle: _copy('Cekingenligi kir', 'Break the hesitation'),
          description: _copy(
            'Kendini tanitma, soru sorma ve mini sohbet akisi.',
            'Self-introduction, asking questions, and a mini conversation flow.',
          ),
          accent: const Color(0xFF0B466F),
          icon: Icons.chat_bubble_outline_rounded,
        ),
        _MiniContentItem(
          title: _copy('Demo speaking challenge', 'Demo speaking challenge'),
          subtitle: _copy('90 saniyelik hizli prova', 'A fast 90-second run'),
          description: _copy(
            'Mikrofonu ac, promptu sesli cevapla ve hemen geri bildirim al.',
            'Open the mic, answer the prompt aloud, and get instant guidance.',
          ),
          accent: const Color(0xFF0F4C81),
          icon: Icons.graphic_eq_rounded,
        ),
        _MiniContentItem(
          title: _copy('Ornek materyal', 'Sample material'),
          subtitle: _copy('1 haftalik mini plan', '1-week mini plan'),
          description: _copy(
            'Kelime, speaking ve ders sonrasi tekrar akisini gor.',
            'See the vocabulary, speaking, and review flow for one week.',
          ),
          accent: const Color(0xFF1D4ED8),
          icon: Icons.description_outlined,
        ),
      ];

  void _openMiniContent(_MiniContentItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bullets = item.title.contains('materyal') ||
                item.title.contains('material')
            ? [
                _copy('Pazartesi speaking, carsamba kelime, cuma tekrar',
                    'Speaking Monday, vocabulary Wednesday, review Friday'),
                _copy('Her ders sonrasi 3 satir ozet',
                    '3-line recap after each lesson'),
                _copy(
                    '1 adet WhatsApp odev akisi', 'One WhatsApp homework flow'),
              ]
            : [
                _copy('Tanisma ve ilk cevap kaliplari',
                    'Introductions and first-response patterns'),
                _copy('Gereksiz duraksamayi azaltan mini tekrarlar',
                    'Mini drills that reduce hesitation'),
                _copy('Egitmene gecis icin deneme dersi baglantisi',
                    'A direct bridge to trial lesson booking'),
              ];

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 48),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E2EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ...bullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(bullet)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _scrollTo(_assessmentKey);
                        },
                        child: Text(
                            _copy('Demo challenge ac', 'Open demo challenge')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openWhatsAppLead(contextLabel: item.title);
                        },
                        child:
                            Text(_copy('Deneme dersi al', 'Book free trial')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<SpeakCoachBootstrap>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _bootstrap == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final testimonials = _testimonialCards();

          return ListView(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            children: [
              const PublicHeader(),
              _HeroPoster(
                compact: compact,
                goal: _selectedGoal,
                assessmentReport: _assessmentReport,
                onStartAssessment: () => _scrollTo(_assessmentKey),
                onOpenTrial: () => _openWhatsAppLead(contextLabel: 'hero'),
                onOpenTutorMatch: () => _scrollTo(_matchesKey),
              ),
              _JumpRail(
                compact: compact,
                items: [
                  _JumpRailItem(
                    label: _copy('Konusma testi', 'Speaking test'),
                    onTap: () => _scrollTo(_assessmentKey),
                  ),
                  _JumpRailItem(
                    label: _copy('Gunluk gorev', 'Daily mission'),
                    onTap: () => _scrollTo(_missionsKey),
                  ),
                  _JumpRailItem(
                    label: _copy('AI prova', 'AI rehearsal'),
                    onTap: () => _scrollTo(_practiceKey),
                  ),
                  _JumpRailItem(
                    label: _copy('Tutor match', 'Tutor match'),
                    onTap: () => _scrollTo(_matchesKey),
                  ),
                  _JumpRailItem(
                    label: _copy('Mini icerikler', 'Mini content'),
                    onTap: () => _scrollTo(_libraryKey),
                  ),
                ],
              ),
              _SectionWrap(
                compact: compact,
                child: _ChoiceBoard(
                  title: _copy(
                    'Hedef bazli onboarding',
                    'Goal-based onboarding',
                  ),
                  description: _copy(
                    'Uygulamanin akisini secimine gore kisilestir. Bu secimler hem icerigi hem egitmen eslesmesini degistirir.',
                    'Personalize the flow based on your goal. These choices shape both content and tutor matching.',
                  ),
                  groups: [
                    _ChoiceGroupData(
                      title: _copy('Ana hedef', 'Main goal'),
                      choices: _goalChoices,
                      selectedId: _localState.goalId,
                      onSelect: (id) => _updateGoal(id),
                    ),
                    _ChoiceGroupData(
                      title: _copy('Egitmen tipi', 'Tutor style'),
                      choices: _accentChoices,
                      selectedId: _localState.accentId,
                      onSelect: (id) async {
                        await _updateState(_localState.copyWith(accentId: id));
                        await _refreshMatches();
                      },
                    ),
                    _ChoiceGroupData(
                      title: _copy('Butce seviyesi', 'Budget level'),
                      choices: _budgetChoices,
                      selectedId: _localState.budgetId,
                      onSelect: (id) async {
                        await _updateState(_localState.copyWith(budgetId: id));
                        await _refreshMatches();
                      },
                    ),
                    _ChoiceGroupData(
                      title: _copy('Uygun saat', 'Best schedule'),
                      choices: _scheduleChoices,
                      selectedId: _localState.scheduleId,
                      onSelect: (id) async {
                        await _updateState(
                            _localState.copyWith(scheduleId: id));
                        await _refreshMatches();
                      },
                    ),
                  ],
                  footer: Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          value: '${_localState.weeklyTarget}',
                          label: _copy('Haftalik hedef', 'Weekly target'),
                          helper: _copy('aktif gun', 'active days'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          value: _selectedSchedule.title,
                          label: _copy('Senin ritmin', 'Your rhythm'),
                          helper: _selectedSchedule.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SectionWrap(
                key: _assessmentKey,
                compact: compact,
                child: _AssessmentPanel(
                  goal: _selectedGoal,
                  compact: compact,
                  isListening: _assessmentListening,
                  elapsedSeconds: _assessmentElapsedSeconds,
                  soundLevel: _soundLevel,
                  transcript: _assessmentTranscript,
                  report: _assessmentReport,
                  speechHint: _speechHint,
                  onStart: _startAssessment,
                  onStop: _stopAssessment,
                  onOpenTutorMatch: () => _scrollTo(_matchesKey),
                ),
              ),
              _SectionWrap(
                key: _missionsKey,
                compact: compact,
                child: _MissionPanel(
                  missions: _missions,
                  completedMissionIds: _completedMissionIdsToday,
                  currentStreak: _currentStreak,
                  weeklyCompletedDays: _weeklyCompletedDays,
                  weeklyTarget: _localState.weeklyTarget,
                  onChangeTarget: (target) =>
                      _updateState(_localState.copyWith(weeklyTarget: target)),
                  onToggle: _toggleMission,
                ),
              ),
              _SectionWrap(
                key: _practiceKey,
                compact: compact,
                child: _PracticeStudio(
                  scenarios: _scenarios,
                  activeScenarioIndex: _activeScenarioIndex,
                  messages: _practiceMessages,
                  controller: _practiceController,
                  isListening: _practiceListening,
                  speechSupported: _speechSupported,
                  onSelectScenario: _changeScenario,
                  onToggleMic: _togglePracticeDictation,
                  onSubmit: _submitPractice,
                ),
              ),
              _SectionWrap(
                key: _matchesKey,
                compact: compact,
                child: _TutorMatchPanel(
                  loading: _loadingMatches,
                  goalTitle: _selectedGoal.title,
                  accentTitle: _selectedAccent.title,
                  matches: _matches,
                  availabilityLabelBuilder: _availabilityLabel,
                  onOpenAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentInstructorsScreen(standalone: true),
                      ),
                    );
                  },
                  onOpenMatch: (match) {
                    final data = InstructorCardData(
                      id: match.instructor.id,
                      name: match.instructor.name,
                      role: match.instructor.jobTitle.isNotEmpty
                          ? match.instructor.jobTitle
                          : _copy('Egitmen', 'Instructor'),
                      tags: match.instructor.tags,
                      about: match.instructor.shortBio.isNotEmpty
                          ? match.instructor.shortBio
                          : match.instructor.bio,
                      rating: match.instructor.avgRating,
                      imageUrl: match.instructor.imageUrl,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentInstructorDetailScreen(data: data),
                      ),
                    );
                  },
                ),
              ),
              _SectionWrap(
                key: _libraryKey,
                compact: compact,
                child: _MiniLibraryPanel(
                  items: _miniContent,
                  onOpenItem: _openMiniContent,
                  onOpenDemo: () => _scrollTo(_assessmentKey),
                ),
              ),
              _SectionWrap(
                compact: compact,
                child: _SocialProofPanel(
                  studentCount: _counterValue('total_student_count', '+3.000'),
                  instructorCount:
                      _counterValue('total_instructor_count', '+100'),
                  completedLessons: NumberFormat.compact().format(
                    _estimatedCompletedLessons,
                  ),
                  availableTodayCount: _availabilityById.values
                      .where((value) => value.todayAvailableCount > 0)
                      .length,
                  testimonials: testimonials,
                ),
              ),
              _SectionWrap(
                key: _ctaKey,
                compact: compact,
                child: _ConversionPanel(
                  compact: compact,
                  goalTitle: _selectedGoal.title,
                  estimatedLevel: _assessmentReport?.level,
                  onStartTrial: () => _openWhatsAppLead(contextLabel: 'trial'),
                  onOpenWhatsApp: () => _openWhatsAppLead(contextLabel: 'cta'),
                  onTakePlacement: () =>
                      Navigator.pushNamed(context, '/placement-test'),
                ),
              ),
              const SizedBox(height: 12),
              const PublicFooter(),
            ],
          );
        },
      ),
    );
  }
}

class SpeakCoachPromoBanner extends StatelessWidget {
  const SpeakCoachPromoBanner({super.key});

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactPublicLayout(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0A3558),
              Color(0xFF0D5B90),
              Color(0xFF1E3A8A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(compact ? 28 : 32),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandDeep.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            compact ? 18 : 24,
            compact ? 18 : 24,
            compact ? 20 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _copy('YENI MUSTERI AKISI', 'NEW CUSTOMER FLOW'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _copy(
                  '90 saniyelik speaking test ile giris al, en uygun egitmeni hemen goster.',
                  'Use a 90-second speaking test to capture leads and surface the right tutor instantly.',
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _copy(
                  'Onboarding, gunluk gorev, AI prova, tutor match ve WhatsApp donusumu ayni akista.',
                  'Onboarding, daily missions, AI rehearsal, tutor match, and WhatsApp conversion in one flow.',
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/start-speaking'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandDeep,
                    ),
                    child: Text(_copy('Akisi ac', 'Open flow')),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/start-speaking'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    child: Text(_copy('Tutor match gor', 'See tutor match')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPoster extends StatelessWidget {
  const _HeroPoster({
    required this.compact,
    required this.goal,
    required this.assessmentReport,
    required this.onStartAssessment,
    required this.onOpenTrial,
    required this.onOpenTutorMatch,
  });

  final bool compact;
  final _CoachChoice goal;
  final _AssessmentReport? assessmentReport;
  final VoidCallback onStartAssessment;
  final VoidCallback onOpenTrial;
  final VoidCallback onOpenTutorMatch;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06243B), Color(0xFF0D5B90), Color(0xFF133C7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 22,
          compact ? 18 : 28,
          compact ? 16 : 22,
          compact ? 22 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _copy('START SPEAKING', 'START SPEAKING'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _copy(
                'Kurs vitrini degil, direkt musteri ceken konusma akisi.',
                'Not just a course app. A speaking flow built to convert.',
              ),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.03,
                    fontSize: compact ? 30 : 42,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              _copy(
                '90 saniyelik speaking testi, 5 dakikalik gorevler, akilli prova, tutor match ve hizli trial CTA ayni ekranda. Hedefin su an: ${goal.title.toLowerCase()}.',
                'A 90-second speaking test, 5-minute missions, smart rehearsal, tutor match, and a direct trial CTA in one flow. Your current goal: ${goal.title.toLowerCase()}.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeroTag(
                  text:
                      _copy('Kayıtsiz speaking test', 'No-login speaking test'),
                ),
                _HeroTag(
                  text: _copy('Gunluk 5 dakika', 'Daily 5 minutes'),
                ),
                _HeroTag(
                  text:
                      _copy('Tutor match + WhatsApp', 'Tutor match + WhatsApp'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onStartAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandDeep,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.mic_none_rounded),
                  label: Text(
                    _copy('90 sn testi baslat', 'Start 90s test'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenTutorMatch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                  ),
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text(_copy('Tutor match gor', 'See tutor match')),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenTrial,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text(_copy('Ucretsiz trial al', 'Book free trial')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            compact
                ? Column(
                    children: [
                      _GlassStat(
                        value: assessmentReport?.level ?? 'A2 / B1',
                        label: _copy(
                          'Tahmini seviye cikisi',
                          'Estimated level output',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassStat(
                        value: '5 min',
                        label: _copy(
                          'Gunluk gorev suresi',
                          'Daily mission length',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassStat(
                        value: '3',
                        label: _copy(
                          'Aninda tutor onerisi',
                          'Instant tutor matches',
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _GlassStat(
                          value: assessmentReport?.level ?? 'A2 / B1',
                          label: _copy(
                            'Tahmini seviye cikisi',
                            'Estimated level output',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassStat(
                          value: '5 min',
                          label: _copy(
                            'Gunluk gorev suresi',
                            'Daily mission length',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassStat(
                          value: '3',
                          label: _copy(
                            'Aninda tutor onerisi',
                            'Instant tutor matches',
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _JumpRail extends StatelessWidget {
  const _JumpRail({required this.compact, required this.items});

  final bool compact;
  final List<_JumpRailItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final item = items[index];
          return ActionChip(
            onPressed: item.onTap,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFD9E4F0)),
            label: Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _SectionWrap extends StatelessWidget {
  const _SectionWrap({
    super.key,
    required this.compact,
    required this.child,
  });

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        8,
        compact ? 14 : 18,
        8,
      ),
      child: child,
    );
  }
}

class _ChoiceBoard extends StatelessWidget {
  const _ChoiceBoard({
    required this.title,
    required this.description,
    required this.groups,
    required this.footer,
  });

  final String title;
  final String description;
  final List<_ChoiceGroupData> groups;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ...groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _ChoiceGroup(group: group),
            ),
          ),
          const SizedBox(height: 6),
          footer,
        ],
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.group});

  final _ChoiceGroupData group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: group.choices.map((choice) {
            final selected = choice.id == group.selectedId;
            return InkWell(
              onTap: () => group.onSelect(choice.id),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFF0F7FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? AppColors.brandDeep
                        : const Color(0xFFE2E8F0),
                    width: selected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.brandDeep
                            : AppColors.brand.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        choice.icon,
                        color: selected ? Colors.white : AppColors.brandDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choice.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            choice.subtitle,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AssessmentPanel extends StatelessWidget {
  const _AssessmentPanel({
    required this.goal,
    required this.compact,
    required this.isListening,
    required this.elapsedSeconds,
    required this.soundLevel,
    required this.transcript,
    required this.report,
    required this.speechHint,
    required this.onStart,
    required this.onStop,
    required this.onOpenTutorMatch,
  });

  final _CoachChoice goal;
  final bool compact;
  final bool isListening;
  final int elapsedSeconds;
  final double soundLevel;
  final String transcript;
  final _AssessmentReport? report;
  final String? speechHint;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onOpenTutorMatch;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    final progress = (elapsedSeconds / 90).clamp(0, 1).toDouble();
    final promptText = goal.id == 'business'
        ? _copy(
            'Kendini tanit, is rolunu anlat ve bir toplanti hedefi soyle.',
            'Introduce yourself, explain your role, and mention one meeting goal.',
          )
        : _copy(
            'Adini, ne yaptigini ve neden İngilizce ogrenmek istedigini anlat.',
            'Say your name, what you do, and why you want to learn English.',
          );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF082C46),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _copy(
                'Kayitsiz 90 saniyelik konusma testi',
                'No-login 90-second speaking test',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _copy(
                'Mikrofonu ac, promptu cevapla ve sonunda tahmini seviye, zayif alan ve uygun egitmen rotasi gor.',
                'Turn on the mic, answer the prompt, and get an estimated level, weak areas, and a tutor path at the end.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AssessmentPrimaryCard(
                        progress: progress,
                        elapsedSeconds: elapsedSeconds,
                        isListening: isListening,
                        report: report,
                        promptText: promptText,
                        transcript: transcript,
                        soundLevel: soundLevel,
                        speechHint: speechHint,
                        onStart: onStart,
                        onStop: onStop,
                      ),
                      const SizedBox(height: 16),
                      report == null
                          ? _EmptyResultCard(
                              title: _copy(
                                'Sonuc burada cikacak',
                                'Your result will appear here',
                              ),
                              description: _copy(
                                'Hedeflenen cikti: A2 / B1 / B2 tahmini, guclu taraflar ve hangi egitmen tipine yonelmen gerektigi.',
                                'Expected output: an A2 / B1 / B2 estimate, strengths, and the tutor direction you should take.',
                              ),
                            )
                          : _AssessmentResultCard(
                              report: report!,
                              onOpenTutorMatch: onOpenTutorMatch,
                            ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _AssessmentPrimaryCard(
                          progress: progress,
                          elapsedSeconds: elapsedSeconds,
                          isListening: isListening,
                          report: report,
                          promptText: promptText,
                          transcript: transcript,
                          soundLevel: soundLevel,
                          speechHint: speechHint,
                          onStart: onStart,
                          onStop: onStop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: report == null
                            ? _EmptyResultCard(
                                title: _copy(
                                  'Sonuc burada cikacak',
                                  'Your result will appear here',
                                ),
                                description: _copy(
                                  'Hedeflenen cikti: A2 / B1 / B2 tahmini, guclu taraflar ve hangi egitmen tipine yonelmen gerektigi.',
                                  'Expected output: an A2 / B1 / B2 estimate, strengths, and the tutor direction you should take.',
                                ),
                              )
                            : _AssessmentResultCard(
                                report: report!,
                                onOpenTutorMatch: onOpenTutorMatch,
                              ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentPrimaryCard extends StatelessWidget {
  const _AssessmentPrimaryCard({
    required this.progress,
    required this.elapsedSeconds,
    required this.isListening,
    required this.report,
    required this.promptText,
    required this.transcript,
    required this.soundLevel,
    required this.speechHint,
    required this.onStart,
    required this.onStop,
  });

  final double progress;
  final int elapsedSeconds;
  final bool isListening;
  final _AssessmentReport? report;
  final String promptText;
  final String transcript;
  final double soundLevel;
  final String? speechHint;
  final VoidCallback onStart;
  final VoidCallback onStop;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AssessmentDial(
                progress: progress,
                elapsedSeconds: elapsedSeconds,
                active: isListening,
                levelText: report?.level,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy('Prompt', 'Prompt'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promptText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              transcript.isEmpty
                  ? _copy(
                      'Konusman burada canli akacak.',
                      'Your transcript will appear here live.',
                    )
                  : transcript,
              style: TextStyle(
                color: transcript.isEmpty ? Colors.white54 : Colors.white,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isListening ? onStop : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandDeep,
                  ),
                  icon: Icon(
                    isListening
                        ? Icons.stop_circle_outlined
                        : Icons.mic_none_rounded,
                  ),
                  label: Text(
                    isListening
                        ? _copy('Testi bitir', 'Finish test')
                        : _copy('Mikrofonu ac', 'Open microphone'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  soundLevel == 0
                      ? _copy('Hazir', 'Ready')
                      : _copy(
                          'Ses ${soundLevel.toStringAsFixed(0)}',
                          'Voice ${soundLevel.toStringAsFixed(0)}',
                        ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if ((speechHint ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              speechHint!,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionPanel extends StatelessWidget {
  const _MissionPanel({
    required this.missions,
    required this.completedMissionIds,
    required this.currentStreak,
    required this.weeklyCompletedDays,
    required this.weeklyTarget,
    required this.onChangeTarget,
    required this.onToggle,
  });

  final List<_DailyMission> missions;
  final List<String> completedMissionIds;
  final int currentStreak;
  final int weeklyCompletedDays;
  final int weeklyTarget;
  final ValueChanged<int> onChangeTarget;
  final ValueChanged<_DailyMission> onToggle;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy('Gunluk 5 dakikalik gorevler', 'Daily 5-minute missions'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _copy(
              'Speaking, kelime ve mini diyalog gorevlerini isaretle. Streak ve haftalik hedef burada birikir.',
              'Check off speaking, vocabulary, and mini dialogue tasks. Your streak and weekly target accumulate here.',
            ),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                value: '$currentStreak',
                label: _copy('Streak', 'Streak'),
                helper: _copy('aktif gun', 'active day streak'),
              ),
              _MetricTile(
                value: '$weeklyCompletedDays / $weeklyTarget',
                label: _copy('Haftalik hedef', 'Weekly target'),
                helper: _copy('tamamlanan gun', 'completed day'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [3, 4, 5, 6].map((target) {
              final selected = weeklyTarget == target;
              return ChoiceChip(
                selected: selected,
                label: Text(
                  _copy('$target gun/hedef', '$target day goal'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onSelected: (_) => onChangeTarget(target),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ...missions.map((mission) {
            final done = completedMissionIds.contains(mission.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onToggle(mission),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: done ? const Color(0xFFE9F8EE) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: done
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDCE6F1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: done
                            ? const Color(0xFF16A34A)
                            : AppColors.brandDeep.withValues(alpha: 0.10),
                        child: Icon(
                          done ? Icons.check : mission.icon,
                          color: done ? Colors.white : AppColors.brandDeep,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mission.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mission.detail,
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mission.durationLabel,
                        style: const TextStyle(
                          color: AppColors.brandDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PracticeStudio extends StatelessWidget {
  const _PracticeStudio({
    required this.scenarios,
    required this.activeScenarioIndex,
    required this.messages,
    required this.controller,
    required this.isListening,
    required this.speechSupported,
    required this.onSelectScenario,
    required this.onToggleMic,
    required this.onSubmit,
  });

  final List<_ScenarioSpec> scenarios;
  final int activeScenarioIndex;
  final List<_PracticeMessage> messages;
  final TextEditingController controller;
  final bool isListening;
  final bool speechSupported;
  final ValueChanged<int> onSelectScenario;
  final VoidCallback onToggleMic;
  final VoidCallback onSubmit;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy('AI konusma provasi', 'AI speaking rehearsal'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _copy(
              'Mulakat, toplanti, tanisma veya seyahat gibi senaryolarla prova yap. Mikrofonu acabilir ya da yazarak cevap verebilirsin.',
              'Rehearse scenarios like interviews, meetings, introductions, or travel. Use the mic or type your answer.',
            ),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(scenarios.length, (index) {
              final scenario = scenarios[index];
              final selected = index == activeScenarioIndex;
              return ChoiceChip(
                selected: selected,
                label: Text(
                  scenario.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                avatar: Icon(
                  scenario.icon,
                  size: 18,
                  color: selected ? AppColors.brandDeep : AppColors.muted,
                ),
                onSelected: (_) => onSelectScenario(index),
              );
            }),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE6F1)),
            ),
            child: Column(
              children: [
                ...messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PracticeBubble(message: message),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE6F1)),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _copy(
                            'Cevabini yaz veya mikrofonu acarak dikte et.',
                            'Write your answer or use the mic to dictate it.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (speechSupported)
                            OutlinedButton.icon(
                              onPressed: onToggleMic,
                              icon: Icon(
                                isListening
                                    ? Icons.stop_circle_outlined
                                    : Icons.mic_none_rounded,
                              ),
                              label: Text(
                                isListening
                                    ? _copy('Durdur', 'Stop')
                                    : _copy('Mikrofon', 'Microphone'),
                              ),
                            ),
                          if (speechSupported) const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSubmit,
                              icon: const Icon(Icons.send_rounded),
                              label: Text(_copy(
                                  'Gonder ve yorum al', 'Send for feedback')),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _TutorMatchPanel extends StatelessWidget {
  const _TutorMatchPanel({
    required this.loading,
    required this.goalTitle,
    required this.accentTitle,
    required this.matches,
    required this.availabilityLabelBuilder,
    required this.onOpenAll,
    required this.onOpenMatch,
  });

  final bool loading;
  final String goalTitle;
  final String accentTitle;
  final List<_TutorMatchViewModel> matches;
  final String Function(int instructorId) availabilityLabelBuilder;
  final VoidCallback onOpenAll;
  final ValueChanged<_TutorMatchViewModel> onOpenMatch;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF082C46), Color(0xFF0E5C93)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy('Tutor match ekrani', 'Tutor match'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _copy(
                        'Secimine gore ilk 3 egitmeni on plana cikar. Hedef: $goalTitle, tercih: $accentTitle.',
                        'Surface the top 3 tutors based on your current choices. Goal: $goalTitle, preference: $accentTitle.',
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onOpenAll,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text(_copy('Tum egitmenler', 'All tutors')),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child:
                  Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (matches.isEmpty)
            _EmptyResultCard(
              title: _copy(
                'Egitmen listesi henuz gelmedi',
                'Tutor list is not available yet',
              ),
              description: _copy(
                'Akis yine de hazir. Liste geldigi anda otomatik olarak eslesme gosterecek.',
                'The flow is still ready. As soon as the list loads, matching will appear automatically.',
              ),
              dark: true,
            )
          else
            Column(
              children: matches.map((match) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        _TutorAvatar(
                          name: match.instructor.name,
                          imageUrl: match.instructor.imageUrl,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      match.instructor.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '%${match.matchPercent}',
                                    style: const TextStyle(
                                      color: AppColors.brand,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                match.instructor.jobTitle.isNotEmpty
                                    ? match.instructor.jobTitle
                                    : _copy('Egitmen', 'Instructor'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: match.reasons.map((reason) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      reason,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                availabilityLabelBuilder(match.instructor.id),
                                style: const TextStyle(
                                  color: Color(0xFFBFDBFE),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => onOpenMatch(match),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.brandDeep,
                          ),
                          child: Text(_copy('Profili ac', 'Open profile')),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MiniLibraryPanel extends StatelessWidget {
  const _MiniLibraryPanel({
    required this.items,
    required this.onOpenItem,
    required this.onOpenDemo,
  });

  final List<_MiniContentItem> items;
  final ValueChanged<_MiniContentItem> onOpenItem;
  final VoidCallback onOpenDemo;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy('Ucretsiz mini icerikler', 'Free mini content'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _copy(
              '3 ornek ders, 1 demo challenge ve 1 materyal onizlemesi ile kullanici kayit olmadan deger gorsun.',
              'Give users value before signup with 3 sample lessons, 1 demo challenge, and 1 material preview.',
            ),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onOpenItem(item),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: item.accent.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: AppColors.brandDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onOpenDemo,
              icon: const Icon(Icons.graphic_eq_rounded),
              label: Text(_copy(
                  'Demo challenge alanina git', 'Jump to demo challenge')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProofPanel extends StatelessWidget {
  const _SocialProofPanel({
    required this.studentCount,
    required this.instructorCount,
    required this.completedLessons,
    required this.availableTodayCount,
    required this.testimonials,
  });

  final String studentCount;
  final String instructorCount;
  final String completedLessons;
  final int availableTodayCount;
  final List<_TestimonialCardData> testimonials;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy('Sosyal kanit', 'Social proof'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _copy(
              'Yorumlar, toplam ogrenci tabani, tamamlanan ders deneyimi ve bugun musait egitmen gorunurlugu ayni blokta.',
              'Show reviews, student volume, delivered lesson experience, and today-available tutors together in one block.',
            ),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricTile(
                value: studentCount,
                label: _copy('Ogrenci', 'Students'),
                helper: _copy('aktif taban', 'active base'),
              ),
              _MetricTile(
                value: instructorCount,
                label: _copy('Egitmen', 'Tutors'),
                helper: _copy('secilebilir egitmen', 'bookable tutors'),
              ),
              _MetricTile(
                value: completedLessons,
                label: _copy('Tamamlanan ders', 'Completed lessons'),
                helper: _copy('toplam deneyim', 'delivered experience'),
              ),
              _MetricTile(
                value: '$availableTodayCount',
                label: _copy('Bugun musait', 'Available today'),
                helper: _copy('onerilen egitmen', 'matched tutors'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, index) =>
                  _ReviewCard(review: testimonials[index]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: testimonials.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionPanel extends StatelessWidget {
  const _ConversionPanel({
    required this.compact,
    required this.goalTitle,
    required this.estimatedLevel,
    required this.onStartTrial,
    required this.onOpenWhatsApp,
    required this.onTakePlacement,
  });

  final bool compact;
  final String goalTitle;
  final String? estimatedLevel;
  final VoidCallback onStartTrial;
  final VoidCallback onOpenWhatsApp;
  final VoidCallback onTakePlacement;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E5C93), Color(0xFF0A3558)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy('Hizli donusum', 'Fast conversion'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _copy(
              'Hedef: $goalTitle. ${estimatedLevel != null ? 'Tahmini seviye: $estimatedLevel. ' : ''}Buradan ucretsiz deneme dersi, WhatsApp ve seviye testi tek hareketle acilir.',
              'Goal: $goalTitle. ${estimatedLevel != null ? 'Estimated level: $estimatedLevel. ' : ''}From here, users can open the free trial, WhatsApp, and level test in one move.',
            ),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          compact
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onStartTrial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandDeep,
                        ),
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: Text(
                          _copy(
                            'Ucretsiz deneme dersi al',
                            'Book free trial lesson',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenWhatsApp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(
                          _copy(
                            'WhatsApp ile basla',
                            'Start on WhatsApp',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onTakePlacement,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                        icon: const Icon(Icons.quiz_outlined),
                        label: Text(
                          _copy(
                            'Seviye testine gec',
                            'Open level test',
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onStartTrial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandDeep,
                        ),
                        icon: const Icon(Icons.rocket_launch_outlined),
                        label: Text(
                          _copy(
                            'Ucretsiz deneme dersi al',
                            'Book free trial lesson',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenWhatsApp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(
                          _copy('WhatsApp ile basla', 'Start on WhatsApp'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTakePlacement,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                        ),
                        icon: const Icon(Icons.quiz_outlined),
                        label: Text(
                          _copy('Seviye testine gec', 'Open level test'),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _AssessmentDial extends StatelessWidget {
  const _AssessmentDial({
    required this.progress,
    required this.elapsedSeconds,
    required this.active,
    required this.levelText,
  });

  final double progress;
  final int elapsedSeconds;
  final bool active;
  final String? levelText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: active ? progress : 0,
            strokeWidth: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                active ? '$elapsedSeconds s' : (levelText ?? '90s'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
              Text(
                active ? 'live' : 'result',
                style: const TextStyle(
                  color: Colors.white54,
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

class _AssessmentResultCard extends StatelessWidget {
  const _AssessmentResultCard({
    required this.report,
    required this.onOpenTutorMatch,
  });

  final _AssessmentReport report;
  final VoidCallback onOpenTutorMatch;

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.level,
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '%${report.score}',
                style: const TextStyle(
                  color: AppColors.brandDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FactLine(
              label: _copy('Kelime', 'Words'), value: '${report.wordCount}'),
          _FactLine(
              label: _copy('Cumle', 'Sentences'),
              value: '${report.sentenceCount}'),
          const SizedBox(height: 12),
          Text(
            _copy('Guclu taraflar', 'Strengths'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...report.strengths.map((item) => _LineBullet(text: item)),
          const SizedBox(height: 12),
          Text(
            _copy('Gelisecek alanlar', 'Focus areas'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...report.focusAreas.map((item) => _LineBullet(text: item)),
          const SizedBox(height: 12),
          Text(
            report.coachNote,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenTutorMatch,
              child:
                  Text(_copy('Uygun egitmenlere git', 'Open matched tutors')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeBubble extends StatelessWidget {
  const _PracticeBubble({required this.message});

  final _PracticeMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _PracticeRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brandDeep : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUser ? AppColors.brandDeep : const Color(0xFFDCE6F1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.ink,
                height: 1.5,
              ),
            ),
            if (message.chips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.chips.map((chip) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFF4F8FC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      chip,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.brandDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.helper,
  });

  final String value;
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorAvatar extends StatelessWidget {
  const _TutorAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final fallback = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white24,
      child: url.isEmpty
          ? Text(
              fallback,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            )
          : ClipOval(
              child: Image.network(
                url,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                errorBuilder: (_, __, ___) => Text(
                  fallback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard({
    required this.title,
    required this.description,
    this.dark = false,
  });

  final String title;
  final String description;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    final subtle = dark ? Colors.white70 : AppColors.muted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? Colors.white12 : const Color(0xFFDCE6F1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: subtle,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineBullet extends StatelessWidget {
  const _LineBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: AppColors.brandDeep),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final _TestimonialCardData review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              review.rating,
              (index) =>
                  const Icon(Icons.star, color: Color(0xFFF6A105), size: 18),
            ),
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: const TextStyle(color: AppColors.ink)),
          const SizedBox(height: 12),
          Text(
            review.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            review.title,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CoachChoice {
  const _CoachChoice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _ChoiceGroupData {
  const _ChoiceGroupData({
    required this.title,
    required this.choices,
    required this.selectedId,
    required this.onSelect,
  });

  final String title;
  final List<_CoachChoice> choices;
  final String selectedId;
  final ValueChanged<String> onSelect;
}

class _DailyMission {
  const _DailyMission({
    required this.id,
    required this.title,
    required this.detail,
    required this.durationLabel,
    required this.icon,
  });

  final String id;
  final String title;
  final String detail;
  final String durationLabel;
  final IconData icon;
}

class _ScenarioSpec {
  const _ScenarioSpec({
    required this.title,
    required this.hook,
    required this.prompt,
    required this.followUp,
    required this.keywords,
    required this.icon,
  });

  final String title;
  final String hook;
  final String prompt;
  final String followUp;
  final List<String> keywords;
  final IconData icon;
}

class _MiniContentItem {
  const _MiniContentItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String description;
  final Color accent;
  final IconData icon;
}

class _AssessmentReport {
  const _AssessmentReport({
    required this.level,
    required this.score,
    required this.wordCount,
    required this.sentenceCount,
    required this.strengths,
    required this.focusAreas,
    required this.transcript,
    required this.coachNote,
  });

  final String level;
  final int score;
  final int wordCount;
  final int sentenceCount;
  final List<String> strengths;
  final List<String> focusAreas;
  final String transcript;
  final String coachNote;
}

class _PracticeFeedback {
  const _PracticeFeedback({required this.reply, required this.tips});

  final String reply;
  final List<String> tips;
}

enum _PracticeRole { coach, user }

class _PracticeMessage {
  const _PracticeMessage({
    required this.role,
    required this.text,
    this.chips = const <String>[],
  });

  final _PracticeRole role;
  final String text;
  final List<String> chips;
}

class _TutorMatchViewModel {
  const _TutorMatchViewModel({
    required this.instructor,
    required this.matchScore,
    required this.reasons,
    this.matchPercent = 70,
  });

  final InstructorSummary instructor;
  final double matchScore;
  final List<String> reasons;
  final int matchPercent;

  _TutorMatchViewModel copyWith({int? matchPercent}) {
    return _TutorMatchViewModel(
      instructor: instructor,
      matchScore: matchScore,
      reasons: reasons,
      matchPercent: matchPercent ?? this.matchPercent,
    );
  }
}

class _JumpRailItem {
  const _JumpRailItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _TestimonialCardData {
  const _TestimonialCardData({
    required this.name,
    required this.title,
    required this.comment,
    required this.rating,
  });

  final String name;
  final String title;
  final String comment;
  final int rating;
}
