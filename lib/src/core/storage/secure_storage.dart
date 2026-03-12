import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _languageKey = 'language_code';
  static const _currencyKey = 'currency_code';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

  static Future<void> setToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }

  static Future<void> setRole(String role) {
    return _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() {
    return _storage.read(key: _roleKey);
  }

  static Future<void> clearAll() {
    return _storage.deleteAll();
  }

  static Future<void> setUserId(String id) {
    return _storage.write(key: _userIdKey, value: id);
  }

  static Future<String?> getUserId() {
    return _storage.read(key: _userIdKey);
  }

  static Future<void> setUserName(String name) {
    return _storage.write(key: _userNameKey, value: name);
  }

  static Future<String?> getUserName() {
    return _storage.read(key: _userNameKey);
  }

  static Future<void> setLanguageCode(String code) {
    return _storage.write(key: _languageKey, value: code);
  }

  static Future<String?> getLanguageCode() {
    return _storage.read(key: _languageKey);
  }

  static Future<void> setCurrencyCode(String code) {
    return _storage.write(key: _currencyKey, value: code);
  }

  static Future<String?> getCurrencyCode() {
    return _storage.read(key: _currencyKey);
  }
}
