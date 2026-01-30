import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all'; // all, subscription, donation

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
        title: Text(
          'Finanzas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3F2A),
          ),
        ),
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        centerTitle: false,
        leading: Navigator.of(context).canPop()
            ? const BackButton(color: Color(0xFF2F3F2A))
            : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6F8F5E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6F8F5E),
          tabs: const [
            Tab(text: 'Historial'),
            Tab(text: 'Liquidaciones a Pymes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildPayoutsTab(),
        ],
      ),
    );
  }

  // --- TAB 1: HISTORIAL ---
  Widget _buildHistoryTab() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Todas', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Suscripciones App', 'subscription'),
              const SizedBox(width: 8),
              _buildFilterChip('Donaciones', 'donation'),
            ],
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getTransactionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No hay transacciones registradas');
              }

              final docs = snapshot.data!.docs;
              double totalAmount = 0;
              for (var doc in docs) {
                totalAmount += ((doc.data() as Map)['amount'] ?? 0).toDouble();
              }

              return Column(
                children: [
                  _buildSummaryCard(totalAmount, 'Total Recaudado (Histórico)'),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _buildTransactionCard(data);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: LIQUIDACIONES (Nuevo Reporte) ---
  Widget _buildPayoutsTab() {
    // Filtramos donaciones y ventas que requieren transferencia a terceros
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('payments')
          .where('type', whereIn: ['donation', 'product_sale'])
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No hay pagos pendientes de liquidar');
        }

        // Agrupar por PymeId
        final Map<String, double> pymeTotals = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final pymeId = data['pymeId'] as String?;
          final amount = (data['amount'] ?? 0).toDouble();
          
          if (pymeId != null) {
            pymeTotals[pymeId] = (pymeTotals[pymeId] ?? 0) + amount;
          }
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pymeTotals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pymeId = pymeTotals.keys.elementAt(index);
            final totalAmount = pymeTotals[pymeId]!;

            // Fetch Pyme Data
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(pymeId).get(),
              builder: (context, pymeSnapshot) {
                if (!pymeSnapshot.hasData) return const SizedBox(); // Loading row
                
                final pymeData = pymeSnapshot.data!.data() as Map<String, dynamic>?;
                final pymeName = pymeData?['name'] ?? 'Pyme desconocida';
                
                // Bank Data
                final bankName = pymeData?['bankName'] ?? 'No registrado';
                final accountType = pymeData?['bankAccountType'] ?? '';
                final accountNumber = pymeData?['bankAccountNumber'] ?? '';
                final holderRut = pymeData?['bankAccountHolderRut'] ?? '';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6F8F5E).withOpacity(0.2),
                      child: const Icon(Icons.store, color: Color(0xFF6F8F5E)),
                    ),
                    title: Text(
                      pymeName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Total a transferir: ${NumberFormat.currency(locale: 'es_CL', symbol: '\$').format(totalAmount)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2F3F2A),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(),
                            Text('Datos Bancarios para Transferencia:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _buildDetailRow('Banco:', bankName),
                            _buildDetailRow('Tipo Cuenta:', accountType),
                            _buildDetailRow('N° Cuenta:', accountNumber),
                            _buildDetailRow('RUT Titular:', holderRut),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Aquí podrías marcar como pagado en BD
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Acción: Transferencia Registrada (Simulado)')),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Marcar como Transferido'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F8F5E),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double amount, String title) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3F2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(locale: 'es_CL', symbol: '\$').format(amount),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.attach_money, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6F8F5E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF6F8F5E).withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : const Color(0xFF6F8F5E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final type = data['type'];
    final isSubscription = type == 'mandatory_subscription';
    final amount = (data['amount'] ?? 0).toDouble();
    final date = data['date'] is Timestamp 
        ? (data['date'] as Timestamp).toDate() 
        : DateTime.now();

    IconData icon;
    Color color;
    String title;

    if (isSubscription) {
      icon = Icons.card_membership;
      color = const Color(0xFF6F8F5E);
      title = 'Suscripción App';
    } else if (type == 'donation') {
      icon = Icons.volunteer_activism;
      color = const Color(0xFF8B5A3C);
      title = 'Donación';
    } else {
      icon = Icons.shopping_bag;
      color = Colors.blueGrey;
      title = 'Venta Producto';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          data['description'] ?? title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2F3F2A)),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(date),
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          NumberFormat.currency(locale: 'es_CL', symbol: '\$').format(amount),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3F2A),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    Query query = _firestore.collection('payments').orderBy('date', descending: true);
    
    if (_selectedFilter == 'subscription') {
      query = query.where('type', isEqualTo: 'mandatory_subscription');
    } else if (_selectedFilter == 'donation') {
       query = query.where('type', isEqualTo: 'donation');
    }
    return query.snapshots();
  }
}
