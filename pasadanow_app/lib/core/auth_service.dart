import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

// ── Custom exception ───────────────────────────────────────────────────────
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

// ── AuthService ────────────────────────────────────────────────────────────
class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.springBase,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'pasadanow',
      publicKey: 'pasadanow_key',
    ),
  );

  static const _keyToken = 'auth_token';
  static const _keyRole = 'auth_role';
  static const _keyVerifiedStatus = 'auth_verified_status';
  static const _keyUsername = 'auth_username';

  // ── Login ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      final role = data['role'] as String?;
      final verifiedStatus = data['verifiedStatus'] as String?;
      final returnedUser = data['username'] as String?;

      if (token == null || role == null) {
        throw const AuthException('Unexpected response from server.');
      }

      try {
        await _storage.write(key: _keyToken, value: token);
        await _storage.write(key: _keyRole, value: role);
        await _storage.write(
            key: _keyVerifiedStatus, value: verifiedStatus ?? '');
        await _storage.write(
            key: _keyUsername, value: returnedUser ?? username);
      } catch (_) {
        // Storage write failed on web — continue anyway
      }

      return {
        'token': token,
        'role': role,
        'verifiedStatus': verifiedStatus,
        'username': returnedUser ?? username,
      };
    } on DioException catch (e) {
      _handleDioError(e, fallback: 'Login failed. Please try again.');
      rethrow;
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────
  Future<void> register(Map<String, dynamic> data) async {
    final body = <String, dynamic>{
      'username': data['username'] ?? '',
      'password': data['password'] ?? '',
      'fullName': data['fullName'] ?? '',
      'age': data['age'] ?? '', // ✅ FIXED: was missing
      'phone': data['phone'] ?? '',
      'email': data['email'] ?? '',
      'address': data['address'] ?? '', // ✅ FIXED: was missing
      'role': data['role'] ?? '',
      if (data['profilePhoto'] != null) 'profilePhoto': data['profilePhoto'],
      if (data['role'] == 'driver') ...{
        'licenseNo': data['licenseNo'] ?? '',
        'plateNo': data['plateNo'] ?? '',
        'todaNo': data['todaNo'] ?? '',
        if (data['photoLicense'] != null) 'photoLicense': data['photoLicense'],
        if (data['photoPlate'] != null) 'photoPlate': data['photoPlate'],
        if (data['photoToda'] != null) 'photoToda': data['photoToda'],
      },
    };

    try {
      await _dio.post('/api/auth/register', data: body);
    } on DioException catch (e) {
      _handleDioError(e, fallback: 'Registration failed. Please try again.');
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      try {
        await _storage.deleteAll();
      } catch (_) {
        // Ignore storage errors on web
      }
    }
  }

  // ── Secure storage readers ────────────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRole() async {
    try {
      return await _storage.read(key: _keyRole);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getVerifiedStatus() async {
    try {
      return await _storage.read(key: _keyVerifiedStatus);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _keyUsername);
    } catch (_) {
      return null;
    }
  }

  // ── Shared error handler ──────────────────────────────────────────────────
  Never _handleDioError(DioException e, {required String fallback}) {
    final serverMsg = e.response?.data is Map
        ? (e.response!.data as Map)['message'] as String?
        : null;

    if (e.response?.statusCode == 401) {
      throw AuthException(serverMsg ?? 'Wrong password.');
    } else if (e.response?.statusCode == 404) {
      throw AuthException(serverMsg ?? 'Account not found.');
    } else if (e.response?.statusCode == 409 || e.response?.statusCode == 400) {
      throw AuthException(serverMsg ?? 'Username already taken.');
    } else if (e.response?.statusCode == 422) {
      throw AuthException(serverMsg ?? 'Please fill in all required fields.');
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const AuthException('Connection timed out. Check your internet.');
    } else {
      throw AuthException(serverMsg ?? fallback);
    }
  }
}
