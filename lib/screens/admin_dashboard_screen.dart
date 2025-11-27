import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Panel de Administración',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Global',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Usuarios',
                    '1,250',
                    Icons.people,
                    const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Pymes',
                    '340',
                    Icons.store,
                    const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Transacciones',
                    '8,900',
                    Icons.receipt_long,
                    const Color(0xFFFFD93D),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Reportes',
                    '12',
                    Icons.warning,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Actividad Reciente',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Nueva Pyme registrada: "Café Central"',
              'Hace 5 min',
              Icons.add_business,
              Colors.green,
            ),
            _buildActivityItem(
              'Usuario reportado: @juanperez',
              'Hace 20 min',
              Icons.report,
              Colors.orange,
            ),
            _buildActivityItem(
              'Soporte solicitado: "Error en login"',
              'Hace 1 hora',
              Icons.support_agent,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
