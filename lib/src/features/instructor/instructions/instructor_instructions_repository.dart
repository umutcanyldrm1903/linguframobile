import '../../../core/localization/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class InstructorInstructionsRepository {
  Future<InstructorInstructionsPayload?> fetchInstructions() async {
    final response = await ApiClient.dio.get(
      '/instructor/instructions',
      queryParameters: {'language': AppStrings.code},
    );
    return InstructorInstructionsPayload.fromJson(
      ApiResponseParser.requireMap(
        response.data,
        context: '/instructor/instructions',
      ),
    );
  }
}

class InstructorInstructionsPayload {
  const InstructorInstructionsPayload({
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final List<InstructorInstructionSection> sections;

  factory InstructorInstructionsPayload.fromJson(Map<String, dynamic> json) {
    return InstructorInstructionsPayload(
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      sections: _parseSections(json['sections']),
    );
  }

  static List<InstructorInstructionSection> _parseSections(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(InstructorInstructionSection.fromJson)
        .toList(growable: false);
  }
}

class InstructorInstructionSection {
  const InstructorInstructionSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  factory InstructorInstructionSection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return InstructorInstructionSection(
      title: (json['title'] ?? '').toString(),
      items: rawItems is List
          ? rawItems.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
}
