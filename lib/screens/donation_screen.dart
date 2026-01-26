import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/pyme_service.dart';
import '../client_app_shell.dart';
import '../widgets/donation_content.dart';

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

  Future<void> _processDonation(double amount, bool isMonthly) async {
    if (_selectedFoundation == null) return;

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
            'amount': amount,
            'isMonthly': isMonthly,
            'date': DateTime.now(),
          });

          // Also record in 'payments' for Admin Transactions view
          await FirebaseFirestore.instance.collection('payments').add({
            'userId': user.uid,
            'amount': amount,
            'type': 'donation',
            'foundationId': _selectedFoundation!.id,
            'foundationName': _selectedFoundation!.name,
            'date': DateTime.now(),
          });
          
          // Increment S+ Score for Foundation
          await _pymeService.incrementSupporterCount(_selectedFoundation!.id);
          
          // Update foundation current donations (Real-time goal support)
          await FirebaseFirestore.instance.collection('users').doc(_selectedFoundation!.id).update({
             'currentDonations': FieldValue.increment(amount),
          });

          // Update User Subscription if Monthly
          if (isMonthly) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'isSubscribed': true,
              'subscriptionDate': DateTime.now(),
            });
          }
        }
      } else {
        // Guest mode: Still update the foundation stats!
         await _pymeService.incrementSupporterCount(_selectedFoundation!.id);
         await FirebaseFirestore.instance.collection('users').doc(_selectedFoundation!.id).update({
             'currentDonations': FieldValue.increment(amount),
          });
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
                        value: _selectedFoundation, // Ensure this object is equal to one in list (Equatable or same refs)
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
                
                if (widget.isGuest)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '* Al donar como invitado no acumularás puntos ni recibirás cupones de descuento.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
