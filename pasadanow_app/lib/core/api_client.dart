import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // ✅ FIX: Added WebOptions so flutter_secure_storage works on Chrome
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'pasadanow',
      publicKey: 'pasadanow_key',
    ),
  );

  static Dio build(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // ✅ FIX: Wrapped storage read in try/catch — prevents
        // "Cannot send Null" crash on Chrome when storage throws
        try {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Cookie'] = 'jwt=$token';
          }
        } catch (_) {
          // Storage unavailable (e.g. first run on web) — proceed without token
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));

    return dio;
  }
}
