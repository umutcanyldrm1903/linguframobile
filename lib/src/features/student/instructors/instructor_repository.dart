import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class InstructorRepository {
  Future<List<InstructorSummary>> fetchInstructors({
    String? search,
    List<String>? tags,
  }) async {
    final response = await ApiClient.dio.get('/instructors', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (tags != null && tags.isNotEmpty) 'tag': tags,
    });

    final data = ApiResponseParser.tryList(response.data) ?? const [];
    return data.map(InstructorSummary.fromJson).toList();
  }

  Future<InstructorSchedule> fetchSchedule({
    required int instructorId,
    String? start,
  }) async {
    final response = await ApiClient.dio.get(
      '/instructors/$instructorId/schedule',
      queryParameters: {
        if (start != null && start.isNotEmpty) 'start': start,
      },
    );

    final data = ApiResponseParser.tryMap(response.data) ?? const {};
    return InstructorSchedule.fromJson(data);
  }

  Future<Map<String, dynamic>> bookSchedule({
    required int instructorId,
    required String slot,
  }) async {
    final response = await ApiClient.dio.post(
      '/instructors/$instructorId/schedule',
      data: {'slot': slot},
    );
    return ApiResponseParser.tryMap(response.data) ?? const {};
  }
}

class InstructorSummary {
  InstructorSummary({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.shortBio,
    required this.bio,
    required this.imageUrl,
    required this.avgRating,
    required this.courseCount,
    required this.tags,
  });

  final int id;
  final String name;
  final String jobTitle;
  final String shortBio;
  final String bio;
  final String? imageUrl;
  final double avgRating;
  final int courseCount;
  final List<String> tags;

  factory InstructorSummary.fromJson(Map<String, dynamic> json) {
    final rawRating = json['avg_rating'];
    final parsedRating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '') ?? 0;
    final rawId = json['id'];
    final parsedId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final rawCourseCount = json['course_count'];
    final parsedCourseCount = rawCourseCount is int
        ? rawCourseCount
        : int.tryParse(rawCourseCount?.toString() ?? '') ?? 0;
    return InstructorSummary(
      id: parsedId,
      name: (json['name'] ?? '').toString(),
      jobTitle: (json['job_title'] ?? '').toString(),
      shortBio: (json['short_bio'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      imageUrl: json['image']?.toString(),
      avgRating: parsedRating,
      courseCount: parsedCourseCount,
      tags: _safeList(json['tags']).map((tag) => tag.toString()).toList(),
    );
  }

  static List<dynamic> _safeList(dynamic raw) => raw is List ? raw : const [];
}

class InstructorSchedule {
  InstructorSchedule({
    required this.weekStart,
    required this.weekEnd,
    required this.prevStart,
    required this.nextStart,
    required this.lessonDuration,
    required this.timezone,
    required this.days,
    required this.slotsByDate,
    required this.instructor,
  });

  final String weekStart;
  final String weekEnd;
  final String prevStart;
  final String nextStart;
  final int lessonDuration;
  final String timezone;
  final List<ScheduleDay> days;
  final Map<String, List<ScheduleSlot>> slotsByDate;
  final InstructorSummary instructor;

  factory InstructorSchedule.fromJson(Map<String, dynamic> json) {
    final daysData = json['days'] is List ? json['days'] as List : const [];
    final slotsData = json['slots'] is Map ? json['slots'] as Map : const {};
    final slots = <String, List<ScheduleSlot>>{};

    slotsData.forEach((key, value) {
      final list = (value is List ? value : const [])
          .whereType<Map>()
          .map((item) => ScheduleSlot.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      slots[key.toString()] = list;
    });

    return InstructorSchedule(
      weekStart: (json['week_start'] ?? '').toString(),
      weekEnd: (json['week_end'] ?? '').toString(),
      prevStart: (json['prev_start'] ?? '').toString(),
      nextStart: (json['next_start'] ?? '').toString(),
      lessonDuration: _intValue(json['lesson_duration']),
      timezone: (json['timezone'] ?? '').toString(),
      days: daysData
          .whereType<Map>()
          .map((item) => ScheduleDay.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      slotsByDate: slots,
      instructor: InstructorSummary.fromJson(
        json['instructor'] is Map
            ? Map<String, dynamic>.from(json['instructor'] as Map)
            : const {},
      ),
    );
  }

  static int _intValue(dynamic raw) =>
      raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
}

class ScheduleDay {
  ScheduleDay({required this.date, required this.dayOfWeek});

  final String date;
  final int dayOfWeek;

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    return ScheduleDay(
      date: (json['date'] ?? '').toString(),
      dayOfWeek: json['day_of_week'] is int
          ? json['day_of_week'] as int
          : int.tryParse(json['day_of_week']?.toString() ?? '') ?? 0,
    );
  }
}

class ScheduleSlot {
  ScheduleSlot({
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.available,
    required this.value,
  });

  final String startTime;
  final String endTime;
  final String label;
  final bool available;
  final String value;

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      available: json['available'] == true ||
          (json['available'] is String &&
              (json['available'] as String).toLowerCase() == 'true'),
      value: (json['value'] ?? '').toString(),
    );
  }
}
