import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SoyPlus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B), // Playful Coral/Red
          secondary: const Color(0xFF4ECDC4), // Playful Teal
          tertiary: const Color(0xFFFFD93D), // Playful Yellow
          background: const Color(0xFFF7F9FC), // Light background
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B6B),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
