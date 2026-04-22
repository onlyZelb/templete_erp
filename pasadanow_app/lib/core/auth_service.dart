import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  final _dio = Dio(BaseOptions(baseUrl: ApiConstants.springBase));

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    final token = res.data['token'];
    final role  = res.data['role'];
    final status = res.data['verifiedStatus'];

    await _storage.write(key: 'jwt_token',       value: token);
    await _storage.write(key: 'user_role',        value: role);
    await _storage.write(key: 'verified_status',  value: status);
    await _storage.write(key: 'username',         value: res.data['username']);

    return res.data;
  }

  Future<void> register(Map<String, dynamic> data) async {
    await _dio.post('/api/auth/register', data: data);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getRole()           => _storage.read(key: 'user_role');
  Future<String?> getToken()          => _storage.read(key: 'jwt_token');
  Future<String?> getVerifiedStatus() => _storage.read(key: 'verified_status');
  Future<String?> getUsername()       => _storage.read(key: 'username');
}