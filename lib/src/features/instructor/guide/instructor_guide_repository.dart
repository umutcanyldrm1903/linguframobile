import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';

class InstructorGuideRepository {
  Future<InstructorGuidePayload?> fetchGuide() async {
    try {
      final response = await ApiClient.dio.get(
        '/instructor/guide',
        queryParameters: {'language': AppStrings.code},
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return InstructorGuidePayload.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (_) {}

    return null;
  }
}

class InstructorGuidePayload {
  const InstructorGuidePayload({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<InstructorGuideSection> sections;

  factory InstructorGuidePayload.fromJson(Map<String, dynamic> json) {
    return InstructorGuidePayload(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      sections: _parseSections(json['sections']),
    );
  }

  static List<InstructorGuideSection> _parseSections(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorGuideSection.fromJson)
        .toList(growable: false);
  }
}

class InstructorGuideSection {
  const InstructorGuideSection({
    required this.title,
    required this.type,
    required this.items,
  });

  final String title;
  final String type;
  final List<String> items;

  bool get isOrdered => type == 'ordered';

  factory InstructorGuideSection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return InstructorGuideSection(
      title: (json['title'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      items: rawItems is List
          ? rawItems.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
}
