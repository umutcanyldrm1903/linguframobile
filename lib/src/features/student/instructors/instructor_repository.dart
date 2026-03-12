import '../../../core/network/api_client.dart';

class InstructorRepository {
  Future<List<InstructorSummary>> fetchInstructors({
    String? search,
    List<String>? tags,
  }) async {
    final response = await ApiClient.dio.get('/instructors', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (tags != null && tags.isNotEmpty) 'tag': tags,
    });

    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => InstructorSummary.fromJson(item as Map<String, dynamic>))
        .toList();
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

    final payload = response.data as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
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
    return response.data as Map<String, dynamic>;
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
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
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
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((tag) => tag.toString())
          .toList(),
    );
  }
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
    final daysData = json['days'] as List<dynamic>? ?? [];
    final slotsData = json['slots'] as Map<String, dynamic>? ?? {};
    final slots = <String, List<ScheduleSlot>>{};

    slotsData.forEach((key, value) {
      final list = (value as List<dynamic>? ?? [])
          .map((item) => ScheduleSlot.fromJson(item as Map<String, dynamic>))
          .toList();
      slots[key] = list;
    });

    return InstructorSchedule(
      weekStart: (json['week_start'] ?? '').toString(),
      weekEnd: (json['week_end'] ?? '').toString(),
      prevStart: (json['prev_start'] ?? '').toString(),
      nextStart: (json['next_start'] ?? '').toString(),
      lessonDuration: (json['lesson_duration'] ?? 0) as int,
      timezone: (json['timezone'] ?? '').toString(),
      days: daysData
          .map((item) => ScheduleDay.fromJson(item as Map<String, dynamic>))
          .toList(),
      slotsByDate: slots,
      instructor:
          InstructorSummary.fromJson(json['instructor'] as Map<String, dynamic>),
    );
  }
}

class ScheduleDay {
  ScheduleDay({required this.date, required this.dayOfWeek});

  final String date;
  final int dayOfWeek;

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    return ScheduleDay(
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['day_of_week'] ?? 0) as int,
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
      available: (json['available'] ?? false) as bool,
      value: (json['value'] ?? '').toString(),
    );
  }
}
