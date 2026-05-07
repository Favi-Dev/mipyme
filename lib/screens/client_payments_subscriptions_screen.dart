import 'package:flutter/material.dart';
import '../services/client_service.dart';
import 'client_subscription_screen.dart';

class ClientPaymentsSubscriptionsScreen extends StatefulWidget {
  const ClientPaymentsSubscriptionsScreen({super.key});

  @override
  State<ClientPaymentsSubscriptionsScreen> createState() => _ClientPaymentsSubscriptionsScreenState();
}

class _ClientPaymentsSubscriptionsScreenState extends State<ClientPaymentsSubscriptionsScreen> {
  final ClientService _clientService = ClientService();
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientSubscriptionScreen()),
    );
  }

  Future<void> _handleUnsubscribe() async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Administrar Suscripcion', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'Estas seguro de que deseas cancelar tu suscripcion? Perderas tus beneficios premium al finalizar el periodo actual.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _clientService.cancelSubscription();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Suscripcion cancelada')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancelar Suscripcion'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mantener Suscripcion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Pagos y Suscripciones',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            labelStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Historial de Pagos'),
              Tab(text: 'Suscripciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPaymentHistory(context),
            _buildSubscriptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _clientService.getPaymentHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay historial de pagos.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final payment = payments[index];
            final date = payment['date'] as DateTime?;
            final dateStr = date != null
                ? '${date.day}/${date.month}/${date.year}'
                : 'Fecha desconocida';
            final amount = payment['amount'];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F3F2A).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.payment, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment['title'] ?? 'Pago',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$$amount',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        payment['status'] ?? 'Completado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF6F8F5E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubscriptions(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<bool>(
      stream: _clientService.getSubscriptionStatus(),
      builder: (context, snapshot) {
        final isSubscribed = snapshot.data ?? false;

        return StreamBuilder<DateTime?>(
          stream: _clientService.getSubscriptionDate(),
          builder: (context, dateSnapshot) {
            final subscriptionDate = dateSnapshot.data;
            String nextBillingString = 'Sin suscripcion activa';

            if (isSubscribed && subscriptionDate != null) {
              final now = DateTime.now();
              DateTime nextDate = subscriptionDate;

              while (!nextDate.isAfter(now)) {
                nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
              }

              final months = [
                'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
              ];

              nextBillingString = 'Proximo cobro: ${nextDate.day} ${months[nextDate.month - 1]} ${nextDate.year}';
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSubscriptionCard(
                  context: context,
                  title: 'Suscripcion Usuario',
                  price: '\$2.000/mes',
                  nextBilling: nextBillingString,
                  isActive: isSubscribed,
                  icon: Icons.star,
                  color: theme.colorScheme.primary,
                  onSubscribe: _handleSubscribe,
                  onManage: _handleUnsubscribe,
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildSubscriptionCard({
    required BuildContext context,
    required String title,
    required String price,
    required String nextBilling,
    required bool isActive,
    required IconData icon,
    required Color color,
    required VoidCallback onSubscribe,
    required VoidCallback onManage,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      price,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF6F8F5E).withOpacity(0.1) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? const Color(0xFF6F8F5E) : theme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  isActive ? 'Activa' : 'Inactiva',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? const Color(0xFF6F8F5E) : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nextBilling,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isActive)
                _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: onSubscribe,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Suscribirse',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              if (isActive)
                TextButton(
                  onPressed: onManage,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Administrar',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
