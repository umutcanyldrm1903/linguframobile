import '../../core/network/api_client.dart';

class AuthRepository {
  Future<Map<String, dynamic>> forgetPassword({
    required String email,
  }) async {
    final response = await ApiClient.dio.post('/forget-password', data: {
      'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.dio.post('/reset-password', data: {
      'forget_password_token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.dio.post('/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> profile() async {
    final response = await ApiClient.dio.get('/profile');
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await ApiClient.dio.post('/logout');
  }
}
