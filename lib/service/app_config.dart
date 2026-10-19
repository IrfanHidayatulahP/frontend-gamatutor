import 'package:flutter/foundation.dart';

class ApiConstants {
  static String  getApiBaseUrl(String path){
    // Jika dijalankan di Web / Chrome / Desktop / iOS Simulator
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://localhost:3000/api$path';
    }
    return "http://192.168.1.53:3000/api$path";
  }
}
