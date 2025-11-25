import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        title: const Text(
          'Métricas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF2C2C3E),
                value: _selectedTimeRange,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.amber),
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
            const Text(
              'Resumen General',
              style: TextStyle(
                color: Colors.white,
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
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Chart Section (Simulated)
            const Text(
              'Actividad Semanal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C3E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Canjes por día',
                          style: TextStyle(color: Colors.white70)),
                      Icon(Icons.bar_chart, color: Colors.white.withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar('Lun', 0.4, Colors.blueAccent),
                      _buildBar('Mar', 0.6, Colors.blueAccent),
                      _buildBar('Mié', 0.3, Colors.blueAccent),
                      _buildBar('Jue', 0.8, Colors.amber),
                      _buildBar('Vie', 0.9, Colors.blueAccent),
                      _buildBar('Sáb', 0.7, Colors.blueAccent),
                      _buildBar('Dom', 0.5, Colors.blueAccent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recent Activity List
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                color: Colors.white,
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
                  color: Colors.greenAccent,
                  title: 'Cupón canjeado',
                  subtitle: 'Cliente #482 - Hace 10 min',
                ),
                _buildActivityItem(
                  icon: Icons.star_border,
                  color: Colors.amber,
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
                  color: Colors.greenAccent,
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
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(16),
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
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  trend,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
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
          style: const TextStyle(color: Colors.white54, fontSize: 10),
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
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }
}