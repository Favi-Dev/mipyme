import 'package:flutter/foundation.dart';
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

  final List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final newOrders = await _pymeService.getOrdersForPymePaginated(
        _currentPymeId,
        lastDocument: _lastDocument,
        pageSize: _pageSize,
      );

      if (newOrders.isNotEmpty) {
        _lastDocument = newOrders.last['_snapshot'] as DocumentSnapshot?;
      }

      setState(() {
        _orders.addAll(newOrders);
        _hasMore = newOrders.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar pedidos: $e')),
        );
      }
    }
  }

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
    if (_orders.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          'No hay pedidos aún',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _orders.clear();
          _lastDocument = null;
          _hasMore = true;
        });
        await _loadNextPage();
      },
      child: ListView.builder(
        itemCount: _orders.length + (_hasMore ? 1 : 0),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            // "Load more" button / auto-loader
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _loadNextPage,
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          'Cargar más pedidos',
                          style: GoogleFonts.poppins(),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2F3F2A),
                          side: const BorderSide(color: Color(0xFF2F3F2A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            );
          }
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }


  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    // Fix: Handle both Timestamp and DateTime (Service converts it, but just in case)
    DateTime?date;
    if (order['createdAt'] is Timestamp) {
      date = (order['createdAt'] as Timestamp).toDate();
    } else if (order['createdAt'] is DateTime) {
      date = order['createdAt'] as DateTime;
    } else if (order['createdAt'] is String) {
       // Just in case serialized
       date = DateTime.tryParse(order['createdAt']);
    }

    final total = order['total'] ?? 0;
    final items = (order['items'] as List<dynamic>?) ?? [];

    Color statusColor;
    String statusText;
    String nextStatus = '';
    String actionText = '';

    switch (status) {
      case 'pending_payment': // Cliente creó orden pero no ha pagado
        statusColor = Colors.orange.shade200;
        statusText = 'Esperando Pago';
        // No hay acción para la Pyme hasta que pague
        break;
      case 'paid': // Nuevo flujo seguro
      case 'pending': // Flujo antiguo
        statusColor = Colors.orange;
        statusText = 'Nuevo Pedido';
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
            ...items.map((item) {
              final variantLabel = item['variantLabel'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['quantity']}x ${item['productName']}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          if (variantLabel != null && variantLabel.isNotEmpty)
                            Text(
                              variantLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6F8F5E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${(item['total'] as num).toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),
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
