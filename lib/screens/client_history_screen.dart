import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/client_service.dart';
import '../services/pyme_service.dart';
import '../models/order_model.dart';

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientService = ClientService();
    final pymeService = PymeService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Compras'),
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: clientService.getOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes compras recientes.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Explora las vitrinas y apoya a las Pymes!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return FutureBuilder(
                future: pymeService.getPymeById(order.pymeId),
                builder: (context, pymeSnap) {
                  final pymeName = pymeSnap.data?.name ?? 'Cargando...';
                  return _buildHistoryItem(context, order, pymeName, theme);
                },
              );
            },
          );
        },
      ),
    );
  }

  // Map all order statuses to human-readable labels and colors
  (String label, Color color) _statusInfo(String status, ThemeData theme) {
    return switch (status) {
      'pending_payment' => ('Esperando Pago', Colors.orange.shade300),
      'paid'            => ('Pagado', Colors.blue),
      'pending'         => ('Nuevo Pedido', Colors.orange),
      'preparing'       => ('En Preparación', Colors.blue),
      'ready'           => ('Listo para Retiro', Colors.green),
      'completed'       => ('Completado', const Color(0xFF6F8F5E)),
      'cancelled'       => ('Cancelado', Colors.red),
      'quote_requested' => ('Cotización Enviada', Colors.purple),
      _                 => (status, Colors.grey),
    };
  }

  Widget _buildHistoryItem(BuildContext context, OrderModel order, String pymeName, ThemeData theme) {
    final items = order.items;
    final firstItem = items.isNotEmpty ? items.first : null;
    final productName = firstItem?.productName ?? 'Producto';
    final variantLabel = firstItem?.variantLabel;
    final itemCount = items.length;
    final displayProduct = itemCount > 1
        ? '$productName + ${itemCount - 1} más'
        : (variantLabel != null && variantLabel.isNotEmpty
            ? '$productName — $variantLabel'
            : productName);

    final date = DateFormat('dd MMM yyyy').format(order.createdAt);
    final (statusLabel, statusColor) = _statusInfo(order.status, theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Store name + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.storefront_outlined, color: theme.colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    pymeName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const Divider(height: 20),
          // Product info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayProduct,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${order.total.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status badge
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
