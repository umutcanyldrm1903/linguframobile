import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authTokenProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier(this._read) : super(false);

  final Ref _read;

  Future<void> login(String email, String password) async {
    state = true;
    try {
      final repo = _read.read(authRepositoryProvider);
      final data = await repo.login(email: email, password: password);
      final token = data['bearer_token']?.toString();
      final userId = data['user_id']?.toString();
      if (token != null) {
        await SecureStorage.setToken(token);
        _read.read(authTokenProvider.notifier).state = token;
      }
      if (userId != null && userId.isNotEmpty) {
        await SecureStorage.setUserId(userId);
      }
      final profile = await repo.profile();
      final name = (profile['data']?['name'])?.toString();
      if (name != null && name.trim().isNotEmpty) {
        await SecureStorage.setUserName(name.trim());
      }
      final role = (profile['data']?['role'])?.toString();
      if (role != null && role.isNotEmpty) {
        await SecureStorage.setRole(role);
      }
    } finally {
      state = false;
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier(ref);
});
