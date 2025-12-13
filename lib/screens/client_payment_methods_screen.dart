import 'package:flutter/material.dart';

class ClientPaymentMethodsScreen extends StatefulWidget {
  const ClientPaymentMethodsScreen({super.key});

  @override
  State<ClientPaymentMethodsScreen> createState() => _ClientPaymentMethodsScreenState();
}

class _ClientPaymentMethodsScreenState extends State<ClientPaymentMethodsScreen> {
  // Mock data for payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'Visa',
      'number': '**** **** **** 4242',
      'expiry': '12/25',
      'isDefault': true,
    },
    {
      'type': 'Mastercard',
      'number': '**** **** **** 5555',
      'expiry': '10/24',
      'isDefault': false,
    },
  ];

  void _addNewCard() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar Nueva Tarjeta',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Número de Tarjeta',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiración (MM/YY)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nombre del Titular',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Mock save
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarjeta agregada (Simulación)')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar Tarjeta'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tus Tarjetas',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) => _buildPaymentCard(context, method)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addNewCard,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Método de Pago'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary),
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> method) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.credit_card,
          color: method['isDefault'] ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          size: 32,
        ),
        title: Text(method['type'], style: theme.textTheme.bodyLarge),
        subtitle: Text('${method['number']} • Exp: ${method['expiry']}', style: theme.textTheme.bodyMedium),
        trailing: method['isDefault']
            ? Chip(
                label: Text('Principal', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondary)),
                backgroundColor: theme.colorScheme.secondary,
              )
            : PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'default', child: Text('Establecer como principal')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Acción: $value (Simulación)')),
                  );
                },
              ),
      ),
    );
  }
}
