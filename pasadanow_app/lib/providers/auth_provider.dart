import 'package:flutter/material.dart';
import '../core/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? role;
  String? verifiedStatus;
  String? username;
  bool    isLoading = false;
  String? error;

  // ── Login ────────────────────────────────────────────────────────────────
  Future<void> login(String u, String p) async {
    isLoading = true;
    error     = null;
    notifyListeners();

    try {
      final data     = await _authService.login(u, p);
      role           = data['role']           as String?;
      verifiedStatus = data['verifiedStatus'] as String?;
      username       = data['username']       as String?;
    } on AuthException catch (e) {
      // Surface the server's own message verbatim so LoginScreen can show it.
      error = e.message;
    } catch (_) {
      error = 'Invalid username or password.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Clear error ──────────────────────────────────────────────────────────
  /// Call from a widget to dismiss a stale error banner without a full login.
  void clearError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    role = verifiedStatus = username = error = null;
    notifyListeners();
  }

  // ── Session restore ──────────────────────────────────────────────────────
  /// Called by the splash screen. Restores state from secure storage so the
  /// router can redirect correctly without a server round-trip.
  Future<bool> isLoggedIn() async {
    final token = await _authService.getToken();
    if (token == null) return false;

    role           = await _authService.getRole();
    verifiedStatus = await _authService.getVerifiedStatus();
    username       = await _authService.getUsername();
    return true;
  }
}