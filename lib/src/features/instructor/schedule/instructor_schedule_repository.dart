import '../../../core/network/api_client.dart';

class InstructorScheduleRepository {
  Future<List<InstructorAvailability>> fetchAvailabilities() async {
    try {
      final response = await ApiClient.dio.get('/instructor/availabilities');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(InstructorAvailability.fromJson)
            .toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  Future<int?> createAvailability({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await ApiClient.dio.post('/instructor/availabilities', data: {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': true,
      });
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        final inner = Map<String, dynamic>.from(data['data'] as Map);
        return inner['id'] is int ? inner['id'] as int : int.tryParse('${inner['id']}');
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteAvailability(int id) async {
    try {
      await ApiClient.dio.delete('/instructor/availabilities/$id');
      return true;
    } catch (_) {
      return false;
    }
  }
}

class InstructorAvailability {
  const InstructorAvailability({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final int id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  String get key => '$dayOfWeek|$startTime|$endTime';

  factory InstructorAvailability.fromJson(Map<String, dynamic> json) {
    return InstructorAvailability(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      dayOfWeek: json['day_of_week'] is int
          ? json['day_of_week'] as int
          : int.tryParse('${json['day_of_week']}') ?? 0,
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      isActive: json['is_active'] == true,
    );
  }
}
