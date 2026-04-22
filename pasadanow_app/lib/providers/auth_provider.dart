import 'package:flutter/material.dart';
import '../core/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? role;
  String? verifiedStatus;
  String? username;
  bool    isLoading = false;
  String? error;

  Future<void> login(String u, String p) async {
    isLoading = true;
    error     = null;
    notifyListeners();
    try {
      final data    = await _authService.login(u, p);
      role           = data['role'];
      verifiedStatus = data['verifiedStatus'];
      username       = data['username'];
    } catch (e) {
      error = 'Invalid username or password';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    role = verifiedStatus = username = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    final token = await _authService.getToken();
    if (token != null) {
      role           = await _authService.getRole();
      verifiedStatus = await _authService.getVerifiedStatus();
      username       = await _authService.getUsername();
      return true;
    }
    return false;
  }
}