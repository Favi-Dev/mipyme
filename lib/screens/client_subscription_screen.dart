import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../client_app_shell.dart';

class ClientSubscriptionScreen extends StatefulWidget {
  final bool isInitialRegistration;

  const ClientSubscriptionScreen({super.key, this.isInitialRegistration = false});

  @override
  State<ClientSubscriptionScreen> createState() => _ClientSubscriptionScreenState();
}

class _ClientSubscriptionScreenState extends State<ClientSubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _processSubscription() async {
    setState(() => _isLoading = true);

    // Simulate Payment Delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update User Subscription in Firestore
        // We set 'subscriptionDate' to now.
        // Logic elsewhere (ClientQrScreen) determines when the coupon becomes active (e.g. +1 month or immediate).
        // Since the user said "se crea el QR", enabling subscription is the key.
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isSubscribed': true,
          'subscriptionDate': DateTime.now(),
          // Ensure coupon status is initialized if not present
          'monthlyCouponRedeemed': false, 
        });

        // Record the payment (Mock)
        await FirebaseFirestore.instance.collection('payments').add({
          'userId': user.uid,
          'amount': 2000,
          'type': 'mandatory_subscription',
          'date': DateTime.now(),
        });
      }

      if (!mounted) return;

      // Success & Navigate
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Suscripción Activada!'),
          content: const Text(
            'Tu suscripción mensual ha sido procesada correctamente. Ahora tienes acceso a tu QR de descuento mensual.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ClientAppShell()),
        (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar suscripción: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1D9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.card_membership, 
                size: 80, 
                color: Color(0xFF6F8F5E)
              ),
              const SizedBox(height: 32),
              
              Text(
                'Suscripción Mensual SoyPlus',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2F3F2A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Para completar tu registro y obtener tu QR mensual de descuentos, es necesario activar tu suscripción.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF2F3F2A).withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Subscription Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F3F2A).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Plan Cliente',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF6F8F5E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$2.000',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F3F2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pago Mensual Obligatorio',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildFeatureItem('Generación de QR de descuentos'),
                    _buildFeatureItem('Acceso a red de Pymes asociadas'),
                    _buildFeatureItem('Beneficios exclusivos mes a mes'),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        'Pagar Suscripción (\$2.000)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: Color(0xFF6F8F5E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF2F3F2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
