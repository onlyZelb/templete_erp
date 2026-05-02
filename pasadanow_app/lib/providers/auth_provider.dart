import 'package:flutter/material.dart';
import '../core/auth_service.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  String? role;
  String? verifiedStatus;
  String? username;
  bool    isLoading = false;
  String? error;

  // ── JWT decoder (no external package needed) ─────────────────────────────
  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64url → Base64 padding fix
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 2: normalized += '=='; break;
        case 3: normalized += '=';  break;
      }

      final decoded = utf8.decode(base64Decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? _extractRoleFromToken(String token) {
    final payload = _decodeJwt(token);
    if (payload == null) return null;

    // Spring Boot commonly stores role as 'role', 'roles', or 'authorities'
    return payload['role'] as String?
        ?? (payload['roles'] as List?)?.first as String?
        ?? payload['authorities'] as String?;
  }

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
      error = e.message;
    } catch (_) {
      error = 'Invalid username or password.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Clear error ──────────────────────────────────────────────────────────
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
  Future<bool> isLoggedIn() async {
    final token = await _authService.getToken();

    debugPrint('DEBUG isLoggedIn => token: $token');

    if (token == null || token.isEmpty) return false;

    // 1️⃣ Try reading role from secure storage first
    String? storedRole = await _authService.getRole();

    // 2️⃣ If storage failed (common on web), fall back to JWT payload
    if (storedRole == null || storedRole.isEmpty) {
      storedRole = _extractRoleFromToken(token);
      debugPrint('DEBUG role from JWT payload: $storedRole');
    }

    if (storedRole == null || storedRole.isEmpty) {
      debugPrint('DEBUG could not determine role — logging out');
      await logout();
      return false;
    }

    role           = storedRole;
    verifiedStatus = await _authService.getVerifiedStatus();
    username       = await _authService.getUsername();

    debugPrint('DEBUG restored session => role: $role | username: $username');

    notifyListeners();
    return true;
  }
}