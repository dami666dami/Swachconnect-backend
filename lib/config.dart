import 'package:flutter/foundation.dart';

class AppConfig {

  static String get backendBase {
    return "https://swachconnect-backend.onrender.com";
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
