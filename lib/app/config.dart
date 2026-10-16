import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the OHS backend runs. Stored on the device and changeable from the sign-in screen, so the same build works
/// against a laptop during development and the agency's server in production.
class ServerConfig {
  static const _key = 'server_url';

  /// Build-time override: flutter run --dart-define=OHS_API_URL=https://ohs.example.gov/api
  static const _fromBuild = String.fromEnvironment('OHS_API_URL');

  static String get defaultUrl {
    if (_fromBuild.isNotEmpty) return _fromBuild;
    // The Android emulator reaches the host computer at 10.0.2.2; everything else uses localhost.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultUrl;
  }

  static Future<void> save(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url.trim());
  }
}
