import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';

import 'services/cart_service.dart';
import 'services/notification_service.dart';
import 'services/pyme_service.dart';
import 'providers/pyme_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Configurar persistencia offline con límite de caché razonable (100 MB)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 104857600, // 100 MB — evita consumo ilimitado de disco
  );
  
  // Initialize Notifications
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => PymeService()),
        ChangeNotifierProxyProvider<PymeService, PymeProvider>(
          create: (context) => PymeProvider(context.read<PymeService>()),
          update: (_, pymeService, previous) => previous ?? PymeProvider(pymeService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'SoyPlus',
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
