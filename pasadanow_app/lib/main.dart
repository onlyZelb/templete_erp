import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/landing_screen.dart';
import 'screens/commuter/commuter_home.dart';
import 'screens/driver/driver_home.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PasadaNowApp());
}

class PasadaNowApp extends StatelessWidget {
  const PasadaNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'PasadaNow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3D7FD4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.isLoggedIn();
    if (mounted) {
      setState(() {
        _checking = false;
        _loggedIn = loggedIn;
      });
    }
  }

  /// Normalises any role format Spring Boot might return:
  /// "DRIVER" / "ROLE_DRIVER" / "driver" / "Driver"  →  "driver"
  /// "COMMUTER" / "ROLE_COMMUTER" / "commuter"        →  "commuter"
  /// "ADMIN"   / "ROLE_ADMIN"    / "admin"            →  "admin"
  String _normalizeRole(String? raw) {
    if (raw == null || raw.isEmpty) return 'commuter';
    final lower = raw.toLowerCase(); // "role_driver" / "driver" / etc.
    if (lower.contains('driver')) return 'driver';
    if (lower.contains('admin'))  return 'admin';
    return 'commuter';
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D8CFF)),
        ),
      );
    }

    if (!_loggedIn) return const LandingScreen();

    final auth = context.watch<AuthProvider>();
    final role = _normalizeRole(auth.role);

    // Remove this line once confirmed working:
    debugPrint('DEBUG normalised role: "$role"  (raw: "${auth.role}")');

    switch (role) {
      case 'driver':
        return const DriverHome();
      case 'admin':
        return const CommuterHome(); // swap for AdminHome() when ready
      case 'commuter':
      default:
        return const CommuterHome();
    }
  }
}