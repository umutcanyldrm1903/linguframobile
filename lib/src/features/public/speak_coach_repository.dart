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
  static const _availabilityCacheKey = 'speak_coach_availability_cache_v1';
  static const _availabilityRetryQueueKey = 'speak_coach_availability_retry_v1';

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

  Future<AvailabilityFetchResult> fetchAvailabilityWithFallback(
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

      final snapshot = InstructorAvailabilitySnapshot(
        todayAvailableCount: todayAvailableCount,
        nextAvailableDate: nextAvailableDate,
        nextAvailableSlotLabel: nextAvailableSlotLabel,
      );
      await _cacheAvailability(instructorId, snapshot);
      return AvailabilityFetchResult(
        snapshot: snapshot,
        fromCache: false,
      );
    } catch (_) {
      final cached = await _cachedAvailability(instructorId);
      await _enqueueAvailabilityRetry(instructorId);
      return AvailabilityFetchResult(
        snapshot: cached,
        fromCache: true,
      );
    }
  }

  Future<int> pendingAvailabilityRetryCount() async {
    final queue = await _readAvailabilityRetryQueue();
    return queue.length;
  }

  Future<void> flushAvailabilityRetryQueue() async {
    final queue = await _readAvailabilityRetryQueue();
    if (queue.isEmpty) return;
    final unresolved = <int>[];
    for (final instructorId in queue) {
      final fetched = await fetchAvailabilityWithFallback(instructorId);
      if (fetched.fromCache) {
        unresolved.add(instructorId);
      }
    }
    await _writeAvailabilityRetryQueue(unresolved);
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

  Future<void> _cacheAvailability(
    int instructorId,
    InstructorAvailabilitySnapshot snapshot,
  ) async {
    final all = await _readAvailabilityCache();
    all['$instructorId'] = snapshot.toJson();
    await SecureStorage.setValue(_availabilityCacheKey, jsonEncode(all));
  }

  Future<InstructorAvailabilitySnapshot?> _cachedAvailability(
    int instructorId,
  ) async {
    final all = await _readAvailabilityCache();
    final raw = all['$instructorId'];
    if (raw is Map<String, dynamic>) {
      return InstructorAvailabilitySnapshot.fromJson(raw);
    }
    return null;
  }

  Future<Map<String, dynamic>> _readAvailabilityCache() async {
    final raw = await SecureStorage.getValue(_availabilityCacheKey);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  Future<void> _enqueueAvailabilityRetry(int instructorId) async {
    final queue = await _readAvailabilityRetryQueue();
    if (!queue.contains(instructorId)) {
      queue.add(instructorId);
      await _writeAvailabilityRetryQueue(queue);
    }
  }

  Future<List<int>> _readAvailabilityRetryQueue() async {
    final raw = await SecureStorage.getValue(_availabilityRetryQueueKey);
    if (raw == null || raw.trim().isEmpty) return <int>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => int.tryParse('$item') ?? 0)
            .where((id) => id > 0)
            .toList(growable: true);
      }
    } catch (_) {}
    return <int>[];
  }

  Future<void> _writeAvailabilityRetryQueue(List<int> queue) async {
    await SecureStorage.setValue(_availabilityRetryQueueKey, jsonEncode(queue));
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
    required this.preferredPracticeMode,
    required this.onboardingCompleted,
    required this.onboardingLevelId,
    required this.challengeStartDate,
    required this.referralCode,
    required this.favoriteInstructorIds,
    required this.savedPhrases,
    required this.compareSessions,
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
  final String preferredPracticeMode;
  final bool onboardingCompleted;
  final String onboardingLevelId;
  final String? challengeStartDate;
  final String referralCode;
  final List<int> favoriteInstructorIds;
  final List<String> savedPhrases;
  final List<SpeakCoachCompareSession> compareSessions;
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
      preferredPracticeMode: 'shadow',
      onboardingCompleted: false,
      onboardingLevelId: 'beginner',
      challengeStartDate: null,
      referralCode: '',
      favoriteInstructorIds: <int>[],
      savedPhrases: <String>[],
      compareSessions: <SpeakCoachCompareSession>[],
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

    final compareSessions =
        (json['compare_sessions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SpeakCoachCompareSession.fromJson)
            .toList(growable: false);

    return SpeakCoachLocalState(
      goalId: (json['goal_id'] ?? 'speaking').toString(),
      accentId: (json['accent_id'] ?? 'foreign').toString(),
      budgetId: (json['budget_id'] ?? 'balanced').toString(),
      scheduleId: (json['schedule_id'] ?? 'evening').toString(),
      reminderWindow: (json['reminder_window'] ?? 'evening').toString(),
      preferredPracticeMode:
          (json['preferred_practice_mode'] ?? 'shadow').toString(),
      onboardingCompleted: json['onboarding_completed'] == true,
      onboardingLevelId: (json['onboarding_level_id'] ?? 'beginner').toString(),
      challengeStartDate:
          (json['challenge_start_date'] as String?)?.trim().isEmpty ?? true
              ? null
              : (json['challenge_start_date'] as String?)?.trim(),
      referralCode: (json['referral_code'] ?? '').toString(),
      favoriteInstructorIds: favoriteInstructorIds,
      savedPhrases: (json['saved_phrases'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      compareSessions: compareSessions,
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
    String? preferredPracticeMode,
    bool? onboardingCompleted,
    String? onboardingLevelId,
    String? challengeStartDate,
    String? referralCode,
    List<int>? favoriteInstructorIds,
    List<String>? savedPhrases,
    List<SpeakCoachCompareSession>? compareSessions,
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
      preferredPracticeMode:
          preferredPracticeMode ?? this.preferredPracticeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingLevelId: onboardingLevelId ?? this.onboardingLevelId,
      challengeStartDate: challengeStartDate ?? this.challengeStartDate,
      referralCode: referralCode ?? this.referralCode,
      favoriteInstructorIds:
          favoriteInstructorIds ?? this.favoriteInstructorIds,
      savedPhrases: savedPhrases ?? this.savedPhrases,
      compareSessions: compareSessions ?? this.compareSessions,
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
      'preferred_practice_mode': preferredPracticeMode,
      'onboarding_completed': onboardingCompleted,
      'onboarding_level_id': onboardingLevelId,
      'challenge_start_date': challengeStartDate,
      'referral_code': referralCode,
      'favorite_instructor_ids': favoriteInstructorIds,
      'saved_phrases': savedPhrases,
      'compare_sessions': compareSessions.map((item) => item.toJson()).toList(),
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

class SpeakCoachCompareSession {
  const SpeakCoachCompareSession({
    required this.id,
    required this.goalId,
    required this.practiceModeId,
    required this.focusLine,
    required this.audioPath,
    required this.durationSeconds,
    required this.clarityScore,
    required this.rhythmScore,
    required this.confidenceScore,
    required this.transcript,
    required this.rewrittenTranscript,
    required this.errorTags,
    required this.errorTagScores,
    required this.createdAtIso,
  });

  final String id;
  final String goalId;
  final String practiceModeId;
  final String focusLine;
  final String audioPath;
  final int durationSeconds;
  final int clarityScore;
  final int rhythmScore;
  final int confidenceScore;
  final String transcript;
  final String rewrittenTranscript;
  final List<String> errorTags;
  final Map<String, int> errorTagScores;
  final String createdAtIso;

  factory SpeakCoachCompareSession.fromJson(Map<String, dynamic> json) {
    return SpeakCoachCompareSession(
      id: (json['id'] ?? '').toString(),
      goalId: (json['goal_id'] ?? '').toString(),
      practiceModeId: (json['practice_mode_id'] ?? '').toString(),
      focusLine: (json['focus_line'] ?? '').toString(),
      audioPath: (json['audio_path'] ?? '').toString(),
      durationSeconds: _parseInt(json['duration_seconds'], 0),
      clarityScore: _parseInt(json['clarity_score'], 0),
      rhythmScore: _parseInt(json['rhythm_score'], 0),
      confidenceScore: _parseInt(json['confidence_score'], 0),
      transcript: (json['transcript'] ?? '').toString(),
      rewrittenTranscript: (json['rewritten_transcript'] ?? '').toString(),
      errorTags: (json['error_tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false),
      errorTagScores: _parseTagScores(json['error_tag_scores']),
      createdAtIso: (json['created_at_iso'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'practice_mode_id': practiceModeId,
      'focus_line': focusLine,
      'audio_path': audioPath,
      'duration_seconds': durationSeconds,
      'clarity_score': clarityScore,
      'rhythm_score': rhythmScore,
      'confidence_score': confidenceScore,
      'transcript': transcript,
      'rewritten_transcript': rewrittenTranscript,
      'error_tags': errorTags,
      'error_tag_scores': errorTagScores,
      'created_at_iso': createdAtIso,
    };
  }

  static int _parseInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    return int.tryParse('${raw ?? ''}') ?? fallback;
  }

  static Map<String, int> _parseTagScores(dynamic raw) {
    final parsed = <String, int>{};
    if (raw is Map<String, dynamic>) {
      raw.forEach((key, value) {
        final numeric = _parseInt(value, 0).clamp(0, 100);
        if (key.trim().isNotEmpty && numeric > 0) {
          parsed[key] = numeric;
        }
      });
    }
    return parsed;
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

  factory InstructorAvailabilitySnapshot.fromJson(Map<String, dynamic> json) {
    return InstructorAvailabilitySnapshot(
      todayAvailableCount: int.tryParse('${json['today_available_count'] ?? 0}') ?? 0,
      nextAvailableDate: (json['next_available_date'] as String?)?.trim(),
      nextAvailableSlotLabel: (json['next_available_slot_label'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today_available_count': todayAvailableCount,
      'next_available_date': nextAvailableDate,
      'next_available_slot_label': nextAvailableSlotLabel,
    };
  }
}

class AvailabilityFetchResult {
  const AvailabilityFetchResult({
    required this.snapshot,
    required this.fromCache,
  });

  final InstructorAvailabilitySnapshot? snapshot;
  final bool fromCache;
}
