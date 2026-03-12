import '../../../core/network/api_client.dart';

class StudentLessonsRepository {
  Future<LiveLessonsResponse> fetchLiveLessons() async {
    final response = await ApiClient.dio.get('/live-lessons');
    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return LiveLessonsResponse.fromJson(data);
  }
}

class LiveLessonsResponse {
  LiveLessonsResponse({required this.upcoming, required this.past});

  final List<LiveLessonItem> upcoming;
  final List<LiveLessonItem> past;

  factory LiveLessonsResponse.fromJson(Map<String, dynamic> json) {
    final upcomingList = json['upcoming'] as List<dynamic>? ?? [];
    final pastList = json['past'] as List<dynamic>? ?? [];

    return LiveLessonsResponse(
      upcoming: upcomingList
          .map((item) => LiveLessonItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      past: pastList
          .map((item) => LiveLessonItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LiveLessonItem {
  LiveLessonItem({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.instructorName,
    required this.startTime,
    required this.durationMinutes,
    required this.status,
    required this.courseSlug,
    required this.canJoin,
    this.kind = 'course',
    this.thumbnail,
    this.meetingId,
    this.password,
    this.joinUrl,
    this.endTime,
  });

  final int id;
  final String title;
  final String courseTitle;
  final String instructorName;
  final DateTime? startTime;
  final int durationMinutes;
  final DateTime? endTime;
  final String status;
  final String? courseSlug;
  final String kind;
  final String? thumbnail;
  final String? meetingId;
  final String? password;
  final String? joinUrl;
  final bool canJoin;

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';

  DateTime? get computedEndTime {
    final start = startTime;
    if (start == null) return null;
    return endTime ?? start.add(Duration(minutes: durationMinutes));
  }

  factory LiveLessonItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final rawStart = json['start_time']?.toString();
    DateTime? parsedStart;
    if (rawStart != null && rawStart.isNotEmpty) {
      parsedStart = DateTime.tryParse(rawStart);
    }

    final rawDuration = json['duration_minutes'];
    final parsedDuration = rawDuration is int
        ? rawDuration
        : int.tryParse(rawDuration?.toString() ?? '') ?? 40;

    final rawEnd = json['end_time']?.toString();
    DateTime? parsedEnd;
    if (rawEnd != null && rawEnd.isNotEmpty) {
      parsedEnd = DateTime.tryParse(rawEnd);
    }

    return LiveLessonItem(
      id: parsedId,
      title: (json['title'] ?? '').toString(),
      courseTitle: (json['course_title'] ?? '').toString(),
      instructorName: (json['instructor_name'] ?? '').toString(),
      startTime: parsedStart,
      durationMinutes: parsedDuration,
      status: (json['status'] ?? '').toString(),
      courseSlug: json['course_slug']?.toString(),
      kind: (json['kind'] ?? '').toString(),
      thumbnail: json['thumbnail']?.toString(),
      meetingId: json['meeting_id']?.toString(),
      password: json['password']?.toString(),
      joinUrl: json['join_url']?.toString(),
      endTime: parsedEnd,
      canJoin: json['can_join'] == true ||
          (json['can_join'] is String &&
              (json['can_join'] as String).toLowerCase() == 'true'),
    );
  }
}
