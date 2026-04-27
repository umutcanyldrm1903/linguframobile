import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/analytics/app_event_logger.dart';
import '../../core/analytics/analytics_sync_service.dart';
import '../../core/analytics/funnel_metrics_service.dart';
import '../../core/growth/growth_policy_service.dart';
import '../../core/localization/app_strings.dart';
import '../../core/notifications/app_notification_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../shared/trial_lesson_gate.dart';
import '../student/instructors/instructor_repository.dart';
import '../student/instructors/student_instructors_screen.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';
import 'public_theme.dart';
import 'speak_coach_repository.dart';
import 'speak_coach/index.dart';

enum _MissionChoiceStyle {
  list,
  visualCards,
  pictureGrid,
  tutorCards,
  toolPills,
}

enum _LessonTaskType {
  listenChoice,
  textChoice,
  pictureChoice,
  speakRepeat,
}

enum _MissionFeedbackKind {
  none,
  success,
  error,
}

class _LessonOptionData {
  const _LessonOptionData({
    required this.id,
    required this.labelTr,
    required this.labelEn,
    this.icon,
  });

  final String id;
  final String labelTr;
  final String labelEn;
  final IconData? icon;

  String label(bool isTr) => isTr ? labelTr : labelEn;
}

class _LessonTaskData {
  const _LessonTaskData({
    required this.id,
    required this.type,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.coachTr,
    required this.coachEn,
    required this.questionTr,
    required this.questionEn,
    required this.successTitleTr,
    required this.successTitleEn,
    required this.successDetailTr,
    required this.successDetailEn,
    this.promptText,
    this.promptDetailTr,
    this.promptDetailEn,
    this.options = const [],
    this.correctOptionId,
    this.targetSpeech,
    this.minimumSpeakingScore = 52,
  });

  final String id;
  final _LessonTaskType type;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String coachTr;
  final String coachEn;
  final String questionTr;
  final String questionEn;
  final String successTitleTr;
  final String successTitleEn;
  final String successDetailTr;
  final String successDetailEn;
  final String? promptText;
  final String? promptDetailTr;
  final String? promptDetailEn;
  final List<_LessonOptionData> options;
  final String? correctOptionId;
  final String? targetSpeech;
  final int minimumSpeakingScore;

  String title(bool isTr) => isTr ? titleTr : titleEn;
  String subtitle(bool isTr) => isTr ? subtitleTr : subtitleEn;
  String coach(bool isTr) => isTr ? coachTr : coachEn;
  String question(bool isTr) => isTr ? questionTr : questionEn;
  String successTitle(bool isTr) => isTr ? successTitleTr : successTitleEn;
  String successDetail(bool isTr) => isTr ? successDetailTr : successDetailEn;
  String? promptDetail(bool isTr) => isTr ? promptDetailTr : promptDetailEn;
}

class SpeakCoachScreen extends StatefulWidget {
  const SpeakCoachScreen({
    super.key,
    this.initialMissionStep = -1,
    this.missionScoreTotal = 0,
    this.missionScoredTaskCount = 0,
    this.missionMistakeCount = 0,
  });

  final int initialMissionStep;
  final int missionScoreTotal;
  final int missionScoredTaskCount;
  final int missionMistakeCount;

  @override
  State<SpeakCoachScreen> createState() => _SpeakCoachScreenState();
}

class _SpeakCoachScreenState extends State<SpeakCoachScreen> {
  static const _trialBookingIntentKey = 'trial_booking_intent_v1';
  static final List<GoalSpec> _goals = [
    GoalSpec(
      id: 'speaking',
      titleTr: 'Gunluk konusma',
      titleEn: 'Daily speaking',
      subtitleTr: 'Akicilik ve dogal cevaplar',
      subtitleEn: 'Fluency and natural answers',
      headlineTr: 'Her gun 10 dakikalik net bir akisla ilerle.',
      headlineEn: 'Move forward with one clean 10-minute flow every day.',
      supportTr:
          'Kisa dersler, tekrar kartlari, gercek hayat senaryolari ve canli hoca destegi ayni yerde.',
      supportEn:
          'Short lessons, review cards, real-life scenarios, and live tutor access in one place.',
      icon: Icons.forum_rounded,
    ),
    GoalSpec(
      id: 'business',
      titleTr: 'Is ingilizcesi',
      titleEn: 'Business English',
      subtitleTr: 'Toplanti, update, sunum dili',
      subtitleEn: 'Meetings, updates, presentations',
      headlineTr: 'Is gunu temposuna uygun kisa ama guclu calisma bloklari.',
      headlineEn:
          'Short but strong study blocks designed for a working schedule.',
      supportTr:
          'Toplanti kaliplari, update dili, follow-up ifadeleri ve profesyonel speaking rutini.',
      supportEn:
          'Meeting phrases, update language, follow-up lines, and a professional speaking routine.',
      icon: Icons.business_center_rounded,
    ),
    GoalSpec(
      id: 'ielts',
      titleTr: 'IELTS ve TOEFL',
      titleEn: 'IELTS & TOEFL',
      subtitleTr: 'Band odakli konusma ve ifade',
      subtitleEn: 'Band-focused speaking and structure',
      headlineTr: 'Sinav speaking icin gunluk tekrar ve net cevap iskeletleri.',
      headlineEn:
          'Daily revision and answer structures for speaking exam performance.',
      supportTr:
          'Cue card akisi, linking words, opinion yapisi ve band arttiran tekrar destesi.',
      supportEn:
          'Cue card structure, linking words, opinion framing, and revision packs that lift band scores.',
      icon: Icons.workspace_premium_rounded,
    ),
    GoalSpec(
      id: 'travel',
      titleTr: 'Seyahat ingilizcesi',
      titleEn: 'Travel English',
      subtitleTr: 'Havalimani, otel, restoran',
      subtitleEn: 'Airport, hotel, restaurant',
      headlineTr:
          'Gundelik seyahat durumlari icin hizli ve kullanisli kaliplar.',
      headlineEn:
          'Fast and useful phrases for the situations you actually face while traveling.',
      supportTr:
          'Check-in, rezervasyon, yardim isteme ve acil durum ifadeleri mini paketlerle hazir.',
      supportEn:
          'Check-in, reservations, asking for help, and emergency phrases are ready in compact packs.',
      icon: Icons.flight_takeoff_rounded,
    ),
  ];

  static const List<PlannerTarget> _targets = [
    PlannerTarget(3, '3 gun', '3 days'),
    PlannerTarget(4, '4 gun', '4 days'),
    PlannerTarget(5, '5 gun', '5 days'),
    PlannerTarget(6, '6 gun', '6 days'),
  ];

  static const List<ScheduleSpec> _schedules = [
    ScheduleSpec('morning', 'Sabah', 'Morning', '08:00 - 11:00'),
    ScheduleSpec('afternoon', 'Ogle', 'Afternoon', '12:00 - 16:00'),
    ScheduleSpec('evening', 'Aksam', 'Evening', '18:00 - 22:00'),
  ];

  static const List<ReminderSpec> _reminders = [
    ReminderSpec('morning', 'Sabah hatirlaticisi', 'Morning reminder'),
    ReminderSpec('afternoon', 'Gun ortasi hatirlaticisi', 'Midday reminder'),
    ReminderSpec('evening', 'Aksam hatirlaticisi', 'Evening reminder'),
  ];

  static const List<PracticeModeSpec> _practiceModes = [
    PracticeModeSpec(
      'shadow',
      'Shadowing',
      'Shadowing',
      'Dinle, hemen tekrar et, ritmi kopyala.',
      'Listen, repeat immediately, and mirror the rhythm.',
      Icons.hearing_rounded,
      Color(0xFF0F766E),
    ),
    PracticeModeSpec(
      'speed',
      'Hizli cevap',
      'Speed response',
      'Kisa surede net cevap cikarma aliskanligi kur.',
      'Build the habit of producing clean answers under time pressure.',
      Icons.flash_on_rounded,
      Color(0xFFB45309),
    ),
    PracticeModeSpec(
      'clarity',
      'Netlik drilli',
      'Clarity drill',
      'Vurgu, agiz acikligi ve temiz artikulasyon odagi.',
      'Focus on stress, mouth opening, and clean articulation.',
      Icons.record_voice_over_rounded,
      Color(0xFF1D4ED8),
    ),
  ];

  final SpeakCoachRepository _repository = SpeakCoachRepository();
  final PublicRepository _publicRepository = PublicRepository();
  final AppEventLogger _eventLogger = AppEventLogger.instance;
  final FunnelMetricsService _funnelMetrics = FunnelMetricsService();
  final AnalyticsSyncService _analyticsSync = AnalyticsSyncService();
  final GrowthPolicyService _growthPolicy = GrowthPolicyService.instance;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final Map<int, InstructorAvailabilitySnapshot?> _availability = {};
  bool _loading = true;
  bool _loadingAvailability = false;
  int _guidedSectionIndex = 0;
  bool _missionCompleted = false;
  _MissionFeedbackKind _missionFeedbackKind = _MissionFeedbackKind.none;
  bool _finalRewardVisible = false;
  String? _missionCompletionTitle;
  String? _missionCompletionDetail;
  String? _selectedMissionChoice;
  String? _missionMatchLeftChoice;
  String? _missionMatchRightChoice;
  bool _missionListenPlaying = false;
  bool _recordingCompare = false;
  bool _audioBusy = false;
  bool _ttsReady = false;
  int _missionScoreTotal = 0;
  int _missionScoredTaskCount = 0;
  int _missionMistakeCount = 0;
  String? _error;
  String? _activePlaybackSessionId;
  String? _activeRecordingFocusLine;
  String? _lastRecordedAudioPath;
  int? _lastMissionSpeechScore;
  String? _lastMissionSpeechTranscript;
  DateTime? _compareStartedAt;
  Amplitude? _compareAmplitude;
  StreamSubscription<Amplitude>? _compareAmplitudeSub;
  bool _speechReady = false;
  bool _availabilityUsingCache = false;
  int _pendingAvailabilityRetryCount = 0;
  String _liveTranscript = '';
  bool _lessonIntroVisible = false;
  bool _lessonOutroVisible = false;
  Timer? _lessonIntroTimer;
  Timer? _lessonOutroTimer;
  Timer? _missionFeedbackTimer;
  Timer? _finalRewardTimer;
  Timer? _missionAdvanceTimer;
  SpeakCoachLocalState _localState = SpeakCoachLocalState.initial();
  List<InstructorSummary> _instructors = const [];
  FunnelMetricsSnapshot? _funnelSnapshot;
  GrowthPolicyDecision? _growthDecision;
  SpeakingCoachFunnelReport? _backendFunnelReport;
  int _lastSyncedEventCount = 0;

  @override
  void initState() {
    super.initState();
    _guidedSectionIndex =
        widget.initialMissionStep < 0 ? 0 : widget.initialMissionStep;
    _missionScoreTotal = widget.missionScoreTotal;
    _missionScoredTaskCount = widget.missionScoredTaskCount;
    _missionMistakeCount = widget.missionMistakeCount;
    _queueLessonIntro();
    _initTts();
    _initSpeech();
    _load();
  }

  @override
  void dispose() {
    _lessonIntroTimer?.cancel();
    _lessonOutroTimer?.cancel();
    _missionFeedbackTimer?.cancel();
    _finalRewardTimer?.cancel();
    _missionAdvanceTimer?.cancel();
    _compareAmplitudeSub?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  bool get _isMissionMode => widget.initialMissionStep >= 0;

  void _queueLessonIntro() {
    _lessonIntroTimer?.cancel();
    _lessonIntroVisible = true;
    _lessonIntroTimer = Timer(const Duration(milliseconds: 980), () {
      if (!mounted) return;
      setState(() => _lessonIntroVisible = false);
    });
  }

  void _triggerLessonOutro() {
    _lessonOutroTimer?.cancel();
    setState(() => _lessonOutroVisible = true);
    _lessonOutroTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _lessonOutroVisible = false);
    });
  }

  void _clearMissionFeedback() {
    _missionFeedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      if (!_missionCompleted) {
        _missionFeedbackKind = _MissionFeedbackKind.none;
        _missionCompletionTitle = null;
        _missionCompletionDetail = null;
      }
    });
  }

  bool _isFinalLessonStep(_LessonTaskData step) {
    final steps = _buildDailyLessonSteps();
    if (steps.isEmpty) return false;
    return steps.last.id == step.id;
  }

  int get _finalMissionScore {
    if (_missionScoredTaskCount <= 0) return 0;
    final raw = (_missionScoreTotal / _missionScoredTaskCount).round();
    final penalty = (_missionMistakeCount * 3).clamp(0, 18);
    return (raw - penalty).clamp(0, 100);
  }

  List<String> get _finalWeaknesses {
    final score = _finalMissionScore;
    final weaknesses = <String>[];
    if (_missionMistakeCount > 0) {
      weaknesses.add(AppStrings.code == 'tr' ? 'dinleme' : 'listening');
    }
    if ((_lastMissionSpeechScore ?? score) < 72) {
      weaknesses.add(AppStrings.code == 'tr' ? 'telaffuz' : 'pronunciation');
    }
    if (score < 82) {
      weaknesses
          .add(AppStrings.code == 'tr' ? 'cumle anlami' : 'sentence meaning');
    }
    if (weaknesses.isEmpty) {
      weaknesses.add(
          AppStrings.code == 'tr' ? 'konusma akiciligi' : 'speaking fluency');
    }
    return weaknesses.take(3).toList(growable: false);
  }

  void _showFinalRewardScene() {
    _finalRewardTimer?.cancel();
    if (!mounted) return;
    setState(() => _finalRewardVisible = true);
  }

  void _hideFinalRewardScene() {
    if (!mounted) return;
    setState(() => _finalRewardVisible = false);
  }

  void _finishLessonExperience() {
    if (!mounted) return;
    _hideFinalRewardScene();
    Navigator.pushNamedAndRemoveUntil(context, '/after-test', (_) => false);
  }

  Future<void> _initTts() async {
    void handleTtsDone() {
      if (!mounted) return;
      setState(() => _missionListenPlaying = false);
    }

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(kIsWeb ? 0.47 : 0.43);
      await _flutterTts.awaitSpeakCompletion(true);
      _flutterTts.setStartHandler(() {
        if (!mounted) return;
        setState(() => _missionListenPlaying = true);
      });
      _flutterTts.setCompletionHandler(handleTtsDone);
      _flutterTts.setCancelHandler(handleTtsDone);
      _flutterTts.setErrorHandler((_) => handleTtsDone());
      if (!mounted) return;
      setState(() => _ttsReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ttsReady = false);
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize();
      if (!mounted) return;
      setState(() => _speechReady = available);
    } catch (_) {
      if (!mounted) return;
      setState(() => _speechReady = false);
    }
  }

  Future<void> _startSpeechRecognition({String localeId = 'en_US'}) async {
    if (!_speechReady || _speechToText.isListening) return;
    try {
      await _speechToText.listen(
        // ignore: deprecated_member_use
        partialResults: true,
        // ignore: deprecated_member_use
        listenMode: stt.ListenMode.dictation,
        localeId: localeId,
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _liveTranscript = result.recognizedWords.trim();
          });
        },
      );
    } catch (_) {}
  }

  Future<void> _stopSpeechRecognition() async {
    if (_speechToText.isListening) {
      try {
        await _speechToText.stop();
      } catch (_) {}
    }
  }

  Future<void> _speakMissionPrompt(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty) return;

    if (!_ttsReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Cihazda dinleme sesi baslatilamadi.',
              'The listening prompt could not start on this device.',
            ),
          ),
        ),
      );
      return;
    }

    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.speak(prompt);
    } catch (_) {
      if (!mounted) return;
      setState(() => _missionListenPlaying = false);
    }
  }

  Future<T?> _showAdaptiveBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      sheetAnimationStyle: AnimationStyle(
        duration: Duration(milliseconds: isIOS ? 420 : 260),
        reverseDuration: Duration(milliseconds: isIOS ? 320 : 200),
      ),
      builder: builder,
    );
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  GoalSpec get _goal {
    return _goals.firstWhere(
      (item) => item.id == _localState.goalId,
      orElse: () => _goals.first,
    );
  }

  ScheduleSpec get _schedule {
    return _schedules.firstWhere(
      (item) => item.id == _localState.scheduleId,
      orElse: () => _schedules.last,
    );
  }

  ReminderSpec get _reminder {
    return _reminders.firstWhere(
      (item) => item.id == _localState.reminderWindow,
      orElse: () => _reminders.last,
    );
  }

  PracticeModeSpec get _practiceMode {
    return _practiceModes.firstWhere(
      (item) => item.id == _localState.preferredPracticeMode,
      orElse: () => _practiceModes.first,
    );
  }

  List<SpeakCoachCompareSession> get _compareSessions {
    return _localState.compareSessions
        .where((item) => item.goalId == _goal.id)
        .take(6)
        .toList(growable: false);
  }

  List<SpeakCoachCompareSession> get _comparePair {
    return _compareSessions.take(2).toList(growable: false);
  }

  String get _todayKey => _dateKey(DateTime.now());

  Set<String> get _completedToday {
    return Set<String>.from(
      _localState.completedMissionIdsByDate[_todayKey] ?? const <String>[],
    );
  }

  int get _weeklySessions {
    final threshold = DateUtils.dateOnly(
      DateTime.now().subtract(const Duration(days: 6)),
    );
    return _localState.activeDates.where((value) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) return false;
      return !DateUtils.dateOnly(parsed).isBefore(threshold);
    }).length;
  }

  int get _streak {
    final activeDays = _localState.activeDates.toSet();
    var streak = 0;
    var cursor = DateUtils.dateOnly(DateTime.now());
    while (activeDays.contains(_dateKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get _bestStreak {
    final activeDays = _localState.activeDates.toSet();
    if (activeDays.isEmpty) return 0;
    final ordered = activeDays.toList()..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < ordered.length; i++) {
      final previous = DateTime.tryParse(ordered[i - 1]);
      final next = DateTime.tryParse(ordered[i]);
      if (previous == null || next == null) continue;
      final diff = DateUtils.dateOnly(next)
          .difference(DateUtils.dateOnly(previous))
          .inDays;
      if (diff == 1) {
        current += 1;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  List<InstructorSummary> get _featuredInstructors {
    if (_instructors.isEmpty) return const <InstructorSummary>[];
    return _instructors.take(4).toList(growable: false);
  }

  List<InstructorSummary> get _matchedInstructors {
    if (_instructors.isEmpty) return const <InstructorSummary>[];
    final ranked = List<InstructorSummary>.from(_instructors)
      ..sort((a, b) => _matchScore(b).compareTo(_matchScore(a)));
    return ranked.take(3).toList(growable: false);
  }

  bool get _challengeStarted =>
      (_localState.challengeStartDate ?? '').trim().isNotEmpty;

  int get _challengeDay {
    final raw = _localState.challengeStartDate;
    if (raw == null || raw.trim().isEmpty) return 0;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 0;
    return DateUtils.dateOnly(DateTime.now())
            .difference(DateUtils.dateOnly(parsed))
            .inDays +
        1;
  }

  int get _challengeProgressDays =>
      _challengeStarted ? _challengeDay.clamp(1, 7) : 0;

  bool get _challengeCompleted => _challengeStarted && _challengeDay >= 7;

  List<SpeakCoachActivityEntry> get _activityLog =>
      _localState.activityLog.take(8).toList(growable: false);

  List<InstructorSummary> get _favoriteTutors {
    final ids = _localState.favoriteInstructorIds.toSet();
    return _instructors.where((item) => ids.contains(item.id)).take(3).toList();
  }

  List<String> get _savedPhrases =>
      _localState.savedPhrases.take(8).toList(growable: false);

  List<CalendarDay> get _calendarDays {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 13));
    final active = _localState.activeDates.toSet();
    return List.generate(14, (index) {
      final date = start.add(Duration(days: index));
      return CalendarDay(
        date: date,
        active: active.contains(_dateKey(date)),
        isToday: DateUtils.isSameDay(date, today),
      );
    });
  }

  int get _availableTodayCount {
    return _availability.values
        .whereType<InstructorAvailabilitySnapshot>()
        .fold<int>(0, (sum, item) => sum + item.todayAvailableCount);
  }

  String get _topGoalLabel => _copy(
        'En cok secilen hedef: ${_goal.titleTr}',
        'Top selected goal: ${_goal.titleEn}',
      );

  List<ProofMetric> get _proofMetrics {
    return [
      ProofMetric(
        value: '${_instructors.length}',
        label: _copy('Aktif hoca', 'Active tutors'),
      ),
      ProofMetric(
        value: '$_availableTodayCount',
        label: _copy('Bugun acik slot', 'Open today'),
      ),
      ProofMetric(
        value: '${_localState.weeklyTarget}',
        label: _copy('Haftalik hedef', 'Weekly target'),
      ),
      ProofMetric(
        value: '${_todayTasks.length}',
        label: _copy('Gunluk gorev', 'Daily tasks'),
      ),
    ];
  }

  SpeakCoachCompareSession? get _latestCompareSession {
    if (_compareSessions.isEmpty) return null;
    return _compareSessions.first;
  }

  List<ProofMetric> get _liveFeedbackMetrics {
    final latest = _latestCompareSession;
    if (latest == null) {
      return _pronunciationMetricsForGoal(_goal);
    }
    return [
      ProofMetric(
        value: '${latest.clarityScore}',
        label: _copy('Netlik', 'Clarity'),
      ),
      ProofMetric(
        value: '${latest.rhythmScore}',
        label: _copy('Ritim', 'Rhythm'),
      ),
      ProofMetric(
        value: '${latest.confidenceScore}',
        label: _copy('Guven', 'Confidence'),
      ),
    ];
  }

  String get _asrTranscript {
    final latest = _latestCompareSession;
    if (latest != null && latest.transcript.trim().isNotEmpty) {
      return latest.transcript;
    }
    if (_liveTranscript.trim().isNotEmpty) {
      return _liveTranscript.trim();
    }
    return _pronunciationSpotForGoal(_goal).focusLine;
  }

  String get _rewrittenTranscript {
    final latest = _latestCompareSession;
    if (latest != null && latest.rewrittenTranscript.trim().isNotEmpty) {
      return latest.rewrittenTranscript;
    }
    return _naturalSentenceHint;
  }

  Map<String, int> get _latestErrorTagScores {
    final latest = _latestCompareSession;
    if (latest == null) {
      return const {'pronunciation': 62};
    }
    if (latest.errorTagScores.isNotEmpty) {
      return latest.errorTagScores;
    }
    if (latest.errorTags.isNotEmpty) {
      return {
        for (final tag in latest.errorTags) tag: 62,
      };
    }
    return const {'pronunciation': 62};
  }

  String get _trialCtaLabel {
    return _growthDecision?.trialCtaLabel ??
        _copy('Ucretsiz deneme iste', 'Request free trial');
  }

  void _nudgeFreeTrial() {
    // Trial conversion now happens in the final report and after-test screens.
    // Keep this method as a no-op so older task hooks do not show bottom banners.
  }

  _WeeklySpeakingReport get _weeklySpeakingReport {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final previousWeekStart = now.subtract(const Duration(days: 14));
    final currentWeek = _compareSessions.where((session) {
      final created = DateTime.tryParse(session.createdAtIso);
      if (created == null) return false;
      return created.isAfter(weekStart);
    }).toList(growable: false);
    final previousWeek = _compareSessions.where((session) {
      final created = DateTime.tryParse(session.createdAtIso);
      if (created == null) return false;
      return created.isAfter(previousWeekStart) && created.isBefore(weekStart);
    }).toList(growable: false);
    if (currentWeek.isEmpty) {
      return const _WeeklySpeakingReport.empty();
    }
    var clarity = 0;
    var rhythm = 0;
    var confidence = 0;
    final tags = <String, int>{};
    for (final session in currentWeek) {
      clarity += session.clarityScore;
      rhythm += session.rhythmScore;
      confidence += session.confidenceScore;
      final sourceTags = session.errorTagScores.isNotEmpty
          ? session.errorTagScores
          : {for (final tag in session.errorTags) tag: 62};
      sourceTags.forEach((tag, score) {
        tags[tag] = (tags[tag] ?? 0) + score;
      });
    }

    var previousClarity = 0;
    var previousRhythm = 0;
    var previousConfidence = 0;
    for (final session in previousWeek) {
      previousClarity += session.clarityScore;
      previousRhythm += session.rhythmScore;
      previousConfidence += session.confidenceScore;
    }
    final previousCount = previousWeek.length;
    final prevAvgClarity =
        previousCount == 0 ? 0 : (previousClarity / previousCount).round();
    final prevAvgRhythm =
        previousCount == 0 ? 0 : (previousRhythm / previousCount).round();
    final prevAvgConfidence =
        previousCount == 0 ? 0 : (previousConfidence / previousCount).round();

    return _WeeklySpeakingReport(
        sessionCount: currentWeek.length,
        avgClarity: (clarity / currentWeek.length).round(),
        avgRhythm: (rhythm / currentWeek.length).round(),
        avgConfidence: (confidence / currentWeek.length).round(),
        clarityDelta: (clarity / currentWeek.length).round() - prevAvgClarity,
        rhythmDelta: (rhythm / currentWeek.length).round() - prevAvgRhythm,
        confidenceDelta:
            (confidence / currentWeek.length).round() - prevAvgConfidence,
        sessionDelta: currentWeek.length - previousCount,
        tagBreakdown: {
          for (final entry in tags.entries)
            entry.key: (entry.value / currentWeek.length).round().clamp(1, 100),
        });
  }

  String get _naturalSentenceHint {
    switch (_goal.id) {
      case 'business':
        return _copy(
          'Could you share the latest version before end of day?',
          'Could you share the latest version before end of day?',
        );
      case 'ielts':
        return _copy(
          'To a large extent, I agree because it improves long-term focus.',
          'To a large extent, I agree because it improves long-term focus.',
        );
      case 'travel':
        return _copy(
          'There seems to be a problem with my booking, could you check it?',
          'There seems to be a problem with my booking, could you check it?',
        );
      default:
        return _copy(
          'These days I am focused on speaking more naturally in daily life.',
          'These days I am focused on speaking more naturally in daily life.',
        );
    }
  }

  List<TodayTask> get _microChallenges {
    return [
      TodayTask(
        id: 'challenge_ab',
        titleTr: 'A/B tekrar',
        titleEn: 'A/B repeat',
        detailTr: 'Ornek cumleyi dinle, ayni ritimde tekrar kaydet.',
        detailEn:
            'Listen to the sample line, then record it with the same rhythm.',
        durationLabel: _copy('2 dk', '2 min'),
        icon: Icons.compare_arrows_rounded,
        buttonTr: 'Kayda gec',
        buttonEn: 'Start recording',
      ),
      TodayTask(
        id: 'challenge_speed',
        titleTr: 'Hizli cevap',
        titleEn: 'Speed answer',
        detailTr: '10 saniyede net bir cevap kur ve kaydet.',
        detailEn: 'Build a clear answer in 10 seconds and save it.',
        durationLabel: _copy('3 dk', '3 min'),
        icon: Icons.flash_on_rounded,
        buttonTr: 'Modu ac',
        buttonEn: 'Open mode',
      ),
      TodayTask(
        id: 'challenge_tutor',
        titleTr: 'Canli adim',
        titleEn: 'Live step',
        detailTr: 'Uygun bir tutor secip deneme dersini kilitle.',
        detailEn: 'Pick a suitable tutor and lock your free trial step.',
        durationLabel: _copy('2 dk', '2 min'),
        icon: Icons.headset_mic_rounded,
        buttonTr: 'Tutorleri gor',
        buttonEn: 'See tutors',
      ),
    ];
  }

  List<TodayTask> get _todayTasks {
    final firstPack = _packsForGoal(_goal).first;
    return [
      TodayTask(
        id: 'placement',
        titleTr: '2 dakikalik seviye testi',
        titleEn: '2-minute level test',
        detailTr: 'Gercek backend sonucu ile seviyeni netlestir.',
        detailEn: 'Confirm your starting level with a real backend result.',
        durationLabel: _copy('2 dk', '2 min'),
        icon: Icons.verified_rounded,
        buttonTr: 'Teste gir',
        buttonEn: 'Take test',
      ),
      TodayTask(
        id: 'pack',
        titleTr: firstPack.titleTr,
        titleEn: firstPack.titleEn,
        detailTr: firstPack.subtitleTr,
        detailEn: firstPack.subtitleEn,
        durationLabel: firstPack.durationLabel,
        icon: firstPack.icon,
        buttonTr: 'Paketi ac',
        buttonEn: 'Open pack',
      ),
      TodayTask(
        id: 'review',
        titleTr: 'Tekrar destesi',
        titleEn: 'Review deck',
        detailTr: 'Gunluk ifadeleri hizli tekrar et ve ritmi koru.',
        detailEn: 'Revisit the core phrases and keep the rhythm alive.',
        durationLabel: _copy('4 dk', '4 min'),
        icon: Icons.layers_rounded,
        buttonTr: 'Kartlari ac',
        buttonEn: 'Open cards',
      ),
    ];
  }

  List<PathStep> get _pathSteps {
    return [
      PathStep(
        title: _copy('Goal sec', 'Pick goal'),
        detail: _copy(
          'Calisma yolunu ihtiyacina gore kur.',
          'Shape the study path around what you need.',
        ),
        done: true,
      ),
      PathStep(
        title: _copy('Mini paket', 'Mini pack'),
        detail: _copy(
          'Kisa ifade ve mini diyalog ile basla.',
          'Start with short phrases and a compact dialogue.',
        ),
        done: _completedToday.contains('pack'),
      ),
      PathStep(
        title: _copy('Tekrar', 'Review'),
        detail: _copy(
          'Kartlari tara ve kullanacagin cumleyi sec.',
          'Scan the cards and keep the sentence you will use.',
        ),
        done: _completedToday.contains('review'),
      ),
      PathStep(
        title: _copy('Canli ders', 'Live lesson'),
        detail: _copy(
          'Ucretsiz deneme veya egitmen profili ile devam et.',
          'Continue with a free trial or a tutor profile.',
        ),
        done: _weeklySessions > 0,
      ),
    ];
  }

  List<StudyPack> _packsForGoal(GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return const [
          StudyPack(
              'business-update',
              'Gunluk update',
              'Daily update',
              'Toplanti oncesi net durum ozeti',
              'A clear status update before the meeting',
              '6 min',
              Icons.campaign_rounded,
              Color(0xFF3D5CFF),
              [
                'We are on track for Friday.',
                'I need one more review before we send it.',
                'The main blocker is timing.',
              ],
              'Quick update: we finished the deck, but we still need legal review before launch.',
              'Kisa, net ve sonuca giden cumleler kullan.',
              'Keep it short and directional.'),
          StudyPack(
              'business-followup',
              'Follow-up dili',
              'Follow-up language',
              'Mail ve mesaj tonunu toparla',
              'Tighten your email and chat tone',
              '5 min',
              Icons.mark_email_read_rounded,
              Color(0xFF0F766E),
              [
                'Just following up on the last update.',
                'Could you share the latest version by EOD?',
                'Let me know if anything changes on your side.',
              ],
              'I am following up on the draft we discussed yesterday. If the latest version is ready, I can review it tonight.',
              'Tarih veya saat ver, sonraki hareketi netlestir.',
              'Add a time marker and make the next action obvious.'),
        ];
      case 'ielts':
        return const [
          StudyPack(
              'ielts-part1',
              'Part 1 iskeleti',
              'Part 1 skeleton',
              'Kisa cevaplari bir tik daha bandli yap',
              'Lift short answers with a better structure',
              '5 min',
              Icons.question_answer_rounded,
              Color(0xFF2563EB),
              [
                'Usually, I prefer...',
                'The main reason is that...',
                'It has become part of my routine.',
              ],
              'Usually, I prefer studying early in the morning because I feel more focused and less distracted at that time.',
              'Cevap + neden + mini detay yapisi kullan.',
              'Use answer + reason + a small detail.'),
          StudyPack(
              'ielts-opinion',
              'Opinion cevabi',
              'Opinion answer',
              'Katiliyorum derken nedeni guclendir',
              'Strengthen the reason when you agree or disagree',
              '6 min',
              Icons.record_voice_over_rounded,
              Color(0xFFEA580C),
              [
                'To a large extent, I agree that...',
                'The strongest argument is...',
                'That said, there is one limitation.',
              ],
              'To a large extent, I agree that online learning is more flexible; however, it still requires a strong routine to stay effective.',
              'Opinion ver, dayanak ver, sonra dengeli bir ikinci cumle ekle.',
              'State the opinion, justify it, then add a balanced second sentence.'),
        ];
      case 'travel':
        return const [
          StudyPack(
              'travel-airport',
              'Havalimani check-in',
              'Airport check-in',
              'Bagaj, gate ve belge dili',
              'Baggage, gate, and document language',
              '5 min',
              Icons.luggage_rounded,
              Color(0xFF3D5CFF),
              [
                'I would like to check in for my flight.',
                'Can I keep this bag with me?',
                'Has the gate changed?',
              ],
              'Hi, I would like to check in for my flight to London. Can I keep this backpack with me?',
              'Ana fiili one koy, sonra detay ekle.',
              'Lead with the verb, then add the detail.'),
          StudyPack(
              'travel-hotel',
              'Otel sorunu',
              'Hotel issue',
              'Rezervasyon ve oda talebi',
              'Reservation and room requests',
              '6 min',
              Icons.hotel_rounded,
              Color(0xFF0F766E),
              [
                'There seems to be a problem with my booking.',
                'Could I change the room, please?',
                'The air conditioner is not working.',
              ],
              'There seems to be a problem with my booking. I requested a quiet room, but this one is next to the elevator.',
              'Sorunu belirt, talebini soyle, sonra gerekce ver.',
              'State the issue, make the request, then explain the reason.'),
        ];
      default:
        return const [
          StudyPack(
              'speaking-intro',
              'Kendini tanit',
              'Introduce yourself',
              'Ilk 30 saniyeyi guclu kur',
              'Make the first 30 seconds stronger',
              '5 min',
              Icons.waving_hand_rounded,
              Color(0xFF3D5CFF),
              [
                'I work in...',
                'These days I am focused on...',
                'Outside work, I enjoy...',
              ],
              'Hi, I am Ece. I work in digital marketing, and these days I am focused on improving my English for meetings and daily communication.',
              'Isim, ne yaptigin, neden buradasin.',
              'Name, what you do, why you are here.'),
          StudyPack(
              'speaking-smalltalk',
              'Small talk',
              'Small talk',
              'Gunluk kisitli ama dogal cevaplar',
              'Short but natural everyday answers',
              '4 min',
              Icons.coffee_rounded,
              Color(0xFF0F766E),
              [
                'It has been a busy week so far.',
                'I am trying to slow down a little.',
                'I finally had time to rest.',
              ],
              'It has been a busy week so far, but I finally had time to slow down last night and read for a while.',
              'Kisa cevap ver ama bir detay ekle.',
              'Keep the answer short, but add one detail.'),
        ];
    }
  }

  List<ReviewCard> _reviewCardsForGoal(GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return const [
          ReviewCard(
              'Net update',
              'Clear update',
              'We are on track.',
              'Planlanan tempodayiz.',
              'We are moving at the planned pace.',
              'Status guncellerken ilk cumle olarak kullan.',
              'Use it as the first line of a status update.'),
          ReviewCard(
              'Acil ama profesyonel',
              'Urgent but professional',
              'Could you share the latest version by EOD?',
              'Gun sonuna kadar son versiyonu paylasabilir misin?',
              'Can you send the latest version by end of day?',
              'Tarih veya saat eklemek tonu guclendirir.',
              'Adding a time marker makes the tone stronger.'),
        ];
      case 'ielts':
        return const [
          ReviewCard(
              'Opinion girisi',
              'Opinion opener',
              'To a large extent, I agree that...',
              'Buyuk olcude katiliyorum ki...',
              'I agree to a great extent that...',
              'Speaking opinion cevabina guclu girer.',
              'A strong start for a speaking opinion answer.'),
          ReviewCard(
              'Baglayici',
              'Connector',
              'As a result, ...',
              'Sonuc olarak...',
              'As a consequence...',
              'Neden-sonuc baglamak icin kullan.',
              'Use it when the idea moves into a result.'),
        ];
      case 'travel':
        return const [
          ReviewCard(
              'Check-in',
              'Check-in',
              'I would like to check in for my flight.',
              'Ucusum icin check-in yapmak istiyorum.',
              'I want to check in for my flight.',
              'Havalimani masasinda acilis cumlesi.',
              'A clean opening line at the airport desk.'),
          ReviewCard(
              'Problem bildir',
              'Report a problem',
              'There seems to be a problem with my booking.',
              'Rezervasyonumda bir sorun var gibi gorunuyor.',
              'It looks like there is an issue with my booking.',
              'Otel ya da rezervasyon deskinde kullan.',
              'Use it at a hotel or booking counter.'),
        ];
      default:
        return const [
          ReviewCard(
              'Tanisma',
              'Introduction',
              'These days I am focused on...',
              'Bu aralar odagim su konuda...',
              'Lately I am focused on...',
              'Kendini tanitirken net bir hedef gosterir.',
              'It shows a clear purpose when you introduce yourself.'),
          ReviewCard(
              'Dogal baglayici',
              'Natural connector',
              'On top of that, ...',
              'Bunun da ustune...',
              'In addition to that...',
              'Cok resmi olmadan cumleyi uzatir.',
              'It extends the thought without sounding too formal.'),
        ];
    }
  }

  PronunciationSpot _pronunciationSpotForGoal(GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return const PronunciationSpot(
          'Toplanti ritmi',
          'Meeting rhythm',
          'I NEED the LAT-est VER-sion by EOD.',
          'Ana vurgu zaman ve teslim ifadesinde olsun.',
          'Put the main stress on time and delivery.',
        );
      case 'ielts':
        return const PronunciationSpot(
          'Uzun cevap ritmi',
          'Long answer rhythm',
          'To a LARGE exTENT, I aGREE that...',
          'Uzun cevabi tek blok okumak yerine vurguyu iki durakta topla.',
          'Do not read the long answer as one block.',
        );
      case 'travel':
        return const PronunciationSpot(
          'Kisa soru netligi',
          'Short-question clarity',
          'Is it WITH-in WALK-ing dis-TANCE?',
          'Soruyu hizlandirma. Her ana kelime net ciksin.',
          'Do not rush the question. Let the key words land clearly.',
        );
      default:
        return const PronunciationSpot(
          'Dogal tanisma tonu',
          'Natural intro tone',
          'These DAYS I am FO-cused on...',
          'Baslangicta iki vurgu yeterli.',
          'Two strong beats are enough at the start.',
        );
    }
  }

  List<ProofMetric> _pronunciationMetricsForGoal(GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return [
          ProofMetric(value: '86', label: _copy('Netlik', 'Clarity')),
          ProofMetric(value: '81', label: _copy('Ritim', 'Rhythm')),
          ProofMetric(value: 'EOD', label: _copy('Odak ses', 'Focus sound')),
        ];
      case 'ielts':
        return [
          ProofMetric(value: '84', label: _copy('Akis', 'Flow')),
          ProofMetric(value: '79', label: _copy('Vurgu', 'Stress')),
          ProofMetric(value: 'ARG', label: _copy('Odak ses', 'Focus sound')),
        ];
      case 'travel':
        return [
          ProofMetric(value: '88', label: _copy('Netlik', 'Clarity')),
          ProofMetric(value: '76', label: _copy('Tempo', 'Tempo')),
          ProofMetric(value: 'WALK', label: _copy('Odak ses', 'Focus sound')),
        ];
      default:
        return [
          ProofMetric(value: '85', label: _copy('Ton', 'Tone')),
          ProofMetric(value: '80', label: _copy('Ritim', 'Rhythm')),
          ProofMetric(value: 'FO', label: _copy('Odak ses', 'Focus sound')),
        ];
    }
  }

  Future<void> _saveLocalState(SpeakCoachLocalState nextState) async {
    setState(() => _localState = nextState);
    await _repository.saveLocalState(nextState);
  }

  Future<void> _tapFeedback() async {
    await HapticFeedback.selectionClick();
  }

  Future<void> _logEvent(
    String name, {
    Map<String, String> properties = const <String, String>{},
  }) async {
    await _eventLogger.log(name, properties: properties);
    final snapshot = await _funnelMetrics.speakingFunnel();
    if (!mounted) return;
    setState(() => _funnelSnapshot = snapshot);
  }

  Future<void> _triggerBehavioralPush({
    required String triggerId,
    required String titleTr,
    required String bodyTr,
    required String titleEn,
    required String bodyEn,
    Duration cooldown = const Duration(hours: 24),
    String? route,
  }) async {
    await AppNotificationService.instance.triggerBehavioralPush(
      triggerId: triggerId,
      titleTr: titleTr,
      bodyTr: bodyTr,
      titleEn: titleEn,
      bodyEn: bodyEn,
      isTurkish: AppStrings.code == 'tr',
      cooldown: cooldown,
      route: route,
    );
  }

  Future<void> _setTrialBookingIntent() async {
    await SecureStorage.setValue(
        _trialBookingIntentKey, DateTime.now().toIso8601String());
  }

  Future<void> _setFinalTrialBookingIntent({
    required int score,
    required List<String> weaknesses,
    required String slotLabel,
    InstructorSummary? tutor,
  }) async {
    await SecureStorage.setValue(
      _trialBookingIntentKey,
      jsonEncode({
        'source': 'speaking_mission_final',
        'created_at': DateTime.now().toIso8601String(),
        'goal': _goal.id,
        'goal_label': AppStrings.code == 'tr' ? _goal.titleTr : _goal.titleEn,
        'score': score,
        'mistakes': _missionMistakeCount,
        'weaknesses': weaknesses,
        'slot_label': slotLabel,
        'tutor_id': tutor?.id,
        'tutor_name': tutor?.name,
      }),
    );
  }

  Future<void> _openRegisterFromFinalReward({
    required int score,
    required List<String> weaknesses,
    required String slotLabel,
    InstructorSummary? tutor,
  }) async {
    await _setFinalTrialBookingIntent(
      score: score,
      weaknesses: weaknesses,
      slotLabel: slotLabel,
      tutor: tutor,
    );
    await _logEvent(
      'final_trial_register_tapped',
      properties: {
        'goal': _goal.id,
        'score': '$score',
        'slot': slotLabel,
        'tutor_id': '${tutor?.id ?? 0}',
      },
    );
    if (!mounted) return;
    Navigator.pushNamed(context, '/register');
  }

  Future<bool> _consumeTrialBookingIntent() async {
    final raw = await SecureStorage.getValue(_trialBookingIntentKey);
    await SecureStorage.deleteValue(_trialBookingIntentKey);
    return raw != null && raw.trim().isNotEmpty;
  }

  Future<void> _setGoal(String goalId) async {
    await _tapFeedback();
    await _saveLocalState(_localState.copyWith(goalId: goalId));
  }

  Future<void> _setReminder(String reminderWindow) async {
    await _saveLocalState(
      _localState.copyWith(reminderWindow: reminderWindow),
    );
    final granted = await AppNotificationService.instance.requestPermissions();
    if (granted) {
      await AppNotificationService.instance.scheduleDailyReminder(
        reminderWindow: reminderWindow,
        isTurkish: AppStrings.code == 'tr',
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? _copy(
                  'Gunluk bildirim aktif edildi.',
                  'Daily notification has been enabled.',
                )
              : _copy(
                  'Bildirim izni verilmedi. Cihaz ayarlarindan acabilirsin.',
                  'Notification permission was not granted. You can enable it from device settings.',
                ),
        ),
      ),
    );
  }

  Future<void> _setPracticeMode(String practiceMode) async {
    await _tapFeedback();
    await _saveLocalState(
      _localState.copyWith(preferredPracticeMode: practiceMode),
    );
    await _recordActivity(
      'practice_mode',
      AppStrings.code == 'tr'
          ? 'Pratik modu guncellendi'
          : 'Practice mode updated',
    );
    _nudgeFreeTrial();
  }

  Future<SpeakCoachCompareSession?> _toggleCompareRecording({
    String? focusLineOverride,
  }) async {
    await _tapFeedback();
    if (_recordingCompare) {
      return _finishCompareRecording();
    }

    if (_audioBusy) return null;

    final permissionGranted = await _audioRecorder.hasPermission();
    if (!permissionGranted) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Mikrofon izni verilmedi. Kayda baslamak icin izin vermelisin.',
              'Microphone permission was not granted. You need to allow it before recording.',
            ),
          ),
        ),
      );
      return null;
    }

    final encoder = await _resolveCompareEncoder();
    if (encoder == null) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Bu cihazda desteklenen bir ses encoder bulunamadi.',
              'No supported audio encoder was found on this device.',
            ),
          ),
        ),
      );
      return null;
    }

    final outputPath = await _buildCompareOutputPath(encoder);
    await _compareAmplitudeSub?.cancel();

    try {
      await _audioPlayer.stop();
      await _audioRecorder.start(
        RecordConfig(
          encoder: encoder,
          numChannels: 1,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: outputPath,
      );
      _compareAmplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 180))
          .listen((amp) {
        if (!mounted) return;
        setState(() => _compareAmplitude = amp);
      });
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Kayit baslatilamadi. Mikrofon veya tarayici ayarlarini kontrol et.',
              'Recording could not start. Check the microphone or browser settings.',
            ),
          ),
        ),
      );
      return null;
    }

    setState(() {
      _recordingCompare = true;
      _compareStartedAt = DateTime.now();
      _compareAmplitude = null;
      _liveTranscript = '';
      _activeRecordingFocusLine = focusLineOverride?.trim();
      _lastMissionSpeechScore = null;
      _lastMissionSpeechTranscript = null;
    });
    await _startSpeechRecognition(localeId: 'en_US');
    await _logEvent('record_started', properties: {
      'goal': _goal.id,
      'mode': _practiceMode.id,
    });
    await _recordActivity(
      'compare_start',
      AppStrings.code == 'tr'
          ? 'Record + compare kaydi basladi'
          : 'Record + compare session started',
    );
    return null;
  }

  Future<SpeakCoachCompareSession?> _finishCompareRecording() async {
    if (_audioBusy) return null;

    final startedAt = _compareStartedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt).inSeconds.clamp(1, 95);
    String? audioPath;

    try {
      audioPath = await _audioRecorder.stop();
    } catch (_) {
      audioPath = null;
    }
    await _stopSpeechRecognition();

    await _compareAmplitudeSub?.cancel();

    if ((audioPath ?? '').trim().isEmpty) {
      setState(() {
        _recordingCompare = false;
        _compareStartedAt = null;
        _compareAmplitude = null;
        _activeRecordingFocusLine = null;
      });
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Kayit tamamlanamadi. Tekrar dene.',
              'The recording could not be completed. Try again.',
            ),
          ),
        ),
      );
      return null;
    }

    final focusLine = (_activeRecordingFocusLine ??
            _pronunciationSpotForGoal(_goal).focusLine)
        .trim();
    final transcript =
        _liveTranscript.trim().isNotEmpty ? _liveTranscript.trim() : focusLine;
    final analysis = ScoreCalculator.analyzeRecording(
      streak: _streak,
      weeklySessions: _weeklySessions,
      elapsedSeconds: elapsed,
      maxAmplitude: _compareAmplitude?.max ?? -42.0,
      practiceModeId: _practiceMode.id,
      transcript: transcript,
      focusLine: focusLine,
    );

    final session = SpeakCoachCompareSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goalId: _goal.id,
      practiceModeId: _practiceMode.id,
      focusLine: focusLine,
      audioPath: audioPath!,
      durationSeconds: elapsed,
      clarityScore: analysis.clarity,
      rhythmScore: analysis.rhythm,
      confidenceScore: analysis.confidence,
      transcript: transcript,
      rewrittenTranscript: analysis.rewrittenTranscript,
      errorTags: analysis.errorTagScores.keys.toList(growable: false),
      errorTagScores: analysis.errorTagScores,
      createdAtIso: DateTime.now().toIso8601String(),
    );

    final next = [session, ..._localState.compareSessions]
        .take(10)
        .toList(growable: false);

    setState(() {
      _recordingCompare = false;
      _compareStartedAt = null;
      _compareAmplitude = null;
      _activeRecordingFocusLine = null;
      _lastRecordedAudioPath = audioPath;
      _liveTranscript = '';
    });
    await _saveLocalState(_localState.copyWith(compareSessions: next));
    await _logEvent('record_completed', properties: {
      'goal': _goal.id,
      'mode': _practiceMode.id,
      'clarity': '${analysis.clarity}',
      'rhythm': '${analysis.rhythm}',
      'confidence': '${analysis.confidence}',
    });
    await _triggerBehavioralPush(
      triggerId: 'record_completed',
      titleTr: 'Harika ilerleme',
      bodyTr: 'Bugunku akisi tamamladin. 1 mini tur daha yapip skoru sabitle.',
      titleEn: 'Great progress',
      bodyEn:
          'You completed today\'s flow. Add one more mini round to lock the score.',
      cooldown: const Duration(hours: 18),
      route: '/start-speaking',
    );
    await _recordActivity(
      'compare_saved',
      AppStrings.code == 'tr'
          ? 'Yeni compare sonucu kaydedildi'
          : 'A new compare result was saved',
    );
    if (!mounted) return session;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _copy(
            'Yeni speaking kaydi compare listesine eklendi.',
            'A new speaking record was added to the compare list.',
          ),
        ),
      ),
    );
    _nudgeFreeTrial();
    return session;
  }

  Future<AudioEncoder?> _resolveCompareEncoder() async {
    const candidates = [
      AudioEncoder.aacLc,
      AudioEncoder.opus,
      AudioEncoder.wav,
    ];
    for (final encoder in candidates) {
      if (await _audioRecorder.isEncoderSupported(encoder)) {
        return encoder;
      }
    }
    return null;
  }

  Future<String> _buildCompareOutputPath(AudioEncoder encoder) async {
    final extension = switch (encoder) {
      AudioEncoder.aacLc => 'm4a',
      AudioEncoder.opus => 'opus',
      _ => 'wav',
    };
    if (!kIsWeb) {
      final directory = await getTemporaryDirectory();
      return '${directory.path}/compare-${DateTime.now().millisecondsSinceEpoch}.$extension';
    }
    return 'compare-${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  Future<void> _playCompareSession(SpeakCoachCompareSession session) async {
    final audioPath = session.audioPath.trim();
    if (audioPath.isEmpty || _audioBusy) return;

    setState(() {
      _audioBusy = true;
      _activePlaybackSessionId = session.id;
    });

    try {
      await _audioPlayer.stop();
      if (_isRemoteAudioPath(audioPath)) {
        await _audioPlayer.setUrl(audioPath);
      } else {
        await _audioPlayer.setFilePath(audioPath);
      }
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _copy(
              'Kayit oynatilamadi. Dosya artik mevcut olmayabilir.',
              'The recording could not be played. The file may no longer be available.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _audioBusy = false;
          _activePlaybackSessionId = null;
        });
      }
    }
  }

  Future<void> _replayLastRecording() async {
    final latest = _compareSessions.isNotEmpty ? _compareSessions.first : null;
    if (latest != null) {
      await _playCompareSession(latest);
      return;
    }

    final path = (_lastRecordedAudioPath ?? '').trim();
    if (path.isEmpty || _audioBusy) return;

    setState(() {
      _audioBusy = true;
      _activePlaybackSessionId = 'latest-preview';
    });
    try {
      await _audioPlayer.stop();
      if (_isRemoteAudioPath(path)) {
        await _audioPlayer.setUrl(path);
      } else {
        await _audioPlayer.setFilePath(path);
      }
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } finally {
      if (mounted) {
        setState(() {
          _audioBusy = false;
          _activePlaybackSessionId = null;
        });
      }
    }
  }

  bool _isRemoteAudioPath(String path) {
    final uri = Uri.tryParse(path);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    return scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'blob' ||
        scheme == 'data';
  }

  Future<bool> _hasAuthToken() async {
    final token = await SecureStorage.getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<bool> _ensurePremiumGate({
    required String title,
    required String detail,
  }) async {
    if (await _hasAuthToken()) return true;
    final growth = _growthDecision;
    await _logEvent('paywall_shown', properties: {
      'segment': growth?.segmentId ?? 'unknown',
      'experiment': growth?.experimentId ?? 'unknown',
    });
    if (!mounted) return false;
    final allow = await _showAdaptiveBottomSheet<bool>(
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(detail, style: Theme.of(context).textTheme.bodyLarge),
                if ((growth?.paywallMessage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    growth!.paywallMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child:
                        Text(AppStrings.code == 'tr' ? 'Giris yap' : 'Log in'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child:
                        Text(AppStrings.code == 'tr' ? 'Daha sonra' : 'Later'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (allow == true && mounted) {
      Navigator.pushNamed(context, '/login');
    }
    return false;
  }

  Future<void> _recordActivity(String type, String title) async {
    final next = [
      SpeakCoachActivityEntry(
        type: type,
        title: title,
        timestampIso: DateTime.now().toIso8601String(),
      ),
      ..._localState.activityLog,
    ].take(12).toList(growable: false);

    await _saveLocalState(_localState.copyWith(activityLog: next));
  }

  Future<void> _toggleFavoriteTutor(InstructorSummary instructor) async {
    if (!await _ensurePremiumGate(
      title: _copy(
        'Favoriler giris ister',
        'Saving tutors requires login',
      ),
      detail: _copy(
        'Hocalari kaydedip sonra donmek icin giris yap.',
        'Log in to save tutors and come back later.',
      ),
    )) {
      return;
    }
    final current = List<int>.from(_localState.favoriteInstructorIds);
    if (current.contains(instructor.id)) {
      current.remove(instructor.id);
      await _recordActivity(
        'favorite_removed',
        AppStrings.code == 'tr'
            ? '${instructor.name} favorilerden cikarildi'
            : '${instructor.name} was removed from saved tutors',
      );
    } else {
      current.add(instructor.id);
      await _recordActivity(
        'favorite',
        AppStrings.code == 'tr'
            ? '${instructor.name} favorilere eklendi'
            : '${instructor.name} was saved',
      );
    }
    await _saveLocalState(_localState.copyWith(favoriteInstructorIds: current));
  }

  Future<void> _toggleSavedPhrase(String phrase) async {
    final trimmed = phrase.trim();
    if (trimmed.isEmpty) return;
    final current = List<String>.from(_localState.savedPhrases);
    if (current.contains(trimmed)) {
      current.remove(trimmed);
      await _recordActivity(
        'phrase_removed',
        AppStrings.code == 'tr'
            ? 'Phrasebook icinden bir ifade kaldirildi'
            : 'A phrase was removed from the phrasebook',
      );
    } else {
      current.insert(0, trimmed);
      final deduped = <String>[];
      for (final item in current) {
        if (!deduped.contains(item)) deduped.add(item);
      }
      current
        ..clear()
        ..addAll(deduped.take(16));
      await _recordActivity(
        'phrase_saved',
        AppStrings.code == 'tr'
            ? 'Phrasebook icine yeni ifade eklendi'
            : 'A new phrase was added to the phrasebook',
      );
    }
    await _saveLocalState(_localState.copyWith(savedPhrases: current));
  }

  Future<void> _startChallenge() async {
    await _saveLocalState(
      _localState.copyWith(
        challengeStartDate:
            DateUtils.dateOnly(DateTime.now()).toIso8601String(),
      ),
    );
    await _recordActivity(
      'challenge',
      AppStrings.code == 'tr'
          ? '7 gunluk challenge basladi'
          : '7-day challenge started',
    );
  }

  Future<void> _copyReferralCode() async {
    final code = _localState.referralCode.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    await _logEvent(
      'referral_copied',
      properties: {
        'segment': _growthDecision?.segmentId ?? 'unknown',
        'experiment': _growthDecision?.experimentId ?? 'unknown',
      },
    );
    await _recordActivity(
      'referral_copy',
      AppStrings.code == 'tr'
          ? 'Referral kodu kopyalandi'
          : 'Referral code copied',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _copy('Kod panoya kopyalandi.', 'Code copied to clipboard.'),
        ),
      ),
    );
  }

  Future<void> _copyReferralInvite() async {
    final code = _localState.referralCode.trim();
    if (code.isEmpty) return;
    final message = _copy(
      'Skillgro ile speaking calisiyorum. Bu kodla katil: $code',
      'I am practicing speaking on Skillgro. Join with this code: $code',
    );
    await Clipboard.setData(ClipboardData(text: message));
    await _logEvent(
      'referral_invite_copied',
      properties: {
        'segment': _growthDecision?.segmentId ?? 'unknown',
        'experiment': _growthDecision?.experimentId ?? 'unknown',
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _copy(
            'Davet mesaji panoya kopyalandi.',
            'Invite message copied to clipboard.',
          ),
        ),
      ),
    );
  }

  String _activityTimeLabel(SpeakCoachActivityEntry entry) {
    final parsed = DateTime.tryParse(entry.timestampIso);
    if (parsed == null) return '-';
    final difference = DateTime.now().difference(parsed.toLocal());
    if (difference.inMinutes < 1) {
      return _copy('Simdi', 'Now');
    }
    if (difference.inHours < 1) {
      return _copy(
        '${difference.inMinutes} dk once',
        '${difference.inMinutes}m ago',
      );
    }
    if (difference.inDays < 1) {
      return _copy(
        '${difference.inHours} sa once',
        '${difference.inHours}h ago',
      );
    }
    return _copy(
      '${difference.inDays} gun once',
      '${difference.inDays}d ago',
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bootstrap = await _repository.load();
      if (!mounted) return;
      setState(() {
        _localState = bootstrap.localState;
        _instructors = bootstrap.instructors;
        _loading = false;
      });
      var synced = 0;
      SpeakingCoachFunnelReport? backendFunnel;
      GrowthPolicyDecision? growthDecision;

      try {
        synced = await _analyticsSync.syncPendingEvents();
      } catch (_) {}

      try {
        backendFunnel = await _publicRepository.fetchSpeakingCoachFunnel();
      } catch (_) {}

      try {
        growthDecision = await _growthPolicy.speakingCoachDecision(
          weeklySessions: _weeklySessions,
          isTurkish: AppStrings.code == 'tr',
          remoteConfig:
              bootstrap.settings?.growthConfig ?? const <String, dynamic>{},
        );
      } catch (_) {}

      if (mounted) {
        setState(() {
          _growthDecision = growthDecision;
          _backendFunnelReport = backendFunnel;
          _lastSyncedEventCount = synced;
        });
        if (growthDecision?.aggressiveNudge == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _nudgeFreeTrial();
          });
        }
      }
      try {
        await _logEvent('speaking_opened', properties: {'goal': _goal.id});
      } catch (_) {}
      if ((_localState.referralCode).trim().isEmpty) {
        try {
          await _saveLocalState(
            _localState.copyWith(
                referralCode: generateSpeakCoachReferralCode()),
          );
        } catch (_) {}
      }
      _loadAvailability();
      var hasPendingBookingIntent = false;
      try {
        hasPendingBookingIntent = await _consumeTrialBookingIntent();
      } catch (_) {}
      if (hasPendingBookingIntent &&
          _matchedInstructors.isNotEmpty &&
          mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showBookingBridgePrompt();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadAvailability() async {
    if (_featuredInstructors.isEmpty) return;
    setState(() => _loadingAvailability = true);
    var usedCache = false;
    final results = await Future.wait(
      _featuredInstructors.map((instructor) async {
        final result =
            await _repository.fetchAvailabilityWithFallback(instructor.id);
        if (result.fromCache) {
          usedCache = true;
        }
        return MapEntry(instructor.id, result.snapshot);
      }),
    );
    final pendingRetryCount = await _repository.pendingAvailabilityRetryCount();
    if (!mounted) return;
    setState(() {
      for (final result in results) {
        _availability[result.key] = result.value;
      }
      _loadingAvailability = false;
      _availabilityUsingCache = usedCache;
      _pendingAvailabilityRetryCount = pendingRetryCount;
    });
    if (!usedCache) {
      await _repository.flushAvailabilityRetryQueue();
      if (!mounted) return;
      final nextPending = await _repository.pendingAvailabilityRetryCount();
      if (!mounted) return;
      setState(() => _pendingAvailabilityRetryCount = nextPending);
    }
  }

  Future<void> _toggleTask(String taskId) async {
    final wasDone = _completedToday.contains(taskId);
    final completed = Map<String, List<String>>.fromEntries(
      _localState.completedMissionIdsByDate.entries.map(
        (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
      ),
    );
    final todayItems = List<String>.from(
      completed[_todayKey] ?? const <String>[],
    );
    if (todayItems.contains(taskId)) {
      todayItems.remove(taskId);
    } else {
      todayItems.add(taskId);
    }
    if (todayItems.isEmpty) {
      completed.remove(_todayKey);
    } else {
      completed[_todayKey] = todayItems;
    }
    final activeDates = List<String>.from(_localState.activeDates);
    if (todayItems.isEmpty) {
      activeDates.remove(_todayKey);
    } else if (!activeDates.contains(_todayKey)) {
      activeDates.add(_todayKey);
    }
    await _saveLocalState(
      _localState.copyWith(
        activeDates: activeDates,
        completedMissionIdsByDate: completed,
      ),
    );
    if (!wasDone && mounted) {
      _showTaskSuccess(taskId);
      _nudgeFreeTrial();
    }
  }

  Future<void> _markTaskDone(String taskId) async {
    if (_completedToday.contains(taskId)) return;
    await _toggleTask(taskId);
  }

  Future<void> _openPlacement() async {
    await _tapFeedback();
    await _markTaskDone('placement');
    await _recordActivity(
      'placement',
      AppStrings.code == 'tr' ? 'Seviye testi acildi' : 'Level test opened',
    );
    if (!mounted) return;
    Navigator.pushNamed(context, '/placement-test');
  }

  Future<void> _openTrial() async {
    await _tapFeedback();
    await _logEvent('trial_cta_tapped', properties: {'goal': _goal.id});
    await _recordActivity(
      'trial',
      AppStrings.code == 'tr'
          ? 'Ucretsiz deneme CTA acildi'
          : 'Free trial CTA opened',
    );
    if (!mounted) return;
    await requestTrialLessonWithLoginGate(
      context,
      submitRequest: () async {
        final result = await _publicRepository.requestTrialLesson();
        await _logEvent('trial_requested', properties: {'goal': _goal.id});
        await _setTrialBookingIntent();
        await _triggerBehavioralPush(
          triggerId: 'trial_requested',
          titleTr: 'Deneme dersi hazir',
          bodyTr: 'Rezervasyon ekranina gecip ilk slotu sec.',
          titleEn: 'Trial lesson is ready',
          bodyEn: 'Open booking and pick your first slot.',
          cooldown: const Duration(hours: 12),
          route: '/start-speaking',
        );
        return TrialLessonActionResult(
          message: result.message,
          supportUrl: result.whatsappUrl,
        );
      },
    );
    if (!mounted) return;
    _showBookingBridgePrompt();
  }

  Future<void> _showBookingBridgePrompt() async {
    final bestTutor =
        _matchedInstructors.isNotEmpty ? _matchedInstructors.first : null;
    if (bestTutor == null || !mounted) return;
    final isTr = AppStrings.code == 'tr';
    final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              isTr ? 'Ilk dersi kilitle' : 'Lock first lesson',
            ),
            content: Text(
              isTr
                  ? 'Deneme dersini tamamlamak icin ${bestTutor.name} ile ilk rezervasyon adimina gec.'
                  : 'To complete your trial flow, continue to the first booking step with ${bestTutor.name}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(isTr ? 'Daha sonra' : 'Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(isTr ? 'Rezervasyona gec' : 'Go to booking'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted || !shouldOpen) return;
    await _logEvent('booking_started',
        properties: {'instructor_id': '${bestTutor.id}'});
    await _triggerBehavioralPush(
      triggerId: 'booking_started',
      titleTr: 'Rezervasyon adimi acik',
      bodyTr: '${bestTutor.name} icin uygun saati secip kaydet.',
      titleEn: 'Booking step is open',
      bodyEn: 'Choose a time with ${bestTutor.name} and confirm it.',
      cooldown: const Duration(hours: 10),
      route: '/student',
    );
    _openTutorProfile(bestTutor);
  }

  void _openTutors() {
    _openTutorsAsync();
  }

  Future<void> _openTutorsAsync() async {
    await _tapFeedback();
    if (!await _ensurePremiumGate(
      title: _copy('Tutor listesi giris ister', 'Tutor list requires login'),
      detail: _copy(
        'Mini gorevler acik kalir. Hoca secimi ve rezervasyon icin giris yap.',
        'Mini tasks stay open. Log in to pick tutors and book lessons.',
      ),
    )) {
      return;
    }
    await _recordActivity(
      'tutors',
      AppStrings.code == 'tr' ? 'Tutor listesi acildi' : 'Tutor list opened',
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentInstructorsScreen(standalone: true),
      ),
    );
  }

  void _openTutorProfile(InstructorSummary instructor) {
    _openTutorProfileAsync(instructor);
  }

  Future<void> _openTutorProfileAsync(InstructorSummary instructor) async {
    await _tapFeedback();
    if (!await _ensurePremiumGate(
      title:
          _copy('Tutor profilleri giris ister', 'Tutor profiles require login'),
      detail: _copy(
        'Ilk mini paket ve tekrar acik. Hoca profili, favori ve rezervasyon icin giris yap.',
        'The first mini pack and review are open. Log in for tutor profiles, favorites, and booking.',
      ),
    )) {
      return;
    }
    await _recordActivity(
      'tutor_view',
      AppStrings.code == 'tr'
          ? '${instructor.name} profili incelendi'
          : '${instructor.name} profile viewed',
    );
    if (!mounted) return;
    final role = instructor.jobTitle.isNotEmpty
        ? instructor.jobTitle
        : AppStrings.t('Instructor');
    final about =
        instructor.shortBio.isNotEmpty ? instructor.shortBio : instructor.bio;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentInstructorDetailScreen(
          data: InstructorCardData(
            id: instructor.id,
            name: instructor.name,
            role: role,
            tags: instructor.tags,
            about: about,
            rating: instructor.avgRating,
            imageUrl: instructor.imageUrl,
          ),
        ),
      ),
    );
  }

  Future<void> _openPlannerSheet({bool initial = false}) async {
    var goalId = _localState.goalId;
    var weeklyTarget = _localState.weeklyTarget;
    var scheduleId = _localState.scheduleId;
    final result = await _showAdaptiveBottomSheet<PlannerResult>(
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      initial
                          ? _copy('Planini kur', 'Build your plan')
                          : _copy(
                              'Calisma planini duzenle', 'Adjust your plan'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _goals.map((goal) {
                        return ChoiceChip(
                          label: Text(
                            AppStrings.code == 'tr'
                                ? goal.titleTr
                                : goal.titleEn,
                          ),
                          selected: goal.id == goalId,
                          onSelected: (_) {
                            setModalState(() => goalId = goal.id);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _targets.map((target) {
                        return ChoiceChip(
                          label: Text(
                            AppStrings.code == 'tr'
                                ? target.labelTr
                                : target.labelEn,
                          ),
                          selected: target.value == weeklyTarget,
                          onSelected: (_) {
                            setModalState(() => weeklyTarget = target.value);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Column(
                      children: _schedules.map((schedule) {
                        final selected = schedule.id == scheduleId;
                        return ListTile(
                          onTap: () =>
                              setModalState(() => scheduleId = schedule.id),
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: selected ? AppColors.brand : AppColors.muted,
                          ),
                          title: Text(
                            AppStrings.code == 'tr'
                                ? schedule.titleTr
                                : schedule.titleEn,
                          ),
                          subtitle: Text(schedule.detail),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            PlannerResult(goalId, scheduleId, weeklyTarget),
                          );
                        },
                        child: Text(_copy('Plani kaydet', 'Save plan')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (result == null) return;
    await _saveLocalState(
      _localState.copyWith(
        goalId: result.goalId,
        scheduleId: result.scheduleId,
        weeklyTarget: result.weeklyTarget,
      ),
    );
  }

  Future<void> _openPackSheet(StudyPack pack) async {
    final defaultPack = _packsForGoal(_goal).first.id;
    if (pack.id != defaultPack &&
        !await _ensurePremiumGate(
          title: _copy('Ek paketler giris ister', 'Extra packs require login'),
          detail: _copy(
            'Ilk mini paket acik. Diger paketler ve tam rutin icin giris yap.',
            'The first mini pack is open. Log in for extra packs and the full routine.',
          ),
        )) {
      return;
    }
    await _markTaskDone('pack');
    await _recordActivity(
      'pack',
      AppStrings.code == 'tr'
          ? '${pack.titleTr} acildi'
          : '${pack.titleEn} opened',
    );
    if (!mounted) return;
    await _showAdaptiveBottomSheet<void>(
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.code == 'tr' ? pack.titleTr : pack.titleEn,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        for (final phrase in pack.phrases.take(4)) {
                          await _toggleSavedPhrase(phrase);
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _copy(
                                'Paket ifadeleri phrasebook icine eklendi.',
                                'Pack phrases were added to your phrasebook.',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bookmark_add_rounded),
                      label: Text(
                        _copy('Ifadeleri kaydet', 'Save phrases'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...pack.phrases.map(
                    (phrase) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SheetPhraseTile(phrase),
                    ),
                  ),
                  _SheetBlock(pack.dialogue),
                  const SizedBox(height: 10),
                  _SheetBlock(
                      AppStrings.code == 'tr' ? pack.note : pack.noteEn),
                ],
              ),
            ),
          ),
        );
      },
    );
    _nudgeFreeTrial();
  }

  Future<void> _openReviewSheet(ReviewCard card) async {
    final defaultReview = _reviewCardsForGoal(_goal).first.phrase;
    if (card.phrase != defaultReview &&
        !await _ensurePremiumGate(
          title: _copy('Ek tekrar kartlari giris ister',
              'Extra review cards require login'),
          detail: _copy(
            'Ilk review deck acik. Tum tekrar seti icin giris yap.',
            'The first review deck is open. Log in for the full review set.',
          ),
        )) {
      return;
    }
    await _markTaskDone('review');
    await _recordActivity(
      'review',
      AppStrings.code == 'tr'
          ? '${card.titleTr} acildi'
          : '${card.titleEn} opened',
    );
    if (!mounted) return;
    await _showAdaptiveBottomSheet<void>(
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.code == 'tr' ? card.titleTr : card.titleEn,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleSavedPhrase(card.phrase),
                      icon: Icon(
                        _localState.savedPhrases.contains(card.phrase)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SheetBlock(card.phrase),
                const SizedBox(height: 10),
                _SheetBlock(
                    AppStrings.code == 'tr' ? card.meaningTr : card.meaningEn),
                const SizedBox(height: 10),
                _SheetBlock(
                    AppStrings.code == 'tr' ? card.usageTr : card.usageEn),
              ],
            ),
          ),
        );
      },
    );
    _nudgeFreeTrial();
  }

  Future<void> _openPackLibrarySheet(List<StudyPack> packs) async {
    if (!mounted) return;
    await _showAdaptiveBottomSheet<void>(
      isScrollControlled: true,
      builder: (context) {
        final isTr = AppStrings.code == 'tr';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Tum mini paketler' : 'All mini packs',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Ana yuzey kisa kalsin diye tum paketleri burada tutuyorum.'
                        : 'The full pack library lives here so the home surface stays short.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...packs.map((pack) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PackCard(
                        _PackCardData(
                          title: isTr ? pack.titleTr : pack.titleEn,
                          subtitle: isTr ? pack.subtitleTr : pack.subtitleEn,
                          durationLabel: pack.durationLabel,
                          icon: pack.icon,
                          accentColor: pack.accentColor,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _openPackSheet(pack);
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReviewLibrarySheet(List<ReviewCard> reviews) async {
    if (!mounted) return;
    await _showAdaptiveBottomSheet<void>(
      isScrollControlled: true,
      builder: (context) {
        final isTr = AppStrings.code == 'tr';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Tum review kartlari' : 'All review cards',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Review alanini kisaltip tam listeyi bu sheet icine aldım.'
                        : 'The review surface is condensed and the full list is available in this sheet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...reviews.map((card) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewDeckCard(
                        ReviewCardData(
                          title: isTr ? card.titleTr : card.titleEn,
                          phrase: card.phrase,
                          meaning: isTr ? card.meaningTr : card.meaningEn,
                          usage: isTr ? card.usageTr : card.usageEn,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _openReviewSheet(card);
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTaskSuccess(String taskId) {
    final isTr = AppStrings.code == 'tr';
    final packs = _packsForGoal(_goal);
    final reviews = _reviewCardsForGoal(_goal);

    final spec = switch (taskId) {
      'placement' => CompletionSpec(
          title: isTr
              ? 'Baslangic noktasi netlesti'
              : 'Your starting point is set',
          detail: isTr
              ? 'Simdi bugunun mini paketine gecip ritmi kur.'
              : 'Now move into today\'s mini pack and build the rhythm.',
          primaryLabel: isTr ? 'Mini paketi ac' : 'Open mini pack',
          primaryAction: () => _openPackSheet(packs.first),
          secondaryLabel: isTr ? 'Plani duzenle' : 'Adjust plan',
          secondaryAction: () => _openPlannerSheet(),
        ),
      'review' => CompletionSpec(
          title: isTr ? 'Tekrar tamamlandi' : 'Review completed',
          detail: isTr
              ? 'Siradaki en mantikli adim uygun hoca secmek veya ucretsiz deneme istemek.'
              : 'The best next step is picking a tutor or requesting a free trial.',
          primaryLabel: _trialCtaLabel,
          primaryAction: _openTrial,
          secondaryLabel: isTr ? 'Uygun hocalari ac' : 'Open tutors',
          secondaryAction: _openTutors,
        ),
      _ => CompletionSpec(
          title: isTr ? 'Gunluk gorev tamamlandi' : 'Daily task completed',
          detail: isTr
              ? 'Bir adim daha attin. Simdi tekrar destesiyle pekistir veya hocaya gec.'
              : 'You moved one step forward. Reinforce it with the review deck or move to a tutor.',
          primaryLabel: isTr ? 'Tekrar kartlarini ac' : 'Open review cards',
          primaryAction: () => _openReviewSheet(reviews.first),
          secondaryLabel: isTr ? 'Uygun hocalari ac' : 'Open tutors',
          secondaryAction: _openTutors,
        ),
    };

    _showAdaptiveBottomSheet<void>(
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        spec.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(spec.detail, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      spec.primaryAction();
                    },
                    child: Text(spec.primaryLabel),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      spec.secondaryAction();
                    },
                    child: Text(spec.secondaryLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _availabilityLabel(InstructorSummary instructor) {
    final snapshot = _availability[instructor.id];
    if (snapshot == null) {
      return _loadingAvailability
          ? _copy('Takvim yukleniyor', 'Loading schedule')
          : _copy('Takvim hazirlaniyor', 'Schedule is loading');
    }
    if (snapshot.todayAvailableCount > 0) {
      return _copy(
        'Bugun ${snapshot.todayAvailableCount} slot acik',
        '${snapshot.todayAvailableCount} slots open today',
      );
    }
    if (snapshot.nextAvailableDate != null &&
        snapshot.nextAvailableDate!.trim().isNotEmpty) {
      return _copy(
        'Siradaki uygunluk ${snapshot.nextAvailableDate}',
        'Next opening ${snapshot.nextAvailableDate}',
      );
    }
    return _copy('Takvim yakinda aciliyor', 'Schedule opens soon');
  }

  int _matchScore(InstructorSummary instructor) {
    final haystack = [
      instructor.jobTitle,
      instructor.shortBio,
      instructor.bio,
      ...instructor.tags,
    ].join(' ').toLowerCase();
    final availability = _availability[instructor.id];
    var score = instructor.avgRating * 10;

    switch (_goal.id) {
      case 'business':
        if (haystack.contains('business')) score += 36;
        if (haystack.contains('meeting')) score += 14;
        if (haystack.contains('presentation')) score += 10;
        break;
      case 'ielts':
        if (haystack.contains('ielts')) score += 36;
        if (haystack.contains('toefl')) score += 24;
        if (haystack.contains('exam')) score += 12;
        break;
      case 'travel':
        if (haystack.contains('speaking')) score += 20;
        if (haystack.contains('conversation')) score += 18;
        if (haystack.contains('general')) score += 10;
        break;
      default:
        if (haystack.contains('speaking')) score += 32;
        if (haystack.contains('conversation')) score += 18;
        if (haystack.contains('general')) score += 10;
        break;
    }

    if ((_schedule.id == 'evening' || _schedule.id == 'afternoon') &&
        availability?.todayAvailableCount != null) {
      score += availability!.todayAvailableCount * 4;
    }

    score += instructor.courseCount.clamp(0, 20).toDouble();
    return score.round();
  }

  List<String> _matchReasons(InstructorSummary instructor) {
    final haystack = [
      instructor.jobTitle,
      instructor.shortBio,
      instructor.bio,
      ...instructor.tags,
    ].join(' ').toLowerCase();
    final availability = _availability[instructor.id];
    final reasons = <String>[];

    switch (_goal.id) {
      case 'business':
        if (haystack.contains('business')) {
          reasons.add(_copy('Is Ingilizcesi odagi', 'Business focus'));
        }
        if (haystack.contains('meeting') || haystack.contains('presentation')) {
          reasons.add(_copy('Toplanti dili deneyimi', 'Meeting language fit'));
        }
        break;
      case 'ielts':
        if (haystack.contains('ielts')) {
          reasons.add(_copy('IELTS speaking uyumu', 'IELTS speaking fit'));
        }
        if (haystack.contains('toefl') || haystack.contains('exam')) {
          reasons.add(_copy('Sinav odakli calisma', 'Exam-focused support'));
        }
        break;
      case 'travel':
        reasons.add(_copy('Pratik konusma akisi', 'Practical speaking flow'));
        break;
      default:
        if (haystack.contains('speaking') ||
            haystack.contains('conversation')) {
          reasons.add(_copy('Speaking odagi', 'Speaking focused'));
        }
        reasons.add(_copy('Gunluk kullanim dili', 'Daily-use language'));
        break;
    }

    if ((availability?.todayAvailableCount ?? 0) > 0) {
      reasons.add(_copy('Bugun uygun slotu var', 'Available today'));
    } else if (availability?.nextAvailableSlotLabel != null &&
        availability!.nextAvailableSlotLabel!.isNotEmpty) {
      reasons.add(
          '${_copy('Siradaki slot', 'Next slot')}: ${availability.nextAvailableSlotLabel}');
    }

    if (instructor.avgRating > 0) {
      reasons.add('${instructor.avgRating.toStringAsFixed(1)} ★');
    }

    return reasons.take(3).toList(growable: false);
  }

  List<Widget> _buildCompactSections(
    BuildContext context, {
    required bool isTr,
    required bool includeTopBar,
    required List<StudyPack> packs,
    required List<ReviewCard> reviews,
    required PronunciationSpot spot,
    required double todayProgress,
    required List<InstructorSummary> matchedPreview,
    required List<ProofMetric> proofPreview,
    required StudyPack firstPack,
    required ReviewCard firstReview,
  }) {
    final sections = [
      if (includeTopBar) ...[
        _TopBar(
          onOpenPlan: _openPlannerSheet,
          onLogin: () => Navigator.pushNamed(context, '/login'),
        ),
        const SizedBox(height: 18),
      ],
      _HeroCard(
        goal: _goal,
        streak: _streak,
        weeklySessions: _weeklySessions,
        weeklyTarget: _localState.weeklyTarget,
        todayProgress: todayProgress,
        onOpenPlan: _openPlannerSheet,
        onOpenPlacement: _openPlacement,
        onOpenTrial: _openTrial,
        goalChips: _goals.map((goal) {
          return _GoalChip(
            label: isTr ? goal.titleTr : goal.titleEn,
            selected: goal.id == _goal.id,
            icon: goal.icon,
            onTap: () => _setGoal(goal.id),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
      _PlannerSummaryCard(
        scheduleLabel: isTr ? _schedule.titleTr : _schedule.titleEn,
        scheduleDetail: _schedule.detail,
        reminderLabel: isTr ? _reminder.titleTr : _reminder.titleEn,
        weeklyTarget: _localState.weeklyTarget,
        onEdit: _openPlannerSheet,
      ),
      const SizedBox(height: 18),
      _SectionCard(
        title:
            isTr ? 'Canli speaking geri bildirimi' : 'Live speaking feedback',
        subtitle: isTr
            ? 'Son kaydina gore netlik, ritim ve guven durumunu tek ekranda gor.'
            : 'See clarity, rhythm, and confidence from your latest speaking take.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureGuideCard(
              icon: Icons.auto_graph_rounded,
              accentColor: AppColors.brand,
              title: isTr ? 'Bu blok neyi gosterir?' : 'What this block shows',
              detail: isTr
                  ? 'Son kaydinin netlik, ritim ve guven skorunu aninda gorursun.'
                  : 'You instantly see clarity, rhythm, and confidence from your last take.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _liveFeedbackMetrics
                  .map((metric) => _FeedbackMeter(metric: metric))
                  .toList(),
            ),
            const SizedBox(height: 14),
            _SentenceFixCard(
              title: isTr ? 'Cumle duzeltme' : 'Sentence refinement',
              yourLine: _asrTranscript,
              naturalLine: _rewrittenTranscript,
              note: isTr
                  ? 'Ipucu: once ana fiili net soyle, sonra nedeni tek cumlede bagla.'
                  : 'Tip: land the core verb first, then connect the reason in one clean sentence.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _latestErrorTagScores.entries
                  .map(
                    (entry) => _ErrorTagChip(
                      label:
                          '${entry.key.replaceAll('_', ' ')} ${entry.value}%',
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleCompareRecording,
                icon: const Icon(Icons.multitrack_audio_rounded),
                label: Text(
                  _recordingCompare
                      ? (isTr ? 'Kaydi bitir' : 'Finish recording')
                      : (isTr
                          ? 'Canli feedback icin kaydet'
                          : 'Record for live feedback'),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _SectionCard(
        title: isTr ? 'Bugunun akisi' : 'Today flow',
        subtitle: isTr
            ? 'Challenge, bugunluk gorev ve canli gecis ayni blokta.'
            : 'Challenge, today tasks, and live conversion are grouped in one block.',
        action: TextButton(
          onPressed: _challengeStarted ? _openPlacement : _startChallenge,
          child: Text(
            !_challengeStarted
                ? (isTr ? 'Challenge baslat' : 'Start challenge')
                : (isTr ? 'Seviyeni gor' : 'See level'),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureGuideCard(
              icon: Icons.flag_circle_rounded,
              accentColor: const Color(0xFF0F766E),
              title: isTr ? 'Ne yapacaksin?' : 'What you do here',
              detail: isTr
                  ? 'Bugun 3 kisa gorevi kapat, sonra tutor veya deneme dersine gec.'
                  : 'Close 3 short tasks today, then move to tutors or a free trial.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: proofPreview
                  .map((metric) => _ProofPill(metric: metric))
                  .toList(),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: todayProgress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 12),
            Text(
              !_challengeStarted
                  ? _copy(
                      '7 gun boyunca mini paket, tekrar ve tutor ritmini kur.',
                      'Build a 7-day rhythm with mini packs, reviews, and tutors.',
                    )
                  : _challengeCompleted
                      ? _copy(
                          'Challenge tamamlandi. Seviye ozetini acip uygun hocaya gec.',
                          'Challenge is complete. Open the level summary and move to the right tutor.',
                        )
                      : _copy(
                          'Gun $_challengeProgressDays / 7 aktif. Bugunun 3 kisa adimini kapat.',
                          'Day $_challengeProgressDays / 7 is active. Close today\'s 3 short steps.',
                        ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            ..._todayTasks.take(3).map((task) {
              final done = _completedToday.contains(task.id);
              final onOpen = task.id == 'placement'
                  ? _openPlacement
                  : task.id == 'review'
                      ? () => _openReviewSheet(firstReview)
                      : () => _openPackSheet(firstPack);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(
                  _TaskTileData(
                    title: isTr ? task.titleTr : task.titleEn,
                    detail: isTr ? task.detailTr : task.detailEn,
                    durationLabel: task.durationLabel,
                    icon: task.icon,
                    done: done,
                    buttonLabel: isTr ? task.buttonTr : task.buttonEn,
                    onOpen: onOpen,
                    onToggleDone: () => _toggleTask(task.id),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openTutors,
                    icon: const Icon(Icons.groups_2_rounded),
                    label: Text(isTr ? 'Tutor onerileri' : 'Tutor picks'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openTrial,
                    icon: const Icon(Icons.headset_mic_rounded),
                    label: Text(isTr ? 'Deneme dersi' : 'Free trial'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _SectionCard(
        title: isTr ? 'Pratik merkezi' : 'Practice hub',
        subtitle: isTr
            ? 'Mod secimi, paketler ve review ayni merkezde.'
            : 'Mode selection, packs, and reviews live in one hub.',
        action: TextButton(
          onPressed: () => _openPackLibrarySheet(packs),
          child: Text(isTr ? 'Tum paketler' : 'All packs'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureGuideCard(
              icon: Icons.bolt_rounded,
              accentColor: const Color(0xFFB45309),
              title: isTr ? 'Buradan basla' : 'Start here',
              detail: isTr
                  ? 'Modunu sec, mini paketi ac, review ile tekrar et.'
                  : 'Pick a mode, open a mini pack, and reinforce it with review.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _practiceModes.map((mode) {
                final selected = mode.id == _practiceMode.id;
                return _GoalChip(
                  label: isTr ? mode.titleTr : mode.titleEn,
                  selected: selected,
                  icon: mode.icon,
                  onTap: () => _setPracticeMode(mode.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PackCard(
                    _PackCardData(
                      title: isTr ? firstPack.titleTr : firstPack.titleEn,
                      subtitle:
                          isTr ? firstPack.subtitleTr : firstPack.subtitleEn,
                      durationLabel: firstPack.durationLabel,
                      icon: firstPack.icon,
                      accentColor: firstPack.accentColor,
                      onTap: () => _openPackSheet(firstPack),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReviewDeckCard(
                    ReviewCardData(
                      title: isTr ? firstReview.titleTr : firstReview.titleEn,
                      phrase: firstReview.phrase,
                      meaning:
                          isTr ? firstReview.meaningTr : firstReview.meaningEn,
                      usage: isTr ? firstReview.usageTr : firstReview.usageEn,
                      onTap: () => _openReviewSheet(firstReview),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openReviewLibrarySheet(reviews),
                    child:
                        Text(isTr ? 'Tum review kartlari' : 'All review cards'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _setPracticeMode('clarity'),
                    child: const Text('Clarity drill'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _pronunciationMetricsForGoal(_goal)
                  .map((metric) => _ProofPill(metric: metric))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.focusLine,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr ? spot.helperTr : spot.helperEn,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _buildCompactRecordSection(context, isTr: isTr, spot: spot),
      const SizedBox(height: 18),
      _SectionCard(
        title: isTr ? 'Mini challenge gorevleri' : 'Mini challenge drills',
        subtitle: isTr
            ? 'Kisa, odakli ve tamamlamasi kolay 3 speaking gorevi.'
            : 'Three short speaking drills designed for fast daily wins.',
        child: Column(
          children: _microChallenges.map((task) {
            final onTap = switch (task.id) {
              'challenge_speed' => () => _setPracticeMode('speed'),
              'challenge_tutor' => _openTutors,
              _ => _toggleCompareRecording,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MiniChallengeCard(
                title: isTr ? task.titleTr : task.titleEn,
                detail: isTr ? task.detailTr : task.detailEn,
                durationLabel: task.durationLabel,
                icon: task.icon,
                ctaLabel: isTr ? task.buttonTr : task.buttonEn,
                onTap: onTap,
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 18),
      _SectionCard(
        title: isTr ? 'Haftalik speaking raporu' : 'Weekly speaking report',
        subtitle: isTr
            ? 'Son 7 gunde kayit performansi ve hata dagilimi.'
            : 'Recording performance and error distribution for the last 7 days.',
        child: _WeeklyReportCard(
          report: _weeklySpeakingReport,
          isTr: isTr,
        ),
      ),
      const SizedBox(height: 18),
      _SectionCard(
        title: isTr ? 'Daha fazlasi' : 'More',
        subtitle: isTr
            ? 'Takvim, tutor eslesmesi ve diger araclar ikinci seviyede.'
            : 'Calendar, tutor matching, and advanced tools are in a second-level panel.',
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openSecondaryHubSheet(
              todayProgress: todayProgress,
              matchedPreview: matchedPreview,
            ),
            icon: const Icon(Icons.layers_rounded),
            label: Text(isTr ? 'Gelismis paneli ac' : 'Open advanced panel'),
          ),
        ),
      ),
    ];

    return List<Widget>.generate(
      sections.length,
      (index) => _AnimatedBlock(
        delayMs: 45 * index,
        child: sections[index],
      ),
    );
  }

  Future<void> _openSecondaryHubSheet({
    required double todayProgress,
    required List<InstructorSummary> matchedPreview,
  }) async {
    final isTr = AppStrings.code == 'tr';
    await _showAdaptiveBottomSheet<void>(
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: ListView(
              shrinkWrap: true,
              physics: Theme.of(context).platform == TargetPlatform.iOS
                  ? const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    )
                  : const ClampingScrollPhysics(),
              children: [
                _buildCompactRhythmSection(
                  context,
                  isTr: isTr,
                  todayProgress: todayProgress,
                  matchedPreview: matchedPreview,
                ),
                const SizedBox(height: 14),
                _buildMoreToolsSection(context, isTr: isTr),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openIOSSecondaryActions() async {
    if (!mounted) return;
    final isTr = AppStrings.code == 'tr';
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(isTr ? 'Hizli islemler' : 'Quick actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _openTrial();
            },
            child: Text(isTr ? 'Ucretsiz deneme dersi' : 'Free trial lesson'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _openTutors();
            },
            child: Text(isTr ? 'Tutorleri ac' : 'Open tutors'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _openPlannerSheet();
            },
            child: Text(isTr ? 'Plan ayarlarini ac' : 'Open plan settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(isTr ? 'Kapat' : 'Close'),
        ),
      ),
    );
  }

  Widget _buildCompactRecordSection(
    BuildContext context, {
    required bool isTr,
    required PronunciationSpot spot,
  }) {
    return _SectionCard(
      title: isTr ? 'Record + compare' : 'Record + compare',
      subtitle: isTr
          ? 'Gercek mikrofon kaydi, replay ve onceki denemeyle karsilastirma.'
          : 'Real microphone capture, replay, and comparison with the previous take.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureGuideCard(
            icon: Icons.mic_rounded,
            accentColor: const Color(0xFF1D4ED8),
            title: isTr ? 'Burada ne olur?' : 'What happens here',
            detail: isTr
                ? 'Kayit al, replay yap, onceki denemeyle karsilastir ve anlik ilerlemeyi hisset.'
                : 'Record, replay, compare with the previous take, and feel progress immediately.',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy('Odak cumlesi', 'Focus line'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  spot.focusLine,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_recordingCompare) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(999),
                    value: (((_compareAmplitude?.current ?? -50) + 50) / 50)
                        .clamp(0.06, 1.0),
                    color: AppColors.brand,
                    backgroundColor: Colors.white,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleCompareRecording,
                        icon: Icon(
                          _recordingCompare
                              ? Icons.stop_circle_rounded
                              : Icons.mic_rounded,
                        ),
                        label: Text(
                          _recordingCompare
                              ? _copy('Kaydi bitir', 'Finish recording')
                              : _copy('Kaydi baslat', 'Start recording'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: (_audioBusy || _compareSessions.isEmpty)
                          ? null
                          : _replayLastRecording,
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(_copy('Replay', 'Replay')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_comparePair.length == 2) ...[
            const SizedBox(height: 14),
            _ComparePairCard(
              latest: _comparePair[0],
              previous: _comparePair[1],
              isTr: isTr,
              activePlaybackSessionId: _activePlaybackSessionId,
              onPlayLatest: () => _playCompareSession(_comparePair[0]),
              onPlayPrevious: () => _playCompareSession(_comparePair[1]),
            ),
          ],
          if (_compareSessions.isNotEmpty) ...[
            const SizedBox(height: 14),
            ..._compareSessions.take(2).map((session) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CompareSessionCard(
                  session: session,
                  isTr: isTr,
                  isPlaying: _activePlaybackSessionId == session.id,
                  onPlay: session.audioPath.trim().isEmpty
                      ? null
                      : () => _playCompareSession(session),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactRhythmSection(
    BuildContext context, {
    required bool isTr,
    required double todayProgress,
    required List<InstructorSummary> matchedPreview,
  }) {
    return _SectionCard(
      title: isTr ? 'Ritim ve tutorler' : 'Rhythm and tutors',
      subtitle: isTr
          ? 'Takvim, sosyal proof ve canli tutor eslesmesini ayni blokta topladim.'
          : 'Calendar rhythm, social proof, and live tutor matching now sit in one block.',
      action: TextButton(
        onPressed: _openTutors,
        child: Text(isTr ? 'Tum tutorler' : 'All tutors'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureGuideCard(
            icon: Icons.insights_rounded,
            accentColor: AppColors.brandNight,
            title: isTr ? 'Bu kisim neyi gosterir?' : 'What this section shows',
            detail: isTr
                ? 'Serini, uygun tutorleri ve bugunun canli firsatlarini tek bakista gorursun.'
                : 'You see your streak, the right tutors, and today’s live opportunities at a glance.',
          ),
          const SizedBox(height: 12),
          _MomentumCard(
            streak: _streak,
            weeklySessions: _weeklySessions,
            weeklyTarget: _localState.weeklyTarget,
            todayProgress: todayProgress,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              _copy(
                'Bugun $_availableTodayCount acik tutor slotu var. $_topGoalLabel.',
                'There are $_availableTodayCount open tutor slots today. $_topGoalLabel.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CalendarSummaryPill(
                  label: _copy('Mevcut seri', 'Current streak'),
                  value: '$_streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CalendarSummaryPill(
                  label: _copy('En iyi seri', 'Best streak'),
                  value: '$_bestStreak',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _calendarDays.map((day) => CalendarDayTile(day: day)).toList(),
          ),
          const SizedBox(height: 14),
          ...matchedPreview.map((instructor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TutorCard(
                _TutorCardData(
                  name: instructor.name,
                  role: instructor.jobTitle.isNotEmpty
                      ? instructor.jobTitle
                      : AppStrings.t('Instructor'),
                  imageUrl: instructor.imageUrl ?? '',
                  tags: _matchReasons(instructor),
                  availabilityLabel: _availabilityLabel(instructor),
                  ctaLabel: isTr ? 'Profili ac' : 'Open profile',
                  isFavorite:
                      _localState.favoriteInstructorIds.contains(instructor.id),
                  onTap: () => _openTutorProfile(instructor),
                  onToggleFavorite: () => _toggleFavoriteTutor(instructor),
                ),
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openTrial,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: Text(
                isTr
                    ? 'Bu ritimle deneme dersi kilitle'
                    : 'Lock a free trial from here',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreToolsSection(BuildContext context, {required bool isTr}) {
    return _SectionCard(
      title: isTr ? 'Diger araclar' : 'More tools',
      subtitle: isTr
          ? 'Ozellikleri silmedim. Derin araclari acilir yuzeylere tasidim.'
          : 'No features were removed. Deeper tools were moved into expandable surfaces.',
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            _FeatureGuideCard(
              icon: Icons.widgets_rounded,
              accentColor: AppColors.brand,
              title: isTr ? 'Ek araclar burada' : 'Extra tools live here',
              detail: isTr
                  ? 'Kaydedilen ifadeler, favori tutorler, reminder ve raporlar bu panelde.'
                  : 'Saved phrases, favorite tutors, reminders, and reports live in this panel.',
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(isTr ? 'Funnel metrikleri' : 'Funnel metrics'),
              subtitle: Text(
                _funnelSnapshot == null
                    ? _copy('Hesaplaniyor', 'Calculating')
                    : _copy(
                        'Acilis ${_funnelSnapshot!.opened} -> Trial ${_funnelSnapshot!.trialRequested}',
                        'Opened ${_funnelSnapshot!.opened} -> Trial ${_funnelSnapshot!.trialRequested}',
                      ),
              ),
              children: [
                if (_funnelSnapshot != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ErrorTagChip(label: 'opened ${_funnelSnapshot!.opened}'),
                      _ErrorTagChip(
                          label: 'start ${_funnelSnapshot!.startedRecord}'),
                      _ErrorTagChip(
                          label:
                              'complete ${_funnelSnapshot!.completedRecord}'),
                      _ErrorTagChip(
                          label: 'tap ${_funnelSnapshot!.trialTapped}'),
                      _ErrorTagChip(
                          label: 'request ${_funnelSnapshot!.trialRequested}'),
                    ],
                  ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(isTr ? 'Growth dashboard' : 'Growth dashboard'),
              subtitle: Text(
                _growthDecision == null
                    ? _copy('Hazirlaniyor', 'Preparing')
                    : _copy(
                        'Segment ${_growthDecision!.segmentId} • Deney ${_growthDecision!.experimentId}',
                        'Segment ${_growthDecision!.segmentId} • Experiment ${_growthDecision!.experimentId}',
                      ),
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ErrorTagChip(label: 'synced $_lastSyncedEventCount'),
                    if (_backendFunnelReport != null)
                      _ErrorTagChip(
                        label:
                            'backend open ${_backendFunnelReport!.counts['speaking_opened'] ?? 0}',
                      ),
                    if (_backendFunnelReport != null)
                      _ErrorTagChip(
                        label:
                            'backend trial ${_backendFunnelReport!.counts['trial_requested'] ?? 0}',
                      ),
                    _ErrorTagChip(
                      label: _growthDecision == null
                          ? 'segment unknown'
                          : 'segment ${_growthDecision!.segmentId}',
                    ),
                    _ErrorTagChip(
                      label: _growthDecision == null
                          ? 'exp unknown'
                          : 'exp ${_growthDecision!.experimentId}',
                    ),
                    _ErrorTagChip(
                      label: _growthDecision?.aggressiveNudge == true
                          ? 'nudge aggressive'
                          : 'nudge standard',
                    ),
                  ],
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(isTr
                  ? 'Phrasebook ve review kayitlari'
                  : 'Phrasebook and review saves'),
              subtitle: Text(
                _savedPhrases.isEmpty
                    ? _copy('Henuz kayit yok', 'No saved phrases yet')
                    : _copy('${_savedPhrases.length} kayitli ifade',
                        '${_savedPhrases.length} saved phrases'),
              ),
              children: _savedPhrases.isEmpty
                  ? [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _copy(
                            'Ilk ifadeyi review veya paket icinden kaydet.',
                            'Save your first phrase from a review card or pack.',
                          ),
                        ),
                      ),
                    ]
                  : _savedPhrases.map((phrase) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.bookmark_rounded,
                          color: AppColors.brand,
                        ),
                        title: Text(phrase),
                        trailing: IconButton(
                          onPressed: () => _toggleSavedPhrase(phrase),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      );
                    }).toList(),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(isTr ? 'Kaydedilen tutorler' : 'Saved tutors'),
              subtitle: Text(
                _favoriteTutors.isEmpty
                    ? _copy('Henuz favori yok', 'No favorites yet')
                    : _copy('${_favoriteTutors.length} kayitli tutor',
                        '${_favoriteTutors.length} saved tutors'),
              ),
              children: _favoriteTutors.isEmpty
                  ? [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _copy(
                            'Tutor kartlarindaki kalp ile profilleri kaydet.',
                            'Save profiles with the heart icon on tutor cards.',
                          ),
                        ),
                      ),
                    ]
                  : _favoriteTutors.map((instructor) {
                      final shortName =
                          instructor.name.trim().split(RegExp(r'\s+')).first;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceSoft,
                          child: Text(
                            shortName.isNotEmpty
                                ? shortName.characters.first.toUpperCase()
                                : 'T',
                          ),
                        ),
                        title: Text(shortName),
                        subtitle: Text(_availabilityLabel(instructor)),
                        trailing: IconButton(
                          onPressed: () => _toggleFavoriteTutor(instructor),
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                        onTap: () => _openTutorProfile(instructor),
                      );
                    }).toList(),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title:
                  Text(isTr ? 'Referral ve reminder' : 'Referral and reminder'),
              subtitle: Text(
                '${_localState.referralCode} • ${isTr ? _reminder.titleTr : _reminder.titleEn}',
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr ? 'Referral kodun' : 'Your referral code',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _localState.referralCode,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: _copyReferralCode,
                            child: Text(isTr ? 'Kopyala' : 'Copy'),
                          ),
                          TextButton(
                            onPressed: _copyReferralInvite,
                            child: Text(isTr ? 'Davet' : 'Invite'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...[
                        _copy('1 ucretsiz mini speaking seansi',
                            '1 free mini speaking session'),
                        _copy('Bonus materyal paketi', 'Bonus material pack'),
                        _copy('Deneme dersi onceligi', 'Priority trial lesson'),
                      ].map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.brand,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._reminders.map((reminder) {
                  final selected = reminder.id == _localState.reminderWindow;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _setReminder(reminder.id),
                    leading: Icon(
                      selected
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: selected ? AppColors.brand : AppColors.muted,
                    ),
                    title: Text(isTr ? reminder.titleTr : reminder.titleEn),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.brand,
                          )
                        : null,
                  );
                }),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(isTr
                  ? 'Speaking gecmisi ve yol'
                  : 'Speaking history and path'),
              subtitle: Text(
                _activityLog.isEmpty
                    ? _copy(
                        'Hareketler burada gorunecek',
                        'Your actions will appear here',
                      )
                    : _activityTimeLabel(_activityLog.first),
              ),
              children: [
                ..._pathSteps.map((step) => _PathRow(step)),
                const SizedBox(height: 10),
                ...(_activityLog.isEmpty
                    ? [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.history_rounded,
                            color: AppColors.brand,
                          ),
                          title: Text(
                            _copy(
                              'Ilk hareketini yaptiginda gecmis burada gorunecek.',
                              'Your first action will appear here.',
                            ),
                          ),
                        ),
                      ]
                    : _activityLog.map((entry) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.history_rounded,
                            color: AppColors.brand,
                          ),
                          title: Text(entry.title),
                          subtitle: Text(_activityTimeLabel(entry)),
                        );
                      }).toList()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildLiveFeedbackSection(BuildContext context, {required bool isTr}) {
    return _SectionCard(
      title: isTr ? 'Canli speaking geri bildirimi' : 'Live speaking feedback',
      subtitle: isTr
          ? 'Son kaydina gore netlik, ritim ve guven durumunu tek ekranda gor.'
          : 'See clarity, rhythm, and confidence from your latest speaking take.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureGuideCard(
            icon: Icons.auto_graph_rounded,
            accentColor: AppColors.brand,
            title: isTr ? 'Bu blok neyi gosterir?' : 'What this block shows',
            detail: isTr
                ? 'Son kaydinin netlik, ritim ve guven skorunu aninda gorursun.'
                : 'You instantly see clarity, rhythm, and confidence from your last take.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _liveFeedbackMetrics
                .map((metric) => _FeedbackMeter(metric: metric))
                .toList(),
          ),
          const SizedBox(height: 14),
          _SentenceFixCard(
            title: isTr ? 'Cumle duzeltme' : 'Sentence refinement',
            yourLine: _asrTranscript,
            naturalLine: _rewrittenTranscript,
            note: isTr
                ? 'Ipucu: once ana fiili net soyle, sonra nedeni tek cumlede bagla.'
                : 'Tip: land the core verb first, then connect the reason in one clean sentence.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _latestErrorTagScores.entries
                .map((entry) => _ErrorTagChip(
                      label:
                          '${entry.key.replaceAll('_', ' ')} ${entry.value}%',
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleCompareRecording,
              icon: const Icon(Icons.multitrack_audio_rounded),
              label: Text(
                _recordingCompare
                    ? (isTr ? 'Kaydi bitir' : 'Finish recording')
                    : (isTr
                        ? 'Canli feedback icin kaydet'
                        : 'Record for live feedback'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTodayFlowSection(
    BuildContext context, {
    required bool isTr,
    required double todayProgress,
    required List<ProofMetric> proofPreview,
    required StudyPack firstPack,
    required ReviewCard firstReview,
  }) {
    return _SectionCard(
      title: isTr ? 'Bugunun akisi' : 'Today flow',
      subtitle: isTr
          ? 'Challenge, bugunluk gorev ve canli gecis ayni blokta.'
          : 'Challenge, today tasks, and live conversion are grouped in one block.',
      action: TextButton(
        onPressed: _challengeStarted ? _openPlacement : _startChallenge,
        child: Text(
          !_challengeStarted
              ? (isTr ? 'Challenge baslat' : 'Start challenge')
              : (isTr ? 'Seviyeni gor' : 'See level'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureGuideCard(
            icon: Icons.flag_circle_rounded,
            accentColor: const Color(0xFF0F766E),
            title: isTr ? 'Ne yapacaksin?' : 'What you do here',
            detail: isTr
                ? 'Bugun 3 kisa gorevi kapat, sonra tutor veya deneme dersine gec.'
                : 'Close 3 short tasks today, then move to tutors or a free trial.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: proofPreview
                .map((metric) => _ProofPill(metric: metric))
                .toList(),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: todayProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Text(
            !_challengeStarted
                ? _copy(
                    '7 gun boyunca mini paket, tekrar ve tutor ritmini kur.',
                    'Build a 7-day rhythm with mini packs, reviews, and tutors.',
                  )
                : _challengeCompleted
                    ? _copy(
                        'Challenge tamamlandi. Seviye ozetini acip uygun hocaya gec.',
                        'Challenge is complete. Open the level summary and move to the right tutor.',
                      )
                    : _copy(
                        'Gun $_challengeProgressDays / 7 aktif. Bugunun 3 kisa adimini kapat.',
                        'Day $_challengeProgressDays / 7 is active. Close today\'s 3 short steps.',
                      ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          ..._todayTasks.take(3).map((task) {
            final done = _completedToday.contains(task.id);
            final onOpen = task.id == 'placement'
                ? _openPlacement
                : task.id == 'review'
                    ? () => _openReviewSheet(firstReview)
                    : () => _openPackSheet(firstPack);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskTile(
                _TaskTileData(
                  title: isTr ? task.titleTr : task.titleEn,
                  detail: isTr ? task.detailTr : task.detailEn,
                  durationLabel: task.durationLabel,
                  icon: task.icon,
                  done: done,
                  buttonLabel: isTr ? task.buttonTr : task.buttonEn,
                  onOpen: onOpen,
                  onToggleDone: () => _toggleTask(task.id),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openTutors,
                  icon: const Icon(Icons.groups_2_rounded),
                  label: Text(isTr ? 'Tutor onerileri' : 'Tutor picks'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openTrial,
                  icon: const Icon(Icons.headset_mic_rounded),
                  label: Text(isTr ? 'Deneme dersi' : 'Free trial'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPracticeHubSection(
    BuildContext context, {
    required bool isTr,
    required List<StudyPack> packs,
    required List<ReviewCard> reviews,
    required PronunciationSpot spot,
    required StudyPack firstPack,
    required ReviewCard firstReview,
  }) {
    return _SectionCard(
      title: isTr ? 'Pratik merkezi' : 'Practice hub',
      subtitle: isTr
          ? 'Mod secimi, paketler ve review ayni merkezde.'
          : 'Mode selection, packs, and reviews live in one hub.',
      action: TextButton(
        onPressed: () => _openPackLibrarySheet(packs),
        child: Text(isTr ? 'Tum paketler' : 'All packs'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FeatureGuideCard(
            icon: Icons.bolt_rounded,
            accentColor: const Color(0xFFB45309),
            title: isTr ? 'Buradan basla' : 'Start here',
            detail: isTr
                ? 'Modunu sec, mini paketi ac, review ile tekrar et.'
                : 'Pick a mode, open a mini pack, and reinforce it with review.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _practiceModes.map((mode) {
              final selected = mode.id == _practiceMode.id;
              return _GoalChip(
                label: isTr ? mode.titleTr : mode.titleEn,
                selected: selected,
                icon: mode.icon,
                onTap: () => _setPracticeMode(mode.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PackCard(
                  _PackCardData(
                    title: isTr ? firstPack.titleTr : firstPack.titleEn,
                    subtitle:
                        isTr ? firstPack.subtitleTr : firstPack.subtitleEn,
                    durationLabel: firstPack.durationLabel,
                    icon: firstPack.icon,
                    accentColor: firstPack.accentColor,
                    onTap: () => _openPackSheet(firstPack),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReviewDeckCard(
                  ReviewCardData(
                    title: isTr ? firstReview.titleTr : firstReview.titleEn,
                    phrase: firstReview.phrase,
                    meaning:
                        isTr ? firstReview.meaningTr : firstReview.meaningEn,
                    usage: isTr ? firstReview.usageTr : firstReview.usageEn,
                    onTap: () => _openReviewSheet(firstReview),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openReviewLibrarySheet(reviews),
                  child:
                      Text(isTr ? 'Tum review kartlari' : 'All review cards'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _setPracticeMode('clarity'),
                  child: const Text('Clarity drill'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _pronunciationMetricsForGoal(_goal)
                .map((metric) => _ProofPill(metric: metric))
                .toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.focusLine,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isTr ? spot.helperTr : spot.helperEn,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMiniChallengeSection(BuildContext context,
      {required bool isTr}) {
    return _SectionCard(
      title: isTr ? 'Mini challenge gorevleri' : 'Mini challenge drills',
      subtitle: isTr
          ? 'Kisa, odakli ve tamamlamasi kolay 3 speaking gorevi.'
          : 'Three short speaking drills designed for fast daily wins.',
      child: Column(
        children: _microChallenges.map((task) {
          final onTap = switch (task.id) {
            'challenge_speed' => () => _setPracticeMode('speed'),
            'challenge_tutor' => _openTutors,
            _ => _toggleCompareRecording,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MiniChallengeCard(
              title: isTr ? task.titleTr : task.titleEn,
              detail: isTr ? task.detailTr : task.detailEn,
              durationLabel: task.durationLabel,
              icon: task.icon,
              ctaLabel: isTr ? task.buttonTr : task.buttonEn,
              onTap: onTap,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildWeeklyReportSection(BuildContext context, {required bool isTr}) {
    return _SectionCard(
      title: isTr ? 'Haftalik speaking raporu' : 'Weekly speaking report',
      subtitle: isTr
          ? 'Son 7 gunde kayit performansi ve hata dagilimi.'
          : 'Recording performance and error distribution for the last 7 days.',
      child: _WeeklyReportCard(
        report: _weeklySpeakingReport,
        isTr: isTr,
      ),
    );
  }

  String _normalizeLessonText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _levenshteinDistance(String source, String target) {
    if (source.isEmpty) return target.length;
    if (target.isEmpty) return source.length;

    final rows = List<int>.generate(target.length + 1, (index) => index);
    for (var i = 1; i <= source.length; i++) {
      var previous = rows.first;
      rows[0] = i;
      for (var j = 1; j <= target.length; j++) {
        final current = rows[j];
        final cost = source[i - 1] == target[j - 1] ? 0 : 1;
        rows[j] = math.min(
          math.min(rows[j] + 1, rows[j - 1] + 1),
          previous + cost,
        );
        previous = current;
      }
    }
    return rows.last;
  }

  int _spokenSimilarityScore(String expected, String actual) {
    final normalizedExpected = _normalizeLessonText(expected);
    final normalizedActual = _normalizeLessonText(actual);
    if (normalizedExpected.isEmpty || normalizedActual.isEmpty) return 0;

    final distance =
        _levenshteinDistance(normalizedExpected, normalizedActual).toDouble();
    final maxLength =
        math.max(normalizedExpected.length, normalizedActual.length).toDouble();
    final charSimilarity =
        ((1 - (distance / maxLength)).clamp(0.0, 1.0) * 100).round();

    final expectedTokens =
        normalizedExpected.split(' ').where((item) => item.isNotEmpty).toSet();
    final actualTokens =
        normalizedActual.split(' ').where((item) => item.isNotEmpty).toSet();
    final tokenOverlap = expectedTokens.isEmpty
        ? 0
        : ((expectedTokens.intersection(actualTokens).length /
                    expectedTokens.length) *
                100)
            .round();

    return ((charSimilarity * 0.62) + (tokenOverlap * 0.38))
        .round()
        .clamp(0, 100);
  }

  List<_LessonTaskData> _buildDailyLessonSteps() {
    switch (_goal.id) {
      case 'business':
        return [
          _LessonTaskData(
            id: 'business_listen_word',
            type: _LessonTaskType.listenChoice,
            titleTr: 'Dinle ve sec',
            titleEn: 'Listen and choose',
            subtitleTr: 'Kelimeyi duy, Turkcesini sec.',
            subtitleEn: 'Hear the word and pick the meaning.',
            coachTr: 'Sesi dinle. Dogru anlami alttan sec.',
            coachEn: 'Listen to the word. Pick the correct meaning below.',
            questionTr: 'Bu kelime ne anlama geliyor?',
            questionEn: 'What does this word mean?',
            promptText: 'deadline',
            promptDetailTr: 'Sese gore Turkce anlami sec.',
            promptDetailEn: 'Choose the Turkish meaning from the audio.',
            options: const [
              _LessonOptionData(
                  id: 'deadline', labelTr: 'son tarih', labelEn: 'deadline'),
              _LessonOptionData(
                  id: 'meeting', labelTr: 'toplanti', labelEn: 'meeting'),
              _LessonOptionData(
                  id: 'invoice', labelTr: 'fatura', labelEn: 'invoice'),
              _LessonOptionData(
                  id: 'coffee', labelTr: 'kahve', labelEn: 'coffee'),
            ],
            correctOptionId: 'deadline',
            successTitleTr: 'Dogru cevap',
            successTitleEn: 'Correct answer',
            successDetailTr: 'Deadline = son tarih.',
            successDetailEn: 'Deadline = son tarih.',
          ),
          _LessonTaskData(
            id: 'business_listen_sentence',
            type: _LessonTaskType.listenChoice,
            titleTr: 'Cumleyi dinle',
            titleEn: 'Listen to the sentence',
            subtitleTr: 'Cumleyi duy, Turkce karsiligini sec.',
            subtitleEn: 'Hear the sentence and choose its meaning.',
            coachTr: 'Cumleyi bir kez dinle. Anlamini tek secimle kapat.',
            coachEn: 'Listen once, then close it with one clean choice.',
            questionTr: 'Bu cumlenin Turkcesi hangisi?',
            questionEn: 'Which Turkish meaning is correct?',
            promptText: 'We need to finish this report before Friday.',
            promptDetailTr: 'Sesi dinle ve anlami sec.',
            promptDetailEn: 'Listen and choose the correct meaning.',
            options: const [
              _LessonOptionData(
                id: 'report_correct',
                labelTr: 'Bu raporu cumadan once bitirmemiz gerekiyor.',
                labelEn: 'Bu raporu cumadan once bitirmemiz gerekiyor.',
              ),
              _LessonOptionData(
                id: 'report_wrong_1',
                labelTr: 'Toplantiyi cuma gunu baslatmamiz gerekiyor.',
                labelEn: 'Toplantiyi cuma gunu baslatmamiz gerekiyor.',
              ),
              _LessonOptionData(
                id: 'report_wrong_2',
                labelTr: 'Bu faturayi bugun gondermemiz gerekiyor.',
                labelEn: 'Bu faturayi bugun gondermemiz gerekiyor.',
              ),
            ],
            correctOptionId: 'report_correct',
            successTitleTr: 'Cumleyi dogru yakaladin',
            successTitleEn: 'You caught the sentence',
            successDetailTr: 'Sira gorsel secim gorevinde.',
            successDetailEn: 'Next up: the visual choice task.',
          ),
          _LessonTaskData(
            id: 'business_picture',
            type: _LessonTaskType.pictureChoice,
            titleTr: 'Resmi sec',
            titleEn: 'Choose the image',
            subtitleTr: 'Kelimeye uygun nesneyi bul.',
            subtitleEn: 'Find the object that matches the word.',
            coachTr: 'Yaziyi oku ve dogru gorseli sec.',
            coachEn: 'Read the word and pick the right visual.',
            questionTr: 'Hangisi "laptop"?',
            questionEn: 'Which one is "laptop"?',
            promptText: 'laptop',
            promptDetailTr: 'Dogru gorseli sec.',
            promptDetailEn: 'Choose the matching visual.',
            options: const [
              _LessonOptionData(
                  id: 'laptop',
                  labelTr: 'laptop',
                  labelEn: 'laptop',
                  icon: Icons.laptop_mac_rounded),
              _LessonOptionData(
                  id: 'printer',
                  labelTr: 'yazici',
                  labelEn: 'printer',
                  icon: Icons.print_rounded),
              _LessonOptionData(
                  id: 'phone',
                  labelTr: 'telefon',
                  labelEn: 'phone',
                  icon: Icons.smartphone_rounded),
              _LessonOptionData(
                  id: 'calendar',
                  labelTr: 'takvim',
                  labelEn: 'calendar',
                  icon: Icons.calendar_month_rounded),
            ],
            correctOptionId: 'laptop',
            successTitleTr: 'Gorsel dogru',
            successTitleEn: 'Visual selected',
            successDetailTr: 'Sira yaziyi anlama gorevinde.',
            successDetailEn: 'Now move to the text meaning task.',
          ),
          _LessonTaskData(
            id: 'business_text',
            type: _LessonTaskType.textChoice,
            titleTr: 'Yaziyi anla',
            titleEn: 'Understand the text',
            subtitleTr: 'Ingilizce cumleyi oku ve Turkcesini sec.',
            subtitleEn:
                'Read the English sentence and pick the Turkish meaning.',
            coachTr: 'Bu adimda ses yok. Sadece okuyup karar ver.',
            coachEn: 'No audio here. Just read and decide.',
            questionTr: 'Bu cumlenin anlami hangisi?',
            questionEn: 'Which meaning is correct?',
            promptText: 'Can we move the meeting to next Monday?',
            promptDetailTr: 'Cumleyi oku ve en yakin anlami sec.',
            promptDetailEn: 'Read the sentence and choose the closest meaning.',
            options: const [
              _LessonOptionData(
                  id: 'meeting_correct',
                  labelTr: 'Toplantiyi gelecek pazartesiye alabilir miyiz?',
                  labelEn: 'Toplantiyi gelecek pazartesiye alabilir miyiz?'),
              _LessonOptionData(
                  id: 'meeting_wrong_1',
                  labelTr: 'Toplantiyi bugun bitirmemiz gerekiyor mu?',
                  labelEn: 'Toplantiyi bugun bitirmemiz gerekiyor mu?'),
              _LessonOptionData(
                  id: 'meeting_wrong_2',
                  labelTr: 'Raporu gelecek hafta gonderecek misin?',
                  labelEn: 'Raporu gelecek hafta gonderecek misin?'),
            ],
            correctOptionId: 'meeting_correct',
            successTitleTr: 'Anlam dogru',
            successTitleEn: 'Meaning locked',
            successDetailTr: 'Simdi ayni dili sen soyle.',
            successDetailEn: 'Now it is your turn to say it.',
          ),
          _LessonTaskData(
            id: 'business_speak_1',
            type: _LessonTaskType.speakRepeat,
            titleTr: 'Konus ve puan al',
            titleEn: 'Speak and score',
            subtitleTr: 'Cumleyi soyle, sistem puanlasin.',
            subtitleEn: 'Say the sentence and let the app score it.',
            coachTr: 'Mikrofona bas. Cumleyi temiz ve net soyle.',
            coachEn: 'Tap the mic. Say the sentence clearly.',
            questionTr: 'Asagidaki cumleyi sesli soyle.',
            questionEn: 'Say the sentence below out loud.',
            promptText: 'I will send the updated file this afternoon.',
            promptDetailTr: 'Ayni cumleyi mikrofonla soyle.',
            promptDetailEn: 'Repeat the same sentence with your microphone.',
            targetSpeech: 'I will send the updated file this afternoon.',
            minimumSpeakingScore: 46,
            successTitleTr: 'Speaking skoru hazir',
            successTitleEn: 'Speaking score ready',
            successDetailTr: 'Bir konusma gorevi daha kaldi.',
            successDetailEn: 'One more speaking task left.',
          ),
          _LessonTaskData(
            id: 'business_speak_2',
            type: _LessonTaskType.speakRepeat,
            titleTr: 'Konus ve bitir',
            titleEn: 'Speak and finish',
            subtitleTr: 'Son cumleyi soyle ve gunluk dersi kapat.',
            subtitleEn: 'Say the final line and finish the daily lesson.',
            coachTr: 'Son gorev. Cumleyi ritimle tamamla.',
            coachEn: 'Final step. Say the line with clean rhythm.',
            questionTr: 'Bu cumleyi sesli tekrar et.',
            questionEn: 'Repeat this sentence out loud.',
            promptText: 'Could you share the final numbers with the team?',
            promptDetailTr: 'Netlik ve vurguya dikkat et.',
            promptDetailEn: 'Pay attention to clarity and stress.',
            targetSpeech: 'Could you share the final numbers with the team?',
            minimumSpeakingScore: 48,
            successTitleTr: 'Gunluk business dersi bitti',
            successTitleEn: 'Business lesson complete',
            successDetailTr: 'Bugunku akisi temiz kapattin.',
            successDetailEn: 'You completed today\'s flow cleanly.',
          ),
        ];
      case 'ielts':
        return [
          _LessonTaskData(
            id: 'ielts_listen_word',
            type: _LessonTaskType.listenChoice,
            titleTr: 'Dinle ve sec',
            titleEn: 'Listen and choose',
            subtitleTr: 'Kelimeyi dinle, Turkcesini sec.',
            subtitleEn: 'Hear the word and choose the meaning.',
            coachTr: 'Tek kelimeyi dinle. Dogru anlami sec.',
            coachEn: 'Listen to the word and pick the right meaning.',
            questionTr: 'Bu kelime ne demek?',
            questionEn: 'What does this word mean?',
            promptText: 'opinion',
            promptDetailTr: 'Sesi dinle ve anlami sec.',
            promptDetailEn: 'Listen and choose the meaning.',
            options: const [
              _LessonOptionData(
                  id: 'opinion', labelTr: 'gorus', labelEn: 'opinion'),
              _LessonOptionData(
                  id: 'evidence', labelTr: 'kanit', labelEn: 'evidence'),
              _LessonOptionData(
                  id: 'station', labelTr: 'istasyon', labelEn: 'station'),
              _LessonOptionData(
                  id: 'coffee', labelTr: 'kahve', labelEn: 'coffee'),
            ],
            correctOptionId: 'opinion',
            successTitleTr: 'Dogru cevap',
            successTitleEn: 'Correct answer',
            successDetailTr: 'Simdi cumle anlamina gec.',
            successDetailEn: 'Now move to sentence meaning.',
          ),
          _LessonTaskData(
            id: 'ielts_listen_sentence',
            type: _LessonTaskType.listenChoice,
            titleTr: 'Cumleyi dinle',
            titleEn: 'Listen to the sentence',
            subtitleTr: 'Speaking tarzinda cumleyi duy.',
            subtitleEn: 'Hear a sentence in speaking style.',
            coachTr: 'Cumleyi dinle ve Turkce karsiligini sec.',
            coachEn: 'Listen and choose the Turkish meaning.',
            questionTr: 'Bu cumlenin Turkcesi hangisi?',
            questionEn: 'Which Turkish meaning is correct?',
            promptText: 'To a large extent, I agree with this idea.',
            promptDetailTr: 'IELTS speaking tonunu da duymaya calis.',
            promptDetailEn: 'Notice the IELTS-style intonation too.',
            options: const [
              _LessonOptionData(
                  id: 'ielts_correct',
                  labelTr: 'Buyuk olcude bu fikre katiliyorum.',
                  labelEn: 'Buyuk olcude bu fikre katiliyorum.'),
              _LessonOptionData(
                  id: 'ielts_wrong_1',
                  labelTr: 'Bu konuyla hic ilgilenmiyorum.',
                  labelEn: 'Bu konuyla hic ilgilenmiyorum.'),
              _LessonOptionData(
                  id: 'ielts_wrong_2',
                  labelTr: 'Bu raporu yarin gonderecegim.',
                  labelEn: 'Bu raporu yarin gonderecegim.'),
            ],
            correctOptionId: 'ielts_correct',
            successTitleTr: 'Anlami dogru yakaladin',
            successTitleEn: 'You got the meaning',
            successDetailTr: 'Sira gorsel secim gorevinde.',
            successDetailEn: 'Next is the visual task.',
          ),
          _LessonTaskData(
            id: 'ielts_picture',
            type: _LessonTaskType.pictureChoice,
            titleTr: 'Gorseli sec',
            titleEn: 'Choose the visual',
            subtitleTr: 'Kelimeyi gorselle bagla.',
            subtitleEn: 'Match the word to the visual.',
            coachTr: 'Hangisi "library"?',
            coachEn: 'Which one is "library"?',
            questionTr: 'Dogru resmi sec.',
            questionEn: 'Pick the correct image.',
            promptText: 'library',
            promptDetailTr: 'Kelimeye uyan gorseli bul.',
            promptDetailEn: 'Find the image that matches the word.',
            options: const [
              _LessonOptionData(
                  id: 'library',
                  labelTr: 'kutuphane',
                  labelEn: 'library',
                  icon: Icons.local_library_rounded),
              _LessonOptionData(
                  id: 'airport',
                  labelTr: 'havaalani',
                  labelEn: 'airport',
                  icon: Icons.flight_rounded),
              _LessonOptionData(
                  id: 'market',
                  labelTr: 'market',
                  labelEn: 'market',
                  icon: Icons.storefront_rounded),
              _LessonOptionData(
                  id: 'beach',
                  labelTr: 'plaj',
                  labelEn: 'beach',
                  icon: Icons.beach_access_rounded),
            ],
            correctOptionId: 'library',
            successTitleTr: 'Dogru secim',
            successTitleEn: 'Correct choice',
            successDetailTr: 'Simdi yazi anlamina gec.',
            successDetailEn: 'Now move to text meaning.',
          ),
          _LessonTaskData(
            id: 'ielts_text',
            type: _LessonTaskType.textChoice,
            titleTr: 'Metni anla',
            titleEn: 'Understand the text',
            subtitleTr: 'Uzun cumleyi oku ve anlamini sec.',
            subtitleEn: 'Read the longer sentence and choose its meaning.',
            coachTr: 'Bu tip cumleler speaking icin cok kullanilir.',
            coachEn: 'This type of sentence appears often in speaking answers.',
            questionTr: 'Bu cumlenin Turkcesi hangisi?',
            questionEn: 'Which Turkish meaning is correct?',
            promptText:
                'One of the main reasons is that public transport saves time.',
            promptDetailTr: 'Cumleyi parcalara ayirarak oku.',
            promptDetailEn: 'Read it in chunks, not as one block.',
            options: const [
              _LessonOptionData(
                  id: 'transport_correct',
                  labelTr:
                      'Ana nedenlerden biri toplu tasimanin zaman kazandirmasidir.',
                  labelEn:
                      'Ana nedenlerden biri toplu tasimanin zaman kazandirmasidir.'),
              _LessonOptionData(
                  id: 'transport_wrong_1',
                  labelTr: 'Toplu tasima cok pahali olabilir.',
                  labelEn: 'Toplu tasima cok pahali olabilir.'),
              _LessonOptionData(
                  id: 'transport_wrong_2',
                  labelTr: 'Sehirde trafik her gun artiyor.',
                  labelEn: 'Sehirde trafik her gun artiyor.'),
            ],
            correctOptionId: 'transport_correct',
            successTitleTr: 'Anlam tamam',
            successTitleEn: 'Meaning complete',
            successDetailTr: 'Simdi ayni dili sen uret.',
            successDetailEn: 'Now produce the same language yourself.',
          ),
          _LessonTaskData(
            id: 'ielts_speak_1',
            type: _LessonTaskType.speakRepeat,
            titleTr: 'Konus ve puan al',
            titleEn: 'Speak and score',
            subtitleTr: 'IELTS speaking ritmiyle tekrar et.',
            subtitleEn: 'Repeat it with IELTS speaking rhythm.',
            coachTr: 'Cumleyi iki ritim duragiyla soyle.',
            coachEn: 'Say it with two clear stress points.',
            questionTr: 'Asagidaki cumleyi sesli tekrar et.',
            questionEn: 'Repeat the sentence out loud.',
            promptText:
                'In my opinion, learning a language opens more opportunities.',
            promptDetailTr: 'Vurguyu opinion ve opportunities uzerine topla.',
            promptDetailEn: 'Land the stress on opinion and opportunities.',
            targetSpeech:
                'In my opinion, learning a language opens more opportunities.',
            minimumSpeakingScore: 48,
            successTitleTr: 'Speaking skoru olustu',
            successTitleEn: 'Speaking score generated',
            successDetailTr: 'Son bir cevap daha kaldi.',
            successDetailEn: 'One final answer remains.',
          ),
          _LessonTaskData(
            id: 'ielts_speak_2',
            type: _LessonTaskType.speakRepeat,
            titleTr: 'Son speaking gorevi',
            titleEn: 'Final speaking task',
            subtitleTr: 'Gunluk speaking turunu bitir.',
            subtitleEn: 'Finish the daily speaking round.',
            coachTr: 'Son cumleyi net kapat.',
            coachEn: 'Close the final sentence cleanly.',
            questionTr: 'Bu cumleyi sesli soyle.',
            questionEn: 'Say this sentence out loud.',
            promptText: 'To sum up, I believe this change would be beneficial.',
            promptDetailTr: 'To sum up kismini yutma, net cikar.',
            promptDetailEn: 'Do not swallow the phrase to sum up.',
            targetSpeech:
                'To sum up, I believe this change would be beneficial.',
            minimumSpeakingScore: 48,
            successTitleTr: 'Gunluk IELTS dersi bitti',
            successTitleEn: 'IELTS lesson complete',
            successDetailTr: 'Gunluk speaking ritmini korudun.',
            successDetailEn: 'You kept your daily speaking rhythm.',
          ),
        ];
      default:
        return [
          _LessonTaskData(
            id: 'daily_listen_word',
            type: _LessonTaskType.listenChoice,
            titleTr: 'Dinle ve sec',
            titleEn: 'Listen and choose',
            subtitleTr: 'Kelimeyi duy, Turkcesini sec.',
            subtitleEn: 'Hear the word and pick the meaning.',
            coachTr: 'Ses oynayacak. Dogru Turkce karsiligi alttan sec.',
            coachEn: 'The audio will play. Pick the correct meaning below.',
            questionTr: 'Bu kelimenin Turkcesi hangisi?',
            questionEn: 'Which Turkish meaning is correct?',
            promptText: 'coffee',
            promptDetailTr: 'Sesi dinle ve dogru anlami sec.',
            promptDetailEn: 'Listen and select the correct meaning.',
            options: const [
              _LessonOptionData(
                  id: 'coffee', labelTr: 'kahve', labelEn: 'coffee'),
              _LessonOptionData(id: 'water', labelTr: 'su', labelEn: 'water'),
              _LessonOptionData(
                  id: 'bread', labelTr: 'ekmek', labelEn: 'bread'),
              _LessonOptionData(id: 'tea', labelTr: 'cay', labelEn: 'tea'),
            ],
            correctOptionId: 'coffee',
            successTitleTr: 'Dogru cevap',
            successTitleEn: 'Correct answer',
            successDetailTr: 'Coffee = kahve.',
            successDetailEn: 'Coffee = kahve.',
          ),
          _LessonTaskData(
            id: 'daily_listen_sentence',
            type: _LessonTaskType.listenChoice,
            titleTr: 'Cumleyi dinle',
            titleEn: 'Listen to the sentence',
            subtitleTr: 'Cumleyi duy ve Turkce anlamini sec.',
            subtitleEn: 'Hear the sentence and choose its Turkish meaning.',
            coachTr: 'Bu adimda cumleyi dinleyip tek secim yapacaksin.',
            coachEn:
                'In this step you will listen to the sentence and make one choice.',
            questionTr: 'Bu cumlenin Turkcesi hangisi?',
            questionEn: 'Which Turkish meaning is correct?',
            promptText: 'I would like a coffee, please.',
            promptDetailTr: 'Sesli cumleyi dinle ve anlamini sec.',
            promptDetailEn:
                'Listen to the spoken sentence and choose the meaning.',
            options: const [
              _LessonOptionData(
                  id: 'coffee_sentence_correct',
                  labelTr: 'Bir kahve almak istiyorum, lutfen.',
                  labelEn: 'Bir kahve almak istiyorum, lutfen.'),
              _LessonOptionData(
                  id: 'coffee_sentence_wrong_1',
                  labelTr: 'Bir masa ayirtmak istiyorum.',
                  labelEn: 'Bir masa ayirtmak istiyorum.'),
              _LessonOptionData(
                  id: 'coffee_sentence_wrong_2',
                  labelTr: 'Kahvemi hemen bitirdim.',
                  labelEn: 'Kahvemi hemen bitirdim.'),
            ],
            correctOptionId: 'coffee_sentence_correct',
            successTitleTr: 'Cumleyi dogru anladin',
            successTitleEn: 'You understood the sentence',
            successDetailTr: 'Simdi kelimeyi gorselle bagla.',
            successDetailEn: 'Now connect the word to a visual.',
          ),
          _LessonTaskData(
            id: 'daily_picture',
            type: _LessonTaskType.pictureChoice,
            titleTr: 'Resmi sec',
            titleEn: 'Choose the image',
            subtitleTr: 'Kelimeye uygun resmi bul.',
            subtitleEn: 'Find the image that matches the word.',
            coachTr: 'Yaziyi oku ve dogru nesneyi sec.',
            coachEn: 'Read the word and choose the right object.',
            questionTr: 'Hangisi "coffee"?',
            questionEn: 'Which one is "coffee"?',
            promptText: 'coffee',
            promptDetailTr: 'Dogru gorseli sec.',
            promptDetailEn: 'Pick the matching visual.',
            options: const [
              _LessonOptionData(
                  id: 'coffee_icon',
                  labelTr: 'kahve',
                  labelEn: 'coffee',
                  icon: Icons.local_cafe_rounded),
              _LessonOptionData(
                  id: 'water_icon',
                  labelTr: 'su',
                  labelEn: 'water',
                  icon: Icons.water_drop_rounded),
              _LessonOptionData(
                  id: 'bread_icon',
                  labelTr: 'ekmek',
                  labelEn: 'bread',
                  icon: Icons.breakfast_dining_rounded),
              _LessonOptionData(
                  id: 'juice_icon',
                  labelTr: 'meyve suyu',
                  labelEn: 'juice',
                  icon: Icons.local_drink_rounded),
            ],
            correctOptionId: 'coffee_icon',
            successTitleTr: 'Gorsel dogru',
            successTitleEn: 'Visual selected',
            successDetailTr: 'Simdi yaziyi okuyup anlamini sec.',
            successDetailEn: 'Now read the text and pick the meaning.',
          ),
          _LessonTaskData(
            id: 'daily_text',
            type: _LessonTaskType.textChoice,
            titleTr: 'Yaziyi anla',
            titleEn: 'Understand the text',
            subtitleTr: 'Ingilizce cumleyi oku ve Turkcesini sec.',
            subtitleEn:
                'Read the English sentence and choose its Turkish meaning.',
            coachTr: 'Bu adimda ses yok. Sadece oku ve sec.',
            coachEn: 'There is no audio in this step. Just read and choose.',
            questionTr: 'Bu cumlenin anlami hangisi?',
            questionEn: 'Which meaning is correct?',
            promptText: 'Where is the train station?',
            promptDetailTr: 'Cumleyi oku ve en yakin anlami sec.',
            promptDetailEn: 'Read the sentence and choose the closest meaning.',
            options: const [
              _LessonOptionData(
                  id: 'station_correct',
                  labelTr: 'Tren istasyonu nerede?',
                  labelEn: 'Tren istasyonu nerede?'),
              _LessonOptionData(
                  id: 'station_wrong_1',
                  labelTr: 'Biletimi nereden alabilirim?',
                  labelEn: 'Biletimi nereden alabilirim?'),
              _LessonOptionData(
                  id: 'station_wrong_2',
                  labelTr: 'Tren ne zaman geliyor?',
                  labelEn: 'Tren ne zaman geliyor?'),
            ],
            correctOptionId: 'station_correct',
            successTitleTr: 'Metin anlami dogru',
            successTitleEn: 'Text meaning correct',
            successDetailTr: 'Simdi sirada konusma gorevi var.',
            successDetailEn: 'Now it is time for the speaking task.',
          ),
          _LessonTaskData(
            id: 'daily_speak_1',
            type: _LessonTaskType.speakRepeat,
            titleTr: 'Konus ve puan al',
            titleEn: 'Speak and score',
            subtitleTr: 'Cumleyi sesli tekrar et, puanini gor.',
            subtitleEn: 'Repeat the sentence aloud and see your score.',
            coachTr: 'Mikrofona bas. Cumleyi net bir ritimle soyle.',
            coachEn: 'Tap the mic. Say the sentence with clean rhythm.',
            questionTr: 'Bu cumleyi sesli tekrar et.',
            questionEn: 'Repeat this sentence out loud.',
            promptText: 'Could I have a coffee, please?',
            promptDetailTr: 'Kisa duraklar kullan. Son kelimeyi yutma.',
            promptDetailEn: 'Use small pauses. Do not swallow the last word.',
            targetSpeech: 'Could I have a coffee, please?',
            minimumSpeakingScore: 44,
            successTitleTr: 'Speaking skoru olustu',
            successTitleEn: 'Speaking score created',
            successDetailTr: 'Bir speaking gorevi daha kaldi.',
            successDetailEn: 'One more speaking task remains.',
          ),
          _LessonTaskData(
            id: 'daily_speak_2',
            type: _LessonTaskType.speakRepeat,
            titleTr: 'Son speaking gorevi',
            titleEn: 'Final speaking task',
            subtitleTr: 'Son cumleyi soyle ve dersi bitir.',
            subtitleEn: 'Say the final sentence and finish the lesson.',
            coachTr: 'Son gorevdesin. Cumleyi net kapat.',
            coachEn: 'You are on the final task. Close the sentence clearly.',
            questionTr: 'Bu cumleyi sesli soyle.',
            questionEn: 'Say this sentence out loud.',
            promptText: 'I am looking for the train station.',
            promptDetailTr: 'Looking ve station kelimelerini net cikar.',
            promptDetailEn: 'Keep the words looking and station clear.',
            targetSpeech: 'I am looking for the train station.',
            minimumSpeakingScore: 46,
            successTitleTr: 'Gunluk ders tamamlandi',
            successTitleEn: 'Daily lesson complete',
            successDetailTr: 'Bugunku gorevleri temiz kapattin.',
            successDetailEn: 'You completed today\'s lesson cleanly.',
          ),
        ];
    }
  }

  Future<void> _handleWrongMissionChoice({
    required String selectedChoice,
    String? snackMessage,
  }) async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;
    _missionFeedbackTimer?.cancel();
    setState(() {
      _missionMistakeCount += 1;
      _selectedMissionChoice = selectedChoice;
      _missionFeedbackKind = _MissionFeedbackKind.error;
      _missionCompletionTitle = _copy('Tekrar dene', 'Try again');
      _missionCompletionDetail = (snackMessage ?? '').trim().isEmpty
          ? _copy(
              'Bu secim dogru degil. Bir kez daha odaklan.',
              'That choice is not correct. Focus and try again.',
            )
          : snackMessage!.trim();
      _missionListenPlaying = false;
    });
    _missionFeedbackTimer = Timer(const Duration(milliseconds: 1450), () {
      _clearMissionFeedback();
    });
  }

  Widget _buildLessonTaskBody(
    BuildContext context, {
    required bool isTr,
    required _LessonTaskData step,
    required String measurementLabel,
  }) {
    switch (step.type) {
      case _LessonTaskType.listenChoice:
        return _buildAudioChoiceLesson(
          context,
          isTr: isTr,
          step: step,
          measurementLabel: measurementLabel,
        );
      case _LessonTaskType.textChoice:
        return _buildTextChoiceLesson(
          context,
          isTr: isTr,
          step: step,
          measurementLabel: measurementLabel,
        );
      case _LessonTaskType.pictureChoice:
        return _buildPictureChoiceLesson(
          context,
          isTr: isTr,
          step: step,
          measurementLabel: measurementLabel,
        );
      case _LessonTaskType.speakRepeat:
        return _buildSpeakingLesson(
          context,
          isTr: isTr,
          step: step,
          measurementLabel: measurementLabel,
        );
    }
  }

  Color _lessonAccentForStep(_LessonTaskData step) {
    switch (step.type) {
      case _LessonTaskType.listenChoice:
        return const Color(0xFF3D8BFF);
      case _LessonTaskType.textChoice:
        return const Color(0xFFFFA33A);
      case _LessonTaskType.pictureChoice:
        return const Color(0xFF8B5CF6);
      case _LessonTaskType.speakRepeat:
        return const Color(0xFF63D60F);
    }
  }

  _LogoCoachMood _lessonMoodForStep(_LessonTaskData step) {
    switch (step.type) {
      case _LessonTaskType.listenChoice:
        return _LogoCoachMood.listen;
      case _LessonTaskType.textChoice:
        return _LogoCoachMood.guide;
      case _LessonTaskType.pictureChoice:
        return _LogoCoachMood.guide;
      case _LessonTaskType.speakRepeat:
        return _LogoCoachMood.celebrate;
    }
  }

  IconData _lessonIconForStep(_LessonTaskData step) {
    switch (step.type) {
      case _LessonTaskType.listenChoice:
        return Icons.volume_up_rounded;
      case _LessonTaskType.textChoice:
        return Icons.translate_rounded;
      case _LessonTaskType.pictureChoice:
        return Icons.image_search_rounded;
      case _LessonTaskType.speakRepeat:
        return Icons.mic_rounded;
    }
  }

  String _lessonSceneLabel(_LessonTaskData step, bool isTr) {
    switch (step.type) {
      case _LessonTaskType.listenChoice:
        return isTr ? 'Dinle' : 'Listen';
      case _LessonTaskType.textChoice:
        return isTr ? 'Anlam' : 'Meaning';
      case _LessonTaskType.pictureChoice:
        return isTr ? 'Gorsel' : 'Visual';
      case _LessonTaskType.speakRepeat:
        return isTr ? 'Konus' : 'Speak';
    }
  }

  String _lessonMeasurementLabel(_LessonTaskData step, bool isTr) {
    switch (step.type) {
      case _LessonTaskType.listenChoice:
        return isTr ? 'Dinleme olculuyor' : 'Listening is being measured';
      case _LessonTaskType.textChoice:
        return isTr ? 'Anlama olculuyor' : 'Comprehension is being measured';
      case _LessonTaskType.pictureChoice:
        return isTr
            ? 'Kelime-gorsel eslesmesi olculuyor'
            : 'Word matching is being measured';
      case _LessonTaskType.speakRepeat:
        return _isFinalLessonStep(step)
            ? (isTr
                ? 'Speaking skoru hazirlaniyor'
                : 'Speaking score is being prepared')
            : (isTr ? 'Telaffuz olculuyor' : 'Pronunciation is being measured');
    }
  }

  Widget _buildAudioChoiceLesson(
    BuildContext context, {
    required bool isTr,
    required _LessonTaskData step,
    required String measurementLabel,
  }) {
    if (_missionCompleted) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 520 || constraints.maxWidth < 420;
        final dense = constraints.maxHeight < 430 || constraints.maxWidth < 380;
        final useGrid = step.options.length <= 4;

        return _LessonAutoFit(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LessonMeasurementPill(label: measurementLabel),
              SizedBox(height: dense ? 8 : 10),
              Text(
                step.question(isTr),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                      fontSize: dense ? 18 : (compact ? 20 : null),
                    ),
              ),
              SizedBox(height: dense ? 4 : (compact ? 6 : 10)),
              if (!dense && (step.promptDetail(isTr) ?? '').trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 12 : 18),
                  child: Text(
                    step.promptDetail(isTr)!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                  ),
                ),
              _LessonTaskHero(
                type: step.type,
                compact: compact,
                dense: dense,
                accent: _lessonAccentForStep(step),
              ),
              SizedBox(height: dense ? 8 : 12),
              _MissionAudioPromptCard(
                prompt: step.promptText ?? '',
                isPlaying: _missionListenPlaying,
                compact: compact,
                onTap: () => _speakMissionPrompt(step.promptText ?? ''),
              ),
              SizedBox(height: dense ? 8 : (compact ? 12 : 20)),
              if ((compact || dense) && useGrid)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: step.options.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: dense ? 8 : 10,
                    crossAxisSpacing: dense ? 8 : 10,
                    childAspectRatio: dense ? 3.1 : 2.6,
                  ),
                  itemBuilder: (context, index) {
                    final option = step.options[index];
                    final optionLabel = option.label(isTr);
                    return _MissionOptionTile(
                      label: optionLabel,
                      compact: true,
                      selected: _selectedMissionChoice == option.id,
                      feedbackKind: _missionFeedbackKind,
                      onTap: () {
                        if (option.id == step.correctOptionId) {
                          _completeMission(
                            title: step.successTitle(isTr),
                            detail: step.successDetail(isTr),
                            selectedChoice: option.id,
                          );
                          return;
                        }
                        _handleWrongMissionChoice(
                          selectedChoice: option.id,
                          snackMessage: isTr
                              ? 'Bu secim dogru degil. Sesi bir kez daha dinle.'
                              : 'That choice is not correct. Listen once more.',
                        );
                      },
                    );
                  },
                )
              else
                ...step.options.map((option) {
                  final optionLabel = option.label(isTr);
                  return Padding(
                    padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                    child: _MissionOptionTile(
                      label: optionLabel,
                      compact: compact,
                      selected: _selectedMissionChoice == option.id,
                      feedbackKind: _missionFeedbackKind,
                      onTap: () {
                        if (option.id == step.correctOptionId) {
                          _completeMission(
                            title: step.successTitle(isTr),
                            detail: step.successDetail(isTr),
                            selectedChoice: option.id,
                          );
                          return;
                        }
                        _handleWrongMissionChoice(
                          selectedChoice: option.id,
                          snackMessage: isTr
                              ? 'Bu secim dogru degil. Sesi bir kez daha dinle.'
                              : 'That choice is not correct. Listen once more.',
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextChoiceLesson(
    BuildContext context, {
    required bool isTr,
    required _LessonTaskData step,
    required String measurementLabel,
  }) {
    if (_missionCompleted) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 560 || constraints.maxWidth < 420;
        final dense = constraints.maxHeight < 450 || constraints.maxWidth < 380;

        return _LessonAutoFit(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LessonMeasurementPill(label: measurementLabel),
              SizedBox(height: dense ? 8 : 10),
              Text(
                step.question(isTr),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                      fontSize: dense ? 18 : (compact ? 20 : null),
                    ),
              ),
              SizedBox(height: dense ? 4 : (compact ? 6 : 10)),
              if (!dense && (step.promptDetail(isTr) ?? '').trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 12 : 18),
                  child: Text(
                    step.promptDetail(isTr)!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                  ),
                ),
              _LessonTaskHero(
                type: step.type,
                compact: compact,
                dense: dense,
                accent: _lessonAccentForStep(step),
              ),
              SizedBox(height: dense ? 8 : 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 14 : 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE3EAF2)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandNight.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.promptText ?? '',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.brandNight,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                fontSize: dense ? 20 : null,
                              ),
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _speakMissionPrompt(step.promptText ?? ''),
                      icon: Icon(
                        _missionListenPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_up_rounded,
                      ),
                      label:
                          Text(isTr ? 'Cumleyi dinle' : 'Listen to sentence'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: dense ? 8 : (compact ? 12 : 20)),
              ...step.options.map((option) {
                final optionLabel = option.label(isTr);
                return Padding(
                  padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                  child: _MissionOptionTile(
                    label: optionLabel,
                    compact: compact,
                    selected: _selectedMissionChoice == option.id,
                    feedbackKind: _missionFeedbackKind,
                    onTap: () {
                      if (option.id == step.correctOptionId) {
                        _completeMission(
                          title: step.successTitle(isTr),
                          detail: step.successDetail(isTr),
                          selectedChoice: option.id,
                        );
                        return;
                      }
                      _handleWrongMissionChoice(
                        selectedChoice: option.id,
                        snackMessage: isTr
                            ? 'Bu anlam degil. Cumleyi tekrar oku.'
                            : 'That is not the right meaning. Read it again.',
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPictureChoiceLesson(
    BuildContext context, {
    required bool isTr,
    required _LessonTaskData step,
    required String measurementLabel,
  }) {
    if (_missionCompleted) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 560 || constraints.maxWidth < 420;
        final dense = constraints.maxHeight < 450 || constraints.maxWidth < 380;

        return _LessonAutoFit(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LessonMeasurementPill(label: measurementLabel),
              SizedBox(height: dense ? 8 : 10),
              Text(
                step.question(isTr),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                      fontSize: dense ? 18 : null,
                    ),
              ),
              SizedBox(height: dense ? 4 : 10),
              if (!dense && (step.promptDetail(isTr) ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    step.promptDetail(isTr)!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                  ),
                ),
              _LessonTaskHero(
                type: step.type,
                compact: compact,
                dense: dense,
                accent: _lessonAccentForStep(step),
              ),
              SizedBox(height: dense ? 8 : 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 16,
                  vertical: compact ? 12 : 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.promptText ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.brandNight,
                              fontWeight: FontWeight.w800,
                              fontSize: dense ? 20 : null,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _speakMissionPrompt(step.promptText ?? ''),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brand,
                      ),
                      icon: Icon(
                        _missionListenPlaying
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_up_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: dense ? 10 : 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: step.options.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: dense ? 10 : 14,
                  crossAxisSpacing: dense ? 10 : 14,
                  childAspectRatio: dense ? 1.04 : (compact ? 0.98 : 0.86),
                ),
                itemBuilder: (context, index) {
                  final option = step.options[index];
                  return _MissionPictureTile(
                    label: option.label(isTr),
                    selected: _selectedMissionChoice == option.id,
                    feedbackKind: _missionFeedbackKind,
                    visualSeed: option.id,
                    icon: option.icon,
                    onTap: () {
                      if (option.id == step.correctOptionId) {
                        _completeMission(
                          title: step.successTitle(isTr),
                          detail: step.successDetail(isTr),
                          selectedChoice: option.id,
                        );
                        return;
                      }
                      _handleWrongMissionChoice(
                        selectedChoice: option.id,
                        snackMessage: isTr
                            ? 'Bu gorsel dogru degil. Yaziyi tekrar oku.'
                            : 'That visual is not correct. Read the word again.',
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeakingLesson(
    BuildContext context, {
    required bool isTr,
    required _LessonTaskData step,
    required String measurementLabel,
  }) {
    if (_missionCompleted) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 600 || constraints.maxWidth < 420;
        final dense = constraints.maxHeight < 500 || constraints.maxWidth < 380;

        return _LessonAutoFit(
          constraints: constraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LessonMeasurementPill(label: measurementLabel),
              SizedBox(height: dense ? 8 : 10),
              Text(
                step.question(isTr),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                      fontSize: dense ? 18 : null,
                    ),
              ),
              SizedBox(height: dense ? 4 : 10),
              if (!dense && (step.promptDetail(isTr) ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    step.promptDetail(isTr)!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                  ),
                ),
              _LessonTaskHero(
                type: step.type,
                compact: compact,
                dense: dense,
                accent: _lessonAccentForStep(step),
              ),
              SizedBox(height: dense ? 10 : 14),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FBFF),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFDDE7F4)),
                ),
                child: Column(
                  children: [
                    _MissionIllustrationSurface(
                      seed: 'speak_real_lesson',
                      label: 'SPEAK',
                      height: dense ? 92 : (compact ? 108 : 132),
                    ),
                    SizedBox(height: dense ? 12 : 18),
                    Text(
                      step.promptText ?? '',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.brandNight,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                fontSize: dense ? 20 : null,
                              ),
                    ),
                    SizedBox(height: dense ? 10 : 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _speakMissionPrompt(step.promptText ?? ''),
                          icon: Icon(
                            _missionListenPlaying
                                ? Icons.graphic_eq_rounded
                                : Icons.volume_up_rounded,
                          ),
                          label: Text(
                              isTr ? 'Cumleyi dinle' : 'Listen to sentence'),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final wasRecording = _recordingCompare;
                            final session = await _toggleCompareRecording(
                              focusLineOverride: step.targetSpeech,
                            );
                            if (!wasRecording) return;
                            if (!mounted ||
                                _recordingCompare ||
                                session == null) {
                              return;
                            }

                            final transcript =
                                session.rewrittenTranscript.trim().isEmpty
                                    ? session.transcript
                                    : session.rewrittenTranscript;
                            final similarity = _spokenSimilarityScore(
                              step.targetSpeech ?? '',
                              transcript,
                            );
                            final score = ((similarity * 0.58) +
                                    (session.confidenceScore * 0.42))
                                .round()
                                .clamp(0, 100);

                            setState(() {
                              _lastMissionSpeechScore = score;
                              _lastMissionSpeechTranscript = transcript.trim();
                            });

                            if (score < step.minimumSpeakingScore) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isTr
                                        ? 'Skorun $score/100. Bir kez daha dene.'
                                        : 'Your score is $score/100. Try once more.',
                                  ),
                                ),
                              );
                              return;
                            }

                            _completeMission(
                              title: step.successTitle(isTr),
                              detail:
                                  '${step.successDetail(isTr)} ${isTr ? 'Skor' : 'Score'}: $score/100',
                              selectedChoice: step.id,
                              isFinalLesson: _isFinalLessonStep(step),
                              earnedScore: score,
                            );
                          },
                          icon: Icon(
                            _recordingCompare
                                ? Icons.stop_circle_rounded
                                : Icons.mic_rounded,
                          ),
                          label: Text(
                            _recordingCompare
                                ? (isTr ? 'Konusmayi bitir' : 'Finish speaking')
                                : (isTr ? 'Mikrofonu ac' : 'Open microphone'),
                          ),
                        ),
                      ],
                    ),
                    if (_liveTranscript.trim().isNotEmpty) ...[
                      SizedBox(height: dense ? 12 : 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _liveTranscript.trim(),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.brandNight,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ],
                    if (_lastMissionSpeechScore != null) ...[
                      SizedBox(height: dense ? 10 : 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8D8),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${isTr ? 'Speaking skoru' : 'Speaking score'}: ${_lastMissionSpeechScore!}/100',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF2E7D10),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if ((_lastMissionSpeechTranscript ?? '')
                                .trim()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _lastMissionSpeechTranscript!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF4A6B3C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<({String title, String subtitle, Widget section})>
      _buildGuidedMissionSections(
    BuildContext context, {
    required bool isTr,
    required List<StudyPack> packs,
    required List<ReviewCard> reviews,
    required List<ProofMetric> proofPreview,
    required StudyPack firstPack,
    required ReviewCard firstReview,
    required PronunciationSpot spot,
    required double todayProgress,
    required List<InstructorSummary> matchedPreview,
  }) {
    return [
      (
        title: isTr ? 'Canli feedback' : 'Live feedback',
        subtitle: isTr
            ? 'Son speaking denemenden net geri bildirim al.'
            : 'Get clear feedback from your latest speaking take.',
        section: _buildListenMission(
          context,
          isTr: isTr,
          question: isTr
              ? 'Bugun en cok hangi alana odaklanacaksin?'
              : 'Which area will you focus on today?',
          helper: isTr
              ? 'Bir alan sec. Bu ilk gorevi temiz kapatir.'
              : 'Pick one area. This clears your first mission.',
          prompt: spot.focusLine,
          options: proofPreview
              .map((metric) => (id: metric.label, label: metric.label))
              .toList(),
          correctOptionId: proofPreview.isEmpty ? '' : proofPreview.first.label,
          successTitle: isTr ? 'Odak alanin hazir' : 'Focus area locked',
          successDetail: isTr
              ? 'Simdi bugunun gorevine gecebilirsin.'
              : 'Now you can move to today’s mission.',
        ),
      ),
      (
        title: isTr ? 'Bugunun akisi' : 'Today flow',
        subtitle:
            isTr ? 'Gorevleri sirayla kapat.' : 'Close the tasks one by one.',
        section: _buildMatchMission(
          context,
          isTr: isTr,
          question: isTr
              ? 'Gorevi dogru sonucuyla eslestir.'
              : 'Match the task with its outcome.',
          helper: isTr
              ? 'Soldan bir gorev, sagdan dogru sonucu sec.'
              : 'Pick one task on the left, then its result on the right.',
          leftOptions: [
            (id: 'placement', label: isTr ? 'Seviye Testi' : 'Placement test'),
            (id: 'review', label: isTr ? 'Review' : 'Review'),
            (id: 'pack', label: isTr ? 'Mini Paket' : 'Mini pack'),
          ],
          rightOptions: [
            (id: 'placement', label: isTr ? 'Seviye gor' : 'See your level'),
            (id: 'review', label: isTr ? 'Tekrar et' : 'Repeat'),
            (id: 'pack', label: isTr ? 'Pratik yap' : 'Practice'),
          ],
          successTitle: isTr ? 'Bugunun gorevi secildi' : 'Today task selected',
          successDetail: isTr
              ? 'Sira speaking modunu secmeye geldi.'
              : 'Next up: choose your speaking mode.',
        ),
      ),
      (
        title: isTr ? 'Pratik merkezi' : 'Practice hub',
        subtitle: isTr
            ? 'Mod sec, mini paket ac, tekrar et.'
            : 'Pick a mode, open a pack, and review.',
        section: _buildSingleChoiceMission(
          context,
          isTr: isTr,
          style: _MissionChoiceStyle.visualCards,
          question: isTr
              ? 'Hangi speaking moduyla devam edeceksin?'
              : 'Which speaking mode will you use next?',
          helper: isTr
              ? 'Bir mod sec. Sonra recording gorevine gececeksin.'
              : 'Pick one mode. Then you will move to the recording mission.',
          options: _practiceModes
              .map((mode) => (
                    id: mode.id,
                    label: isTr ? mode.titleTr : mode.titleEn,
                  ))
              .toList(),
          successTitle: isTr ? 'Mod secildi' : 'Mode selected',
          successDetail: isTr
              ? 'Simdi tek bir recording denemesi yap.'
              : 'Now complete one recording attempt.',
          onSelect: (id) => _setPracticeMode(id),
        ),
      ),
      (
        title: 'Record + Compare',
        subtitle: isTr
            ? 'Kayit al ve onceki denemenle karsilastir.'
            : 'Record and compare with your previous take.',
        section: _buildSpeakMission(
          context,
          isTr: isTr,
          question: isTr
              ? 'Bir speaking denemesi tamamlamaya hazir misin?'
              : 'Are you ready to complete one speaking attempt?',
          helper: isTr
              ? 'Bu adimda tek bir recording aksiyonu var.'
              : 'This step has one recording action only.',
          actionLabel: isTr ? 'Kaydi tamamla' : 'Complete recording',
          successTitle: isTr ? 'Kayit tamamlandi' : 'Recording complete',
          successDetail: isTr
              ? 'Guzel. Simdi mini challenge sec.'
              : 'Good. Next, choose a mini challenge.',
        ),
      ),
      (
        title: isTr ? 'Mini challenge' : 'Mini challenge',
        subtitle: isTr
            ? 'Kisa speaking gorevleriyle ritmi koru.'
            : 'Keep the rhythm with short speaking drills.',
        section: _buildPictureSelectMission(
          context,
          isTr: isTr,
          question: isTr ? 'Dogru resmi sec.' : 'Pick the correct image.',
          helper: isTr
              ? 'Konusma sprintine en yakin gorev kartini bul.'
              : 'Find the card that best matches a speaking sprint.',
          options: _microChallenges
              .take(3)
              .map((task) => (
                    id: task.id,
                    label: isTr ? task.titleTr : task.titleEn,
                  ))
              .toList(),
          correctOptionId:
              _microChallenges.isEmpty ? '' : _microChallenges.first.id,
          successTitle: isTr ? 'Challenge secildi' : 'Challenge selected',
          successDetail: isTr
              ? 'Sira dogru tutoru secmeye geldi.'
              : 'Now it is time to choose the right tutor.',
        ),
      ),
      (
        title: isTr ? 'Ritim ve tutorler' : 'Rhythm and tutors',
        subtitle: isTr
            ? 'Ilerlemeni gor ve dogru hocaya gec.'
            : 'See your progress and move to the right tutor.',
        section: _buildSingleChoiceMission(
          context,
          isTr: isTr,
          style: _MissionChoiceStyle.tutorCards,
          question: isTr
              ? 'Bugun sana en uygun hocayi sec.'
              : 'Pick the tutor that fits you today.',
          helper: isTr
              ? 'Bir tutor sec. Sonra rapor adimina gececeksin.'
              : 'Choose one tutor. Then move to your report.',
          options: matchedPreview
              .map((instructor) => (
                    id: instructor.id.toString(),
                    label: instructor.name,
                  ))
              .toList(),
          successTitle: isTr ? 'Tutor secildi' : 'Tutor selected',
          successDetail: isTr
              ? 'Ilerlemeni kisa raporda goreceksin.'
              : 'You will see your progress in a short report.',
        ),
      ),
      (
        title: isTr ? 'Haftalik rapor' : 'Weekly report',
        subtitle: isTr
            ? 'Speaking performansini haftalik gor.'
            : 'See your speaking performance weekly.',
        section: _buildSingleChoiceMission(
          context,
          isTr: isTr,
          style: _MissionChoiceStyle.visualCards,
          question: isTr
              ? 'Bu hafta en guclu alanin hangisi?'
              : 'What was your strongest area this week?',
          helper: isTr
              ? 'Bir alan sec. Sonra son araca gec.'
              : 'Choose one strength. Then move to the final tool step.',
          options: _proofMetrics
              .take(3)
              .map((metric) => (id: metric.label, label: metric.label))
              .toList(),
          successTitle: isTr ? 'Rapor tamamlandi' : 'Report complete',
          successDetail: isTr
              ? 'Son adimda aracini sec.'
              : 'Choose your tool in the final step.',
        ),
      ),
      (
        title: isTr ? 'Diger araclar' : 'More tools',
        subtitle: isTr
            ? 'Kayitlar, favoriler ve reminderlar.'
            : 'Saved items, favorites, and reminders.',
        section: _buildSingleChoiceMission(
          context,
          isTr: isTr,
          style: _MissionChoiceStyle.toolPills,
          question: isTr
              ? 'Bugun hangi araci once kullanacaksin?'
              : 'Which tool will you use first today?',
          helper: isTr
              ? 'Bir araci sec ve gunluk akisi bitir.'
              : 'Pick one tool and finish the daily flow.',
          options: [
            (id: 'phrasebook', label: 'Phrasebook'),
            (
              id: 'saved_tutors',
              label: isTr ? 'Kayitli tutorler' : 'Saved tutors',
            ),
            (
              id: 'reminders',
              label: isTr ? 'Hatirlaticilar' : 'Reminders',
            ),
          ],
          successTitle: isTr ? 'Gunluk akisi bitirdin' : 'Daily flow complete',
          successDetail: isTr
              ? 'Tum gorevler temiz kapandi.'
              : 'All missions were completed cleanly.',
        ),
      ),
    ];
  }

  Widget _buildSingleChoiceMission(
    BuildContext context, {
    required bool isTr,
    required _MissionChoiceStyle style,
    required String question,
    required String helper,
    required List<({String id, String label})> options,
    required String successTitle,
    required String successDetail,
    FutureOr<void> Function(String id)? onSelect,
  }) {
    if (_missionCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 26),
        _buildMissionOptionsLayout(
          context,
          style: style,
          options: options,
          onSelect: (optionId) async {
            if (onSelect != null) {
              await onSelect(optionId);
            }
            _completeMission(
              title: successTitle,
              detail: successDetail,
              selectedChoice: optionId,
            );
          },
        ),
      ],
    );
  }

  Widget _buildListenMission(
    BuildContext context, {
    required bool isTr,
    required String question,
    required String helper,
    required String prompt,
    required List<({String id, String label})> options,
    required String correctOptionId,
    required String successTitle,
    required String successDetail,
  }) {
    if (_missionCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 20),
        _MissionAudioPromptCard(
          prompt: prompt,
          isPlaying: _missionListenPlaying,
          onTap: () async {
            if (_missionListenPlaying) return;
            setState(() => _missionListenPlaying = true);
            await Future<void>.delayed(const Duration(milliseconds: 900));
            if (!mounted) return;
            setState(() => _missionListenPlaying = false);
          },
        ),
        const SizedBox(height: 18),
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MissionOptionTile(
              label: option.label,
              selected: _selectedMissionChoice == option.id,
              onTap: () {
                if (option.id == correctOptionId) {
                  _completeMission(
                    title: successTitle,
                    detail: successDetail,
                    selectedChoice: option.id,
                  );
                } else {
                  setState(() => _selectedMissionChoice = option.id);
                }
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatchMission(
    BuildContext context, {
    required bool isTr,
    required String question,
    required String helper,
    required List<({String id, String label})> leftOptions,
    required List<({String id, String label})> rightOptions,
    required String successTitle,
    required String successDetail,
  }) {
    if (_missionCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftOptions.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MissionMatchChip(
                      label: option.label,
                      selected: _missionMatchLeftChoice == option.id,
                      accent: const Color(0xFF7C3AED),
                      onTap: () {
                        setState(() => _missionMatchLeftChoice = option.id);
                        if (_missionMatchRightChoice == option.id) {
                          _completeMission(
                            title: successTitle,
                            detail: successDetail,
                            selectedChoice: option.id,
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: rightOptions.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MissionMatchChip(
                      label: option.label,
                      selected: _missionMatchRightChoice == option.id,
                      accent: const Color(0xFF06B6D4),
                      onTap: () {
                        setState(() => _missionMatchRightChoice = option.id);
                        if (_missionMatchLeftChoice == option.id) {
                          _completeMission(
                            title: successTitle,
                            detail: successDetail,
                            selectedChoice: option.id,
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeakMission(
    BuildContext context, {
    required bool isTr,
    required String question,
    required String helper,
    required String actionLabel,
    required String successTitle,
    required String successDetail,
  }) {
    if (_missionCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF6FBFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDDE7F4)),
          ),
          child: Column(
            children: [
              const _MissionIllustrationSurface(
                seed: 'speak_mission',
                label: 'SPEAK',
                height: 132,
              ),
              const SizedBox(height: 16),
              if (_recordingCompare)
                Text(
                  _copy(
                    'Konusuyorsun... bitirdiginde kaydet.',
                    'You are speaking... save when you finish.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w700,
                      ),
                )
              else
                Text(
                  _copy(
                    'Tek bir speaking denemesi kaydet.',
                    'Record one speaking attempt.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              const SizedBox(height: 12),
              if (_liveTranscript.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _liveTranscript.trim(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final wasRecording = _recordingCompare;
                    await _toggleCompareRecording();
                    if (wasRecording && mounted && !_recordingCompare) {
                      _completeMission(
                        title: successTitle,
                        detail: successDetail,
                      );
                    }
                  },
                  icon: Icon(
                    _recordingCompare
                        ? Icons.stop_circle_rounded
                        : Icons.mic_rounded,
                  ),
                  label: Text(
                    _recordingCompare
                        ? (isTr ? 'Konusmayi bitir' : 'Finish speaking')
                        : actionLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPictureSelectMission(
    BuildContext context, {
    required bool isTr,
    required String question,
    required String helper,
    required List<({String id, String label})> options,
    required String correctOptionId,
    required String successTitle,
    required String successDetail,
  }) {
    if (_missionCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            return _MissionPictureTile(
              label: option.label,
              selected: _selectedMissionChoice == option.id,
              visualSeed: option.id,
              onTap: () {
                if (option.id == correctOptionId) {
                  _completeMission(
                    title: successTitle,
                    detail: successDetail,
                    selectedChoice: option.id,
                  );
                } else {
                  setState(() => _selectedMissionChoice = option.id);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMissionOptionsLayout(
    BuildContext context, {
    required _MissionChoiceStyle style,
    required List<({String id, String label})> options,
    required FutureOr<void> Function(String optionId) onSelect,
  }) {
    switch (style) {
      case _MissionChoiceStyle.pictureGrid:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.84,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            return _MissionPictureTile(
              label: option.label,
              selected: _selectedMissionChoice == option.id,
              visualSeed: option.id,
              onTap: () => onSelect(option.id),
            );
          },
        );
      case _MissionChoiceStyle.tutorCards:
        return Column(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MissionTutorTile(
                label: option.label,
                selected: _selectedMissionChoice == option.id,
                visualSeed: option.id,
                onTap: () => onSelect(option.id),
              ),
            );
          }).toList(),
        );
      case _MissionChoiceStyle.toolPills:
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            return _MissionToolPill(
              label: option.label,
              selected: _selectedMissionChoice == option.id,
              visualSeed: option.id,
              onTap: () => onSelect(option.id),
            );
          }).toList(),
        );
      case _MissionChoiceStyle.visualCards:
        return Column(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MissionVisualCardTile(
                label: option.label,
                selected: _selectedMissionChoice == option.id,
                visualSeed: option.id,
                onTap: () => onSelect(option.id),
              ),
            );
          }).toList(),
        );
      case _MissionChoiceStyle.list:
        return Column(
          children: options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MissionOptionTile(
                label: option.label,
                selected: _selectedMissionChoice == option.id,
                onTap: () => onSelect(option.id),
              ),
            );
          }).toList(),
        );
    }
  }

  // ignore: unused_element
  Widget _buildSingleActionMission(
    BuildContext context, {
    required bool isTr,
    required String question,
    required String helper,
    required String actionLabel,
    required String successTitle,
    required String successDetail,
  }) {
    if (_missionCompleted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          helper,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF6FBFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDDE7F4)),
          ),
          child: Column(
            children: [
              const _MissionIllustrationSurface(
                seed: 'record_action',
                label: 'REC',
                height: 132,
              ),
              const SizedBox(height: 16),
              Text(
                isTr
                    ? 'Bu adimda tek bir aksiyon var.'
                    : 'This mission has one clear action.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _completeMission(
                      title: successTitle,
                      detail: successDetail,
                    );
                  },
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildMissionSuccessPanel(
    BuildContext context, {
    required String title,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FCD8),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7ED321).withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _LogoCoach(
            size: 104,
            bubbleText: '',
            bubbleAccent: const Color(0xFF7ED321),
            showBubble: false,
          ),
          const SizedBox(height: 16),
          const Icon(
            Icons.check_circle_rounded,
            size: 52,
            color: Color(0xFF59C10E),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2E7D10),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF4A6B3C),
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }

  void _goToNextMissionSection(int total) {
    if (_guidedSectionIndex >= total - 1) return;
    setState(() => _guidedSectionIndex += 1);
  }

  void _goToPreviousMissionSection() {
    if (_guidedSectionIndex <= 0) return;
    setState(() => _guidedSectionIndex -= 1);
  }

  void _replaceMissionRoute(int nextIndex) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => PublicTheme(
          child: SpeakCoachScreen(
            initialMissionStep: nextIndex,
            missionScoreTotal: _missionScoreTotal,
            missionScoredTaskCount: _missionScoredTaskCount,
            missionMistakeCount: _missionMistakeCount,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.18, 0),
            end: Offset.zero,
          ).animate(curve);
          final scale = Tween<double>(
            begin: 0.97,
            end: 1,
          ).animate(curve);
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  void _completeMission({
    required String title,
    required String detail,
    String? selectedChoice,
    bool isFinalLesson = false,
    int earnedScore = 100,
  }) {
    if (!mounted) return;
    _missionFeedbackTimer?.cancel();
    _missionAdvanceTimer?.cancel();
    setState(() {
      _missionScoreTotal += earnedScore.clamp(0, 100);
      _missionScoredTaskCount += 1;
      _missionCompleted = true;
      _missionFeedbackKind = _MissionFeedbackKind.success;
      _missionCompletionTitle = title;
      _missionCompletionDetail = detail;
      _selectedMissionChoice = selectedChoice;
      _missionListenPlaying = false;
    });
    _triggerLessonOutro();
    if (isFinalLesson) {
      _finalRewardTimer?.cancel();
      _finalRewardTimer = Timer(const Duration(milliseconds: 960), () {
        _showFinalRewardScene();
      });
      return;
    }
    if (_isMissionMode) {
      final nextIndex = widget.initialMissionStep + 1;
      _missionAdvanceTimer = Timer(const Duration(milliseconds: 1180), () {
        if (!mounted) return;
        _replaceMissionRoute(nextIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoCoach(
                size: 92,
                bubbleText: AppStrings.t('One moment'),
                bubbleAccent: const Color(0xFF7ED957),
                mood: _LogoCoachMood.guide,
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.t('Preparing your lesson...'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.t(
                      'An unexpected error occurred. Please try again.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _load,
                  child: Text(AppStrings.t('Try Again')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isTr = AppStrings.code == 'tr';
    final packs = _packsForGoal(_goal);
    final reviews = _reviewCardsForGoal(_goal);
    final spot = _pronunciationSpotForGoal(_goal);
    final todayProgress =
        _todayTasks.isEmpty ? 0.0 : _completedToday.length / _todayTasks.length;
    final matchedPreview = _matchedInstructors.take(2).toList(growable: false);
    final proofPreview = _proofMetrics.take(3).toList(growable: false);
    final firstPack = packs.first;
    final firstReview = reviews.first;
    final useCompactLayout = AppStrings.code == 'tr' || AppStrings.code == 'en';
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final compactSections = _buildCompactSections(
      context,
      isTr: isTr,
      includeTopBar: !isIOS,
      packs: packs,
      reviews: reviews,
      spot: spot,
      todayProgress: todayProgress,
      matchedPreview: matchedPreview,
      proofPreview: proofPreview,
      firstPack: firstPack,
      firstReview: firstReview,
    );
    final guidedMissionSections = _buildGuidedMissionSections(
      context,
      isTr: isTr,
      packs: packs,
      reviews: reviews,
      proofPreview: proofPreview,
      firstPack: firstPack,
      firstReview: firstReview,
      spot: spot,
      todayProgress: todayProgress,
      matchedPreview: matchedPreview,
    );
    final safeGuidedIndex = guidedMissionSections.isEmpty
        ? 0
        : _guidedSectionIndex.clamp(0, guidedMissionSections.length - 1);
    final guidedActiveSection = guidedMissionSections.isEmpty
        ? null
        : guidedMissionSections[safeGuidedIndex];
    final lessonSteps = _buildDailyLessonSteps();
    final safeLessonIndex = lessonSteps.isEmpty
        ? 0
        : _guidedSectionIndex.clamp(0, lessonSteps.length - 1);
    final activeLessonStep =
        lessonSteps.isEmpty ? null : lessonSteps[safeLessonIndex];

    if (_isMissionMode && activeLessonStep != null) {
      final missionSize = MediaQuery.sizeOf(context);
      final compactMissionChrome =
          missionSize.height < 980 || missionSize.width < 430;
      final lessonAccent = _lessonAccentForStep(activeLessonStep);
      final lessonMood = _lessonMoodForStep(activeLessonStep);
      final lessonIcon = _lessonIconForStep(activeLessonStep);
      final lessonSceneLabel = _lessonSceneLabel(activeLessonStep, isTr);
      final lessonBodyBottomInset =
          _missionFeedbackKind == _MissionFeedbackKind.none
              ? (compactMissionChrome ? 4.0 : 8.0)
              : (compactMissionChrome ? 124.0 : 140.0);
      return Scaffold(
        backgroundColor: Colors.white,
        body: publicAppViewport(
          context,
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _MissionLessonHeader(
                    currentIndex: safeLessonIndex,
                    totalSteps: lessonSteps.length,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
                ),
                if (!compactMissionChrome) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: _MissionPromptCard(
                      stepLabel:
                          '${isTr ? 'Gorev' : 'Mission'} ${safeLessonIndex + 1}',
                      title: activeLessonStep.title(isTr),
                      subtitle: activeLessonStep.subtitle(isTr),
                      coachMessage: activeLessonStep.coach(isTr),
                      accentColor: lessonAccent,
                      mood: lessonMood,
                      sceneIcon: lessonIcon,
                      sceneLabel: lessonSceneLabel,
                      compact: false,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0.12, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          final scale = Tween<double>(
                            begin: 0.96,
                            end: 1,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ));
                          final tilt = Tween<double>(
                            begin: 0.02,
                            end: 0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ));
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: ScaleTransition(
                                scale: scale,
                                child: AnimatedBuilder(
                                  animation: tilt,
                                  child: child,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: tilt.value,
                                      child: child,
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          key: ValueKey(activeLessonStep.id),
                          padding: EdgeInsets.fromLTRB(
                            18,
                            compactMissionChrome ? 12 : 12,
                            18,
                            lessonBodyBottomInset,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: _MissionViewportFrame(
                                compact: compactMissionChrome,
                                child: _buildLessonTaskBody(
                                  context,
                                  isTr: isTr,
                                  step: activeLessonStep,
                                  measurementLabel: _lessonMeasurementLabel(
                                    activeLessonStep,
                                    isTr,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring:
                            _missionFeedbackKind == _MissionFeedbackKind.none,
                        child: AnimatedSlide(
                          offset:
                              _missionFeedbackKind == _MissionFeedbackKind.none
                                  ? const Offset(0, 1.1)
                                  : Offset.zero,
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _missionFeedbackKind ==
                                    _MissionFeedbackKind.none
                                ? 0
                                : 1,
                            duration: const Duration(milliseconds: 260),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 0, 18, 14),
                                child: _MissionSlideUpSuccessCard(
                                  kind: _missionFeedbackKind,
                                  title: _missionCompletionTitle ??
                                      (isTr ? 'Harika' : 'Nice work'),
                                  detail: _missionCompletionDetail ??
                                      (isTr
                                          ? 'Gorevi tamamladin.'
                                          : 'You completed the mission.'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: !(_lessonIntroVisible || _lessonOutroVisible),
                        child: AnimatedOpacity(
                          opacity: (_lessonIntroVisible || _lessonOutroVisible)
                              ? 1
                              : 0,
                          duration: const Duration(milliseconds: 240),
                          child: _LessonSceneOverlay(
                            visible: _lessonIntroVisible || _lessonOutroVisible,
                            accent: lessonAccent,
                            icon: lessonIcon,
                            label: _lessonOutroVisible
                                ? (isTr
                                    ? 'Gorev tamamlandi'
                                    : 'Mission complete')
                                : lessonSceneLabel,
                            title: _lessonOutroVisible
                                ? (_missionCompletionTitle ??
                                    (isTr ? 'Harika' : 'Nice work'))
                                : activeLessonStep.title(isTr),
                            detail: _lessonOutroVisible
                                ? (_missionCompletionDetail ??
                                    (isTr
                                        ? 'Siradaki goreve hazirsin.'
                                        : 'You are ready for the next mission.'))
                                : activeLessonStep.coach(isTr),
                            mood: _lessonOutroVisible
                                ? _LogoCoachMood.celebrate
                                : lessonMood,
                          ),
                        ),
                      ),
                      if (_finalRewardVisible)
                        _FinalLessonRewardScene(
                          isTr: isTr,
                          accent: lessonAccent,
                          goalLabel: isTr ? _goal.titleTr : _goal.titleEn,
                          streak: _streak,
                          weeklySessions: _weeklySessions,
                          finalScore: _finalMissionScore,
                          mistakeCount: _missionMistakeCount,
                          weaknesses: _finalWeaknesses,
                          recommendedTutors: _matchedInstructors,
                          onRegister: ({
                            required slotLabel,
                            required tutor,
                          }) =>
                              _openRegisterFromFinalReward(
                            score: _finalMissionScore,
                            weaknesses: _finalWeaknesses,
                            slotLabel: slotLabel,
                            tutor: tutor,
                          ),
                          onDone: _finishLessonExperience,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          expandHeight: true,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: publicAppViewport(
        context,
        Stack(
          children: [
            if (useCompactLayout && isIOS)
              CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverNavigationBar(
                    largeTitle: Text(
                      isTr ? 'Speaking Coach' : 'Speaking Coach',
                    ),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _openIOSSecondaryActions,
                      child: const Icon(CupertinoIcons.ellipsis_circle),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      6,
                      16,
                      MediaQuery.paddingOf(context).bottom + 126,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        guidedActiveSection == null
                            ? compactSections
                            : [
                                ...compactSections.take(2),
                                const SizedBox(height: 18),
                                _MissionStepperCard(
                                  currentIndex: safeGuidedIndex,
                                  totalSteps: guidedMissionSections.length,
                                  title: guidedActiveSection.title,
                                  subtitle: guidedActiveSection.subtitle,
                                  onNext: () => _goToNextMissionSection(
                                      guidedMissionSections.length),
                                  onPrevious: _goToPreviousMissionSection,
                                ),
                                const SizedBox(height: 14),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 320),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    final offset = Tween<Offset>(
                                      begin: const Offset(0.08, 0),
                                      end: Offset.zero,
                                    ).animate(animation);
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: offset,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(safeGuidedIndex),
                                    child: guidedActiveSection.section,
                                  ),
                                ),
                              ],
                      ),
                    ),
                  ),
                ],
              )
            else
              ListView(
                physics: isIOS
                    ? const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      )
                    : const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 10,
                  16,
                  MediaQuery.paddingOf(context).bottom + 126,
                ),
                children: useCompactLayout
                    ? guidedActiveSection == null
                        ? compactSections
                        : [
                            ...compactSections.take(isIOS ? 2 : 3),
                            const SizedBox(height: 18),
                            _MissionStepperCard(
                              currentIndex: safeGuidedIndex,
                              totalSteps: guidedMissionSections.length,
                              title: guidedActiveSection.title,
                              subtitle: guidedActiveSection.subtitle,
                              onNext: () => _goToNextMissionSection(
                                  guidedMissionSections.length),
                              onPrevious: _goToPreviousMissionSection,
                            ),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final offset = Tween<Offset>(
                                  begin: const Offset(0.08, 0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offset,
                                    child: child,
                                  ),
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(safeGuidedIndex),
                                child: guidedActiveSection.section,
                              ),
                            ),
                          ]
                    : [
                        _TopBar(
                          onOpenPlan: _openPlannerSheet,
                          onLogin: () => Navigator.pushNamed(context, '/login'),
                        ),
                        const SizedBox(height: 18),
                        _HeroCard(
                          goal: _goal,
                          streak: _streak,
                          weeklySessions: _weeklySessions,
                          weeklyTarget: _localState.weeklyTarget,
                          todayProgress: _todayTasks.isEmpty
                              ? 0
                              : _completedToday.length / _todayTasks.length,
                          onOpenPlan: _openPlannerSheet,
                          onOpenPlacement: _openPlacement,
                          onOpenTrial: _openTrial,
                          goalChips: _goals.map((goal) {
                            return _GoalChip(
                              label: isTr ? goal.titleTr : goal.titleEn,
                              selected: goal.id == _goal.id,
                              icon: goal.icon,
                              onTap: () => _setGoal(goal.id),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        _PlannerSummaryCard(
                          scheduleLabel:
                              isTr ? _schedule.titleTr : _schedule.titleEn,
                          scheduleDetail: _schedule.detail,
                          reminderLabel:
                              isTr ? _reminder.titleTr : _reminder.titleEn,
                          weeklyTarget: _localState.weeklyTarget,
                          onEdit: _openPlannerSheet,
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title:
                              isTr ? '7 gunluk challenge' : '7-day challenge',
                          subtitle: isTr
                              ? 'Her gun 1 speaking gorevi. Sonunda ozet + tutor onerisi.'
                              : 'One speaking task per day. End with a summary and tutor recommendation.',
                          action: !_challengeStarted
                              ? TextButton(
                                  onPressed: _startChallenge,
                                  child: Text(isTr ? 'Baslat' : 'Start'),
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                !_challengeStarted
                                    ? _copy(
                                        '7 gun boyunca mini paket + tekrar + tutor inceleme ritmi kur.',
                                        'Build a 7-day rhythm with mini packs, review, and tutor discovery.',
                                      )
                                    : _challengeCompleted
                                        ? _copy(
                                            'Challenge tamamlandi. Simdi seviyeni gorup uygun hocaya gec.',
                                            'Challenge complete. Now review your level and move to the right tutor.',
                                          )
                                        : _copy(
                                            'Gun $_challengeProgressDays / 7 aktif. Ritmi bozma.',
                                            'Day $_challengeProgressDays / 7 is active. Keep the rhythm.',
                                          ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 14),
                              LinearProgressIndicator(
                                value: _challengeStarted
                                    ? (_challengeProgressDays / 7)
                                        .clamp(0.0, 1.0)
                                    : 0,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _ProofPill(
                                    metric: ProofMetric(
                                      value: _challengeStarted
                                          ? '$_challengeProgressDays/7'
                                          : '0/7',
                                      label: _copy(
                                          'Challenge gunu', 'Challenge day'),
                                    ),
                                  ),
                                  _ProofPill(
                                    metric: ProofMetric(
                                      value: _challengeCompleted
                                          ? _copy('Hazir', 'Ready')
                                          : _copy('Devam', 'Live'),
                                      label: _copy(
                                          'Seviye ozeti', 'Level summary'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _challengeStarted
                                          ? _openPlacement
                                          : _startChallenge,
                                      child: Text(
                                        !_challengeStarted
                                            ? _copy('Challenge baslat',
                                                'Start challenge')
                                            : _copy('Seviyeni gor',
                                                'See your level'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _openTutors,
                                      child: Text(
                                        isTr ? 'Tutor onerisi' : 'Tutor picks',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Canli sinyaller' : 'Live momentum',
                          subtitle: isTr
                              ? 'Uygulamadaki gercek akistan gelen sinyaller.'
                              : 'Signals that come from the real flow inside the app.',
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _proofMetrics
                                    .map((metric) => _ProofPill(metric: metric))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              _MomentumCard(
                                streak: _streak,
                                weeklySessions: _weeklySessions,
                                weeklyTarget: _localState.weeklyTarget,
                                todayProgress: _todayTasks.isEmpty
                                    ? 0
                                    : _completedToday.length /
                                        _todayTasks.length,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _copy('Sosyal proof', 'Social proof'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _copy(
                                        'Bugun $_availableTodayCount acik tutor slotu var. $_topGoalLabel.',
                                        'There are $_availableTodayCount open tutor slots today. $_topGoalLabel.',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Hemen basla' : 'Start now',
                          subtitle: isTr
                              ? 'Reklamdan gelen yeni kullanici icin en hizli deger akisi burada.'
                              : 'This is the fastest value loop for a new user coming from an ad.',
                          child: Column(
                            children: [
                              _QuickActionCard(
                                title: isTr
                                    ? '90 saniyede baslangic noktani sec'
                                    : 'Pick your starting point in 90 seconds',
                                detail: isTr
                                    ? 'Seviye testi ile hemen basla, sonra bugunun mini paketine gec.'
                                    : 'Start with the level test, then move into today\'s mini pack.',
                                badge: isTr ? 'Ucretsiz' : 'Free',
                                icon: Icons.rocket_launch_rounded,
                                accentColor: AppColors.brand,
                                ctaLabel: isTr
                                    ? 'Seviye testini ac'
                                    : 'Open level test',
                                onTap: _openPlacement,
                              ),
                              const SizedBox(height: 12),
                              _QuickActionCard(
                                title: isTr
                                    ? 'Ilk canli adimi kilitle'
                                    : 'Lock the first live step',
                                detail: isTr
                                    ? 'Ucretsiz deneme ile hocaya gecmeden once ritmi yakala.'
                                    : 'Use the free trial to connect to a tutor once the rhythm is set.',
                                badge: isTr ? 'Canli gecis' : 'Live next step',
                                icon: Icons.headset_mic_rounded,
                                accentColor: const Color(0xFF0F766E),
                                ctaLabel: _trialCtaLabel,
                                onTap: _openTrial,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Pratik modlari' : 'Practice modes',
                          subtitle: isTr
                              ? 'Rakip uygulamalardaki en guclu pattern: ayni hedefe farkli calisma modu.'
                              : 'The strongest competitor pattern: different training modes for the same goal.',
                          child: Column(
                            children: _practiceModes.map((mode) {
                              final selected = mode.id == _practiceMode.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _QuickActionCard(
                                  title: isTr ? mode.titleTr : mode.titleEn,
                                  detail: isTr ? mode.detailTr : mode.detailEn,
                                  badge: selected
                                      ? _copy('Aktif mod', 'Active mode')
                                      : _copy('Pratik modu', 'Practice mode'),
                                  icon: mode.icon,
                                  accentColor: mode.accentColor,
                                  ctaLabel: selected
                                      ? _copy('Aktif', 'Active')
                                      : _copy('Bu modu sec', 'Use this mode'),
                                  onTap: () => _setPracticeMode(mode.id),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Bugunun plan\'i' : 'Today plan',
                          subtitle: isTr
                              ? 'Test, mini paket ve tekrar ile kisa ama net bir gunluk akis.'
                              : 'A short but clean daily loop: test, mini pack, and review.',
                          child: Column(
                            children: _todayTasks.map((task) {
                              final done = _completedToday.contains(task.id);
                              final onOpen = task.id == 'placement'
                                  ? _openPlacement
                                  : task.id == 'review'
                                      ? () => _openReviewSheet(reviews.first)
                                      : () => _openPackSheet(packs.first);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TaskTile(
                                  _TaskTileData(
                                    title: isTr ? task.titleTr : task.titleEn,
                                    detail:
                                        isTr ? task.detailTr : task.detailEn,
                                    durationLabel: task.durationLabel,
                                    icon: task.icon,
                                    done: done,
                                    buttonLabel:
                                        isTr ? task.buttonTr : task.buttonEn,
                                    onOpen: onOpen,
                                    onToggleDone: () => _toggleTask(task.id),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Bu haftanin yolu' : 'This week path',
                          subtitle: isTr
                              ? 'Calis, tekrar et, sonra canli derse baglan.'
                              : 'Study, review, then connect a live lesson.',
                          child: Column(
                            children: _pathSteps
                                .map((step) => _PathRow(step))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Mini paketler' : 'Mini packs',
                          subtitle: isTr
                              ? 'Gercek hayat kaliplari ve mini diyaloglarla ilerle.'
                              : 'Move through real-life phrase sets and short dialogues.',
                          child: SizedBox(
                            height: 198,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: packs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) => _PackCard(
                                _PackCardData(
                                  title: isTr
                                      ? packs[index].titleTr
                                      : packs[index].titleEn,
                                  subtitle: isTr
                                      ? packs[index].subtitleTr
                                      : packs[index].subtitleEn,
                                  durationLabel: packs[index].durationLabel,
                                  icon: packs[index].icon,
                                  accentColor: packs[index].accentColor,
                                  onTap: () => _openPackSheet(packs[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Tekrar destesi' : 'Review deck',
                          subtitle: isTr
                              ? 'Kartlari ac, notu gor ve ihtiyacin olan cumleyi sec.'
                              : 'Open the cards, scan the note, and keep the sentence you need.',
                          child: SizedBox(
                            height: 184,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: reviews.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) => _ReviewDeckCard(
                                ReviewCardData(
                                  title: isTr
                                      ? reviews[index].titleTr
                                      : reviews[index].titleEn,
                                  phrase: reviews[index].phrase,
                                  meaning: isTr
                                      ? reviews[index].meaningTr
                                      : reviews[index].meaningEn,
                                  usage: isTr
                                      ? reviews[index].usageTr
                                      : reviews[index].usageEn,
                                  onTap: () => _openReviewSheet(reviews[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: 'Pronunciation spot',
                          subtitle: isTr
                              ? 'Tek odakli ritim calismasi. Sahte skor yok, temiz pratik var.'
                              : 'A single-focus rhythm drill. No fake score, just clean practice.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _pronunciationMetricsForGoal(_goal)
                                    .map((metric) => _ProofPill(metric: metric))
                                    .toList(),
                              ),
                              const SizedBox(height: 14),
                              _SheetBlock(isTr
                                  ? '${spot.titleTr}\n\n${spot.focusLine}\n\n${spot.helperTr}'
                                  : '${spot.titleEn}\n\n${spot.focusLine}\n\n${spot.helperEn}'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _setPracticeMode('clarity'),
                                icon:
                                    const Icon(Icons.multitrack_audio_rounded),
                                label: Text(
                                  _copy('Netlik drilline gec',
                                      'Switch to clarity drill'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Record + compare' : 'Record + compare',
                          subtitle: isTr
                              ? 'Ayni odak cumlesini tekrar kaydedip gelisimi karsilastir.'
                              : 'Repeat the same focus line and compare your progress over time.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _copy('Odak cumlesi', 'Focus line'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      spot.focusLine,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    if (_recordingCompare) ...[
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(
                                        minHeight: 8,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        value: (((_compareAmplitude?.current ??
                                                        -50) +
                                                    50) /
                                                50)
                                            .clamp(0.06, 1.0),
                                        color: AppColors.brand,
                                        backgroundColor: Colors.white,
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _toggleCompareRecording,
                                            icon: Icon(
                                              _recordingCompare
                                                  ? Icons.stop_circle_rounded
                                                  : Icons.mic_rounded,
                                            ),
                                            label: Text(
                                              _recordingCompare
                                                  ? _copy('Kaydi bitir',
                                                      'Finish recording')
                                                  : _copy('Kaydi baslat',
                                                      'Start recording'),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          onPressed: (_audioBusy ||
                                                  _compareSessions.isEmpty)
                                              ? null
                                              : _replayLastRecording,
                                          icon:
                                              const Icon(Icons.replay_rounded),
                                          label: Text(
                                            _copy('Replay', 'Replay'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _recordingCompare
                                          ? _copy(
                                              'Kayit aktif. Mikrofona yakin konus, ritmi sabit tut. Ses seviye cubugu anlik tepki veriyor.',
                                              'Recording is active. Stay close to the mic and keep the rhythm steady. The level bar reacts live.',
                                            )
                                          : _copy(
                                              'Gercek mikrofon kaydi alinir. Son kaydi oynatabilir, onceki denemeyle yan yana karsilastirabilirsin.',
                                              'A real microphone capture is saved. You can replay the latest take and compare it side by side with the previous attempt.',
                                            ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              if (_comparePair.length == 2) ...[
                                const SizedBox(height: 14),
                                _ComparePairCard(
                                  latest: _comparePair[0],
                                  previous: _comparePair[1],
                                  isTr: isTr,
                                  activePlaybackSessionId:
                                      _activePlaybackSessionId,
                                  onPlayLatest: () =>
                                      _playCompareSession(_comparePair[0]),
                                  onPlayPrevious: () =>
                                      _playCompareSession(_comparePair[1]),
                                ),
                              ],
                              if (_compareSessions.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                ..._compareSessions.take(3).map((session) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CompareSessionCard(
                                      session: session,
                                      isTr: isTr,
                                      isPlaying: _activePlaybackSessionId ==
                                          session.id,
                                      onPlay: session.audioPath.trim().isEmpty
                                          ? null
                                          : () => _playCompareSession(session),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Streak takvimi' : 'Streak calendar',
                          subtitle: isTr
                              ? 'Son 14 gundeki ritmini gor. Devam gunleri retention icin kritik.'
                              : 'See your rhythm across the last 14 days. Consistency days matter for retention.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _CalendarSummaryPill(
                                      label: _copy(
                                          'Mevcut seri', 'Current streak'),
                                      value: '$_streak',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _CalendarSummaryPill(
                                      label:
                                          _copy('En iyi seri', 'Best streak'),
                                      value: '$_bestStreak',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _calendarDays.map((day) {
                                  return CalendarDayTile(day: day);
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        if (_savedPhrases.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: isTr
                                ? 'Kaydedilen phrasebook'
                                : 'Saved phrasebook',
                            subtitle: isTr
                                ? 'Duolingo/Falou tipi hizli geri donus alani. Ihtiyacin olan ifadeyi tek yerde tut.'
                                : 'A fast-return area inspired by Duolingo/Falou style phrase practice.',
                            child: Column(
                              children: _savedPhrases.map((phrase) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.bookmark_rounded,
                                    color: AppColors.brand,
                                  ),
                                  title: Text(phrase),
                                  trailing: IconButton(
                                    onPressed: () => _toggleSavedPhrase(phrase),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr
                              ? 'Sana en uygun 3 hoca'
                              : '3 tutors that fit your goal',
                          subtitle: isTr
                              ? 'Sahte AI degil. Hedef, uygunluk ve aktif profile gore secilen canli liste.'
                              : 'Not fake AI. Picked from the live list based on goal, availability, and active profile data.',
                          action: TextButton(
                            onPressed: _openTutors,
                            child: Text(isTr ? 'Tumunu ac' : 'Open all'),
                          ),
                          child: Column(
                            children: [
                              if (_availabilityUsingCache)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    isTr
                                        ? 'Baglanti zayif. Uygunluk bilgisi onbellekten gosteriliyor. Bekleyen tekrar: $_pendingAvailabilityRetryCount'
                                        : 'Weak network. Availability is shown from cache. Pending retries: $_pendingAvailabilityRetryCount',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ..._matchedInstructors.map((instructor) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TutorCard(
                                    _TutorCardData(
                                      name: instructor.name,
                                      role: instructor.jobTitle.isNotEmpty
                                          ? instructor.jobTitle
                                          : AppStrings.t('Instructor'),
                                      imageUrl: instructor.imageUrl ?? '',
                                      tags: _matchReasons(instructor),
                                      availabilityLabel:
                                          _availabilityLabel(instructor),
                                      ctaLabel:
                                          isTr ? 'Profili ac' : 'Open profile',
                                      isFavorite: _localState
                                          .favoriteInstructorIds
                                          .contains(instructor.id),
                                      onTap: () =>
                                          _openTutorProfile(instructor),
                                      onToggleFavorite: () =>
                                          _toggleFavoriteTutor(instructor),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        if (_favoriteTutors.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: isTr ? 'Kaydedilen hocalar' : 'Saved tutors',
                            subtitle: isTr
                                ? 'Kararsiz kaldigin profilleri burada tut.'
                                : 'Keep the profiles you want to revisit here.',
                            child: Column(
                              children: _favoriteTutors.map((instructor) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TutorCard(
                                    _TutorCardData(
                                      name: instructor.name,
                                      role: instructor.jobTitle.isNotEmpty
                                          ? instructor.jobTitle
                                          : AppStrings.t('Instructor'),
                                      imageUrl: instructor.imageUrl ?? '',
                                      tags: _matchReasons(instructor),
                                      availabilityLabel:
                                          _availabilityLabel(instructor),
                                      ctaLabel: isTr ? 'Geri don' : 'Resume',
                                      isFavorite: true,
                                      onTap: () =>
                                          _openTutorProfile(instructor),
                                      onToggleFavorite: () =>
                                          _toggleFavoriteTutor(instructor),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Referral akisi' : 'Referral flow',
                          subtitle: isTr
                              ? 'Arkadas getir, ekstra speaking ve oncelik kazan.'
                              : 'Bring a friend and unlock extra speaking plus priority.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isTr
                                                ? 'Referral kodun'
                                                : 'Your referral code',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _localState.referralCode,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                    color:
                                                        AppColors.brandNight),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _copyReferralCode,
                                      child: Text(isTr ? 'Kopyala' : 'Copy'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: _copyReferralInvite,
                                      child: Text(isTr ? 'Davet' : 'Invite'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...[
                                _copy('1 ucretsiz mini speaking seansi',
                                    '1 free mini speaking session'),
                                _copy('Bonus materyal paketi',
                                    'Bonus material pack'),
                                _copy('Deneme dersi onceligi',
                                    'Priority trial lesson'),
                              ].map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.brand,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(item)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Hatirlatici plani' : 'Reminder plan',
                          subtitle: isTr
                              ? 'Gunluk 5 dakikalik gorev icin en uygun zamani sec.'
                              : 'Choose the best time for the daily 5-minute task.',
                          child: Column(
                            children: [
                              ..._reminders.map((reminder) {
                                final selected =
                                    reminder.id == _localState.reminderWindow;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () => _setReminder(reminder.id),
                                  leading: Icon(
                                    selected
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_none_rounded,
                                    color: selected
                                        ? AppColors.brand
                                        : AppColors.muted,
                                  ),
                                  title: Text(
                                    isTr ? reminder.titleTr : reminder.titleEn,
                                  ),
                                  subtitle: Text(
                                    isTr
                                        ? 'Rutini bu zaman penceresine gore kur.'
                                        : 'Build the routine around this time window.',
                                  ),
                                  trailing: selected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.brand,
                                        )
                                      : null,
                                );
                              }),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTr
                                          ? 'Retention triggerlari'
                                          : 'Retention triggers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 10),
                                    ...[
                                      _copy('Gunluk gorev hazir',
                                          'Daily task is ready'),
                                      _copy('Streak gidiyor',
                                          'Your streak is at risk'),
                                      _copy('Bugun uygun tutor var',
                                          'A tutor is available today'),
                                      _copy('Deneme dersi seni bekliyor',
                                          'Your trial lesson is waiting'),
                                    ].map(
                                      (label) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: AppColors.brand,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(label)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: isTr ? 'Speaking gecmisi' : 'Speaking history',
                          subtitle: isTr
                              ? 'Bugun ne actin, ne bitirdin, hangi hocayi inceledin.'
                              : 'See what you opened, completed, and reviewed today.',
                          child: Column(
                            children: _activityLog.isEmpty
                                ? [
                                    Text(
                                      _copy(
                                        'Ilk hareketini yaptiginda gecmis burada gorunecek.',
                                        'Your first actions will appear here.',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ]
                                : _activityLog.map((entry) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(
                                        Icons.history_rounded,
                                        color: AppColors.brand,
                                      ),
                                      title: Text(entry.title),
                                      subtitle: Text(_activityTimeLabel(entry)),
                                    );
                                  }).toList(),
                          ),
                        ),
                      ],
              ),
          ],
        ),
        expandHeight: true,
      ),
    );
  }
}

typedef _TaskTileData = TaskTileData;
typedef _PackCardData = PackCardData;
typedef _TutorCardData = TutorCardData;

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isIOS ? 14 : 16),
        border: Border.all(color: const Color(0xFFE3EAF7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
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
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenPlan, required this.onLogin});

  final Future<void> Function({bool initial}) onOpenPlan;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return TopBar(onOpenPlan: onOpenPlan, onLogin: onLogin);
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.brand : const Color(0xFFE3EAF7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: selected ? Colors.white : AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.goal,
    required this.streak,
    required this.weeklySessions,
    required this.weeklyTarget,
    required this.todayProgress,
    required this.onOpenPlan,
    required this.onOpenPlacement,
    required this.onOpenTrial,
    required this.goalChips,
  });

  final GoalSpec goal;
  final int streak;
  final int weeklySessions;
  final int weeklyTarget;
  final double todayProgress;
  final Future<void> Function({bool initial}) onOpenPlan;
  final VoidCallback onOpenPlacement;
  final VoidCallback onOpenTrial;
  final List<Widget> goalChips;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandNight,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? goal.titleTr : goal.titleEn,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF9FB3FF),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTr ? goal.headlineTr : goal.headlineEn,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isTr ? goal.supportTr : goal.supportEn,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _LogoCoach(
                size: 92,
                bubbleText: isTr
                    ? 'Bugun sadece bir sonraki adima odaklan.'
                    : 'Focus only on the next step today.',
                bubbleAccent: const Color(0xFF9FB3FF),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: goalChips),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: todayProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: AppColors.brand,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  value: '$streak',
                  label: isTr ? 'Seri' : 'Streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  value: '$weeklySessions/$weeklyTarget',
                  label: isTr ? 'Hafta' : 'Week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onOpenPlacement,
                  child: Text(isTr ? 'Teste gir' : 'Take test'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenTrial,
                  child: Text(isTr ? 'Deneme iste' : 'Free trial'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerSummaryCard extends StatelessWidget {
  const _PlannerSummaryCard({
    required this.scheduleLabel,
    required this.scheduleDetail,
    required this.reminderLabel,
    required this.weeklyTarget,
    required this.onEdit,
  });

  final String scheduleLabel;
  final String scheduleDetail;
  final String reminderLabel;
  final int weeklyTarget;
  final Future<void> Function({bool initial}) onEdit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.code == 'tr' ? 'Plan ozeti' : 'Plan summary',
      subtitle: scheduleDetail,
      action: TextButton(
        onPressed: () => onEdit(),
        child: Text(AppStrings.code == 'tr' ? 'Duzenle' : 'Edit'),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProofPill(
              metric: ProofMetric(value: scheduleLabel, label: 'Schedule'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProofPill(
              metric: ProofMetric(value: '$weeklyTarget', label: 'Target'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProofPill(
              metric: ProofMetric(value: reminderLabel, label: 'Reminder'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionStepperCard extends StatelessWidget {
  const _MissionStepperCard({
    required this.currentIndex,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.onNext,
    required this.onPrevious,
  });

  final int currentIndex;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final progress = totalSteps <= 1 ? 1.0 : (currentIndex + 1) / totalSteps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFFFC44D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A00).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isTr ? 'Adim' : 'Step'} ${currentIndex + 1}/$totalSteps',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _LogoCoach(
                size: 42,
                bubbleText: '',
                bubbleAccent: Colors.white,
                showBubble: false,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(isTr ? 'Geri' : 'Back'),
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: currentIndex >= totalSteps - 1 ? null : onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandNight,
                  ),
                  child: Text(
                    currentIndex >= totalSteps - 1
                        ? (isTr ? 'Son adim' : 'Last step')
                        : (isTr ? 'Devam et' : 'Continue'),
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

class _ProofPill extends StatelessWidget {
  const _ProofPill({required this.metric});

  final ProofMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.brandNight,
            ),
          ),
          const SizedBox(height: 4),
          Text(metric.label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _LessonProgressBar extends StatefulWidget {
  const _LessonProgressBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.height,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;

  @override
  State<_LessonProgressBar> createState() => _LessonProgressBarState();
}

class _LessonProgressBarState extends State<_LessonProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: widget.backgroundColor),
                  child: const SizedBox.expand(),
                ),
                FractionallySizedBox(
                  widthFactor: widget.value.clamp(0.0, 1.0),
                  child: Stack(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(color: widget.color),
                        child: const SizedBox.expand(),
                      ),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Align(
                            alignment: Alignment(
                              -1 + (_controller.value * 2),
                              0,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0.22,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0),
                                      Colors.white.withValues(alpha: 0.24),
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MissionLessonHeader extends StatelessWidget {
  const _MissionLessonHeader({
    required this.currentIndex,
    required this.totalSteps,
    required this.onClose,
  });

  final int currentIndex;
  final int totalSteps;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps <= 1 ? 1.0 : (currentIndex + 1) / totalSteps;
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.muted,
          ),
          icon: const Icon(Icons.close_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LessonProgressBar(
            value: progress,
            color: const Color(0xFF63D60F),
            backgroundColor: const Color(0xFFE6E9EE),
            height: 14,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: const [
              Icon(Icons.favorite_rounded, color: Color(0xFFFF5B7F), size: 18),
              SizedBox(width: 6),
              Text(
                '5',
                style: TextStyle(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionPromptCard extends StatelessWidget {
  const _MissionPromptCard({
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.coachMessage,
    required this.accentColor,
    required this.mood,
    required this.sceneIcon,
    required this.sceneLabel,
    this.compact = false,
  });

  final String stepLabel;
  final String title;
  final String subtitle;
  final String coachMessage;
  final Color accentColor;
  final _LogoCoachMood mood;
  final IconData sceneIcon;
  final String sceneLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 12 : 16,
        compact ? 14 : 18,
        compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF8FBFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6EDF8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -10,
            child: Container(
              width: compact ? 72 : 110,
              height: compact ? 72 : 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.18),
                    const Color(0xFF63D60F).withValues(alpha: 0.06),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              _LogoCoach(
                size: compact ? 64 : 116,
                bubbleText: compact ? '' : coachMessage,
                bubbleAccent: accentColor,
                mood: mood,
                showBubble: !compact,
              ),
              SizedBox(height: compact ? 8 : 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      stepLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 12 : null,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE5ECF7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sceneIcon, size: 16, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          sceneLabel,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppColors.brandNight,
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 12 : null,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 18 : null,
                    ),
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionViewportFrame extends StatelessWidget {
  const _MissionViewportFrame({
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 20,
        compact ? 12 : 18,
        compact ? 12 : 20,
        compact ? 12 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LessonAutoFit extends StatelessWidget {
  const _LessonAutoFit({
    required this.constraints,
    required this.child,
  });

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shouldFit = constraints.maxHeight < 620 || constraints.maxWidth < 430;
    if (!shouldFit) {
      return child;
    }

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MissionOptionTile extends StatelessWidget {
  const _MissionOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.feedbackKind = _MissionFeedbackKind.none,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final _MissionFeedbackKind feedbackKind;

  @override
  Widget build(BuildContext context) {
    final wrongSelected =
        selected && feedbackKind == _MissionFeedbackKind.error;
    final selectedColor =
        wrongSelected ? const Color(0xFFFFF1E5) : const Color(0xFFEAF7FF);
    final borderColor =
        wrongSelected ? const Color(0xFFFFA33A) : AppColors.brand;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: wrongSelected ? 1 : 0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final shake = wrongSelected
            ? math.sin(value * math.pi * 6) * (1 - value) * 10
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            scale: selected ? 1.015 : 1,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 12 : 20,
          ),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.white,
            borderRadius: BorderRadius.circular(compact ? 18 : 24),
            border: Border.all(
              color: selected ? borderColor : const Color(0xFFDCE4EE),
              width: selected ? 2.4 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? borderColor : AppColors.brandNight)
                    .withValues(alpha: selected ? 0.16 : 0.06),
                blurRadius: selected ? 20 : 14,
                offset: Offset(0, selected ? 12 : 9),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: compact ? 14 : 18,
                height: compact ? 14 : 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? borderColor : Colors.white,
                  border: Border.all(
                    color: selected ? borderColor : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: (compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.titleMedium)
                      ?.copyWith(
                    color: AppColors.brandNight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: selected ? 1.12 : 1,
                child: Icon(
                  selected
                      ? (wrongSelected
                          ? Icons.close_rounded
                          : Icons.check_circle_rounded)
                      : Icons.chevron_right_rounded,
                  color: selected ? borderColor : AppColors.muted,
                  size: compact ? 18 : 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionAudioPromptCard extends StatelessWidget {
  const _MissionAudioPromptCard({
    required this.prompt,
    required this.isPlaying,
    required this.onTap,
    this.compact = false,
  });

  final String prompt;
  final bool isPlaying;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        border: Border.all(color: const Color(0xFFE3EAF2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _PulsingSpeakerButton(
            compact: compact,
            isPlaying: isPlaying,
            onTap: onTap,
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Text(
              prompt,
              style: (compact
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(
                color: AppColors.brandNight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingSpeakerButton extends StatefulWidget {
  const _PulsingSpeakerButton({
    required this.compact,
    required this.isPlaying,
    required this.onTap,
  });

  final bool compact;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  State<_PulsingSpeakerButton> createState() => _PulsingSpeakerButtonState();
}

class _PulsingSpeakerButtonState extends State<_PulsingSpeakerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingSpeakerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 44.0 : 56.0;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final pulse = 1 + (_controller.value * 0.32);
                return Opacity(
                  opacity: widget.isPlaying
                      ? (0.28 - (_controller.value * 0.22))
                      : 0,
                  child: Transform.scale(
                    scale: pulse,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.isPlaying
                    ? const Color(0xFFEAF7FF)
                    : const Color(0xFFF4F8FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isPlaying
                      ? AppColors.brand
                      : const Color(0xFFDCE7F7),
                  width: 1.8,
                ),
              ),
              child: Icon(
                widget.isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.volume_up_rounded,
                color: AppColors.brand,
                size: widget.compact ? 20 : 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionMatchChip extends StatelessWidget {
  const _MissionMatchChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 170),
      scale: selected ? 1.015 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.14) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE2E8F0),
              width: selected ? 2.2 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: selected ? 0.18 : 0.0),
                blurRadius: selected ? 16 : 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonSceneOverlay extends StatelessWidget {
  const _LessonSceneOverlay({
    required this.visible,
    required this.accent,
    required this.icon,
    required this.label,
    required this.title,
    required this.detail,
    required this.mood,
  });

  final bool visible;
  final Color accent;
  final IconData icon;
  final String label;
  final String title;
  final String detail;
  final _LogoCoachMood mood;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 260),
            scale: visible ? 1 : 0.96,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LogoCoach(
                    size: 88,
                    bubbleText: '',
                    bubbleAccent: accent,
                    mood: mood,
                    showBubble: false,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.brandNight,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _FinalRewardRegisterCallback = FutureOr<void> Function({
  required String slotLabel,
  required InstructorSummary? tutor,
});

class _FinalLessonRewardScene extends StatefulWidget {
  const _FinalLessonRewardScene({
    required this.isTr,
    required this.accent,
    required this.goalLabel,
    required this.streak,
    required this.weeklySessions,
    required this.finalScore,
    required this.mistakeCount,
    required this.weaknesses,
    required this.recommendedTutors,
    required this.onRegister,
    required this.onDone,
  });

  final bool isTr;
  final Color accent;
  final String goalLabel;
  final int streak;
  final int weeklySessions;
  final int finalScore;
  final int mistakeCount;
  final List<String> weaknesses;
  final List<InstructorSummary> recommendedTutors;
  final _FinalRewardRegisterCallback onRegister;
  final VoidCallback onDone;

  @override
  State<_FinalLessonRewardScene> createState() =>
      _FinalLessonRewardSceneState();
}

class _FinalLessonRewardSceneState extends State<_FinalLessonRewardScene> {
  late String _selectedSlot;
  int _selectedTutorIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedSlot = _slotOptions.first;
  }

  List<String> get _slotOptions => widget.isTr
      ? const ['Bugun 19:00', 'Yarin 20:30', 'Hafta sonu']
      : const ['Today 19:00', 'Tomorrow 20:30', 'Weekend'];

  InstructorSummary? get _selectedTutor {
    if (widget.recommendedTutors.isEmpty) return null;
    final index =
        _selectedTutorIndex.clamp(0, widget.recommendedTutors.length - 1);
    return widget.recommendedTutors[index];
  }

  String get _levelComment {
    final score = widget.finalScore;
    if (widget.isTr) {
      if (score >= 88) {
        return 'Speaking seviyen B1-B2 arasi. Akicilik iyi, canli derste hiz ve dogallik calisilmali.';
      }
      if (score >= 72) {
        return 'Speaking seviyen A2-B1 arasi. En hizli gelisim telaffuz ve cumle kurma ile gelir.';
      }
      return 'Speaking seviyen A1-A2 arasi. Once temel cumle ritmi ve gunluk kaliplar guclenmeli.';
    }
    if (score >= 88) {
      return 'Your speaking level is around B1-B2. Fluency is strong; live lessons should focus on speed and natural delivery.';
    }
    if (score >= 72) {
      return 'Your speaking level is around A2-B1. The fastest gains will come from pronunciation and sentence building.';
    }
    return 'Your speaking level is around A1-A2. Start with sentence rhythm and daily speaking patterns.';
  }

  String get _weaknessText {
    final joined = widget.weaknesses.join(', ');
    return widget.isTr
        ? 'Bugun zorlandigin alanlar: $joined.'
        : 'Today you struggled most with: $joined.';
  }

  String _tutorBadge(int index) {
    if (widget.isTr) {
      return const [
        'En uygun',
        'En erken musait',
        'Speaking uzmani'
      ][index.clamp(0, 2)];
    }
    return const [
      'Best match',
      'Earliest available',
      'Speaking specialist'
    ][index.clamp(0, 2)];
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.isTr;
    final accent = widget.accent;
    final tutorList = widget.recommendedTutors.take(3).toList(growable: false);
    return IgnorePointer(
      ignoring: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.94),
              const Color(0xFFF7FFF1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.16),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isTr ? 'Ders tamamlandi' : 'Lesson complete',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LogoCoach(
                      size: 118,
                      bubbleText: '',
                      bubbleAccent: accent,
                      mood: _LogoCoachMood.celebrate,
                      showBubble: false,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isTr
                          ? 'Harika, bugunku akisi bitirdin'
                          : 'Nice work, you finished today\'s flow',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.brandNight,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTr
                          ? '${widget.goalLabel} rotasinda ilerlemeye devam ediyorsun.'
                          : 'You are still moving forward on your ${widget.goalLabel} path.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _RewardStatChip(
                            label: isTr ? 'Puan' : 'Score',
                            value: '${widget.finalScore}',
                            accent: accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RewardStatChip(
                            label: isTr ? 'Hata' : 'Mistakes',
                            value: '${widget.mistakeCount}',
                            accent: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _RewardStatChip(
                            label: isTr ? 'Seri' : 'Streak',
                            value: '${widget.streak}',
                            accent: accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RewardStatChip(
                            label: isTr ? 'Hafta' : 'Week',
                            value: '${widget.weeklySessions}',
                            accent: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _RewardInsightCard(
                      isTr: isTr,
                      accent: accent,
                      levelComment: _levelComment,
                      weaknessText: _weaknessText,
                    ),
                    const SizedBox(height: 12),
                    _RewardSlotPicker(
                      isTr: isTr,
                      accent: accent,
                      slots: _slotOptions,
                      selectedSlot: _selectedSlot,
                      onSelected: (value) => setState(() {
                        _selectedSlot = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _TutorCompareSection(
                      isTr: isTr,
                      accent: accent,
                      tutors: tutorList,
                      selectedIndex: _selectedTutorIndex,
                      badgeForIndex: _tutorBadge,
                      onSelected: (index) => setState(() {
                        _selectedTutorIndex = index;
                      }),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => widget.onRegister(
                          slotLabel: _selectedSlot,
                          tutor: _selectedTutor,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5FD117),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          isTr
                              ? 'Ucretsiz deneme dersi al'
                              : 'Get a free trial lesson',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onDone,
                      child: Text(
                        isTr ? "Lingufranca'yi tani" : 'Meet Lingufranca',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardStatChip extends StatelessWidget {
  const _RewardStatChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RewardInsightCard extends StatelessWidget {
  const _RewardInsightCard({
    required this.isTr,
    required this.accent,
    required this.levelComment,
    required this.weaknessText,
  });

  final bool isTr;
  final Color accent;
  final String levelComment;
  final String weaknessText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Kisisel seviye yorumu' : 'Personal level insight',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            levelComment,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brandNight,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            weaknessText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Sana uygun hedef: gunluk speaking rutini ve canli telaffuz dersi.'
                : 'Recommended goal: daily speaking routine and live pronunciation lesson.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brandNight,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE9FFD8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isTr
                  ? 'Odul: 1 ucretsiz mini speaking seansi kazandin. Bu hak 24 saat gecerli.'
                  : 'Reward: you unlocked 1 free mini speaking session. This is valid for 24 hours.',
              style: const TextStyle(
                color: Color(0xFF2E7D10),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardSlotPicker extends StatelessWidget {
  const _RewardSlotPicker({
    required this.isTr,
    required this.accent,
    required this.slots,
    required this.selectedSlot,
    required this.onSelected,
  });

  final bool isTr;
  final Color accent;
  final List<String> slots;
  final String selectedSlot;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Deneme dersi icin saat sec' : 'Pick a trial lesson time',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final selected = slot == selectedSlot;
              return ChoiceChip(
                label: Text(slot),
                selected: selected,
                onSelected: (_) => onSelected(slot),
                selectedColor: accent.withValues(alpha: 0.18),
                labelStyle: TextStyle(
                  color: selected ? accent : AppColors.brandNight,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? accent : const Color(0xFFE3EAF5),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TutorCompareSection extends StatelessWidget {
  const _TutorCompareSection({
    required this.isTr,
    required this.accent,
    required this.tutors,
    required this.selectedIndex,
    required this.badgeForIndex,
    required this.onSelected,
  });

  final bool isTr;
  final Color accent;
  final List<InstructorSummary> tutors;
  final int selectedIndex;
  final String Function(int index) badgeForIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (tutors.isEmpty) {
      return _TrialBookingCard(
        isTr: isTr,
        accent: accent,
        tutor: null,
        onRegister: () {},
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Sana uygun ogretmenler' : 'Teachers matched to you',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          ...List.generate(tutors.length, (index) {
            final tutor = tutors[index];
            final selected = index == selectedIndex;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == tutors.length - 1 ? 0 : 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        selected ? accent.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? accent : const Color(0xFFE3EAF5),
                      width: selected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        backgroundImage: (tutor.imageUrl ?? '').trim().isEmpty
                            ? null
                            : NetworkImage(tutor.imageUrl!.trim()),
                        child: (tutor.imageUrl ?? '').trim().isEmpty
                            ? Icon(Icons.person_rounded, color: accent)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badgeForIndex(index),
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tutor.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: AppColors.brandNight,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              tutor.jobTitle.isEmpty
                                  ? (isTr
                                      ? 'Speaking ogretmeni'
                                      : 'Speaking teacher')
                                  : tutor.jobTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (tutor.avgRating > 0) ...[
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB020), size: 18),
                        Text(
                          tutor.avgRating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
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

class _TrialBookingCard extends StatelessWidget {
  const _TrialBookingCard({
    required this.isTr,
    required this.accent,
    required this.tutor,
    required this.onRegister,
  });

  final bool isTr;
  final Color accent;
  final InstructorSummary? tutor;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final name = (tutor?.name.trim().isNotEmpty ?? false)
        ? tutor!.name.trim()
        : (isTr ? 'Speaking tutoru' : 'Speaking tutor');
    final role = (tutor?.jobTitle.trim().isNotEmpty ?? false)
        ? tutor!.jobTitle.trim()
        : (isTr ? 'Canli ders ogretmeni' : 'Live lesson teacher');
    final about = (tutor?.shortBio.trim().isNotEmpty ?? false)
        ? tutor!.shortBio.trim()
        : (isTr
            ? 'Puanina gore sana uygun deneme dersi icin ogretmen onerisi hazir.'
            : 'A teacher recommendation is ready for your trial lesson based on your score.');
    final imageUrl = tutor?.imageUrl?.trim() ?? '';
    final tags = (tutor?.tags ?? const <String>[]).take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Siradaki adim' : 'Next step',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 62,
                  height: 62,
                  color: accent.withValues(alpha: 0.12),
                  child: imageUrl.isEmpty
                      ? Icon(Icons.person_rounded, color: accent, size: 34)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            color: accent,
                            size: 34,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if ((tutor?.avgRating ?? 0) > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB020),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tutor!.avgRating.toStringAsFixed(1),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.brandNight,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            about,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.35,
                ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(
                isTr
                    ? 'Rezervasyon yap, kayit ol'
                    : 'Book a lesson, create account',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionSlideUpSuccessCard extends StatelessWidget {
  const _MissionSlideUpSuccessCard({
    required this.kind,
    required this.title,
    required this.detail,
  });

  final _MissionFeedbackKind kind;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final success = kind != _MissionFeedbackKind.error;
    final accent = success ? const Color(0xFF74D117) : const Color(0xFFFFA33A);
    final bgTop = success ? const Color(0xFFE8FFD3) : const Color(0xFFFFF1E5);
    final bgBottom =
        success ? const Color(0xFFD7F7BA) : const Color(0xFFFFE2C7);
    final border = success ? const Color(0xFFCFEFAE) : const Color(0xFFFFD3A8);
    final titleColor =
        success ? const Color(0xFF2E7D10) : const Color(0xFFB45309);
    final bodyColor =
        success ? const Color(0xFF4A6B3C) : const Color(0xFF9A5B22);
    final icon = success ? Icons.check_circle_rounded : Icons.close_rounded;
    final mood = success ? _LogoCoachMood.celebrate : _LogoCoachMood.guide;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bgTop,
            bgBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -6,
            child: Opacity(
              opacity: 0.16,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 76,
                color: accent.withValues(alpha: 0.8),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogoCoach(
                size: 62,
                bubbleText: '',
                bubbleAccent: accent,
                mood: mood,
                showBubble: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: titleColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: bodyColor,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionVisualCardTile extends StatelessWidget {
  const _MissionVisualCardTile({
    required this.label,
    required this.selected,
    required this.visualSeed,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String visualSeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      scale: selected ? 1.02 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FBFF) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? AppColors.brand : const Color(0xFFE4EAF1),
              width: selected ? 2.4 : 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? AppColors.brand : AppColors.brandNight)
                    .withValues(alpha: selected ? 0.14 : 0.05),
                blurRadius: selected ? 22 : 14,
                offset: Offset(0, selected ? 14 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MissionIllustrationSurface(
                  seed: visualSeed, label: label, height: 112),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: selected ? 1.14 : 1,
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: selected ? AppColors.brand : AppColors.muted,
                    ),
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

class _MissionPictureTile extends StatelessWidget {
  const _MissionPictureTile({
    required this.label,
    required this.selected,
    required this.visualSeed,
    this.icon,
    required this.onTap,
    this.feedbackKind = _MissionFeedbackKind.none,
  });

  final String label;
  final bool selected;
  final String visualSeed;
  final IconData? icon;
  final VoidCallback onTap;
  final _MissionFeedbackKind feedbackKind;

  @override
  Widget build(BuildContext context) {
    final wrongSelected =
        selected && feedbackKind == _MissionFeedbackKind.error;
    final visual = icon == null
        ? _MissionIllustrationSurface(
            seed: visualSeed,
            label: label,
            height: double.infinity,
          )
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _missionAccentForSeed(visualSeed).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 52,
                color: _missionAccentForSeed(visualSeed),
              ),
            ),
          );
    final borderColor =
        wrongSelected ? const Color(0xFFFFA33A) : AppColors.brand;
    final fillColor =
        wrongSelected ? const Color(0xFFFFF1E5) : const Color(0xFFEAF7FF);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: wrongSelected ? 1 : 0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final shake = wrongSelected
            ? math.sin(value * math.pi * 6) * (1 - value) * 10
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            scale: selected ? 1.03 : 1,
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? fillColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? borderColor : const Color(0xFFE3EAF2),
              width: selected ? 2.2 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? borderColor : AppColors.brandNight)
                    .withValues(alpha: selected ? 0.14 : 0.05),
                blurRadius: selected ? 20 : 14,
                offset: Offset(0, selected ? 14 : 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: visual,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.brandNight,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionTutorTile extends StatelessWidget {
  const _MissionTutorTile({
    required this.label,
    required this.selected,
    required this.visualSeed,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String visualSeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials =
        label.trim().isEmpty ? 'T' : label.trim().substring(0, 1).toUpperCase();
    final accent = _missionAccentForSeed(visualSeed);
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      scale: selected ? 1.02 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5FBFF) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.brand : const Color(0xFFE3EAF2),
              width: selected ? 2.2 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? AppColors.brand : AppColors.brandNight)
                    .withValues(alpha: selected ? 0.14 : 0.05),
                blurRadius: selected ? 20 : 14,
                offset: Offset(0, selected ? 14 : 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.brandNight,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.code == 'tr'
                          ? 'Bugun uygun ve eslesmeye hazir'
                          : 'Available today and ready to match',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: selected ? 1.14 : 1,
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? AppColors.brand : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionToolPill extends StatelessWidget {
  const _MissionToolPill({
    required this.label,
    required this.selected,
    required this.visualSeed,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String visualSeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _missionAccentForSeed(visualSeed);
    return AnimatedScale(
      duration: const Duration(milliseconds: 170),
      scale: selected ? 1.03 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.16) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE3EAF2),
              width: selected ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: selected ? 0.14 : 0),
                blurRadius: selected ? 16 : 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonMeasurementPill extends StatelessWidget {
  const _LessonMeasurementPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCFE8FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.analytics_rounded,
            size: 15,
            color: Color(0xFF1D7CFF),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF12345B),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _LessonTaskHero extends StatelessWidget {
  const _LessonTaskHero({
    required this.type,
    required this.compact,
    required this.dense,
    required this.accent,
  });

  final _LessonTaskType type;
  final bool compact;
  final bool dense;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final height = dense ? 70.0 : (compact ? 82.0 : 96.0);
    final logoSize = dense ? 34.0 : (compact ? 42.0 : 50.0);

    final isTr = AppStrings.code == 'tr';
    final (title, detail, icon, mood) = switch (type) {
      _LessonTaskType.listenChoice => (
          isTr ? 'DINLE' : 'LISTEN',
          isTr
              ? 'Bir kez dinle ve dogru anlami sec.'
              : 'Listen once and choose the right meaning.',
          Icons.volume_up_rounded,
          _LogoCoachMood.listen,
        ),
      _LessonTaskType.textChoice => (
          isTr ? 'ANLAM' : 'MEANING',
          isTr
              ? 'Cumleyi oku ve Turkce karsiligini bul.'
              : 'Read the line and catch the translation.',
          Icons.translate_rounded,
          _LogoCoachMood.guide,
        ),
      _LessonTaskType.pictureChoice => (
          isTr ? 'GORSEL' : 'VISUAL',
          isTr
              ? 'Kelimeyi dogru gorselle eslestir.'
              : 'Match the word with the right scene.',
          Icons.auto_awesome_mosaic_rounded,
          _LogoCoachMood.guide,
        ),
      _LessonTaskType.speakRepeat => (
          isTr ? 'KONUS' : 'SPEAK',
          isTr
              ? 'Net soyle ve speaking skorunu gor.'
              : 'Say it clearly and watch the score.',
          Icons.mic_rounded,
          _LogoCoachMood.celebrate,
        ),
    };

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.14),
                    accent.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: dense ? 12 : 16,
            top: 0,
            bottom: 0,
            child: _LogoCoach(
              size: logoSize + (dense ? 6 : 8),
              bubbleText: '',
              bubbleAccent: accent,
              mood: mood,
              showBubble: false,
            ),
          ),
          Positioned(
            left: dense ? 74 : 88,
            right: dense ? 14 : 18,
            top: dense ? 12 : 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: dense ? 18 : 22,
                      height: dense ? 18 : 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: dense ? 11 : 14,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: dense ? 4 : 6),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w700,
                        height: 1.22,
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

class _MissionIllustrationSurface extends StatelessWidget {
  const _MissionIllustrationSurface({
    required this.seed,
    required this.label,
    required this.height,
  });

  final String seed;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final accent = _missionAccentForSeed(seed);
    final parts = label
        .trim()
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList(growable: false);
    final short = parts.isEmpty
        ? 'GO'
        : parts.map((part) => part[0]).join().toUpperCase();

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -8,
            top: 14,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 18,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                short,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _missionAccentForSeed(String seed) {
  final accents = <Color>[
    const Color(0xFF3D5CFF),
    const Color(0xFF06B6D4),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
  ];
  final hash = seed.codeUnits.fold<int>(0, (sum, value) => sum + value);
  return accents[hash % accents.length];
}

class _AnimatedBlock extends StatelessWidget {
  const _AnimatedBlock({
    required this.child,
    required this.delayMs,
  });

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: Opacity(
            opacity: value.clamp(0, 1),
            child: child,
          ),
        );
      },
    );
  }
}

class _FeatureGuideCard extends StatelessWidget {
  const _FeatureGuideCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                Positioned(
                  left: 10,
                  top: 16,
                  child: _LogoCoach(
                    size: 32,
                    bubbleText: '',
                    bubbleAccent: accentColor,
                    showBubble: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.brandNight,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
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

enum _LogoCoachMood {
  idle,
  guide,
  listen,
  celebrate,
}

class _LogoCoach extends StatefulWidget {
  const _LogoCoach({
    required this.size,
    required this.bubbleText,
    required this.bubbleAccent,
    this.showBubble = true,
    this.mood = _LogoCoachMood.guide,
  });

  final double size;
  final String bubbleText;
  final Color bubbleAccent;
  final bool showBubble;
  final _LogoCoachMood mood;

  @override
  State<_LogoCoach> createState() => _LogoCoachState();
}

class _LogoCoachState extends State<_LogoCoach>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _blinkProgress(double value) {
    double blinkAt(double center, double width) {
      final distance = (value - center).abs();
      if (distance >= width) return 1;
      return (distance / width).clamp(0.0, 1.0);
    }

    return math.min(blinkAt(0.18, 0.045), blinkAt(0.72, 0.035));
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final theta = _controller.value * math.pi * 2;
        final wave = math.sin(theta);
        final secondary = math.cos(theta);
        final bounceAmplitude = switch (widget.mood) {
          _LogoCoachMood.idle => 4.0,
          _LogoCoachMood.guide => 6.0,
          _LogoCoachMood.listen => 5.0,
          _LogoCoachMood.celebrate => 9.0,
        };
        final rotationAmplitude = switch (widget.mood) {
          _LogoCoachMood.idle => 0.02,
          _LogoCoachMood.guide => 0.035,
          _LogoCoachMood.listen => 0.026,
          _LogoCoachMood.celebrate => 0.045,
        };
        final glowBoost = switch (widget.mood) {
          _LogoCoachMood.idle => 0.16,
          _LogoCoachMood.guide => 0.18,
          _LogoCoachMood.listen => 0.20,
          _LogoCoachMood.celebrate => 0.28,
        };
        final bounce = wave * bounceAmplitude;
        final rotation = secondary * rotationAmplitude;
        final shadowScale = 1 - (wave.abs() * 0.1);
        final blink = _blinkProgress(_controller.value);
        final eyeHeight =
            math.max(widget.size * 0.035, widget.size * 0.12 * blink);
        final bodyColor = switch (widget.mood) {
          _LogoCoachMood.idle => const Color(0xFF2F80ED),
          _LogoCoachMood.guide => const Color(0xFF1D7CFF),
          _LogoCoachMood.listen => const Color(0xFF00A7E8),
          _LogoCoachMood.celebrate => const Color(0xFF1368E8),
        };
        final wingColor =
            Color.lerp(bodyColor, Colors.white, 0.46) ?? bodyColor;
        final bellyColor = Colors.white;
        final eyelidColor =
            Color.lerp(bodyColor, Colors.black, 0.08) ?? bodyColor;
        final innerEarColor = const Color(0xFFEAF6FF);
        final muzzleColor = const Color(0xFFF8FCFF);
        final noseColor = const Color(0xFF12345B);
        final pupilOffset = secondary * widget.size * 0.008;
        final shell = SizedBox(
          width: widget.size + 34,
          height: widget.size + 34,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.mood == _LogoCoachMood.celebrate ||
                  widget.mood == _LogoCoachMood.guide) ...[
                Positioned(
                  left: 10,
                  top: 12 + (secondary * 6),
                  child: _CoachSparkle(
                    size: widget.size * 0.1,
                    color: const Color(0xFFFFC44D),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 22 - (wave * 5),
                  child: _CoachSparkle(
                    size: widget.size * 0.08,
                    color: widget.bubbleAccent,
                  ),
                ),
              ],
              if (widget.mood == _LogoCoachMood.listen) ...[
                Positioned(
                  right: 6,
                  child: _CoachWaveDots(
                    progress: _controller.value,
                    color: AppColors.brand,
                    size: widget.size * 0.14,
                  ),
                ),
              ],
              Transform.translate(
                offset: Offset(0, bounce),
                child: Transform.rotate(
                  angle: rotation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1 + ((secondary + 1) * 0.03),
                        child: Container(
                          width: widget.size * 1.02,
                          height: widget.size * 1.02,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.bubbleAccent.withValues(
                              alpha: glowBoost,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: widget.size * 0.07,
                        bottom: widget.size * 0.2,
                        child: Transform.rotate(
                          angle: -0.62 + (wave * 0.05),
                          child: Container(
                            width: widget.size * 0.18,
                            height: widget.size * 0.34,
                            decoration: BoxDecoration(
                              color: wingColor,
                              borderRadius: BorderRadius.circular(widget.size),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -widget.size * 0.02,
                        bottom: widget.size * 0.17,
                        child: Transform.rotate(
                          angle: 0.88 - (wave * 0.12),
                          child: Container(
                            width: widget.size * 0.22,
                            height: widget.size * 0.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  bodyColor,
                                  wingColor,
                                  Colors.white,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(widget.size),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: widget.size * 0.06,
                        left: widget.size * 0.26,
                        child: Transform.rotate(
                          angle: -0.28,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: widget.size * 0.2,
                                height: widget.size * 0.24,
                                decoration: BoxDecoration(
                                  color: bodyColor,
                                  borderRadius:
                                      BorderRadius.circular(widget.size * 0.08),
                                ),
                              ),
                              Container(
                                width: widget.size * 0.1,
                                height: widget.size * 0.12,
                                decoration: BoxDecoration(
                                  color: innerEarColor,
                                  borderRadius:
                                      BorderRadius.circular(widget.size * 0.06),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: widget.size * 0.06,
                        right: widget.size * 0.26,
                        child: Transform.rotate(
                          angle: 0.28,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: widget.size * 0.2,
                                height: widget.size * 0.24,
                                decoration: BoxDecoration(
                                  color: bodyColor,
                                  borderRadius:
                                      BorderRadius.circular(widget.size * 0.08),
                                ),
                              ),
                              Container(
                                width: widget.size * 0.1,
                                height: widget.size * 0.12,
                                decoration: BoxDecoration(
                                  color: innerEarColor,
                                  borderRadius:
                                      BorderRadius.circular(widget.size * 0.06),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: widget.size * 0.12,
                        child: Container(
                          width: widget.size * 0.42,
                          height: widget.size * 0.08,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(widget.size),
                          ),
                        ),
                      ),
                      Container(
                        width: widget.size * 0.9,
                        height: widget.size * 0.88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(bodyColor, Colors.white, 0.16) ??
                                  bodyColor,
                              bodyColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius:
                              BorderRadius.circular(widget.size * 0.42),
                          boxShadow: [
                            BoxShadow(
                              color: widget.bubbleAccent.withValues(
                                alpha: glowBoost,
                              ),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: widget.size * 0.2,
                              child: Container(
                                width: widget.size * 0.62,
                                height: widget.size * 0.42,
                                decoration: BoxDecoration(
                                  color: muzzleColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft:
                                        Radius.circular(widget.size * 0.28),
                                    topRight:
                                        Radius.circular(widget.size * 0.28),
                                    bottomLeft:
                                        Radius.circular(widget.size * 0.16),
                                    bottomRight:
                                        Radius.circular(widget.size * 0.16),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: widget.size * 0.08,
                              child: Container(
                                width: widget.size * 0.42,
                                height: widget.size * 0.34,
                                decoration: BoxDecoration(
                                  color: bellyColor,
                                  borderRadius: BorderRadius.circular(
                                    widget.size * 0.26,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: widget.size * 0.22,
                              left: widget.size * 0.2,
                              child: _MascotEye(
                                size: widget.size * 0.22,
                                pupilOffset: pupilOffset,
                                eyeHeight: eyeHeight,
                                eyelidColor: eyelidColor,
                              ),
                            ),
                            Positioned(
                              top: widget.size * 0.22,
                              right: widget.size * 0.2,
                              child: _MascotEye(
                                size: widget.size * 0.22,
                                pupilOffset: pupilOffset,
                                eyeHeight: eyeHeight,
                                eyelidColor: eyelidColor,
                              ),
                            ),
                            Positioned(
                              top: widget.size * 0.46,
                              child: Column(
                                children: [
                                  Transform.rotate(
                                    angle: math.pi / 4,
                                    child: Container(
                                      width: widget.size * 0.11,
                                      height: widget.size * 0.11,
                                      decoration: BoxDecoration(
                                        color: noseColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(3),
                                          bottomRight: Radius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: widget.size * 0.025),
                                  Container(
                                    width: widget.size * 0.18,
                                    height: widget.size * 0.035,
                                    decoration: BoxDecoration(
                                      color: noseColor.withValues(alpha: 0.72),
                                      borderRadius:
                                          BorderRadius.circular(widget.size),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: widget.size * 0.04,
                        left: widget.size * 0.34,
                        child: Container(
                          width: widget.size * 0.05,
                          height: widget.size * 0.13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF12345B),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: widget.size * 0.04,
                        right: widget.size * 0.34,
                        child: Container(
                          width: widget.size * 0.05,
                          height: widget.size * 0.13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF12345B),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Transform.scale(
                  scaleX: shadowScale,
                  child: Container(
                    width: widget.size * 0.48,
                    height: widget.size * 0.08,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        if (!widget.showBubble || widget.bubbleText.trim().isEmpty) {
          return shell;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Opacity(
              opacity: 0.92 + ((secondary + 1) * 0.04),
              child: Transform.translate(
                offset: Offset(0, -2 + (wave * 3)),
                child: _CoachSpeechBubble(
                  text: widget.bubbleText,
                  accent: widget.bubbleAccent,
                ),
              ),
            ),
            const SizedBox(height: 8),
            shell,
          ],
        );
      },
    );
  }
}

class _CoachSpeechBubble extends StatelessWidget {
  const _CoachSpeechBubble({
    required this.text,
    required this.accent,
  });

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 176),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.brandNight,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
          ),
        ),
        Transform.translate(
          offset: const Offset(-18, -2),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: accent.withValues(alpha: 0.18)),
                  bottom: BorderSide(color: accent.withValues(alpha: 0.18)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MascotEye extends StatelessWidget {
  const _MascotEye({
    required this.size,
    required this.pupilOffset,
    required this.eyeHeight,
    required this.eyelidColor,
  });

  final double size;
  final double pupilOffset;
  final double eyeHeight;
  final Color eyelidColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size * 0.78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Transform.translate(
            offset: Offset(pupilOffset, 0),
            child: Container(
              width: size * 0.32,
              height: eyeHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1D2733),
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: size,
              height: ((1 - (eyeHeight / (size * 0.78)).clamp(0.08, 1.0)) *
                      size *
                      0.56)
                  .clamp(0, size * 0.4),
              decoration: BoxDecoration(
                color: eyelidColor,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachSparkle extends StatelessWidget {
  const _CoachSparkle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _CoachWaveDots extends StatelessWidget {
  const _CoachWaveDots({
    required this.progress,
    required this.color,
    required this.size,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final phase = math.sin(progress * math.pi * 2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final opacity = 0.26 + (((phase + 1) / 2) * (0.18 + (index * 0.08)));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: size + (index * 2),
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ErrorTagChip extends StatelessWidget {
  const _ErrorTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brandNight,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WeeklySpeakingReport {
  const _WeeklySpeakingReport({
    required this.sessionCount,
    required this.avgClarity,
    required this.avgRhythm,
    required this.avgConfidence,
    required this.sessionDelta,
    required this.clarityDelta,
    required this.rhythmDelta,
    required this.confidenceDelta,
    required this.tagBreakdown,
  });

  const _WeeklySpeakingReport.empty()
      : sessionCount = 0,
        avgClarity = 0,
        avgRhythm = 0,
        avgConfidence = 0,
        sessionDelta = 0,
        clarityDelta = 0,
        rhythmDelta = 0,
        confidenceDelta = 0,
        tagBreakdown = const <String, int>{};

  final int sessionCount;
  final int avgClarity;
  final int avgRhythm;
  final int avgConfidence;
  final int sessionDelta;
  final int clarityDelta;
  final int rhythmDelta;
  final int confidenceDelta;
  final Map<String, int> tagBreakdown;
}

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard({required this.report, required this.isTr});

  final _WeeklySpeakingReport report;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    if (report.sessionCount == 0) {
      return Text(
        isTr
            ? 'Bu hafta henuz speaking kaydi yok. Ilk kaydinla rapor olusacak.'
            : 'No speaking recordings yet this week. Your first take will build the report.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final sortedTags = report.tagBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ProofPill(
              metric: ProofMetric(
                value:
                    '${report.sessionCount} (${_deltaLabel(report.sessionDelta)})',
                label: isTr ? 'Kayit' : 'Sessions',
              ),
            ),
            _ProofPill(
              metric: ProofMetric(
                value:
                    '${report.avgClarity} (${_deltaLabel(report.clarityDelta)})',
                label: isTr ? 'Ort. netlik' : 'Avg clarity',
              ),
            ),
            _ProofPill(
              metric: ProofMetric(
                value:
                    '${report.avgRhythm} (${_deltaLabel(report.rhythmDelta)})',
                label: isTr ? 'Ort. ritim' : 'Avg rhythm',
              ),
            ),
            _ProofPill(
              metric: ProofMetric(
                value:
                    '${report.avgConfidence} (${_deltaLabel(report.confidenceDelta)})',
                label: isTr ? 'Ort. guven' : 'Avg confidence',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isTr ? 'Hata turu dagilimi' : 'Error type distribution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedTags
              .map(
                (entry) => _ErrorTagChip(
                  label: '${entry.key.replaceAll('_', ' ')} ${entry.value}%',
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _deltaLabel(int value) {
    if (value > 0) return '+$value';
    return '$value';
  }
}

class _FeedbackMeter extends StatelessWidget {
  const _FeedbackMeter({required this.metric});

  final ProofMetric metric;

  @override
  Widget build(BuildContext context) {
    final score = int.tryParse(metric.value) ?? 0;
    final progress = (score / 100).clamp(0.0, 1.0);
    final tone = score >= 85
        ? const Color(0xFF0F766E)
        : score >= 70
            ? const Color(0xFFB45309)
            : const Color(0xFFB91C1C);
    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(
            score > 0 ? '$score' : '--',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 6,
            value: score > 0 ? progress : 0.0,
            borderRadius: BorderRadius.circular(999),
            color: tone,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SentenceFixCard extends StatelessWidget {
  const _SentenceFixCard({
    required this.title,
    required this.yourLine,
    required this.naturalLine,
    required this.note,
  });

  final String title;
  final String yourLine;
  final String naturalLine;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            AppStrings.code == 'tr' ? 'Senin cumlen' : 'Your line',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(yourLine, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          Text(
            AppStrings.code == 'tr'
                ? 'Daha dogal versiyon'
                : 'More natural version',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            naturalLine,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.brandNight,
            ),
          ),
          const SizedBox(height: 8),
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({
    required this.streak,
    required this.weeklySessions,
    required this.weeklyTarget,
    required this.todayProgress,
  });

  final int streak;
  final int weeklySessions;
  final int weeklyTarget;
  final double todayProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$weeklySessions / $weeklyTarget',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: todayProgress,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.code == 'tr' ? 'Mevcut seri' : 'Current streak'}: $streak',
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.detail,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String detail;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QuickActionCard(
      title: title,
      detail: detail,
      badge: badge,
      icon: icon,
      accentColor: accentColor,
      ctaLabel: ctaLabel,
      onTap: onTap,
    );
  }
}

class _MiniChallengeCard extends StatelessWidget {
  const _MiniChallengeCard({
    required this.title,
    required this.detail,
    required this.durationLabel,
    required this.icon,
    required this.ctaLabel,
    required this.onTap,
  });

  final String title;
  final String detail;
  final String durationLabel;
  final IconData icon;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandNight, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandNight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 6),
                Text(
                  durationLabel,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onTap, child: Text(ctaLabel)),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(this.data);

  final TaskTileData data;

  @override
  Widget build(BuildContext context) {
    return TaskTile(
      title: data.title,
      detail: data.detail,
      icon: data.icon,
      done: data.done,
      onTap: data.onOpen,
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow(this.step);

  final PathStep step;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        step.done ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: step.done ? AppColors.brand : AppColors.muted,
      ),
      title: Text(step.title),
      subtitle: Text(step.detail),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard(this.data);

  final PackCardData data;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final child = SizedBox(
      width: 220,
      child: StudyPackCard(
        title: data.title,
        subtitle: data.subtitle,
        duration: data.durationLabel,
        icon: data.icon,
        accentColor: data.accentColor,
        onTap: data.onTap,
      ),
    );
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              data.onTap();
            },
            child: Text(isTr ? 'Paketi ac' : 'Open pack'),
          ),
        ],
        child: child,
      );
    }
    return child;
  }
}

class _ReviewDeckCard extends StatelessWidget {
  const _ReviewDeckCard(this.data);

  final ReviewCardData data;

  @override
  Widget build(BuildContext context) {
    final isTr = AppStrings.code == 'tr';
    final child = SizedBox(
      width: 200,
      child: ReviewDeckCard(
        title: data.title,
        phrase: data.phrase,
        onTap: data.onTap,
      ),
    );
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoContextMenu(
        actions: [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.pop(context);
              data.onTap();
            },
            child: Text(isTr ? 'Review kartini ac' : 'Open review'),
          ),
        ],
        child: child,
      );
    }
    return child;
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard(this.data);

  final TutorCardData data;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      name: data.name,
      role: data.role,
      imageUrl: data.imageUrl,
      tags: data.tags,
      availabilityLabel: data.availabilityLabel,
      ctaLabel: data.ctaLabel,
      isFavorite: data.isFavorite,
      onTap: data.onTap,
      onToggleFavorite: data.onToggleFavorite,
    );
  }
}

class _SheetPhraseTile extends StatelessWidget {
  const _SheetPhraseTile(this.phrase);

  final String phrase;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(phrase),
    );
  }
}

class _SheetBlock extends StatelessWidget {
  const _SheetBlock(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF7)),
      ),
      child: Text(text),
    );
  }
}

class _ComparePairCard extends StatelessWidget {
  const _ComparePairCard({
    required this.latest,
    required this.previous,
    required this.isTr,
    required this.activePlaybackSessionId,
    required this.onPlayLatest,
    required this.onPlayPrevious,
  });

  final SpeakCoachCompareSession latest;
  final SpeakCoachCompareSession previous;
  final bool isTr;
  final String? activePlaybackSessionId;
  final VoidCallback onPlayLatest;
  final VoidCallback onPlayPrevious;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompareSessionCard(
            session: latest,
            isTr: isTr,
            isPlaying: activePlaybackSessionId == latest.id,
            onPlay: onPlayLatest,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompareSessionCard(
            session: previous,
            isTr: isTr,
            isPlaying: activePlaybackSessionId == previous.id,
            onPlay: onPlayPrevious,
          ),
        ),
      ],
    );
  }
}

class _CompareSessionCard extends StatelessWidget {
  const _CompareSessionCard({
    required this.session,
    required this.isTr,
    required this.isPlaying,
    required this.onPlay,
  });

  final SpeakCoachCompareSession session;
  final bool isTr;
  final bool isPlaying;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.durationSeconds}s',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '${isTr ? 'Netlik' : 'Clarity'} ${session.clarityScore} • ${isTr ? 'Ritim' : 'Rhythm'} ${session.rhythmScore}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPlay,
            icon: Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(isTr ? 'Cal' : 'Play'),
          ),
        ],
      ),
    );
  }
}

class _CalendarSummaryPill extends StatelessWidget {
  const _CalendarSummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _ProofPill(metric: ProofMetric(value: value, label: label));
  }
}

class CalendarDayTile extends StatelessWidget {
  const CalendarDayTile({super.key, required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: day.active ? AppColors.brand : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.isToday ? AppColors.brandNight : const Color(0xFFE3EAF7),
        ),
      ),
      child: Icon(
        day.active ? Icons.check_rounded : Icons.circle_outlined,
        color: day.active ? Colors.white : AppColors.muted,
      ),
    );
  }
}
