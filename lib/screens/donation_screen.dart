import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/pyme_service.dart';
import '../client_app_shell.dart';

class DonationScreen extends StatefulWidget {
  final bool isGuest;
  final bool isInitialRegistration;
  final UserProfile? preSelectedFoundation;

  const DonationScreen({
    super.key,
    this.isGuest = false,
    this.isInitialRegistration = false,
    this.preSelectedFoundation,
  });

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final PymeService _pymeService = PymeService();
  final TextEditingController _amountController = TextEditingController();
  
  UserProfile? _selectedFoundation;
  bool _isMonthly = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to monthly if it's initial registration (as per requirement)
    if (widget.isInitialRegistration) {
      _isMonthly = true;
    }
    if (widget.preSelectedFoundation != null) {
      _selectedFoundation = widget.preSelectedFoundation;
    }
  }

  Future<void> _processDonation() async {
    if (_selectedFoundation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una fundación')),
      );
      return;
    }
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate Payment Delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      if (!widget.isGuest) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Record donation in Firestore (Mock)
          await FirebaseFirestore.instance.collection('donations').add({
            'userId': user.uid,
            'foundationId': _selectedFoundation!.id,
            'foundationName': _selectedFoundation!.name,
            'amount': double.parse(_amountController.text),
            'isMonthly': _isMonthly,
            'date': DateTime.now(),
          });

          // Also record in 'payments' for Admin Transactions view
          await FirebaseFirestore.instance.collection('payments').add({
            'userId': user.uid,
            'amount': double.parse(_amountController.text),
            'type': 'donation',
            'foundationId': _selectedFoundation!.id,
            'foundationName': _selectedFoundation!.name,
            'date': DateTime.now(),
          });

          // Update User Subscription if Monthly
          if (_isMonthly) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'isSubscribed': true,
              'subscriptionDate': DateTime.now(),
            });
          }
        }
      }

      if (!mounted) return;

      // Success Message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Gracias por tu aporte!'),
          content: Text(widget.isGuest 
            ? 'Tu donación ha sido recibida. Regístrate para obtener beneficios exclusivos.'
            : 'Tu donación ha sido procesada exitosamente.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close Dialog
                if (widget.isInitialRegistration) {
                  // Go to App Home
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const ClientAppShell()),
                    (route) => false,
                  );
                } else if (widget.isGuest) {
                  // Go back to Login
                  Navigator.pop(context);
                } else {
                  // Go back to previous screen (Home)
                  Navigator.pop(context);
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error procesando donación: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  value: _selectedFoundation,
                  hint: const Text('Elige una causa...'),
                  items: foundations.map((f) {
                    return DropdownMenuItem(
                      value: f,
                      child: Text(f.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedFoundation = val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Monto a Donar (CLP)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                
                // Preset Amounts chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [1000, 3000, 5000, 10000, 20000].map((amount) {
                    final isSelected = _amountController.text == amount.toString();
                    return ChoiceChip(
                      label: Text('\$${amount.toString()}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                           if (selected) {
                             _amountController.text = amount.toString();
                           }
                        });
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                     setState(() {}); // Trigger rebuild to update chips
                  },
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    labelText: 'Otro monto', // Added label for clarity
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                if (!widget.isGuest) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _isMonthly,
                          onChanged: (val) => setState(() => _isMonthly = val ?? false),
                          title: const Text('Donación Mensual Automática'),
                          subtitle: Text(widget.isInitialRegistration 
                              ? 'Requerido para mantener tu cuenta activa y apoyar la plataforma.'
                              : 'Suscríbete para obtener cupones y beneficios exclusivos en la app.'),
                          activeColor: theme.colorScheme.primary,
                        ),
                        if (_isMonthly)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Al marcar esta opción, autorizas el cargo automático mensual a tu medio de pago.',
                              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _processDonation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator()
                    : Text(
                        widget.isGuest ? 'Donar como Invitado' : 'Confirmar Donación',
                        style: const TextStyle(fontSize: 18),
                      ),
                ),
                
                if (widget.isGuest) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '* Al donar como invitado no acumularás puntos ni recibirás cupones de descuento.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
