import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authTokenProvider = StateProvider<String?>((ref) => null);

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier(this._read) : super(false);

  final Ref _read;

  Future<String> login(String email, String password) async {
    state = true;
    try {
      final repo = _read.read(authRepositoryProvider);
      final data = await repo.login(email: email, password: password);
      return _persistSession(data, repo: repo);
    } catch (error) {
      throw AuthFailure(_extractMessage(error));
    } finally {
      state = false;
    }
  }

  Future<String> register({
    required String name,
    required String email,
    String? phone,
    required String role,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = true;
    try {
      final repo = _read.read(authRepositoryProvider);
      final registerData = await repo.register(
        name: name,
        email: email,
        phone: phone,
        role: role,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      if ((registerData['bearer_token']?.toString().trim() ?? '').isNotEmpty) {
        return _persistSession(registerData, repo: repo);
      }
      final loginData = await repo.login(email: email, password: password);
      return _persistSession(loginData, repo: repo);
    } catch (error) {
      throw AuthFailure(_extractMessage(error));
    } finally {
      state = false;
    }
  }

  Future<String> _persistSession(
    Map<String, dynamic> data, {
    required AuthRepository repo,
  }) async {
    final token = data['bearer_token']?.toString().trim() ?? '';
    if (token.isEmpty) {
      throw const AuthFailure('Something went wrong');
    }

    final userId = data['user_id']?.toString().trim() ?? '';
    final payload = data['data'];

    final payloadName = payload is Map<String, dynamic>
        ? payload['name']?.toString().trim() ?? ''
        : '';
    final payloadRole = payload is Map<String, dynamic>
        ? payload['role']?.toString().trim() ?? ''
        : '';

    await SecureStorage.setToken(token);
    _read.read(authTokenProvider.notifier).state = token;

    if (userId.isNotEmpty) {
      await SecureStorage.setUserId(userId);
    }
    if (payloadName.isNotEmpty) {
      await SecureStorage.setUserName(payloadName);
    }
    if (payloadRole.isNotEmpty) {
      await SecureStorage.setRole(payloadRole);
      return payloadRole;
    }

    final profile = await repo.profile();
    final profileData = profile['data'];
    if (profileData is Map<String, dynamic>) {
      final name = profileData['name']?.toString().trim() ?? '';
      final role = profileData['role']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        await SecureStorage.setUserName(name);
      }
      if (role.isNotEmpty) {
        await SecureStorage.setRole(role);
        return role;
      }
    }

    return 'student';
  }

  String _extractMessage(Object error) {
    if (error is AuthFailure) {
      return error.message;
    }
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        if (message is Map) {
          for (final value in message.values) {
            if (value is List && value.isNotEmpty) {
              final first = value.first?.toString().trim() ?? '';
              if (first.isNotEmpty) return first;
            }
            final single = value?.toString().trim() ?? '';
            if (single.isNotEmpty) return single;
          }
        }

        final errors = data['errors'];
        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              final first = value.first?.toString().trim() ?? '';
              if (first.isNotEmpty) return first;
            }
            final single = value?.toString().trim() ?? '';
            if (single.isNotEmpty) return single;
          }
        }
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }

    return 'Something went wrong';
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref);
});
