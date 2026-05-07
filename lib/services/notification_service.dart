import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Listen to Foreground Messages — show in-app banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM Foreground: ${message.notification?.title}');
      }
      // In-app notification is handled by the notifications bell icon
      // (stored in Firestore by the Cloud Function). No local popup needed on web.
      // On mobile, use flutter_local_notifications if added to pubspec.
    });
  }

  Future<String?> getToken() async {
    try {
      // On web, vapidKey is required. Pass it here if configured.
      final token = await _messaging.getToken();
      if (kDebugMode) debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}
