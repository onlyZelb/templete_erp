import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // ── Base URLs ─────────────────────────────────────────────────────────────
  // On web (Chrome), 10.0.2.2 is unreachable — use localhost instead.
  // On Android emulator, 10.0.2.2 maps to the host machine's localhost.
  // On a real device, replace with your LAN IP (e.g. 192.168.x.x).

  static String get springBase =>
      kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';

  static String get phpBase =>
      kIsWeb ? 'http://localhost:8081' : 'http://10.0.2.2:8081';

  static String get djangoBase =>
      kIsWeb ? 'http://localhost:8082' : 'http://10.0.2.2:8082';
}
