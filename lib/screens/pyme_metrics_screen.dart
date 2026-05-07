import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vitrina_data.dart';
import '../models/user_profile.dart';
import '../services/pyme_service.dart';
import 'foundation_donations_goal_screen.dart';
import 'pyme_event_participants_screen.dart';

class PymeMetricsScreen extends StatefulWidget {
  const PymeMetricsScreen({super.key});

  @override
  State<PymeMetricsScreen> createState() => _PymeMetricsScreenState();
}

class _PymeMetricsScreenState extends State<PymeMetricsScreen> with SingleTickerProviderStateMixin {
  final PymeService _pymeService = PymeService();
  final String _currentPymeId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabController;

  // Date range filter
  String _selectedRange = 'Semana';
  final List<String> _rangeOptions = ['Semana', 'Mes', '30 días', 'Todo'];

  DateTime get _rangeStart {
    final now = DateTime.now();
    return switch (_selectedRange) {
      'Semana' => now.subtract(const Duration(days: 7)),
      'Mes'    => DateTime(now.year, now.month, 1),
      '30 días'=> now.subtract(const Duration(days: 30)),
      _        => DateTime(2020, 1, 1), // Todo
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3F2A),
        elevation: 0,
        title: Text(
          'Panel de Control',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF4F1EA),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6F8F5E),
          labelColor: const Color(0xFFF4F1EA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Ventas y Pedidos'),
            Tab(text: 'Eventos y Talleres'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSalesTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Selector
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _rangeOptions.map((range) {
                final isSelected = _selectedRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(range),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6F8F5E),
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : const Color(0xFF2F3F2A),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (_) => setState(() => _selectedRange = range),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<Map<String, dynamic>>(
            stream: _pymeService.getPymeMetricsForRange(_currentPymeId, _rangeStart),
              builder: (context, snapshot) {
                final metrics = snapshot.data ?? {
                  'totalSales': 0.0,
                  'completedOrders': 0,
                };
                
                // Fetch pending separately or assume 0 if not implemented fully yet
                // For now let's query orders count direct here for 'pending' state
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders')
                      .where('pymeId', isEqualTo: _currentPymeId)
                      .where('status', whereIn: ['pending', 'quote_requested'])
                      .snapshots(),
                  builder: (context, orderSnapshot) {
                    final pendingCount = orderSnapshot.hasData ? orderSnapshot.data!.docs.length : 0;
                    final totalOrders = (metrics['completedOrders'] as int) + pendingCount;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                trend: '${metrics['completedOrders']} ${VitrinaData.isFoundation ? "donaciones" : "ventas"} ok',
                                isPositive: true,
                                icon: Icons.attach_money,
                                color: const Color(0xFF6F8F5E),
                              ),
                            ),
                            _buildKpiCard(
                              title: 'Pendientes',
                              value: '$pendingCount',
                              trend: 'Requiere atención',
                              isPositive: false,
                              icon: Icons.pending_actions,
                              color: const Color(0xFF8B5A3C),
                            ),
                            _buildKpiCard(
                              title: 'Total Pedidos',
                              value: '$totalOrders',
                              trend: 'Histórico',
                              isPositive: null,
                              icon: Icons.receipt_long,
                              color: const Color(0xFFE3B58F),
                            ),
                            FutureBuilder<UserProfile?>(
                              future: _pymeService.getUserProfile(_currentPymeId),
                              builder: (context, profileSnap) {
                                final profile = profileSnap.data;
                                final rating = profile?.averageRating ?? 0.0;
                                final count = profile?.reviewCount ?? 0;
                                return _buildKpiCard(
                                  title: 'Calificación',
                                  value: rating > 0 ? rating.toStringAsFixed(1) : '-',
                                  trend: '$count reseñas',
                                  isPositive: rating >= 4.0,
                                  icon: Icons.star,
                                  color: Colors.amber.shade700,
                                );
                              }
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Tendencia — $_selectedRange',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2F3F2A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 220,
                          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2F3F2A).withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: StreamBuilder<List<double>>(
                            stream: VitrinaData.isFoundation 
                                ? _pymeService.getSevenDaysDonationCount(_currentPymeId)
                                : _pymeService.getSevenDaysSales(_currentPymeId),
                            builder: (context, AsyncSnapshot<List<double>> snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              List<double> dailyTotals = snapshot.data ?? List.filled(7, 0.0);
                              
                              // Create FlSpots
                              List<FlSpot> spots = [];
                              for (int i = 0; i < 7; i++) {
                                spots.add(FlSpot(i.toDouble(), dailyTotals[i]));
                              }
                              
                              // Check if we need to adjust max Y (in fl_chart, if max Y is 0 it gets weird)
                              double maxY = dailyTotals.reduce((a, b) => a > b ? a : b);
                              if (maxY == 0) maxY = 100; // default view if no sales
                              
                              return LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  minY: 0,
                                  maxY: maxY * 1.2, // add some padding to the top
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          const style = TextStyle(color: Colors.grey, fontSize: 10);
                                          // Calcular los días correctos base a hoy
                                          final todayStr = DateTime.now();
                                          final daysBase = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
                                          
                                          if (value >= 0 && value < 7) {
                                            int diff = 6 - value.toInt(); // 6 is today, 5 is yesterday, etc.
                                            final currentDay = todayStr.subtract(Duration(days: diff));
                                            return Text(daysBase[currentDay.weekday % 7], style: style);
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: const Color(0xFF6F8F5E),
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: const Color(0xFF6F8F5E).withOpacity(0.15),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                        ),
                        const SizedBox(height: 24),

                        const SizedBox(height: 32),
                      ],
                    );
                  }
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
     // Fetch products that are events
     return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products') 
            .where('pymeId', isEqualTo: _currentPymeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allProducts = snapshot.data!.docs;
          final events = allProducts.where((doc) {
             final data = doc.data() as Map<String, dynamic>;
             final attrs = data['customAttributes'] as Map<String, dynamic>?;
             return attrs != null && attrs['is_event'].toString().toLowerCase() == 'true';
          }).toList();

          if (events.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.event_available, size: 50, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   const Text('No has creado eventos aún.', style: TextStyle(
                     color: Color(0xFF2F3F2A),
                     fontSize: 16,
                   )),
                 ],
               ),
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
               final eventDoc = events[index];
               final eventData = eventDoc.data() as Map<String, dynamic>;
               final eventId = eventDoc.id;
               final eventName = eventData['name'] ?? 'Evento sin nombre';
               final eventDateStr = (eventData['customAttributes'] as Map?)?['event_date'] ?? 'Fecha pendiente';
               
               return Card(
                 color: const Color(0xFFFFFFFF),
                 elevation: 2,
                 margin: const EdgeInsets.only(bottom: 12),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 child: ListTile(
                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   leading: Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: const Color(0xFF6F8F5E).withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.event, color: Color(0xFF6F8F5E)),
                   ),
                   title: Text(eventName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2F3F2A))),
                   subtitle: Text('Fecha: $eventDateStr', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.6))),
                   trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2F3F2A)),
                   onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => PymeEventParticipantsScreen(
                           eventId: eventId,
                           eventName: eventName,
                         ),
                       ),
                     );
                   },
                 ),
               );
            },
          );
        },
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
        color: const Color(0xFFFFFFFF),
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
              // Trend indicator removed for simplicity/space
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
}
