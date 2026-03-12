import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';

class StudentGuideRepository {
  Future<StudentGuidePayload?> fetchGuide() async {
    try {
      final response = await ApiClient.dio.get(
        '/guide',
        queryParameters: {'language': AppStrings.code},
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return StudentGuidePayload.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (_) {}
    return null;
  }
}

class StudentGuidePayload {
  const StudentGuidePayload({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<StudentGuideItem> items;

  factory StudentGuidePayload.fromJson(Map<String, dynamic> json) {
    return StudentGuidePayload(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      items: _parseItems(json['items']),
    );
  }

  static List<StudentGuideItem> _parseItems(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(StudentGuideItem.fromJson)
        .toList(growable: false);
  }
}

class StudentGuideItem {
  const StudentGuideItem({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  bool get hasUrl => url.trim().isNotEmpty;

  factory StudentGuideItem.fromJson(Map<String, dynamic> json) {
    return StudentGuideItem(
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
    );
  }
}
