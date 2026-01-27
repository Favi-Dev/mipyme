import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/pyme_service.dart';

class DonationContent extends StatefulWidget {
  final UserProfile pymeData;
  final List<int> amounts;
  final bool isGuest;
  final Future<void> Function(double amount, bool isMonthly)? onDonate;

  const DonationContent({
    super.key,
    required this.pymeData,
    required this.amounts,
    this.isGuest = false,
    this.onDonate,
  });

  @override
  State<DonationContent> createState() => _DonationContentState();
}

class _DonationContentState extends State<DonationContent> {
  bool isMonthly = false;
  int? selectedAmount = 3000;
  final TextEditingController _customAmountController = TextEditingController();
  final PymeService _pymeService = PymeService();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<UserProfile?>(
      stream: _pymeService.getUserProfileStream(widget.pymeData.id),
      initialData: widget.pymeData,
      builder: (context, snapshot) {
        final pyme = snapshot.data ?? widget.pymeData;
        final currentDonations = pyme.currentDonations ?? 0.0;
        final donationGoal = pyme.donationGoal ?? 100000.0;
        final progress = (currentDonations / donationGoal).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3F2A).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Donar a ${pyme.name}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2F3F2A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pyme.donationGoalDescription ?? 'Tu aporte ayuda a continuar con nuestra labor.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5A5A55),
                ),
              ),
              const SizedBox(height: 24),

              // Toggle Type
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3F2A).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isMonthly = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isMonthly ? theme.colorScheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !isMonthly ? [
                              BoxShadow(
                                color: const Color(0xFF2F3F2A).withOpacity(0.1),
                                blurRadius: 4,
                              )
                            ] : null,
                          ),
                          child: Text(
                            'Única vez',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: !isMonthly ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isMonthly = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isMonthly ? theme.colorScheme.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isMonthly ? [
                              BoxShadow(
                                color: const Color(0xFF2F3F2A).withOpacity(0.1),
                                blurRadius: 4,
                              )
                            ] : null,
                          ),
                          child: Text(
                            'Mensual',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isMonthly ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Amount Selection
              Text(
                'Selecciona un monto',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...widget.amounts.map((amount) => ChoiceChip(
                    label: Text('\$${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'),
                    selected: selectedAmount == amount,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedAmount = amount;
                          _customAmountController.clear();
                        });
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selectedAmount == amount ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: selectedAmount == amount ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                    ),
                  )),
                  ChoiceChip(
                    label: const Text('Otro monto'),
                    selected: selectedAmount == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedAmount = null;
                        });
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: selectedAmount == null ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: selectedAmount == null ? theme.colorScheme.primary : theme.colorScheme.outline),
                    ),
                  ),
                ],
              ),
              
              if (selectedAmount == null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    labelText: 'Ingresa el monto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Progress
              Text(
                'Meta de recaudación',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: const Color(0xFF6F8F5E), // Light Green for progress
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${currentDonations.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6F8F5E), // Light Green
                    ),
                  ),
                  Text(
                    'Meta: \$${donationGoal.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Payment Method Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.credit_card, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isGuest
                            ? 'Serás redirigido a una pasarela externa para ingresar tus datos de pago de forma segura.'
                            : 'Se utilizará tu método de pago registrado para realizar el aporte.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = (selectedAmount ?? int.tryParse(_customAmountController.text.replaceAll('.', '')))?.toDouble() ?? 0.0;
                    
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor ingresa un monto válido')),
                      );
                      return;
                    }

                    if (widget.onDonate != null) {
                      await widget.onDonate!(amount, isMonthly);
                      return;
                    }

                    // Temporary: Simulate donation processing
                    // Update Pyme currentDonations
                    try {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                          content: Text('Procesando donación...'),
                          backgroundColor: Color(0xFF6F8F5E),
                        ),
                      );

                      // Simulate backend update
                      // In a real app, this would be a Cloud Function triggered by payment success
                      // Here we update directly for demo purposes as requested
                      final pymeRef = FirebaseFirestore.instance.collection('users').doc(pyme.id);
                      await pymeRef.update({
                        'currentDonations': FieldValue.increment(amount),
                        'supporterCount': FieldValue.increment(1),
                      });

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isMonthly 
                              ? '¡Gracias por suscribirte con \$${amount}/mes!' 
                              : '¡Gracias por tu donación de \$${amount}!'),
                            backgroundColor: const Color(0xFF6F8F5E),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error donating: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3F2A), // Verde Hoja Profundo
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isMonthly ? 'Suscribirse Mensualmente' : 'Realizar Donación',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF4F1EA),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}