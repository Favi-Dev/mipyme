import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PaymentService {
  // URLs directas de Cloud Run (Firebase Functions v2) para evitar problemas de redirección CORS.
  final String createPreferenceUrl = "https://createpreference-4bt25b22uq-uc.a.run.app";
  final String createSubscriptionUrl = "https://createsubscription-4bt25b22uq-uc.a.run.app";

  // Crea una preferencia de pago para Mercado Pago (Pago Único / Carrito)
  // Llama a la función 'createPreference' desplegada en Firebase.
  Future<Map<String, dynamic>> createPreference({
    required String title,
    required double price,
    required String pymeId,
    int quantity = 1,
    String? externalReference, // NEW: Permitir enviar el ID de Orden
  }) async {
    final url = Uri.parse(createPreferenceUrl);
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'price': price,
          'quantity': quantity,
          'pymeId': pymeId,
          'externalReference': externalReference, // NEW: Enviar al backend
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear pago en Servidor: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en createPreference payment_service: $e');
      rethrow;
    }
  }

  // Crea una suscripción mensual (Preapproval)
  // Llama a la función 'createSubscription' desplegada en Firebase.
  Future<Map<String, dynamic>> createSubscription({
    required String title,
    required double price,
    required String payerEmail,
  }) async {
    final url = Uri.parse(createSubscriptionUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'price': price,
          'payer_email': payerEmail,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al crear suscripción en Servidor: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en createSubscription payment_service: $e');
      rethrow;
    }
  }
}
