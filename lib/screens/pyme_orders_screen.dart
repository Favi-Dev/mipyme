import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/pyme_service.dart';

class PymeOrdersScreen extends StatefulWidget {
  final bool showAppBar;
  const PymeOrdersScreen({super.key, this.showAppBar = true});

  @override
  State<PymeOrdersScreen> createState() => _PymeOrdersScreenState();
}

class _PymeOrdersScreenState extends State<PymeOrdersScreen> {
  final PymeService _pymeService = PymeService();
  final String _currentPymeId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return _buildBody();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Pedidos Entrantes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _pymeService.getOrdersForPyme(_currentPymeId),
        builder: (context, snapshot) {
          // Robust error handling
          if (snapshot.hasError) {
             print('Error fetching orders: ${snapshot.error}');
             // Don't show scary error to user, show empty state with retry or friendly message
             // unless it's critical. For now, treat as empty/loading issue or just show friendly text
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: const Color(0xFF8B5A3C).withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No se pudieron cargar los pedidos', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A))),
                    Text('Intente nuevamente más tarde', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF2F3F2A).withOpacity(0.5))),
                  ],
               ),
             );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'No hay pedidos pendientes',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            );
          }
          return ListView.builder(
            itemCount: orders.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
      );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final date = (order['createdAt'] as Timestamp?)?.toDate();
    final total = order['total'] ?? 0;
    final items = (order['items'] as List<dynamic>?) ?? [];

    Color statusColor;
    String statusText;
    String nextStatus = '';
    String actionText = '';

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        nextStatus = 'preparing';
        actionText = 'Aceptar Pedido';
        break;
      case 'preparing':
        statusColor = Colors.blue;
        statusText = 'En Preparación';
        nextStatus = 'ready';
        actionText = 'Marcar Listo';
        break;
      case 'ready':
        statusColor = Colors.green;
        statusText = 'Listo para Retiro';
        nextStatus = 'completed';
        actionText = 'Entregar';
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusText = 'Completado';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelado';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden #${order['id'].toString().substring(0, 6).toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : '',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const Divider(height: 24),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['quantity']}x ${item['productName']}',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                      Text(
                        '\$${(item['total'] as num).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '\$${(total as num).toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF6F8F5E),
                  ),
                ),
              ],
            ),
            if (actionText.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _pymeService.updateOrderStatus(order['id'], nextStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3F2A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(actionText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
