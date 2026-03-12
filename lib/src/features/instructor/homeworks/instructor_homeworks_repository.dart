import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';

class InstructorHomeworksRepository {
  Future<InstructorHomeworksPayload?> fetchHomeworks() async {
    try {
      final response = await ApiClient.dio.get(
        '/instructor/homeworks',
        queryParameters: {'language': AppStrings.code},
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return InstructorHomeworksPayload.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (_) {}

    return null;
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
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final String statusLabel;
  final String studentName;
  final DateTime? dueAt;

  factory InstructorHomeworkItem.fromJson(Map<String, dynamic> json) {
    final dueAtRaw = (json['due_at'] ?? '').toString();
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
    );
  }
}
