import 'package:flutter/material.dart';
import '../services/client_service.dart';

class ClientPaymentMethodsScreen extends StatelessWidget {
  final String? title;
  const ClientPaymentMethodsScreen({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientService = ClientService();

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Métodos de Pago'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: clientService.getPaymentMethods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final paymentMethods = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Tus Tarjetas',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (paymentMethods.isEmpty)
                 Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay métodos de pago guardados.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ...paymentMethods.map((method) => _buildPaymentCard(context, method, clientService)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _showAddCardDialog(context, clientService),
                icon: const Icon(Icons.add),
                label: const Text('Agregar Método de Pago'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.colorScheme.primary),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, ClientService clientService) {
    final theme = Theme.of(context);
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final nameController = TextEditingController();

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
              controller: numberController,
              decoration: InputDecoration(
                labelText: 'Número de Tarjeta',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiración (MM/YY)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
             TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Titular',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (numberController.text.length > 4) {
                    // Basic validation & save
                    final last4 = numberController.text.substring(numberController.text.length - 4);
                    // Infer type roughly
                    String type = 'Tarjeta';
                    if (numberController.text.startsWith('4')) type = 'Visa';
                    if (numberController.text.startsWith('5')) type = 'Mastercard';

                    clientService.addPaymentMethod({
                      'type': type,
                      'number': '**** **** **** $last4', // Masked
                      'expiry': expiryController.text,
                      'holderName': nameController.text,
                      // 'cvv': cvvController.text // Don't save CVV!
                    });
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tarjeta agregada exitosamente')),
                    );
                  }
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

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> method, ClientService clientService) {
    final theme = Theme.of(context);
    final isDefault = method['isDefault'] == true;
    final id = method['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.credit_card,
          color: isDefault ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          size: 32,
        ),
        title: Text(method['type'] ?? 'Tarjeta', style: theme.textTheme.bodyLarge),
        subtitle: Text('${method['number']} • Exp: ${method['expiry']}', style: theme.textTheme.bodyMedium),
        trailing: isDefault
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
                  if (value == 'delete') {
                    clientService.deletePaymentMethod(id);
                  } else if (value == 'default') {
                    clientService.setDefaultPaymentMethod(id);
                  }
                },
              ),
        onTap: !isDefault ? () => clientService.setDefaultPaymentMethod(id) : null,
      ),
    );
  }
}
