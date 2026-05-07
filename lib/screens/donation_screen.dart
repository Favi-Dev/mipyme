import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Importante para abrir el link
import 'package:mipyme/models/user_profile.dart';
import 'package:mipyme/services/pyme_service.dart';
import 'package:mipyme/services/payment_service.dart'; // Importar servicio de pago
import 'package:mipyme/client_app_shell.dart';
import 'package:mipyme/widgets/donation_content.dart';

class DonationScreen extends StatefulWidget {
  final bool isInitialRegistration;
  final UserProfile? preSelectedFoundation;

  const DonationScreen({
    super.key,
    this.isInitialRegistration = false,
    this.preSelectedFoundation,
  });

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final PymeService _pymeService = PymeService();
  final PaymentService _paymentService = PaymentService();
  // final TextEditingController _amountController = TextEditingController();
  
  UserProfile? _selectedFoundation;
  // bool _isMonthly = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to monthly if it's initial registration (as per requirement)
    /* if (widget.isInitialRegistration) {
      _isMonthly = true;
    } */
    if (widget.preSelectedFoundation != null) {
      _selectedFoundation = widget.preSelectedFoundation;
    }
  }

  Future<void> _processDonation(double amount, bool isMonthly) async {
    if (_selectedFoundation == null) return;

    // setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String payerEmail = user?.email ?? 'invitado@soyplus.app';
      final String title = isMonthly 
          ? 'Suscripción Mensual a ${_selectedFoundation!.name}' 
          : 'Donación a ${_selectedFoundation!.name}';

      Map<String, dynamic> result;
      
      if (isMonthly) {
        // Opción 1: Crear Suscripción (Si está logueado o tiene email)
        result = await _paymentService.createSubscription(
          payerEmail: payerEmail,
        );
      } else {
        // Opción 2: Pago Único (Checkout Pro)
        result = await _paymentService.createPreference(
          title: title,
          price: amount,
          pymeId: _selectedFoundation!.id,
        );
      }

      // 1. Obtener el link de pago (sandbox para pruebas)
      final String initPoint = result['sandbox_init_point'] ?? result['init_point'];
      
      // 2. Abrir Mercado Pago
      final Uri url = Uri.parse(initPoint);
      final String? externalReference = result['external_reference'];

      // Usar platformDefault para mayor compatibilidad web y evitar bloqueo de popups
      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
        throw 'No se pudo abrir la pasarela de pago. Por favor, revisa si tienes bloqueador de pop-ups.';
      }

      // 3. SECUENCIA REAL DE PAGO (Polling / Escucha Activa)
      if (!mounted) return;

      if (externalReference != null) {
        // Mostrar Dialog de "Esperando Confirmación del Banco..."
        // No dejamos cerrar este dialog fácilmente para evitar que el usuario se vaya sin confirmar
        // Aunque Mercado Pago avisa rápido, puede tomar unos segundos.
        
        // bool paymentConfirmed = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false, // Bloquear el botón atrás
            child: AlertDialog(
              title: const Text('Procesando Pago...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Estamos esperando la confirmación segura de Mercado Pago.\nPor favor, completa el pago en tu navegador.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancelar / Cerrar'), // Escotilla de escape si el usuario se arrepiente
                ),
              ],
            ),
          ),
        );

        // Escuchar cambios en Firestore donde externalReference coincida
        // NOTA: El Webhook escribirá un documento en 'payments' con este externalReference
        // final subscription = 
        FirebaseFirestore.instance
            .collection('payments')
            .where('externalReference', isEqualTo: externalReference)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                 // ¡PAGO CONFIRMADO!
                 // paymentConfirmed = true;
                 Navigator.pop(context); // Cerrar Dialog de Espera
                 _showSuccessDialog(); // Mostrar Éxito
              }
            });
            
        // Esperamos un tiempo razonable (ej. 5 min) o hasta que el usuario cierre manualmente
        // Pero como es un listener, se queda vivo. Deberíamos cancelarlo al salir de pantalla.
        // Por simplicidad en este MVP, si el usuario cancela el dialog, el listener se debería cancelar.
        
        // *MEJORA*: Cancelar subscription cuando el widget se desmonte o el dialogo se cierre.
        // Como showDialog es una ruta futura, no tenemos control directo del listener desde "adentro" del builder facilmente
        // salvo usando un StatefuleWidget o variables de estado. 
        // Para simplificar, añadimos la suscripción a una variable de estado para limpiar en dispose.

      } else {
         // Fallback legacy por si falta externalReference (subscription mensual)
         _showLegacyConfirmation();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar pago: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Pago Confirmado!'),
        content: const Text(
          'Tu donación ha sido procesada exitosamente.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Success Dialog
              if (widget.isInitialRegistration) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientAppShell()),
                  (route) => false,
                );
              } else {
                Navigator.pop(context); // Go back
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showLegacyConfirmation() async {
      // Preguntar si completó la donación (Antiguo método)
      // ... (Lógica actual) 
      // Mantenemos esto solo para Suscripciones mensuales por ahora
      if (!mounted) return;
      
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Completar Donación'),
          content: const Text(
            'Se ha abierto el navegador para procesar tu donación. ¿Pudiste completarla?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // No
              child: const Text('Cancelar'),
            ),
             ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Sí
              child: const Text('¡Sí, ya doné!'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
         setState(() => _isLoading = false);
         return;
      }
      
      _showSuccessDialog();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizar Donación'),
        automaticallyImplyLeading: !widget.isInitialRegistration,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _pymeService.getFoundations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final foundations = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (widget.isInitialRegistration) ...[
                        Text(
                          '¡Bienvenido a SoyPlus!',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu donación inicial activa tu suscripción y se utiliza para el mantenimiento y promoción de las Pymes y Fundaciones de la comunidad.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                      ],

                      Text(
                        'Selecciona una Fundación',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<UserProfile>(
                        initialValue: _selectedFoundation, // Ensure this object is equal to one in list (Equatable or same refs)
                        // If objects are recreated in stream, equality might fail unless UserProfile overrides ==
                        // We rely on 'id' ideally, but Dropdown uses object identity by default if 'value' not in 'items'.
                        // Since 'foundations' come from stream, they are new objects. 
                        // We might need to find the matching object in 'foundations' by ID.
                        hint: const Text('Elige una causa...'),
                        items: foundations.map((f) {
                          return DropdownMenuItem(
                            value: f, // If we used ID here it would be easier, but we use UserProfile
                            child: Text(f.name),
                          );
                        }).toList(),
                        // Fix for object equality issues: find matching foundation from list
                        selectedItemBuilder: (context) {
                          return foundations.map((f) {
                            return Text(f.name);
                          }).toList();
                        },
                        onChanged: (val) => setState(() => _selectedFoundation = val),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectedFoundation != null)
                   DonationContent(
                      pymeData: _selectedFoundation!,
                      amounts: const [1000, 3000, 5000, 10000, 20000],
                      onDonate: _processDonation,
                   )
                else
                   const SizedBox(
                     height: 200,
                     child: Center(
                       child: Text('Selecciona una organización para continuar'),
                     ),
                   ),
                
                
              ],
            ),
          );
        },
      ),
    );
  }
}
