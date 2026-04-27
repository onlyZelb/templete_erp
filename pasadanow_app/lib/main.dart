// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/landing_screen.dart';

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
        home: const LandingScreen(),  // ← Entry point
      ),
    );
  }
}