import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_strings.dart';
import '../../core/notifications/app_notification_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../shared/trial_lesson_gate.dart';
import '../student/instructors/instructor_repository.dart';
import '../student/instructors/student_instructors_screen.dart';
import 'public_page_scaffold.dart';
import 'public_repository.dart';
import 'speak_coach_repository.dart';

class SpeakCoachScreen extends StatefulWidget {
  const SpeakCoachScreen({super.key});

  @override
  State<SpeakCoachScreen> createState() => _SpeakCoachScreenState();
}

class _SpeakCoachScreenState extends State<SpeakCoachScreen> {
  static final List<_GoalSpec> _goals = [
    _GoalSpec(
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
    _GoalSpec(
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
    _GoalSpec(
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
    _GoalSpec(
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

  static const List<_PlannerTarget> _targets = [
    _PlannerTarget(3, '3 gun', '3 days'),
    _PlannerTarget(4, '4 gun', '4 days'),
    _PlannerTarget(5, '5 gun', '5 days'),
    _PlannerTarget(6, '6 gun', '6 days'),
  ];

  static const List<_ScheduleSpec> _schedules = [
    _ScheduleSpec('morning', 'Sabah', 'Morning', '08:00 - 11:00'),
    _ScheduleSpec('afternoon', 'Ogle', 'Afternoon', '12:00 - 16:00'),
    _ScheduleSpec('evening', 'Aksam', 'Evening', '18:00 - 22:00'),
  ];

  static const List<_ReminderSpec> _reminders = [
    _ReminderSpec('morning', 'Sabah hatirlaticisi', 'Morning reminder'),
    _ReminderSpec('afternoon', 'Gun ortasi hatirlaticisi', 'Midday reminder'),
    _ReminderSpec('evening', 'Aksam hatirlaticisi', 'Evening reminder'),
  ];

  final SpeakCoachRepository _repository = SpeakCoachRepository();
  final PublicRepository _publicRepository = PublicRepository();
  final Map<int, InstructorAvailabilitySnapshot?> _availability = {};
  bool _loading = true;
  bool _loadingAvailability = false;
  bool _plannerAutoShown = false;
  String? _error;
  SpeakCoachLocalState _localState = SpeakCoachLocalState.initial();
  List<InstructorSummary> _instructors = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _copy(String tr, String en) => AppStrings.code == 'tr' ? tr : en;

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  _GoalSpec get _goal {
    return _goals.firstWhere(
      (item) => item.id == _localState.goalId,
      orElse: () => _goals.first,
    );
  }

  _ScheduleSpec get _schedule {
    return _schedules.firstWhere(
      (item) => item.id == _localState.scheduleId,
      orElse: () => _schedules.last,
    );
  }

  _ReminderSpec get _reminder {
    return _reminders.firstWhere(
      (item) => item.id == _localState.reminderWindow,
      orElse: () => _reminders.last,
    );
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

  int get _availableTodayCount {
    return _availability.values
        .whereType<InstructorAvailabilitySnapshot>()
        .fold<int>(0, (sum, item) => sum + item.todayAvailableCount);
  }

  String get _topGoalLabel => _copy(
        'En cok secilen hedef: ${_goal.titleTr}',
        'Top selected goal: ${_goal.titleEn}',
      );

  List<_ProofMetric> get _proofMetrics {
    return [
      _ProofMetric(
        value: '${_instructors.length}',
        label: _copy('Aktif hoca', 'Active tutors'),
      ),
      _ProofMetric(
        value: '$_availableTodayCount',
        label: _copy('Bugun acik slot', 'Open today'),
      ),
      _ProofMetric(
        value: '${_localState.weeklyTarget}',
        label: _copy('Haftalik hedef', 'Weekly target'),
      ),
      _ProofMetric(
        value: '${_todayTasks.length}',
        label: _copy('Gunluk gorev', 'Daily tasks'),
      ),
    ];
  }

  List<_TodayTask> get _todayTasks {
    final firstPack = _packsForGoal(_goal).first;
    return [
      _TodayTask(
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
      _TodayTask(
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
      _TodayTask(
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

  List<_PathStep> get _pathSteps {
    return [
      _PathStep(
        title: _copy('Goal sec', 'Pick goal'),
        detail: _copy(
          'Calisma yolunu ihtiyacina gore kur.',
          'Shape the study path around what you need.',
        ),
        done: true,
      ),
      _PathStep(
        title: _copy('Mini paket', 'Mini pack'),
        detail: _copy(
          'Kisa ifade ve mini diyalog ile basla.',
          'Start with short phrases and a compact dialogue.',
        ),
        done: _completedToday.contains('pack'),
      ),
      _PathStep(
        title: _copy('Tekrar', 'Review'),
        detail: _copy(
          'Kartlari tara ve kullanacagin cumleyi sec.',
          'Scan the cards and keep the sentence you will use.',
        ),
        done: _completedToday.contains('review'),
      ),
      _PathStep(
        title: _copy('Canli ders', 'Live lesson'),
        detail: _copy(
          'Ucretsiz deneme veya egitmen profili ile devam et.',
          'Continue with a free trial or a tutor profile.',
        ),
        done: _weeklySessions > 0,
      ),
    ];
  }

  List<_StudyPack> _packsForGoal(_GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return const [
          _StudyPack(
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
          _StudyPack(
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
          _StudyPack(
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
          _StudyPack(
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
          _StudyPack(
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
          _StudyPack(
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
          _StudyPack(
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
          _StudyPack(
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

  List<_ReviewCard> _reviewCardsForGoal(_GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return const [
          _ReviewCard(
              'Net update',
              'Clear update',
              'We are on track.',
              'Planlanan tempodayiz.',
              'We are moving at the planned pace.',
              'Status guncellerken ilk cumle olarak kullan.',
              'Use it as the first line of a status update.'),
          _ReviewCard(
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
          _ReviewCard(
              'Opinion girisi',
              'Opinion opener',
              'To a large extent, I agree that...',
              'Buyuk olcude katiliyorum ki...',
              'I agree to a great extent that...',
              'Speaking opinion cevabina guclu girer.',
              'A strong start for a speaking opinion answer.'),
          _ReviewCard(
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
          _ReviewCard(
              'Check-in',
              'Check-in',
              'I would like to check in for my flight.',
              'Ucusum icin check-in yapmak istiyorum.',
              'I want to check in for my flight.',
              'Havalimani masasinda acilis cumlesi.',
              'A clean opening line at the airport desk.'),
          _ReviewCard(
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
          _ReviewCard(
              'Tanisma',
              'Introduction',
              'These days I am focused on...',
              'Bu aralar odagim su konuda...',
              'Lately I am focused on...',
              'Kendini tanitirken net bir hedef gosterir.',
              'It shows a clear purpose when you introduce yourself.'),
          _ReviewCard(
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

  _PronunciationSpot _pronunciationSpotForGoal(_GoalSpec goal) {
    switch (goal.id) {
      case 'business':
        return const _PronunciationSpot(
          'Toplanti ritmi',
          'Meeting rhythm',
          'I NEED the LAT-est VER-sion by EOD.',
          'Ana vurgu zaman ve teslim ifadesinde olsun.',
          'Put the main stress on time and delivery.',
        );
      case 'ielts':
        return const _PronunciationSpot(
          'Uzun cevap ritmi',
          'Long answer rhythm',
          'To a LARGE exTENT, I aGREE that...',
          'Uzun cevabi tek blok okumak yerine vurguyu iki durakta topla.',
          'Do not read the long answer as one block.',
        );
      case 'travel':
        return const _PronunciationSpot(
          'Kisa soru netligi',
          'Short-question clarity',
          'Is it WITH-in WALK-ing dis-TANCE?',
          'Soruyu hizlandirma. Her ana kelime net ciksin.',
          'Do not rush the question. Let the key words land clearly.',
        );
      default:
        return const _PronunciationSpot(
          'Dogal tanisma tonu',
          'Natural intro tone',
          'These DAYS I am FO-cused on...',
          'Baslangicta iki vurgu yeterli.',
          'Two strong beats are enough at the start.',
        );
    }
  }

  Future<void> _saveLocalState(SpeakCoachLocalState nextState) async {
    setState(() => _localState = nextState);
    await _repository.saveLocalState(nextState);
  }

  Future<void> _setGoal(String goalId) async {
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

  Future<bool> _hasAuthToken() async {
    final token = await SecureStorage.getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<bool> _ensurePremiumGate({
    required String title,
    required String detail,
  }) async {
    if (await _hasAuthToken()) return true;
    if (!mounted) return false;
    final allow = await showModalBottomSheet<bool>(
      context: context,
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
      if ((_localState.referralCode).trim().isEmpty) {
        await _saveLocalState(
          _localState.copyWith(referralCode: generateSpeakCoachReferralCode()),
        );
      }
      _loadAvailability();
      if (!_plannerAutoShown && !_localState.onboardingCompleted) {
        _plannerAutoShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openOnboardingSheet();
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
    final results = await Future.wait(
      _featuredInstructors.map((instructor) async {
        final snapshot = await _repository.fetchAvailability(instructor.id);
        return MapEntry(instructor.id, snapshot);
      }),
    );
    if (!mounted) return;
    setState(() {
      for (final result in results) {
        _availability[result.key] = result.value;
      }
      _loadingAvailability = false;
    });
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
    }
  }

  Future<void> _markTaskDone(String taskId) async {
    if (_completedToday.contains(taskId)) return;
    await _toggleTask(taskId);
  }

  Future<void> _openPlacement() async {
    await _markTaskDone('placement');
    await _recordActivity(
      'placement',
      AppStrings.code == 'tr' ? 'Seviye testi acildi' : 'Level test opened',
    );
    if (!mounted) return;
    Navigator.pushNamed(context, '/placement-test');
  }

  Future<void> _openTrial() async {
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
        return TrialLessonActionResult(
          message: result.message,
          supportUrl: result.whatsappUrl,
        );
      },
    );
  }

  void _openTutors() {
    _openTutorsAsync();
  }

  Future<void> _openTutorsAsync() async {
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

  Future<void> _openOnboardingSheet() async {
    var goalId = _localState.goalId;
    var scheduleId = _localState.scheduleId;
    var levelId = _localState.onboardingLevelId;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy('Baslamadan once 3 hizli soru',
                          '3 quick questions before you start'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(_copy('Hedefin ne?', 'What is your goal?')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _goals.map((goal) {
                        return ChoiceChip(
                          label: Text(AppStrings.code == 'tr'
                              ? goal.titleTr
                              : goal.titleEn),
                          selected: goal.id == goalId,
                          onSelected: (_) =>
                              setModalState(() => goalId = goal.id),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(_copy(
                        'Hangi saat uygunsun?', 'Which time works best?')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _schedules.map((schedule) {
                        return ChoiceChip(
                          label: Text(AppStrings.code == 'tr'
                              ? schedule.titleTr
                              : schedule.titleEn),
                          selected: schedule.id == scheduleId,
                          onSelected: (_) =>
                              setModalState(() => scheduleId = schedule.id),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(_copy('Seviyeni nasil hissediyorsun?',
                        'How would you describe your level?')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        ('beginner', 'Baslangic', 'Beginner'),
                        ('intermediate', 'Orta', 'Intermediate'),
                        ('advanced', 'Ileri', 'Advanced'),
                      ].map((item) {
                        return ChoiceChip(
                          label:
                              Text(AppStrings.code == 'tr' ? item.$2 : item.$3),
                          selected: item.$1 == levelId,
                          onSelected: (_) =>
                              setModalState(() => levelId = item.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveLocalState(
                            _localState.copyWith(
                              goalId: goalId,
                              scheduleId: scheduleId,
                              onboardingLevelId: levelId,
                              onboardingCompleted: true,
                            ),
                          );
                          if (context.mounted) Navigator.pop(context);
                          if (mounted) {
                            await _recordActivity(
                              'onboarding',
                              AppStrings.code == 'tr'
                                  ? 'Onboarding tamamlandi'
                                  : 'Onboarding completed',
                            );
                          }
                        },
                        child: Text(_copy('Akisi baslat', 'Start the flow')),
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
  }

  Future<void> _openPlannerSheet({bool initial = false}) async {
    var goalId = _localState.goalId;
    var weeklyTarget = _localState.weeklyTarget;
    var scheduleId = _localState.scheduleId;
    final result = await showModalBottomSheet<_PlannerResult>(
      context: context,
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
                            _PlannerResult(goalId, scheduleId, weeklyTarget),
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

  Future<void> _openPackSheet(_StudyPack pack) async {
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
    await showModalBottomSheet<void>(
      context: context,
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
  }

  Future<void> _openReviewSheet(_ReviewCard card) async {
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
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.code == 'tr' ? card.titleTr : card.titleEn,
                  style: Theme.of(context).textTheme.headlineSmall,
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
  }

  void _showTaskSuccess(String taskId) {
    final isTr = AppStrings.code == 'tr';
    final packs = _packsForGoal(_goal);
    final reviews = _reviewCardsForGoal(_goal);

    final spec = switch (taskId) {
      'placement' => _CompletionSpec(
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
      'review' => _CompletionSpec(
          title: isTr ? 'Tekrar tamamlandi' : 'Review completed',
          detail: isTr
              ? 'Siradaki en mantikli adim uygun hoca secmek veya ucretsiz deneme istemek.'
              : 'The best next step is picking a tutor or requesting a free trial.',
          primaryLabel: isTr ? 'Ucretsiz deneme iste' : 'Request free trial',
          primaryAction: _openTrial,
          secondaryLabel: isTr ? 'Uygun hocalari ac' : 'Open tutors',
          secondaryAction: _openTutors,
        ),
      _ => _CompletionSpec(
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

    showModalBottomSheet<void>(
      context: context,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: publicAppViewport(
        context,
        Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 10,
                16,
                MediaQuery.paddingOf(context).bottom + 126,
              ),
              children: [
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
                  scheduleLabel: isTr ? _schedule.titleTr : _schedule.titleEn,
                  scheduleDetail: _schedule.detail,
                  reminderLabel: isTr ? _reminder.titleTr : _reminder.titleEn,
                  weeklyTarget: _localState.weeklyTarget,
                  onEdit: _openPlannerSheet,
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: isTr ? '7 gunluk challenge' : '7-day challenge',
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
                            ? (_challengeProgressDays / 7).clamp(0.0, 1.0)
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
                            metric: _ProofMetric(
                              value: _challengeStarted
                                  ? '$_challengeProgressDays/7'
                                  : '0/7',
                              label: _copy('Challenge gunu', 'Challenge day'),
                            ),
                          ),
                          _ProofPill(
                            metric: _ProofMetric(
                              value: _challengeCompleted
                                  ? _copy('Hazir', 'Ready')
                                  : _copy('Devam', 'Live'),
                              label: _copy('Seviye ozeti', 'Level summary'),
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
                                    ? _copy(
                                        'Challenge baslat', 'Start challenge')
                                    : _copy('Seviyeni gor', 'See your level'),
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
                            : _completedToday.length / _todayTasks.length,
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _copy(
                                'Bugun $_availableTodayCount acik tutor slotu var. $_topGoalLabel.',
                                'There are $_availableTodayCount open tutor slots today. $_topGoalLabel.',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
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
                        ctaLabel:
                            isTr ? 'Seviye testini ac' : 'Open level test',
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
                        ctaLabel:
                            isTr ? 'Deneme dersi iste' : 'Request free trial',
                        onTap: _openTrial,
                      ),
                    ],
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
                    children: _pathSteps.map((step) => _PathRow(step)).toList(),
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
                        _ReviewCardData(
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
                  child: _SheetBlock(isTr
                      ? '${spot.titleTr}\n\n${spot.focusLine}\n\n${spot.helperTr}'
                      : '${spot.titleEn}\n\n${spot.focusLine}\n\n${spot.helperEn}'),
                ),
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
                    children: _matchedInstructors.map((instructor) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TutorCard(
                          _TutorCardData(
                            name: instructor.name,
                            role: instructor.jobTitle.isNotEmpty
                                ? instructor.jobTitle
                                : AppStrings.t('Instructor'),
                            imageUrl: instructor.imageUrl,
                            tags: _matchReasons(instructor),
                            availabilityLabel: _availabilityLabel(instructor),
                            ctaLabel: isTr ? 'Profili ac' : 'Open profile',
                            isFavorite: _localState.favoriteInstructorIds
                                .contains(instructor.id),
                            onTap: () => _openTutorProfile(instructor),
                            onToggleFavorite: () =>
                                _toggleFavoriteTutor(instructor),
                          ),
                        ),
                      );
                    }).toList(),
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
                              imageUrl: instructor.imageUrl,
                              tags: _matchReasons(instructor),
                              availabilityLabel: _availabilityLabel(instructor),
                              ctaLabel: isTr ? 'Geri don' : 'Resume',
                              isFavorite: true,
                              onTap: () => _openTutorProfile(instructor),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTr
                                        ? 'Referral kodun'
                                        : 'Your referral code',
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _localState.referralCode,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(color: AppColors.brandNight),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _copyReferralCode,
                              child: Text(isTr ? 'Kopyala' : 'Copy'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...[
                        _copy('1 ucretsiz mini speaking seansi',
                            '1 free mini speaking session'),
                        _copy('Bonus materyal paketi', 'Bonus material pack'),
                        _copy('Deneme dersi onceligi', 'Priority trial lesson'),
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
                            color: selected ? AppColors.brand : AppColors.muted,
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            ...[
                              _copy(
                                  'Gunluk gorev hazir', 'Daily task is ready'),
                              _copy('Streak gidiyor', 'Your streak is at risk'),
                              _copy('Bugun uygun tutor var',
                                  'A tutor is available today'),
                              _copy('Deneme dersi seni bekliyor',
                                  'Your trial lesson is waiting'),
                            ].map(
                              (label) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
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
                              style: Theme.of(context).textTheme.bodyMedium,
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
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _BottomDock(
                onOpenPlan: _openPlannerSheet,
                onOpenPlacement: _openPlacement,
                onOpenTutors: _openTutors,
                onLogin: () => Navigator.pushNamed(context, '/login'),
                onOpenTrial: _openTrial,
              ),
            ),
          ],
        ),
        expandHeight: true,
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
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EBF7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/icon/app_icon_source.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.language_rounded,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LinguFranca',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                AppStrings.code == 'tr'
                    ? 'Gunluk ders akisi'
                    : 'Daily lesson flow',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => onOpenPlan(),
          icon: const Icon(Icons.tune_rounded),
        ),
        TextButton(
          onPressed: onLogin,
          child: Text(AppStrings.code == 'tr' ? 'Giris' : 'Login'),
        ),
      ],
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

  final _GoalSpec goal;
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3656FF), Color(0xFF2643D5), Color(0xFF162D88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isTr ? goal.subtitleTr : goal.subtitleEn,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTr ? goal.headlineTr : goal.headlineEn,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              isTr ? goal.supportTr : goal.supportEn,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOpenPlacement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandNight,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(isTr ? 'Seviye testi' : 'Level test'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpenTrial,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Text(isTr ? 'Ucretsiz deneme' : 'Free trial'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _HeroStat('$streak', 'Streak')),
                Expanded(
                    child: _HeroStat('$weeklySessions/$weeklyTarget',
                        isTr ? 'Haftalik' : 'Weekly')),
                Expanded(
                    child: _HeroStat('%${(todayProgress * 100).round()}',
                        isTr ? 'Bugun' : 'Today')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  isTr ? 'Hedefi degistir' : 'Change goal',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => onOpenPlan(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(isTr ? 'Plani duzenle' : 'Edit plan'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => goalChips[index],
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: goalChips.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
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
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.brandNight : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.brandNight : Colors.white,
                  ),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE3EBF7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.code == 'tr'
                      ? 'Calisma planin'
                      : 'Your study plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '$scheduleLabel  •  $scheduleDetail',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.code == 'tr'
                      ? 'Hatirlatici: $reminderLabel'
                      : 'Reminder: $reminderLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.code == 'tr'
                      ? '$weeklyTarget gun / hafta hedefi'
                      : '$weeklyTarget days / week target',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => onEdit(),
            child: Text(AppStrings.code == 'tr' ? 'Duzenle' : 'Edit'),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE3EBF7)),
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
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(this.task);

  final _TaskTileData task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: task.onOpen,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: task.done ? AppColors.surfaceSoft : const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: task.done ? AppColors.brand : const Color(0xFFE3EAF7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: task.done
                    ? AppColors.brand.withValues(alpha: 0.16)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(task.icon,
                  color: task.done ? AppColors.brand : AppColors.brandNight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(task.title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text(task.durationLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(task.detail,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: task.onOpen,
                        child: Text(task.buttonLabel),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: task.onToggleDone,
                        icon: Icon(
                          task.done
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: task.done ? AppColors.brand : AppColors.muted,
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
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow(this.step);

  final _PathStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: step.done
                  ? AppColors.brand.withValues(alpha: 0.14)
                  : AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              step.done ? Icons.check_rounded : Icons.circle_outlined,
              size: 16,
              color: step.done ? AppColors.brand : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(step.detail,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard(this.card);

  final _PackCardData card;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: card.onTap,
      child: Ink(
        width: 226,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3EBF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: card.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(card.icon, color: card.accentColor),
            ),
            const SizedBox(height: 16),
            Text(card.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(card.subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Row(
              children: [
                Text(card.durationLabel,
                    style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDeckCard extends StatelessWidget {
  const _ReviewDeckCard(this.card);

  final _ReviewCardData card;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: card.onTap,
      child: Ink(
        width: 248,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.brand),
            ),
            const SizedBox(height: 8),
            Text(card.phrase, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(card.meaning, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(card.usage, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TutorCard extends StatelessWidget {
  const _TutorCard(this.card);

  final _TutorCardData card;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: card.onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3EAF7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.surfaceSoft,
              backgroundImage:
                  card.imageUrl != null && card.imageUrl!.trim().isNotEmpty
                      ? NetworkImage(card.imageUrl!)
                      : null,
              child: card.imageUrl == null || card.imageUrl!.trim().isEmpty
                  ? Text(card.name.isNotEmpty ? card.name.substring(0, 1) : '?')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(card.role,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  if (card.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: card.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE3EAF7)),
                          ),
                          child: Text(
                            tag,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    card.availabilityLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.brandNight,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton(
                            onPressed: card.onTap,
                            child: Text(card.ctaLabel),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            AppStrings.code == 'tr' ? 'Kaydet' : 'Save tutor',
                        onPressed: card.onToggleFavorite,
                        icon: Icon(
                          card.isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: card.isFavorite
                              ? AppColors.brand
                              : AppColors.muted,
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
    );
  }
}

class _ProofPill extends StatelessWidget {
  const _ProofPill({required this.metric});

  final _ProofMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            metric.value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.brandNight,
                ),
          ),
          const SizedBox(height: 4),
          Text(metric.label, style: Theme.of(context).textTheme.bodySmall),
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
    final double weeklyProgress = weeklyTarget == 0
        ? 0.0
        : (weeklySessions / weeklyTarget).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.code == 'tr' ? 'Ilerleme hissi' : 'Progress signal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.code == 'tr'
                ? '$streak gunluk seri ve $weeklySessions/$weeklyTarget haftalik adim tamamlandi.'
                : '$streak day streak and $weeklySessions/$weeklyTarget weekly steps completed.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.code == 'tr' ? 'Bugun' : 'Today',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: todayProgress.clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.code == 'tr' ? 'Bu hafta' : 'This week',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: weeklyProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            color: const Color(0xFF0F766E),
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3EAF7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: Text(ctaLabel),
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
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.onOpenPlan,
    required this.onOpenPlacement,
    required this.onOpenTutors,
    required this.onLogin,
    required this.onOpenTrial,
  });

  final Future<void> Function({bool initial}) onOpenPlan;
  final VoidCallback onOpenPlacement;
  final VoidCallback onOpenTutors;
  final VoidCallback onLogin;
  final VoidCallback onOpenTrial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNight.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DockItem(
              icon: Icons.tune_rounded,
              label: AppStrings.code == 'tr' ? 'Plan' : 'Plan',
              onTap: () => onOpenPlan(),
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.verified_rounded,
              label: AppStrings.code == 'tr' ? 'Test' : 'Test',
              onTap: onOpenPlacement,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: onOpenTrial,
                child: Text(AppStrings.code == 'tr' ? 'Deneme' : 'Trial'),
              ),
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.groups_rounded,
              label: AppStrings.code == 'tr' ? 'Tutor' : 'Tutors',
              onTap: onOpenTutors,
            ),
          ),
          Expanded(
            child: _DockItem(
              icon: Icons.login_rounded,
              label: AppStrings.code == 'tr' ? 'Giris' : 'Login',
              onTap: onLogin,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(phrase, style: Theme.of(context).textTheme.titleMedium),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _GoalSpec {
  const _GoalSpec({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.subtitleTr,
    required this.subtitleEn,
    required this.headlineTr,
    required this.headlineEn,
    required this.supportTr,
    required this.supportEn,
    required this.icon,
  });
  final String id;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String headlineTr;
  final String headlineEn;
  final String supportTr;
  final String supportEn;
  final IconData icon;
}

class _TodayTask {
  const _TodayTask({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.detailTr,
    required this.detailEn,
    required this.durationLabel,
    required this.icon,
    required this.buttonTr,
    required this.buttonEn,
  });
  final String id;
  final String titleTr;
  final String titleEn;
  final String detailTr;
  final String detailEn;
  final String durationLabel;
  final IconData icon;
  final String buttonTr;
  final String buttonEn;
}

class _PathStep {
  const _PathStep({
    required this.title,
    required this.detail,
    required this.done,
  });
  final String title;
  final String detail;
  final bool done;
}

class _StudyPack {
  const _StudyPack(
    this.id,
    this.titleTr,
    this.titleEn,
    this.subtitleTr,
    this.subtitleEn,
    this.durationLabel,
    this.icon,
    this.accentColor,
    this.phrases,
    this.dialogue,
    this.note,
    this.noteEn,
  );
  final String id;
  final String titleTr;
  final String titleEn;
  final String subtitleTr;
  final String subtitleEn;
  final String durationLabel;
  final IconData icon;
  final Color accentColor;
  final List<String> phrases;
  final String dialogue;
  final String note;
  final String noteEn;
}

class _ReviewCard {
  const _ReviewCard(
    this.titleTr,
    this.titleEn,
    this.phrase,
    this.meaningTr,
    this.meaningEn,
    this.usageTr,
    this.usageEn,
  );
  final String titleTr;
  final String titleEn;
  final String phrase;
  final String meaningTr;
  final String meaningEn;
  final String usageTr;
  final String usageEn;
}

class _PronunciationSpot {
  const _PronunciationSpot(
    this.titleTr,
    this.titleEn,
    this.focusLine,
    this.helperTr,
    this.helperEn,
  );
  final String titleTr;
  final String titleEn;
  final String focusLine;
  final String helperTr;
  final String helperEn;
}

class _PlannerTarget {
  const _PlannerTarget(this.value, this.labelTr, this.labelEn);
  final int value;
  final String labelTr;
  final String labelEn;
}

class _ScheduleSpec {
  const _ScheduleSpec(this.id, this.titleTr, this.titleEn, this.detail);
  final String id;
  final String titleTr;
  final String titleEn;
  final String detail;
}

class _ReminderSpec {
  const _ReminderSpec(this.id, this.titleTr, this.titleEn);
  final String id;
  final String titleTr;
  final String titleEn;
}

class _ProofMetric {
  const _ProofMetric({required this.value, required this.label});
  final String value;
  final String label;
}

class _PlannerResult {
  const _PlannerResult(this.goalId, this.scheduleId, this.weeklyTarget);
  final String goalId;
  final String scheduleId;
  final int weeklyTarget;
}

class _CompletionSpec {
  const _CompletionSpec({
    required this.title,
    required this.detail,
    required this.primaryLabel,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryAction,
  });

  final String title;
  final String detail;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;
}

class _TaskTileData {
  const _TaskTileData({
    required this.title,
    required this.detail,
    required this.durationLabel,
    required this.icon,
    required this.done,
    required this.buttonLabel,
    required this.onOpen,
    required this.onToggleDone,
  });
  final String title;
  final String detail;
  final String durationLabel;
  final IconData icon;
  final bool done;
  final String buttonLabel;
  final VoidCallback onOpen;
  final VoidCallback onToggleDone;
}

class _PackCardData {
  const _PackCardData({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String durationLabel;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
}

class _ReviewCardData {
  const _ReviewCardData({
    required this.title,
    required this.phrase,
    required this.meaning,
    required this.usage,
    required this.onTap,
  });
  final String title;
  final String phrase;
  final String meaning;
  final String usage;
  final VoidCallback onTap;
}

class _TutorCardData {
  const _TutorCardData({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.tags,
    required this.availabilityLabel,
    required this.ctaLabel,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });
  final String name;
  final String role;
  final String? imageUrl;
  final List<String> tags;
  final String availabilityLabel;
  final String ctaLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
}
