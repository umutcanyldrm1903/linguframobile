import '../../core/network/api_client.dart';

class ZoomRepository {
  Future<String?> fetchSdkJwt() async {
    final response = await ApiClient.dio.get('/zoom/sdk-jwt');
    final data = response.data;

    if (data is Map && data['data'] is Map) {
      final jwt = (data['data']['jwt'] ?? '').toString().trim();
      return jwt.isEmpty ? null : jwt;
    }
    return null;
  }
}

