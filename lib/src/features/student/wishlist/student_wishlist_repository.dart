import '../../../core/network/api_client.dart';

class StudentWishlistRepository {
  Future<List<CourseListItem>> fetchWishlist({int limit = 30}) async {
    final response = await ApiClient.dio.get(
      '/wishlist-courses',
      queryParameters: {'limit': limit},
    );
    final list = _extractList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map(CourseListItem.fromJson)
        .toList(growable: false);
  }

  Future<void> toggleWishlist(String slug) async {
    if (slug.trim().isEmpty) return;
    await ApiClient.dio.get('/add-remove-wishlist/$slug');
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['data'] is List) return inner['data'] as List;
    }
    if (data is List) return data;
    return const [];
  }
}

class CourseListItem {
  const CourseListItem({
    required this.slug,
    required this.title,
    required this.thumbnail,
    required this.priceLabel,
    required this.discountLabel,
    required this.instructorName,
    required this.instructorImage,
    required this.rating,
    required this.students,
  });

  final String slug;
  final String title;
  final String thumbnail;
  final String priceLabel;
  final String discountLabel;
  final String instructorName;
  final String instructorImage;
  final double rating;
  final int students;

  factory CourseListItem.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    return CourseListItem(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      priceLabel: (json['price'] ?? '').toString(),
      discountLabel: (json['discount'] ?? '').toString(),
      instructorName:
          instructor is Map ? (instructor['name'] ?? '').toString() : '',
      instructorImage:
          instructor is Map ? (instructor['image'] ?? '').toString() : '',
      rating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
      students: json['students'] is int
          ? json['students'] as int
          : int.tryParse('${json['students'] ?? 0}') ?? 0,
    );
  }
}

