import '../../../core/network/api_client.dart';

class InstructorDashboardRepository {
  Future<InstructorDashboardPayload?> fetchDashboard() async {
    try {
      final response = await ApiClient.dio.get('/instructor/dashboard');
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return InstructorDashboardPayload.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (_) {}
    return null;
  }
}

class InstructorDashboardPayload {
  const InstructorDashboardPayload({
    required this.name,
    required this.stats,
    required this.upcoming,
  });

  final String name;
  final InstructorStats stats;
  final List<InstructorUpcomingLesson> upcoming;

  factory InstructorDashboardPayload.fromJson(Map<String, dynamic> json) {
    return InstructorDashboardPayload(
      name: (json['name'] ?? '').toString(),
      stats: InstructorStats.fromJson(
        json['stats'] is Map<String, dynamic>
            ? json['stats'] as Map<String, dynamic>
            : const {},
      ),
      upcoming: _parseUpcoming(json['upcoming']),
    );
  }

  static List<InstructorUpcomingLesson> _parseUpcoming(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorUpcomingLesson.fromJson)
        .toList(growable: false);
  }
}

class InstructorStats {
  const InstructorStats({
    required this.totalLessons,
    required this.upcomingLessons,
    required this.activeStudents,
    required this.avgRating,
  });

  final int totalLessons;
  final int upcomingLessons;
  final int activeStudents;
  final double avgRating;

  factory InstructorStats.fromJson(Map<String, dynamic> json) {
    return InstructorStats(
      totalLessons: json['total_lessons'] is int
          ? json['total_lessons'] as int
          : int.tryParse('${json['total_lessons'] ?? 0}') ?? 0,
      upcomingLessons: json['upcoming_lessons'] is int
          ? json['upcoming_lessons'] as int
          : int.tryParse('${json['upcoming_lessons'] ?? 0}') ?? 0,
      activeStudents: json['active_students'] is int
          ? json['active_students'] as int
          : int.tryParse('${json['active_students'] ?? 0}') ?? 0,
      avgRating: json['avg_rating'] is num
          ? (json['avg_rating'] as num).toDouble()
          : double.tryParse('${json['avg_rating'] ?? 0}') ?? 0,
    );
  }
}

class InstructorUpcomingLesson {
  const InstructorUpcomingLesson({
    required this.id,
    required this.title,
    required this.studentName,
    required this.startTime,
    required this.durationMinutes,
    required this.joinUrl,
    required this.meetingId,
    required this.password,
    required this.status,
    this.endTime,
  });

  final int id;
  final String title;
  final String studentName;
  final DateTime? startTime;
  final int durationMinutes;
  final String? joinUrl;
  final String meetingId;
  final String password;
  final String status;
  final DateTime? endTime;

  bool get isPending => status == 'pending';

  DateTime? get computedEndTime {
    final start = startTime;
    if (start == null) return null;
    return endTime ?? start.add(Duration(minutes: durationMinutes));
  }

  factory InstructorUpcomingLesson.fromJson(Map<String, dynamic> json) {
    final start = (json['start_time'] ?? '').toString();
    final rawDuration = json['duration_minutes'];
    final parsedDuration = rawDuration is int
        ? rawDuration
        : int.tryParse(rawDuration?.toString() ?? '') ?? 40;
    final rawEnd = json['end_time']?.toString();
    DateTime? parsedEnd;
    if (rawEnd != null && rawEnd.isNotEmpty) {
      parsedEnd = DateTime.tryParse(rawEnd);
    }
    return InstructorUpcomingLesson(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      startTime: DateTime.tryParse(start),
      durationMinutes: parsedDuration,
      joinUrl: json['join_url']?.toString(),
      meetingId: (json['meeting_id'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      endTime: parsedEnd,
    );
  }
}
