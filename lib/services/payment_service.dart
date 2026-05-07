import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final String createPreferenceUrl = "https://createpreference-4bt25b22uq-uc.a.run.app";
  final String createSubscriptionUrl = "https://createsubscription-4bt25b22uq-uc.a.run.app";

  Future<Map<String, dynamic>> createPreference({
    String? title,
    double? price,
    String? pymeId,
    int quantity = 1,
    String? orderId,
  }) async {
    final url = Uri.parse(createPreferenceUrl);

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (title != null) 'title': title,
          if (price != null) 'price': price,
          if (pymeId != null) 'pymeId': pymeId,
          'quantity': quantity,
          if (orderId != null) 'orderId': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear pago en servidor: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en createPreference payment_service: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createSubscription({
    required String payerEmail,
  }) async {
    final url = Uri.parse(createSubscriptionUrl);

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payer_email': payerEmail,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear suscripcion en servidor: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en createSubscription payment_service: $e');
      rethrow;
    }
  }
}
