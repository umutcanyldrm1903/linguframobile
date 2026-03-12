import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class InstructorLessonsRepository {
  Future<InstructorLessonsPayload?> fetchLessons() async {
    final response = await ApiClient.dio.get('/instructor/lessons');
    return InstructorLessonsPayload.fromJson(
      ApiResponseParser.requireMap(
        response.data,
        context: '/instructor/lessons',
      ),
    );
  }

  Future<InstructorLessonStartResult?> startLesson(int lessonId) async {
    if (lessonId <= 0) return null;
    final response = await ApiClient.dio.post('/instructor/lessons/$lessonId/start');
    return InstructorLessonStartResult.fromJson(
      ApiResponseParser.requireMap(
        response.data,
        context: '/instructor/lessons/$lessonId/start',
      ),
    );
  }
}

class InstructorLessonsPayload {
  const InstructorLessonsPayload({
    required this.upcoming,
    required this.past,
  });

  final List<InstructorLessonItem> upcoming;
  final List<InstructorLessonItem> past;

  factory InstructorLessonsPayload.fromJson(Map<String, dynamic> json) {
    return InstructorLessonsPayload(
      upcoming: _parseList(json['upcoming']),
      past: _parseList(json['past']),
    );
  }

  static List<InstructorLessonItem> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorLessonItem.fromJson)
        .toList(growable: false);
  }
}

class InstructorLessonItem {
  const InstructorLessonItem({
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
  final DateTime? endTime;
  final String? joinUrl;
  final String meetingId;
  final String password;
  final String status;

  bool get isPending => status == 'pending';

  DateTime? get computedEndTime {
    final start = startTime;
    if (start == null) return null;
    return endTime ?? start.add(Duration(minutes: durationMinutes));
  }

  factory InstructorLessonItem.fromJson(Map<String, dynamic> json) {
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
    return InstructorLessonItem(
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

class InstructorLessonStartResult {
  const InstructorLessonStartResult({
    required this.id,
    required this.status,
    required this.joinUrl,
    required this.meetingId,
    required this.password,
  });

  final int id;
  final String status;
  final String joinUrl;
  final String meetingId;
  final String password;

  factory InstructorLessonStartResult.fromJson(Map<String, dynamic> json) {
    return InstructorLessonStartResult(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      status: (json['status'] ?? '').toString(),
      joinUrl: (json['join_url'] ?? '').toString(),
      meetingId: (json['meeting_id'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
    );
  }
}
