import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all'; // all, subscription, donation

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Transacciones',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3F2A),
          ),
        ),
        backgroundColor: const Color(0xFFF4F1EA),
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFF2F3F2A)),
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              const PopupMenuItem(value: 'subscription', child: Text('Suscripciones')),
              const PopupMenuItem(value: 'donation', child: Text('Donaciones')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todas', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Suscripciones', 'subscription'),
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

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;
                double totalAmount = 0;
                for (var doc in docs) {
                  totalAmount += ((doc.data() as Map)['amount'] ?? 0).toDouble();
                }

                return Column(
                  children: [
                    // Summary Card
                    Container(
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
                                'Total Ingresos',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(locale: 'es_CL', symbol: '\$').format(totalAmount),
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
                    ),

                    // List
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No hay transacciones registradas',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final isSubscription = data['type'] == 'mandatory_subscription';
    final amount = (data['amount'] ?? 0).toDouble();
    final date = data['date'] is Timestamp 
        ? (data['date'] as Timestamp).toDate() 
        : DateTime.now();

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
            color: (isSubscription ? const Color(0xFF6F8F5E) : const Color(0xFF8B5A3C)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSubscription ? Icons.card_membership : Icons.volunteer_activism,
            color: isSubscription ? const Color(0xFF6F8F5E) : const Color(0xFF8B5A3C),
          ),
        ),
        title: Text(
          isSubscription ? 'Suscripción Mensual' : 'Donación',
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

  Stream<QuerySnapshot> _getTransactionsStream() {
    Query query;
    // We look at 'payments' collection now (as implemented in client_subscription_screen)
    // and potentially 'donations' if you store donations separately.
    // For simplicity, let's assume we started storing everything in 'payments' OR 
    // we query 'payments'. If donations are elsewhere, we might need a unified query or logic.
    // Based on client_subscription_screen, we use 'payments' for subscriptions.
    
    // Let's assume for this version we query 'payments' collection.
    // If you need donations from 'donations' collection, we'd need to merge or rethink structure.
    // For now, I'll query 'payments' and handle filter.
    
    query = _firestore.collection('payments').orderBy('date', descending: true);
    
    if (_selectedFilter == 'subscription') {
      query = query.where('type', isEqualTo: 'mandatory_subscription');
    } else if (_selectedFilter == 'donation') {
       query = query.where('type', isEqualTo: 'donation');
    }
    
    // Note: If you have donations in a separate collection 'donations' (as seen in donation_screen.dart),
    // you won't see them here unless we merge or migrate. 
    // Recommendation: Future refactor to unify all money transactions in one collection.
    
    return query.snapshots();
  }
}
