import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
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
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
