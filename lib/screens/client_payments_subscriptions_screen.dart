import 'package:flutter/material.dart';

class ClientPaymentsSubscriptionsScreen extends StatelessWidget {
  const ClientPaymentsSubscriptionsScreen({super.key});

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
    final payments = [
      {
        'title': 'Suscripción Mensual App',
        'date': '12 Dic 2025',
        'amount': '\$5.990',
        'status': 'Completado'
      },
      {
        'title': 'Donación Fundación Los Robles',
        'date': '10 Dic 2025',
        'amount': '\$3.000',
        'status': 'Completado'
      },
      {
        'title': 'Compra en Café Eclipse',
        'date': '05 Dic 2025',
        'amount': '\$12.500',
        'status': 'Completado'
      },
      {
        'title': 'Suscripción Mensual App',
        'date': '12 Nov 2025',
        'amount': '\$5.990',
        'status': 'Completado'
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                      payment['title']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      payment['date']!,
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
                    payment['amount']!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    payment['status']!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green, // Keep green for success status
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
  }

  Widget _buildSubscriptions(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSubscriptionCard(
          context: context,
          title: 'Plan Premium App',
          price: '\$5.990/mes',
          nextBilling: 'Próximo cobro: 12 Ene 2026',
          isActive: true,
          icon: Icons.star,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _buildSubscriptionCard(
          context: context,
          title: 'Donación Fundación Los Robles',
          price: '\$3.000/mes',
          nextBilling: 'Próximo cobro: 10 Ene 2026',
          isActive: true,
          icon: Icons.volunteer_activism,
          color: const Color(0xFFE63946), // Keep specific brand color
        ),
      ],
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
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: isActive ? Colors.green.withOpacity(0.1) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.green : theme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  isActive ? 'Activa' : 'Inactiva',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive ? Colors.green : theme.colorScheme.onSurfaceVariant,
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
              TextButton(
                onPressed: () {},
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
