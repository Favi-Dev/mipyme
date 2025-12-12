import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/cart_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SoyPlus',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0056D2), // Hero Blue
            primary: const Color(0xFF0056D2),
            secondary: const Color(0xFFE63946), // Action Red
            tertiary: const Color(0xFFFFD700), // Golden
            background: const Color(0xFFF0F4F8), // Cool background
            surface: Colors.white,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF0F4F8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0056D2),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0056D2),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
