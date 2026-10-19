import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userJson,
  }) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    await _storage.write(key: 'userJson', value: userJson);
  }

  static Future<String?> getToken() async => await _storage.read(key: 'token');
  static Future<String?> getRefreshToken() async =>
      await _storage.read(key: 'refreshToken');
  static Future<String?> getUserJson() async =>
      await _storage.read(key: 'userJson');

  static Future<void> clearSession() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'userJson');
  }

  static Future<String?> getFocusStartTime() async {
    return await _storage.read(key: 'focusStartTime');
  }

  static Future<void> saveFocusStartTime(String startTime) async {
    await _storage.write(key: 'focusStartTime', value: startTime);
  }

  static Future<void> clearFocusStartTime() async {
    await _storage.delete(key: 'focusStartTime');
  }
}
