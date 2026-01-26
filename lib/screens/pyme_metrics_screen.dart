import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vitrina_data.dart';
import '../services/pyme_service.dart';
import 'foundation_donations_goal_screen.dart';

class PymeMetricsScreen extends StatefulWidget {
  const PymeMetricsScreen({super.key});

  @override
  State<PymeMetricsScreen> createState() => _PymeMetricsScreenState();
}

class _PymeMetricsScreenState extends State<PymeMetricsScreen> {
  String _selectedTimeRange = 'Últimos 7 días';
  final PymeService _pymeService = PymeService();
  final String _currentPymeId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3F2A),
        elevation: 0,
        title: Text(
          'Métricas',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF4F1EA),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF4F1EA)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFFF4F1EA),
                value: _selectedTimeRange,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF4F1EA)),
                style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA), fontSize: 14),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeRange = newValue!;
                  });
                },
                items: <String>[
                  'Hoy',
                  'Últimos 7 días',
                  'Este Mes',
                  'Este Año'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(color: const Color(0xFF2F3F2A))),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _pymeService.getPymeMetrics(_currentPymeId),
        builder: (context, snapshot) {
          final metrics = snapshot.data ?? {
            'totalOrders': 0,
            'totalSales': 0.0,
            'completedOrders': 0,
            'pendingOrders': 0,
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen General',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3F2A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // KPI Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    GestureDetector(
                      onTap: () {
                         if (VitrinaData.isFoundation) {
                           Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => const FoundationDonationsGoalScreen()),
                           );
                         }
                      },
                      child: _buildKpiCard(
                        title: VitrinaData.isFoundation ? 'Recaudado' : 'Ventas Totales',
                        value: '\$${(metrics['totalSales'] as num).toStringAsFixed(0)}',
                        trend: '${metrics['completedOrders']} ${VitrinaData.isFoundation ? "donaciones" : "pedidos"}',
                        isPositive: true,
                        icon: Icons.attach_money,
                        color: const Color(0xFF6F8F5E),
                      ),
                    ),
                    _buildKpiCard(
                      title: 'Pendientes',
                      value: '${metrics['pendingOrders']}',
                      trend: 'Requiere atención',
                      isPositive: false,
                      icon: Icons.pending_actions,
                      color: const Color(0xFF8B5A3C),
                    ),
                    _buildKpiCard(
                      title: 'Total Pedidos',
                      value: '${metrics['totalOrders']}',
                      trend: 'Histórico',
                      isPositive: null,
                      icon: Icons.receipt_long,
                      color: const Color(0xFFE3B58F),
                    ),
                    // Removed fake Valuation card
                  ],
                ),
                const SizedBox(height: 32),
                
                // Chart Section Removed (Simulated data)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool? isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (isPositive != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF6F8F5E).withOpacity(0.1)
                        : const Color(0xFF8B5A3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF6F8F5E) : const Color(0xFF8B5A3C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  trend,
                  style: TextStyle(
                    color: const Color(0xFF2F3F2A).withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2F3F2A),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2F3F2A).withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double heightFactor, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3F2A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3F2A).withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
        ],
      ),
    );
  }
}
