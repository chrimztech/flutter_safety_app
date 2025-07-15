import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  bool get isAuthenticated => _token != null;

  String? get token => _token;

  Future<void> loadToken() async {
    _token = await StorageService.getToken();
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    await StorageService.saveToken(token);
    _token = token;
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.deleteToken();
    _token = null;
    notifyListeners();
  }
}
