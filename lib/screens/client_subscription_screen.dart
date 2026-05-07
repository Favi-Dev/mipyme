import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_service.dart';
import '../client_app_shell.dart';

class ClientSubscriptionScreen extends StatefulWidget {
  final bool isInitialRegistration;

  const ClientSubscriptionScreen({super.key, this.isInitialRegistration = false});

  @override
  State<ClientSubscriptionScreen> createState() => _ClientSubscriptionScreenState();
}

class _ClientSubscriptionScreenState extends State<ClientSubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _waitForSubscriptionConfirmation(String externalReference) async {
    final query = FirebaseFirestore.instance
        .collection('payments')
        .where('externalReference', isEqualTo: externalReference)
        .limit(1);

    await for (final snapshot in query.snapshots()) {
      if (snapshot.docs.isNotEmpty) {
        break;
      }
    }
  }

  Future<void> _processSubscription() async {
    setState(() => _isLoading = true);
    bool waitingDialogOpen = false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw 'Debes iniciar sesion para suscribirte.';
      }

      final result = await PaymentService().createSubscription(
        payerEmail: user.email!,
      );

      final String? initPoint = result['sandbox_init_point'] ?? result['init_point'];
      final String? externalReference = result['external_reference'];

      if (initPoint == null || externalReference == null) {
        throw 'No se pudo iniciar la suscripcion.';
      }

      final Uri url = Uri.parse(initPoint);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el link de pago';
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Procesando suscripcion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Estamos esperando la confirmacion segura de Mercado Pago. Cuando el pago sea aprobado activaremos tu suscripcion automaticamente.',
              ),
            ],
          ),
        ),
      );
      waitingDialogOpen = true;

      await _waitForSubscriptionConfirmation(externalReference);

      if (!mounted) return;
      if (waitingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        waitingDialogOpen = false;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Suscripcion activada'),
          content: const Text(
            'Tu suscripcion fue confirmada por el backend. El QR mensual quedara disponible segun el ciclo configurado en tu cuenta.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
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
      if (waitingDialogOpen && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar suscripcion: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1D9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + bottomPadding + 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.card_membership,
                size: 80,
                color: Color(0xFF6F8F5E),
              ),
              const SizedBox(height: 32),
              Text(
                'Suscripcion mensual SoyPlus',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2F3F2A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para completar tu registro y obtener tu QR mensual de descuentos, es necesario activar tu suscripcion.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF2F3F2A).withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
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
                      'Plan cliente',
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
                      'Pago mensual obligatorio',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildFeatureItem('Generacion de QR de descuentos disponible al mes siguiente del pago'),
                    _buildFeatureItem('Acceso a red de pymes asociadas'),
                    _buildFeatureItem('Beneficios exclusivos mes a mes'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Pagar suscripcion (\$2.000)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
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
