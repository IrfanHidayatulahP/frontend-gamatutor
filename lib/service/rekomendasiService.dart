// lib/services/user_quiz_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/service/app_config.dart';

class rekomendasiService {
  // Mengambil baseUrl dari ApiConstants yang sudah dinamis (support web, emulator, dll)
  static String get baseUrl => ApiConstants.getApiBaseUrl('');

  // Mengambil unlocked features berdasarkan userId
  static Future<List<String>> getUnlockedFeatures(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-quiz-results/latest/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5), // Proteksi agar tidak infinite waiting/gantung
        onTimeout: () => throw Exception('Koneksi timeout ke server.'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quizResult = data['quizResult'];
        
        // Ambil data unlocked_features dari JSONB (biasanya berupa List<dynamic>)
        final List<dynamic> unlockedJson = quizResult['unlocked_features'] ?? [];
        return unlockedJson.map((e) => e.toString()).toList();
      }
      
      // Jika status code bukan 200 (misal 404 belum ada kuis), kembalikan list kosong
      return [];
    } catch (e) {
      print("Error fetching unlocked features: $e");
      return []; // Return kosong agar aman dan langsung mendisable semua chip
    }
  }
}