import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';

class StudentLibraryRepository {
  Future<LibraryPayload?> fetchLibrary() async {
    final responses = await Future.wait([
      ApiClient.dio.get(
        '/course-main-categories',
        queryParameters: {'language': AppStrings.code},
      ),
      ApiClient.dio.get('/popular-courses'),
    ]);

    final categoriesData = _extractList(responses[0].data);
    final coursesData = _extractList(responses[1].data);

    return LibraryPayload(
      categories:
          categoriesData.whereType<Map<String, dynamic>>().map(LibraryCategory.fromJson).toList(),
      popularCourses:
          coursesData.whereType<Map<String, dynamic>>().map(LibraryCourse.fromJson).toList(),
    );
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is Map<String, dynamic>) {
      final list = data['data'] ?? data['items'] ?? data['results'];
      return list is List ? list : [];
    }
    if (data is List) return data;
    return [];
  }
}

class LibraryPayload {
  const LibraryPayload({
    required this.categories,
    required this.popularCourses,
  });

  final List<LibraryCategory> categories;
  final List<LibraryCourse> popularCourses;
}

class LibraryCategory {
  const LibraryCategory({
    required this.slug,
    required this.name,
    required this.icon,
  });

  final String slug;
  final String name;
  final String icon;

  factory LibraryCategory.fromJson(Map<String, dynamic> json) {
    return LibraryCategory(
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
    );
  }
}

class LibraryCourse {
  const LibraryCourse({
    required this.slug,
    required this.title,
    required this.thumbnail,
    required this.instructorName,
    required this.rating,
  });

  final String slug;
  final String title;
  final String thumbnail;
  final String instructorName;
  final double rating;

  factory LibraryCourse.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    return LibraryCourse(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      instructorName: instructor is Map
          ? (instructor['name'] ?? '').toString()
          : '',
      rating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : 0,
    );
  }
}
