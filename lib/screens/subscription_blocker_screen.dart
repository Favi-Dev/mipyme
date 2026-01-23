import 'package:flutter/material.dart';
import 'client_subscription_screen.dart';

class SubscriptionBlockerScreen extends StatefulWidget {
  const SubscriptionBlockerScreen({super.key});

  @override
  State<SubscriptionBlockerScreen> createState() => _SubscriptionBlockerScreenState();
}

class _SubscriptionBlockerScreenState extends State<SubscriptionBlockerScreen> {
  
  void _goToDonation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ClientSubscriptionScreen(isInitialRegistration: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1D9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.workspace_premium,
                size: 80,
                color: Color(0xFF6F8F5E),
              ),
              const SizedBox(height: 32),
              Text(
                'Suscripción Requerida',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2F3F2A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Para acceder a SoyPlus y disfrutar de todos los beneficios, es necesario activar tu suscripción mensual.',
                style: theme.textTheme.bodyLarge?.copyWith(
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
                      'Plan Mensual',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6F8F5E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$2.000',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F3F2A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cobrado mensualmente',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                          onPressed: _goToDonation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F8F5E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Realizar Donación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
