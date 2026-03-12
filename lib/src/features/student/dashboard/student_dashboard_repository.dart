import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../lessons/student_lessons_repository.dart';

class StudentDashboardRepository {
  Future<DashboardPayload?> fetchDashboard() async {
    final responses = await Future.wait([
      ApiClient.dio.get('/profile'),
      ApiClient.dio.get('/live-lessons'),
    ]);

    final profileData = ApiResponseParser.requireMap(
      responses[0].data,
      context: '/profile',
    );
    final liveData = ApiResponseParser.requireMap(
      responses[1].data,
      context: '/live-lessons',
    );

    final name = (profileData['name'] ?? '').toString();
    final planRaw = profileData['plan'];
    final plan = planRaw is Map<String, dynamic>
        ? PlanSummary.fromJson(planRaw)
        : null;
    final phone = (profileData['phone'] ?? '').toString();

    final upcoming = _parseList(
      liveData['upcoming'],
      LiveLessonItem.fromJson,
    );
    final past = _parseList(liveData['past'], LiveLessonItem.fromJson);

    return DashboardPayload(
      name: name,
      phone: phone,
      plan: plan,
      upcoming: upcoming,
      past: past,
    );
  }

  List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) mapper) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(mapper)
        .toList(growable: false);
  }

  Future<TrialLessonRequestResult> requestTrialLesson() async {
    final response = await ApiClient.dio.post('/trial/request');
    final payload = response.data;

    if (payload is Map<String, dynamic>) {
      final message = (payload['message'] ?? '').toString();
      var whatsappUrl = '';
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        whatsappUrl = (data['whatsapp_url'] ?? '').toString();
      }
      return TrialLessonRequestResult(
        message: message,
        whatsappUrl: whatsappUrl,
      );
    }

    return const TrialLessonRequestResult(message: '', whatsappUrl: '');
  }
}

class DashboardPayload {
  const DashboardPayload({
    required this.name,
    required this.phone,
    required this.plan,
    required this.upcoming,
    required this.past,
  });

  final String name;
  final String phone;
  final PlanSummary? plan;
  final List<LiveLessonItem> upcoming;
  final List<LiveLessonItem> past;
}

class TrialLessonRequestResult {
  const TrialLessonRequestResult({
    required this.message,
    required this.whatsappUrl,
  });

  final String message;
  final String whatsappUrl;
}

class PlanSummary {
  const PlanSummary({
    required this.title,
    required this.lessonsRemaining,
    required this.cancelRemaining,
    required this.assignedInstructorName,
  });

  final String title;
  final int lessonsRemaining;
  final int cancelRemaining;
  final String? assignedInstructorName;

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    return PlanSummary(
      title: (json['title'] ?? '').toString(),
      lessonsRemaining: json['lessons_remaining'] is int
          ? json['lessons_remaining'] as int
          : int.tryParse('${json['lessons_remaining'] ?? 0}') ?? 0,
      cancelRemaining: json['cancel_remaining'] is int
          ? json['cancel_remaining'] as int
          : int.tryParse('${json['cancel_remaining'] ?? 0}') ?? 0,
      assignedInstructorName: json['assigned_instructor_name']?.toString(),
    );
  }
}
