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
            const Text(
              'Agregar Nueva Tarjeta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Número de Tarjeta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: const TextField(
                    decoration: InputDecoration(
                      labelText: 'Expiración (MM/YY)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: const TextField(
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
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métodos de Pago'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tus Tarjetas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) => _buildPaymentCard(method)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _addNewCard,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Método de Pago'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFFF6B6B)),
              foregroundColor: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.credit_card,
          color: method['isDefault'] ? const Color(0xFFFF6B6B) : Colors.grey,
          size: 32,
        ),
        title: Text(method['type']),
        subtitle: Text('${method['number']} • Exp: ${method['expiry']}'),
        trailing: method['isDefault']
            ? const Chip(
                label: Text('Principal', style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Color(0xFF4ECDC4),
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
