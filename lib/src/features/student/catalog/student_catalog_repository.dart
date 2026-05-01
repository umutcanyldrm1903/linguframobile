import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class StudentCatalogRepository {
  Future<List<CatalogCourseItem>> searchCourses({
    String? search,
    String? mainCategory,
    String? subCategory,
    String? currency,
    int limit = 30,
  }) async {
    final response = await ApiClient.dio.get(
      '/search-courses',
      queryParameters: {
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (mainCategory != null && mainCategory.trim().isNotEmpty)
          'main_category': mainCategory.trim(),
        if (subCategory != null && subCategory.trim().isNotEmpty)
          'sub_category': subCategory.trim(),
        if (currency != null && currency.trim().isNotEmpty)
          'currency': currency.trim(),
        'language': AppStrings.code,
      },
    );

    final list = ApiResponseParser.tryList(response.data) ?? const [];
    return list.map(CatalogCourseItem.fromJson).toList(growable: false);
  }

  Future<void> toggleWishlist(String slug) async {
    if (slug.trim().isEmpty) return;
    await ApiClient.dio.get('/add-remove-wishlist/$slug');
  }

  Future<void> addToCart(String slug) async {
    if (slug.trim().isEmpty) return;
    await ApiClient.dio.post('/add-to-cart/$slug');
  }

  Future<CatalogCourseDetail?> fetchCourseDetail(
    String slug, {
    String? currency,
  }) async {
    if (slug.trim().isEmpty) return null;

    final response = await ApiClient.dio.get(
      '/course/${slug.trim()}',
      queryParameters: {
        'language': AppStrings.code,
        if (currency != null && currency.trim().isNotEmpty)
          'currency': currency.trim(),
      },
    );

    final data = ApiResponseParser.tryMap(response.data);
    return data == null ? null : CatalogCourseDetail.fromJson(data);
  }
}

class CatalogCourseItem {
  const CatalogCourseItem({
    required this.slug,
    required this.title,
    required this.thumbnail,
    required this.priceLabel,
    required this.discountLabel,
    required this.instructorName,
    required this.rating,
    required this.students,
  });

  final String slug;
  final String title;
  final String thumbnail;
  final String priceLabel;
  final String discountLabel;
  final String instructorName;
  final double rating;
  final int students;

  factory CatalogCourseItem.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    return CatalogCourseItem(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      priceLabel: (json['price'] ?? '').toString(),
      discountLabel: (json['discount'] ?? '').toString(),
      instructorName:
          instructor is Map ? (instructor['name'] ?? '').toString() : '',
      rating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
      students: json['students'] is int
          ? json['students'] as int
          : int.tryParse('${json['students'] ?? 0}') ?? 0,
    );
  }
}

class CatalogCourseDetail {
  const CatalogCourseDetail({
    required this.slug,
    required this.title,
    required this.thumbnail,
    required this.priceLabel,
    required this.discountLabel,
    required this.instructorName,
    required this.rating,
    required this.reviewsCount,
    required this.students,
    required this.description,
    required this.curriculums,
  });

  final String slug;
  final String title;
  final String thumbnail;
  final String priceLabel;
  final String discountLabel;
  final String instructorName;
  final double rating;
  final int reviewsCount;
  final int students;
  final String description;
  final List<CatalogCurriculum> curriculums;

  factory CatalogCourseDetail.fromJson(Map<String, dynamic> json) {
    final instructor = json['instructor'];
    final curriculumsRaw = json['curriculums'];

    return CatalogCourseDetail(
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      priceLabel: (json['price'] ?? '').toString(),
      discountLabel: (json['discount'] ?? '').toString(),
      instructorName:
          instructor is Map ? (instructor['name'] ?? '').toString() : '',
      rating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
      reviewsCount: json['reviews_count'] is int
          ? json['reviews_count'] as int
          : int.tryParse('${json['reviews_count'] ?? 0}') ?? 0,
      students: json['students'] is int
          ? json['students'] as int
          : int.tryParse('${json['students'] ?? 0}') ?? 0,
      description: (json['description'] ?? '').toString(),
      curriculums: _parseCurriculums(curriculumsRaw),
    );
  }

  static List<CatalogCurriculum> _parseCurriculums(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            CatalogCurriculum.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

class CatalogCurriculum {
  const CatalogCurriculum({required this.title, required this.items});

  final String title;
  final List<CatalogCurriculumItem> items;

  factory CatalogCurriculum.fromJson(Map<String, dynamic> json) {
    final chapters = json['chapters'];
    return CatalogCurriculum(
      title: (json['title'] ?? '').toString(),
      items: _parseItems(chapters),
    );
  }

  static List<CatalogCurriculumItem> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) =>
            CatalogCurriculumItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}

class CatalogCurriculumItem {
  const CatalogCurriculumItem({
    required this.type,
    required this.title,
    required this.duration,
    required this.isFree,
  });

  final String type;
  final String title;
  final String duration;
  final bool isFree;

  factory CatalogCurriculumItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    final itemMap = item is Map
        ? Map<String, dynamic>.from(item)
        : const <String, dynamic>{};
    return CatalogCurriculumItem(
      type: (json['type'] ?? '').toString(),
      title: (itemMap['title'] ?? '').toString(),
      duration: (itemMap['duration'] ?? '').toString(),
      isFree: itemMap['is_free'] == true,
    );
  }
}
