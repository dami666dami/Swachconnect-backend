import 'package:flutter/foundation.dart';

class AppConfig {
  /* ================= BACKEND ================= */

  /// Base URL for backend API
  static String get backendBase {
    return "http://10.77.175.169:4000";
  }

  static const String tokenKey = "token";

  static const String nameKey = "name";

  /* ================= API HELPERS ================= */


  static Map<String, String> jsonHeaders({String? token}) {
    final headers = {
      "Content-Type": "application/json",
    };

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  static Map<String, String> multipartHeaders({String? token}) {
    final headers = <String, String>{};

    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }


  static const int apiTimeoutSeconds = 20;
}
