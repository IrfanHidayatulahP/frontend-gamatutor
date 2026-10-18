import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/model/user.dart';
import 'package:gamatutor_kanban/service/localtokenService.dart';
import 'app_config.dart';

class LoginService {
  String get baseUrl => ApiConstants.getApiBaseUrl('/auth');

  Future<User?> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/login');
      debugPrint('Mencoba login ke URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        Map<String, dynamic> userData;
        String? token;
        String? refreshToken;

        if (data is Map<String, dynamic> && data.containsKey('user')) {
          userData = Map<String, dynamic>.from(data['user']);
          token = data['token'] ?? data['accessToken'] ?? data['access_token'];
          refreshToken = data['refreshToken'] ?? data['refresh_token'];
        } else {
          userData = Map<String, dynamic>.from(data);
          token = userData['token'] ?? userData['accessToken'] ?? userData['access_token'];
          refreshToken = userData['refreshToken'] ?? userData['refresh_token'];
        }

        if (token != null) userData['token'] = token;
        if (refreshToken != null) userData['refreshToken'] = refreshToken;

        final user = User.fromJson(userData);

        await LocalTokenStorage.saveSession(
          token: user.token ?? '',
          refreshToken: user.refreshToken ?? '',
          userJson: jsonEncode(user.toJson()),
        );

        return user;
      } else {
        debugPrint('Login gagal dengan status HTTP: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('Network SocketException: $e');
      throw Exception(
        'Gagal terhubung ke server ($baseUrl). '
        'Pastikan backend berjalan di PC & izin koneksi internet diizinkan.',
      );
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<User?> tryAutoLogin() async {
    final token = await LocalTokenStorage.getToken();
    final userJsonStr = await LocalTokenStorage.getUserJson();

    if (token == null || userJsonStr == null) return null;

    try {
      final userData = jsonDecode(userJsonStr);
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  Future<User?> refreshAuthToken(String currentToken) async {
    try {
      final url = Uri.parse('$baseUrl/refresh');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final newToken = data['token'] as String?;

        if (newToken != null) {
          user.token = newToken;
        }

        await LocalTokenStorage.saveSession(
          token: user.token ?? currentToken,
          refreshToken: user.refreshToken ?? '',
          userJson: jsonEncode(user.toJson()),
        );

        return user;
      } else {
        await LocalTokenStorage.clearSession();
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await LocalTokenStorage.clearSession();
  }
}