import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class InstructorScheduleRepository {
  Future<List<InstructorAvailability>> fetchAvailabilities() async {
    final response = await ApiClient.dio.get('/instructor/availabilities');
    return ApiResponseParser.requireList(
      response.data,
      context: '/instructor/availabilities',
    ).map(InstructorAvailability.fromJson).toList(growable: false);
  }

  Future<int?> createAvailability({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await ApiClient.dio.post(
      '/instructor/availabilities',
      data: {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': true,
      },
    );
    final data = ApiResponseParser.requireMap(
      response.data,
      context: '/instructor/availabilities',
    );
    return data['id'] is int ? data['id'] as int : int.tryParse('${data['id']}');
  }

  Future<void> deleteAvailability(int id) async {
    await ApiClient.dio.delete('/instructor/availabilities/$id');
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
