import '../../../core/network/api_client.dart';

class StudentLibraryRepository {
  Future<StudentLibraryPayload?> fetchLibrary({String? category}) async {
    final response = await ApiClient.dio.get(
      '/library',
      queryParameters: {
        if (category != null && category.trim().isNotEmpty) 'category': category,
      },
    );
    final data = _extractMap(response.data);
    if (data == null) {
      return null;
    }
    return StudentLibraryPayload.fromJson(data);
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

class StudentLibraryPayload {
  const StudentLibraryPayload({
    required this.categories,
    required this.items,
    required this.selectedCategory,
  });

  final List<StudentLibraryCategory> categories;
  final List<StudentLibraryItem> items;
  final String selectedCategory;

  factory StudentLibraryPayload.fromJson(Map<String, dynamic> json) {
    return StudentLibraryPayload(
      categories: _parseCategories(json['categories']),
      items: _parseItems(json['items']),
      selectedCategory: (json['selected_category'] ?? '').toString(),
    );
  }

  static List<StudentLibraryCategory> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StudentLibraryCategory.fromJson)
        .toList(growable: false);
  }

  static List<StudentLibraryItem> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StudentLibraryItem.fromJson)
        .toList(growable: false);
  }
}

class StudentLibraryCategory {
  const StudentLibraryCategory({
    required this.name,
    required this.slug,
  });

  final String name;
  final String slug;

  factory StudentLibraryCategory.fromJson(Map<String, dynamic> json) {
    return StudentLibraryCategory(
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class StudentLibraryItem {
  const StudentLibraryItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileType,
    required this.filePath,
    required this.instructorName,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String title;
  final String description;
  final String fileName;
  final String fileType;
  final String filePath;
  final String instructorName;
  final DateTime? createdAt;

  factory StudentLibraryItem.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = (json['created_at'] ?? '').toString();
    return StudentLibraryItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      category: (json['category'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fileName: (json['file_name'] ?? '').toString(),
      fileType: (json['file_type'] ?? '').toString(),
      filePath: (json['file_path'] ?? '').toString(),
      instructorName: (json['instructor_name'] ?? '').toString(),
      createdAt: DateTime.tryParse(createdAtRaw),
    );
  }
}
