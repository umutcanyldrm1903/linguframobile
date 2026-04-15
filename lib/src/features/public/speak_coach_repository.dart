import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';

import '../../core/storage/secure_storage.dart';
import '../student/instructors/instructor_repository.dart';
import 'public_repository.dart';

class SpeakCoachRepository {
  SpeakCoachRepository({
    PublicRepository? publicRepository,
    InstructorRepository? instructorRepository,
  })  : _publicRepository = publicRepository ?? PublicRepository(),
        _instructorRepository = instructorRepository ?? InstructorRepository();

  static const _storageKey = 'speak_coach_state_v1';

  final PublicRepository _publicRepository;
  final InstructorRepository _instructorRepository;

  Future<SpeakCoachBootstrap> load() async {
    final results = await Future.wait<dynamic>([
      _guard(_publicRepository.fetchHomePage()),
      _guard(_instructorRepository.fetchInstructors()),
      _guard(_publicRepository.fetchSettings()),
      loadLocalState(),
    ]);

    final home = results[0] as HomePayload?;
    final fetchedInstructors =
        results[1] as List<InstructorSummary>? ?? const <InstructorSummary>[];
    final settings = results[2] as PublicSettings?;
    final localState = results[3] as SpeakCoachLocalState;

    final instructors = fetchedInstructors.isNotEmpty
        ? fetchedInstructors
        : _fallbackInstructors(home);

    return SpeakCoachBootstrap(
      home: home,
      instructors: instructors,
      settings: settings,
      localState: localState,
    );
  }

  Future<SpeakCoachLocalState> loadLocalState() async {
    final raw = await SecureStorage.getValue(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return SpeakCoachLocalState.initial();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SpeakCoachLocalState.fromJson(decoded);
      }
    } catch (_) {}

    return SpeakCoachLocalState.initial();
  }

  Future<void> saveLocalState(SpeakCoachLocalState state) async {
    await SecureStorage.setValue(_storageKey, jsonEncode(state.toJson()));
  }

  Future<InstructorAvailabilitySnapshot?> fetchAvailability(
    int instructorId,
  ) async {
    try {
      final schedule = await _instructorRepository.fetchSchedule(
        instructorId: instructorId,
      );

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var todayAvailableCount = 0;
      String? nextAvailableDate;
      String? nextAvailableSlotLabel;

      final entries = schedule.slotsByDate.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in entries) {
        final available = entry.value.where((slot) => slot.available).toList();
        if (entry.key == todayKey) {
          todayAvailableCount = available.length;
        }
        if (nextAvailableDate == null && available.isNotEmpty) {
          nextAvailableDate = entry.key;
          nextAvailableSlotLabel = available.first.label;
        }
      }

      return InstructorAvailabilitySnapshot(
        todayAvailableCount: todayAvailableCount,
        nextAvailableDate: nextAvailableDate,
        nextAvailableSlotLabel: nextAvailableSlotLabel,
      );
    } catch (_) {
      return null;
    }
  }

  List<InstructorSummary> _fallbackInstructors(HomePayload? home) {
    if (home == null || home.selectedInstructors.isEmpty) {
      return const <InstructorSummary>[];
    }

    return home.selectedInstructors
        .map(
          (item) => InstructorSummary(
            id: item.id,
            name: item.name,
            jobTitle: item.jobTitle,
            shortBio: item.shortBio,
            bio: item.shortBio,
            imageUrl: item.imageUrl,
            avgRating: item.avgRating,
            courseCount: item.courseCount,
            tags: _tagsFromText('${item.jobTitle} ${item.shortBio}'),
          ),
        )
        .toList(growable: false);
  }

  List<String> _tagsFromText(String raw) {
    final text = raw.toLowerCase();
    final tags = <String>[];
    if (text.contains('speaking') || text.contains('conversation')) {
      tags.add('Speaking Lessons');
    }
    if (text.contains('business')) {
      tags.add('Business English');
    }
    if (text.contains('ielts') || text.contains('toefl')) {
      tags.add('IELTS & TOEFL');
    }
    if (text.contains('turk')) {
      tags.add('Turkish');
    }
    if (!text.contains('turk')) {
      tags.add('Foreign');
    }
    return tags;
  }

  Future<T?> _guard<T>(Future<T> task) async {
    try {
      return await task;
    } catch (_) {
      return null;
    }
  }
}

class SpeakCoachBootstrap {
  const SpeakCoachBootstrap({
    required this.home,
    required this.instructors,
    required this.settings,
    required this.localState,
  });

  final HomePayload? home;
  final List<InstructorSummary> instructors;
  final PublicSettings? settings;
  final SpeakCoachLocalState localState;
}

class SpeakCoachLocalState {
  const SpeakCoachLocalState({
    required this.goalId,
    required this.accentId,
    required this.budgetId,
    required this.scheduleId,
    required this.reminderWindow,
    required this.onboardingCompleted,
    required this.onboardingLevelId,
    required this.challengeStartDate,
    required this.referralCode,
    required this.favoriteInstructorIds,
    required this.activityLog,
    required this.weeklyTarget,
    required this.activeDates,
    required this.completedMissionIdsByDate,
  });

  final String goalId;
  final String accentId;
  final String budgetId;
  final String scheduleId;
  final String reminderWindow;
  final bool onboardingCompleted;
  final String onboardingLevelId;
  final String? challengeStartDate;
  final String referralCode;
  final List<int> favoriteInstructorIds;
  final List<SpeakCoachActivityEntry> activityLog;
  final int weeklyTarget;
  final List<String> activeDates;
  final Map<String, List<String>> completedMissionIdsByDate;

  factory SpeakCoachLocalState.initial() {
    return const SpeakCoachLocalState(
      goalId: 'speaking',
      accentId: 'foreign',
      budgetId: 'balanced',
      scheduleId: 'evening',
      reminderWindow: 'evening',
      onboardingCompleted: false,
      onboardingLevelId: 'beginner',
      challengeStartDate: null,
      referralCode: '',
      favoriteInstructorIds: <int>[],
      activityLog: <SpeakCoachActivityEntry>[],
      weeklyTarget: 4,
      activeDates: <String>[],
      completedMissionIdsByDate: <String, List<String>>{},
    );
  }

  factory SpeakCoachLocalState.fromJson(Map<String, dynamic> json) {
    final activeDates = (json['active_dates'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .where((value) => value.trim().isNotEmpty)
        .toList(growable: false);

    final completedMissionIdsByDate = <String, List<String>>{};
    final rawCompleted = json['completed_mission_ids_by_date'];
    if (rawCompleted is Map<String, dynamic>) {
      rawCompleted.forEach((key, value) {
        final ids = (value as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList(growable: false);
        completedMissionIdsByDate[key] = ids;
      });
    }

    final favoriteInstructorIds =
        (json['favorite_instructor_ids'] as List<dynamic>? ?? const [])
            .map((item) => int.tryParse(item.toString()) ?? 0)
            .where((id) => id > 0)
            .toList(growable: false);

    final activityLog = (json['activity_log'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SpeakCoachActivityEntry.fromJson)
        .toList(growable: false);

    return SpeakCoachLocalState(
      goalId: (json['goal_id'] ?? 'speaking').toString(),
      accentId: (json['accent_id'] ?? 'foreign').toString(),
      budgetId: (json['budget_id'] ?? 'balanced').toString(),
      scheduleId: (json['schedule_id'] ?? 'evening').toString(),
      reminderWindow: (json['reminder_window'] ?? 'evening').toString(),
      onboardingCompleted: json['onboarding_completed'] == true,
      onboardingLevelId: (json['onboarding_level_id'] ?? 'beginner').toString(),
      challengeStartDate:
          (json['challenge_start_date'] as String?)?.trim().isEmpty ?? true
              ? null
              : (json['challenge_start_date'] as String?)?.trim(),
      referralCode: (json['referral_code'] ?? '').toString(),
      favoriteInstructorIds: favoriteInstructorIds,
      activityLog: activityLog,
      weeklyTarget: _parseInt(json['weekly_target'], 4),
      activeDates: activeDates,
      completedMissionIdsByDate: completedMissionIdsByDate,
    );
  }

  SpeakCoachLocalState copyWith({
    String? goalId,
    String? accentId,
    String? budgetId,
    String? scheduleId,
    String? reminderWindow,
    bool? onboardingCompleted,
    String? onboardingLevelId,
    String? challengeStartDate,
    String? referralCode,
    List<int>? favoriteInstructorIds,
    List<SpeakCoachActivityEntry>? activityLog,
    int? weeklyTarget,
    List<String>? activeDates,
    Map<String, List<String>>? completedMissionIdsByDate,
  }) {
    return SpeakCoachLocalState(
      goalId: goalId ?? this.goalId,
      accentId: accentId ?? this.accentId,
      budgetId: budgetId ?? this.budgetId,
      scheduleId: scheduleId ?? this.scheduleId,
      reminderWindow: reminderWindow ?? this.reminderWindow,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingLevelId: onboardingLevelId ?? this.onboardingLevelId,
      challengeStartDate: challengeStartDate ?? this.challengeStartDate,
      referralCode: referralCode ?? this.referralCode,
      favoriteInstructorIds:
          favoriteInstructorIds ?? this.favoriteInstructorIds,
      activityLog: activityLog ?? this.activityLog,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      activeDates: activeDates ?? this.activeDates,
      completedMissionIdsByDate:
          completedMissionIdsByDate ?? this.completedMissionIdsByDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'accent_id': accentId,
      'budget_id': budgetId,
      'schedule_id': scheduleId,
      'reminder_window': reminderWindow,
      'onboarding_completed': onboardingCompleted,
      'onboarding_level_id': onboardingLevelId,
      'challenge_start_date': challengeStartDate,
      'referral_code': referralCode,
      'favorite_instructor_ids': favoriteInstructorIds,
      'activity_log': activityLog.map((item) => item.toJson()).toList(),
      'weekly_target': weeklyTarget,
      'active_dates': activeDates,
      'completed_mission_ids_by_date': completedMissionIdsByDate,
    };
  }

  static int _parseInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    return int.tryParse('${raw ?? ''}') ?? fallback;
  }
}

class SpeakCoachActivityEntry {
  const SpeakCoachActivityEntry({
    required this.type,
    required this.title,
    required this.timestampIso,
  });

  final String type;
  final String title;
  final String timestampIso;

  factory SpeakCoachActivityEntry.fromJson(Map<String, dynamic> json) {
    return SpeakCoachActivityEntry(
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      timestampIso: (json['timestamp_iso'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'timestamp_iso': timestampIso,
    };
  }
}

String generateSpeakCoachReferralCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random();
  return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
}

class InstructorAvailabilitySnapshot {
  const InstructorAvailabilitySnapshot({
    required this.todayAvailableCount,
    required this.nextAvailableDate,
    required this.nextAvailableSlotLabel,
  });

  final int todayAvailableCount;
  final String? nextAvailableDate;
  final String? nextAvailableSlotLabel;
}
