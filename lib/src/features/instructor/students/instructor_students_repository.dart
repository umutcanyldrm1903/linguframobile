import '../../../core/network/api_client.dart';

class InstructorStudentsRepository {
  Future<List<InstructorStudent>> fetchStudents() async {
    try {
      final response = await ApiClient.dio.get('/instructor/students');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(InstructorStudent.fromJson)
            .toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }
}

class InstructorStudent {
  const InstructorStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String imageUrl;

  factory InstructorStudent.fromJson(Map<String, dynamic> json) {
    return InstructorStudent(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
    );
  }
}
