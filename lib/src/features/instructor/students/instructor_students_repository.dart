import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class InstructorStudentsRepository {
  Future<List<InstructorStudent>> fetchStudents() async {
    final response = await ApiClient.dio.get('/instructor/students');
    return ApiResponseParser.requireList(
      response.data,
      context: '/instructor/students',
    ).map(InstructorStudent.fromJson).toList(growable: false);
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
