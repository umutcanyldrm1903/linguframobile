import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class LibraryUploadFile {
  const LibraryUploadFile({
    required this.path,
    required this.name,
  });

  final String path;
  final String name;
}

class InstructorLibraryRepository {
  Future<InstructorLibraryPayload?> fetchLibrary() async {
    final response = await ApiClient.dio.get('/instructor/library');
    return InstructorLibraryPayload.fromJson(
      ApiResponseParser.requireMap(
        response.data,
        context: '/instructor/library',
      ),
    );
  }

  Future<void> createLibraryItem({
    required int studentId,
    required String category,
    required String title,
    String? description,
    LibraryUploadFile? file,
  }) async {
    final data = <String, dynamic>{
      'student_id': studentId,
      'category': category.trim(),
      'title': title.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    if (file != null) {
      data['file'] =
          await MultipartFile.fromFile(file.path, filename: file.name);
    }

    await ApiClient.dio.post(
      '/instructor/library',
      data: FormData.fromMap(data),
    );
  }

  Future<void> updateLibraryItem({
    required int id,
    required String category,
    required String title,
    String? description,
    LibraryUploadFile? file,
  }) async {
    final data = <String, dynamic>{
      'category': category.trim(),
      'title': title.trim(),
      if (description != null) 'description': description.trim(),
    };
    if (file != null) {
      data['file'] =
          await MultipartFile.fromFile(file.path, filename: file.name);
    }

    await ApiClient.dio.put(
      '/instructor/library/$id',
      data: FormData.fromMap(data),
    );
  }

  Future<void> deleteLibraryItem(int id) async {
    await ApiClient.dio.delete('/instructor/library/$id');
  }
}

class InstructorLibraryPayload {
  const InstructorLibraryPayload({
    required this.categories,
    required this.items,
  });

  final List<String> categories;
  final List<InstructorLibraryItem> items;

  factory InstructorLibraryPayload.fromJson(Map<String, dynamic> json) {
    return InstructorLibraryPayload(
      categories: _parseCategories(json['categories']),
      items: _parseItems(json['items']),
    );
  }

  static List<String> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList(growable: false);
  }

  static List<InstructorLibraryItem> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorLibraryItem.fromJson)
        .toList(growable: false);
  }
}

class InstructorLibraryItem {
  const InstructorLibraryItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.fileUrl,
    required this.studentName,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String title;
  final String description;
  final String fileName;
  final String fileType;
  final String filePath;
  final String fileUrl;
  final String studentName;
  final DateTime? createdAt;

  factory InstructorLibraryItem.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = (json['created_at'] ?? '').toString();
    return InstructorLibraryItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      category: (json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fileName: (json['file_name'] ?? '').toString(),
      fileType: (json['file_type'] ?? '').toString(),
      filePath: (json['file_path'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      createdAt: DateTime.tryParse(rawCreatedAt),
    );
  }
}
