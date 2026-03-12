import '../../../core/network/api_client.dart';

class StudentHomeworksRepository {
  Future<StudentHomeworksPayload?> fetchHomeworks() async {
    final response = await ApiClient.dio.get('/homeworks');
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return StudentHomeworksPayload.fromJson(data);
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

class StudentHomeworksPayload {
  const StudentHomeworksPayload({
    required this.active,
    required this.archived,
  });

  final List<StudentHomeworkItem> active;
  final List<StudentHomeworkItem> archived;

  factory StudentHomeworksPayload.fromJson(Map<String, dynamic> json) {
    return StudentHomeworksPayload(
      active: _parseList(json['active']),
      archived: _parseList(json['archived']),
    );
  }

  static List<StudentHomeworkItem> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StudentHomeworkItem.fromJson)
        .toList(growable: false);
  }
}

class StudentHomeworkItem {
  const StudentHomeworkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueAt,
    required this.instructorName,
    required this.instructorImage,
    required this.submission,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final DateTime? dueAt;
  final String instructorName;
  final String instructorImage;
  final HomeworkSubmission? submission;

  bool get isArchived => status == 'archived';

  factory StudentHomeworkItem.fromJson(Map<String, dynamic> json) {
    final due = (json['due_at'] ?? '').toString();
    final submissionRaw = json['submission'];
    return StudentHomeworkItem(
      id: json['id'] is int ? json['id'] as int : 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      dueAt: DateTime.tryParse(due),
      instructorName: (json['instructor_name'] ?? '').toString(),
      instructorImage: (json['instructor_image'] ?? '').toString(),
      submission: submissionRaw is Map<String, dynamic>
          ? HomeworkSubmission.fromJson(submissionRaw)
          : null,
    );
  }
}

class HomeworkSubmission {
  const HomeworkSubmission({
    required this.status,
    required this.submissionName,
    required this.submissionPath,
    required this.submittedAt,
    required this.note,
  });

  final String status;
  final String submissionName;
  final String submissionPath;
  final DateTime? submittedAt;
  final String note;

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    final submitted = (json['submitted_at'] ?? '').toString();
    return HomeworkSubmission(
      status: (json['status'] ?? '').toString(),
      submissionName: (json['submission_name'] ?? '').toString(),
      submissionPath: (json['submission_path'] ?? '').toString(),
      submittedAt: DateTime.tryParse(submitted),
      note: (json['note'] ?? '').toString(),
    );
  }
}
