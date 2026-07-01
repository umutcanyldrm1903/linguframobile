import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _languageKey = 'language_code';
  static const _currencyKey = 'currency_code';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

  static Future<void> setToken(String token) {
    return _write(_tokenKey, token);
  }

  static Future<String?> getToken() {
    return _read(_tokenKey);
  }

  static Future<void> clearToken() async {
    await _delete(_tokenKey);
  }

  static Future<void> setRole(String role) {
    return _write(_roleKey, role);
  }

  static Future<String?> getRole() {
    return _read(_roleKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll(
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await _storage.deleteAll();
  }

  static Future<void> setUserId(String id) {
    return _write(_userIdKey, id);
  }

  static Future<String?> getUserId() {
    return _read(_userIdKey);
  }

  static Future<void> setUserName(String name) {
    return _write(_userNameKey, name);
  }

  static Future<String?> getUserName() {
    return _read(_userNameKey);
  }

  static Future<void> setLanguageCode(String code) {
    return _write(_languageKey, code);
  }

  static Future<String?> getLanguageCode() {
    return _read(_languageKey);
  }

  static Future<void> setCurrencyCode(String code) {
    return _write(_currencyKey, code);
  }

  static Future<String?> getCurrencyCode() {
    return _read(_currencyKey);
  }

  static Future<void> setValue(String key, String value) {
    return _write(key, value);
  }

  static Future<String?> getValue(String key) {
    return _read(key);
  }

  static Future<void> deleteValue(String key) async {
    await _delete(key);
  }

  static Future<void> _write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static Future<String?> _read(String key) async {
    final hardened = await _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    if (hardened != null && hardened.isNotEmpty) return hardened;

    // Backward compatibility for tokens written before platform options existed.
    return _storage.read(key: key);
  }

  static Future<void> _delete(String key) async {
    await _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await _storage.delete(key: key);
  }
}
