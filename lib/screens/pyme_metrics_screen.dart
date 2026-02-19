import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vitrina_data.dart';
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
             StreamBuilder<Map<String, dynamic>>(
              stream: _pymeService.getPymeMetrics(_currentPymeId), // Streams confirmed sales from payments
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

                    return GridView.count(
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
