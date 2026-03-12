import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';

class InstructorReportsRepository {
  Future<InstructorReportsPayload?> fetchReports() async {
    try {
      final response = await ApiClient.dio.get(
        '/instructor/reports',
        queryParameters: {'language': AppStrings.code},
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return InstructorReportsPayload.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (_) {}
    return null;
  }
}

class InstructorReportsPayload {
  const InstructorReportsPayload({
    required this.title,
    required this.subtitle,
    required this.metrics,
    required this.studentsCount,
    required this.monthly,
  });

  final String title;
  final String subtitle;
  final InstructorReportMetrics metrics;
  final int studentsCount;
  final List<InstructorMonthlyReport> monthly;

  factory InstructorReportsPayload.fromJson(Map<String, dynamic> json) {
    return InstructorReportsPayload(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      metrics: InstructorReportMetrics.fromJson(
        json['metrics'] is Map<String, dynamic>
            ? json['metrics'] as Map<String, dynamic>
            : const {},
      ),
      studentsCount: json['students_count'] is int
          ? json['students_count'] as int
          : int.tryParse('${json['students_count'] ?? 0}') ?? 0,
      monthly: _parseMonthly(json['monthly']),
    );
  }

  static List<InstructorMonthlyReport> _parseMonthly(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorMonthlyReport.fromJson)
        .toList(growable: false);
  }
}

class InstructorReportMetrics {
  const InstructorReportMetrics({
    required this.totalLessons,
    required this.upcomingLessons,
    required this.completed,
    required this.noShow,
    required this.late,
    required this.cancelledByTeacher,
    required this.cancelledByStudent,
  });

  final int totalLessons;
  final int upcomingLessons;
  final int completed;
  final int noShow;
  final int late;
  final int cancelledByTeacher;
  final int cancelledByStudent;

  factory InstructorReportMetrics.fromJson(Map<String, dynamic> json) {
    int parse(dynamic value) {
      if (value is int) return value;
      return int.tryParse('${value ?? 0}') ?? 0;
    }

    return InstructorReportMetrics(
      totalLessons: parse(json['total_lessons']),
      upcomingLessons: parse(json['upcoming_lessons']),
      completed: parse(json['completed']),
      noShow: parse(json['no_show']),
      late: parse(json['late']),
      cancelledByTeacher: parse(json['cancelled_by_teacher']),
      cancelledByStudent: parse(json['cancelled_by_student']),
    );
  }
}

class InstructorMonthlyReport {
  const InstructorMonthlyReport({
    required this.month,
    required this.total,
    required this.completed,
    required this.late,
    required this.noShow,
  });

  final String month;
  final int total;
  final int completed;
  final int late;
  final int noShow;

  factory InstructorMonthlyReport.fromJson(Map<String, dynamic> json) {
    int parse(dynamic value) {
      if (value is int) return value;
      return int.tryParse('${value ?? 0}') ?? 0;
    }

    return InstructorMonthlyReport(
      month: (json['month'] ?? '').toString(),
      total: parse(json['total']),
      completed: parse(json['completed']),
      late: parse(json['late']),
      noShow: parse(json['no_show']),
    );
  }
}
