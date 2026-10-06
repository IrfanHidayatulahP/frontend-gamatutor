class LocalTokenStorage {
  static String? _storedToken;
  static String? _storedRefreshToken;
  static String? _storedUserJson;

  static Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String userJson,
  }) async {
    _storedToken = token;
    _storedRefreshToken = refreshToken;
    _storedUserJson = userJson;
  }

  static Future<String?> getToken() async => _storedToken;
  static Future<String?> getRefreshToken() async => _storedRefreshToken;
  static Future<String?> getUserJson() async => _storedUserJson;

  static Future<void> clearSession() async {
    _storedToken = null;
    _storedRefreshToken = null;
    _storedUserJson = null;
  }
}