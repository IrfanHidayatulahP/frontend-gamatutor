import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/model/card.dart';

class CardService {
  final String baseUrl = 'http://10.0.2.2:3000/api';

  Future<List<Card>> getCardsByUser(String token) async {
   try {
      final url = Uri.parse(baseUrl);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Card.fromJson(json)).toList();
      } else {
        debugPrint('Gagal mengambil data card dari database: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error pada CardService: $e');
      return [];
    }
  }
}