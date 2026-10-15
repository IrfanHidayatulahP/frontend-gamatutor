import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/model/card.dart' as model;
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/model/columnmovement.dart';

String getApiBaseUrl(String path) {
  // Jika dijalankan di Web / Chrome / Desktop / iOS Simulator
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return 'http://localhost:3000/api$path';
  }
  // Khusus Android Emulator
  return 'http://localhost:3000/api$path';
}
class CardService {
  String get baseUrl => getApiBaseUrl('');

  Future<List<model.Card>> getCardsByUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        List<model.Card> cards = body.map((dynamic item) => model.Card.fromJson(item)).toList();
        return cards;
      } else {
        debugPrint('Gagal mengambil cards: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('CardService Error: $e');
      return [];
    }
  }

  // Mengambil CardList berdasarkan cardId
  Future<CardList?> getCardList(String token, String cardId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards/$cardId/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return CardList.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mengambil Column Movements berdasarkan cardId
  Future<List<ColumnMovement>> getColumnMovements(String token, String cardId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/column-movements/card/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => ColumnMovement.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}