import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PymeMetricsScreen extends StatefulWidget {
  const PymeMetricsScreen({super.key});

  @override
  State<PymeMetricsScreen> createState() => _PymeMetricsScreenState();
}

class _PymeMetricsScreenState extends State<PymeMetricsScreen> {
  String _selectedTimeRange = 'Últimos 7 días';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Métricas',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                value: _selectedTimeRange,
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFFD93D)),
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
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
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: GoogleFonts.poppins(
                color: Colors.black87,
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
                _buildKpiCard(
                  title: 'Cupones Canjeados',
                  value: '124',
                  trend: '+12%',
                  isPositive: true,
                  icon: Icons.qr_code,
                  color: Colors.blueAccent,
                ),
                _buildKpiCard(
                  title: 'Visitas al Perfil',
                  value: '1,205',
                  trend: '+5%',
                  isPositive: true,
                  icon: Icons.visibility,
                  color: Colors.purpleAccent,
                ),
                _buildKpiCard(
                  title: 'Ofertas Activas',
                  value: '3',
                  trend: 'Max: 5',
                  isPositive: null, // Neutral
                  icon: Icons.local_offer,
                  color: Colors.orangeAccent,
                ),
                _buildKpiCard(
                  title: 'Valoración',
                  value: '4.8',
                  trend: '-0.1',
                  isPositive: false,
                  icon: Icons.star,
                  color: const Color(0xFFFFD93D),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Chart Section (Simulated)
            Text(
              'Actividad Semanal',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Canjes por día',
                          style: GoogleFonts.poppins(color: Colors.grey[600])),
                      Icon(Icons.bar_chart, color: Colors.grey[400]),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('Lun', 0.4, const Color(0xFF4ECDC4)),
                      _buildBar('Mar', 0.6, const Color(0xFF4ECDC4)),
                      _buildBar('Mié', 0.3, const Color(0xFF4ECDC4)),
                      _buildBar('Jue', 0.8, const Color(0xFFFFD93D)),
                      _buildBar('Vie', 0.9, const Color(0xFF4ECDC4)),
                      _buildBar('Sáb', 0.7, const Color(0xFF4ECDC4)),
                      _buildBar('Dom', 0.5, const Color(0xFF4ECDC4)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recent Activity List
            Text(
              'Actividad Reciente',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActivityItem(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  title: 'Cupón canjeado',
                  subtitle: 'Cliente #482 - Hace 10 min',
                ),
                _buildActivityItem(
                  icon: Icons.star_border,
                  color: const Color(0xFFFFD93D),
                  title: 'Nueva reseña recibida',
                  subtitle: '5 estrellas de Juan P. - Hace 2 horas',
                ),
                _buildActivityItem(
                  icon: Icons.edit,
                  color: Colors.blueAccent,
                  title: 'Oferta actualizada',
                  subtitle: 'Exclusivo App Soy Pro - Ayer',
                ),
                _buildActivityItem(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  title: 'Cupón canjeado',
                  subtitle: 'Cliente #301 - Ayer',
                ),
              ],
            ),
          ],
        ),
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  trend,
                  style: TextStyle(
                    color: Colors.grey[500],
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
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
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
          style: TextStyle(color: Colors.grey[600], fontSize: 10),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}