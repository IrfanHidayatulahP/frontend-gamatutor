import 'package:flutter/foundation.dart';

class ApiConstants {
  static String getApiBaseUrl(String path) {
    // Jika dijalankan di Web / Chrome / Desktop / iOS Simulator
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://localhost:3000/api$path';
    }
    // Khusus Android Emulator
    return 'http://localhost:3000/api$path';
  }
}
