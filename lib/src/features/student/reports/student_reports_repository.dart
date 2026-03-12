import '../../../core/network/api_client.dart';

class StudentReportsRepository {
  Future<StudentReportSummary?> fetchReports() async {
    final response = await ApiClient.dio.get('/reports');
    final data = _extractMap(response.data);
    if (data == null) return null;
    return StudentReportSummary.fromJson(data);
  }

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
}

class StudentReportSummary {
  const StudentReportSummary({
    required this.totalMinutes,
    required this.completedLessons,
    required this.quizAverage,
    required this.reviewCount,
  });

  final int totalMinutes;
  final int completedLessons;
  final double quizAverage;
  final int reviewCount;

  factory StudentReportSummary.fromJson(Map<String, dynamic> json) {
    return StudentReportSummary(
      totalMinutes: json['total_minutes'] is int
          ? json['total_minutes'] as int
          : int.tryParse('${json['total_minutes'] ?? 0}') ?? 0,
      completedLessons: json['completed_lessons'] is int
          ? json['completed_lessons'] as int
          : int.tryParse('${json['completed_lessons'] ?? 0}') ?? 0,
      quizAverage: json['quiz_average'] is num
          ? (json['quiz_average'] as num).toDouble()
          : double.tryParse('${json['quiz_average'] ?? 0}') ?? 0,
      reviewCount: json['review_count'] is int
          ? json['review_count'] as int
          : int.tryParse('${json['review_count'] ?? 0}') ?? 0,
    );
  }
}
