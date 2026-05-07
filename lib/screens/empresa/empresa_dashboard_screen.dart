import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/empresa_service.dart';
import '../../models/user_profile.dart';

class EmpresaDashboardScreen extends StatefulWidget {
  const EmpresaDashboardScreen({super.key});

  @override
  State<EmpresaDashboardScreen> createState() => _EmpresaDashboardScreenState();
}

class _EmpresaDashboardScreenState extends State<EmpresaDashboardScreen> {
  final EmpresaService _empresaService = EmpresaService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? _metrics;
  String _empresaName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_uid == null) return;
    // Cargar nombre de la empresa
    final doc = await FirebaseFirestore.instance.collection('empresas').doc(_uid).get();
    if (doc.exists) {
      _empresaName = doc.data()?['name'] ?? 'Mi Empresa';
    }
    // Cargar métricas
    final metrics = await _empresaService.getAggregatedMetrics(_uid!);
    if (mounted) {
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3F2A),
        title: Text(
          _empresaName.isEmpty ? 'Dashboard' : _empresaName,
          style: const TextStyle(color: Color(0xFFF4F1EA), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF4F1EA)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          icon: Icons.store,
                          title: 'Tiendas',
                          value: '${_metrics?['storeCount'] ?? 0}',
                          color: const Color(0xFF6F8F5E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          icon: Icons.receipt_long,
                          title: 'Órdenes',
                          value: '${_metrics?['totalOrders'] ?? 0}',
                          color: const Color(0xFF8B5A3C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildKpiCard(
                    icon: Icons.attach_money,
                    title: 'Ventas Totales',
                    value: '\$${((_metrics?['totalSales'] ?? 0.0) as double).toStringAsFixed(0)}',
                    color: const Color(0xFF2F3F2A),
                    large: true,
                  ),
                  const SizedBox(height: 24),

                  // Top Tiendas
                  const Text(
                    'Rendimiento por Tienda',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F3F2A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_metrics?['topStores'] as List<Map<String, dynamic>>? ?? []).map((store) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6F8F5E).withValues(alpha: 0.15),
                          child: const Icon(Icons.storefront, color: Color(0xFF6F8F5E)),
                        ),
                        title: Text(
                          store['storeName'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${store['orders']} órdenes'),
                        trailing: Text(
                          '\$${(store['sales'] as double).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F8F5E),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }),
                  if ((_metrics?['topStores'] as List?)?.isEmpty ?? true)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.store_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no tienes tiendas creadas.\nVe a la pestaña "Tiendas" para comenzar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool large = false,
  }) {
    return Container(
      padding: EdgeInsets.all(large ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: large ? 28 : 22,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: large ? 28 : 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: large ? 26 : 20,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
