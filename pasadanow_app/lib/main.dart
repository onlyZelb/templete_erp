import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/pending_screen.dart';
import 'screens/commuter/commuter_home.dart';
import 'screens/driver/driver_home.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const PasadaNowApp(),
    ),
  );
}

class PasadaNowApp extends StatelessWidget {
  const PasadaNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PasadaNow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth    = context.read<AuthProvider>();
    final loggedIn = await auth.isLoggedIn();

    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (auth.verifiedStatus != 'verified') {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const PendingScreen()));
      return;
    }

    if (auth.role == 'ROLE_DRIVER') {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const DriverHome()));
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const CommuterHome()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}