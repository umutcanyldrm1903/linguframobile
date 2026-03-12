import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class InstructorHomeworksRepository {
  Future<InstructorHomeworksPayload?> fetchHomeworks() async {
    final response = await ApiClient.dio.get(
      '/instructor/homeworks',
      queryParameters: {'language': AppStrings.code},
    );
    return InstructorHomeworksPayload.fromJson(
      ApiResponseParser.requireMap(
        response.data,
        context: '/instructor/homeworks',
      ),
    );
  }

  Future<void> createHomework({
    required int studentId,
    required String title,
    String? description,
    DateTime? dueAt,
  }) async {
    await ApiClient.dio.post(
      '/instructor/homeworks',
      data: {
        'student_id': studentId,
        'title': title.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (dueAt != null) 'due_at': dueAt.toIso8601String(),
      },
    );
  }

  Future<void> updateHomework({
    required int id,
    required String title,
    String? description,
    DateTime? dueAt,
    String? status,
  }) async {
    await ApiClient.dio.put(
      '/instructor/homeworks/$id',
      data: {
        'title': title.trim(),
        if (description != null) 'description': description.trim(),
        if (dueAt != null) 'due_at': dueAt.toIso8601String(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
  }

  Future<void> archiveHomework(int id) async {
    await ApiClient.dio.post('/instructor/homeworks/$id/archive');
  }

  Future<void> reviewHomework({
    required int id,
    required String status,
    String? instructorNote,
  }) async {
    await ApiClient.dio.put(
      '/instructor/homeworks/$id/review',
      data: {
        'status': status,
        if (instructorNote != null) 'instructor_note': instructorNote.trim(),
      },
    );
  }
}

class InstructorHomeworksPayload {
  const InstructorHomeworksPayload({
    required this.active,
    required this.archived,
  });

  final List<InstructorHomeworkItem> active;
  final List<InstructorHomeworkItem> archived;

  factory InstructorHomeworksPayload.fromJson(Map<String, dynamic> json) {
    return InstructorHomeworksPayload(
      active: _parseList(json['active']),
      archived: _parseList(json['archived']),
    );
  }

  static List<InstructorHomeworkItem> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorHomeworkItem.fromJson)
        .toList(growable: false);
  }
}

class InstructorHomeworkItem {
  const InstructorHomeworkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.studentName,
    required this.dueAt,
    required this.attachmentName,
    required this.attachmentPath,
    required this.submission,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String statusLabel;
  final String studentName;
  final DateTime? dueAt;
  final String attachmentName;
  final String attachmentPath;
  final InstructorHomeworkSubmission? submission;

  factory InstructorHomeworkItem.fromJson(Map<String, dynamic> json) {
    final dueAtRaw = (json['due_at'] ?? '').toString();
    final submissionRaw = json['submission'];
    return InstructorHomeworkItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      dueAt: DateTime.tryParse(dueAtRaw),
      attachmentName: (json['attachment_name'] ?? '').toString(),
      attachmentPath: (json['attachment_path'] ?? '').toString(),
      submission: submissionRaw is Map<String, dynamic>
          ? InstructorHomeworkSubmission.fromJson(submissionRaw)
          : null,
    );
  }
}

class InstructorHomeworkSubmission {
  const InstructorHomeworkSubmission({
    required this.status,
    required this.submissionName,
    required this.submissionPath,
    required this.submittedAt,
    required this.studentNote,
    required this.instructorNote,
    required this.reviewedAt,
  });

  final String status;
  final String submissionName;
  final String submissionPath;
  final DateTime? submittedAt;
  final String studentNote;
  final String instructorNote;
  final DateTime? reviewedAt;

  factory InstructorHomeworkSubmission.fromJson(Map<String, dynamic> json) {
    final submittedAtRaw = (json['submitted_at'] ?? '').toString();
    final reviewedAtRaw = (json['reviewed_at'] ?? '').toString();
    return InstructorHomeworkSubmission(
      status: (json['status'] ?? '').toString(),
      submissionName: (json['submission_name'] ?? '').toString(),
      submissionPath: (json['submission_path'] ?? '').toString(),
      submittedAt: DateTime.tryParse(submittedAtRaw),
      studentNote: (json['student_note'] ?? json['note'] ?? '').toString(),
      instructorNote: (json['instructor_note'] ?? '').toString(),
      reviewedAt: DateTime.tryParse(reviewedAtRaw),
    );
  }
}
