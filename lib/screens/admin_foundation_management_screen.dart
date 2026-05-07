import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';

class AdminFoundationManagementScreen extends StatefulWidget {
  const AdminFoundationManagementScreen({super.key});

  @override
  State<AdminFoundationManagementScreen> createState() => _AdminFoundationManagementScreenState();
}

class _AdminFoundationManagementScreenState extends State<AdminFoundationManagementScreen> {
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'all'; // all, verified, pending

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Fundaciones',
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Color(0xFF2F3F2A)),
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todas')),
              const PopupMenuItem(value: 'verified', child: Text('Verificadas')),
              // const PopupMenuItem(value: 'pending', child: Text('Pendientes')),
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
                _buildFilterChip('Verificadas', 'verified'),
                // const SizedBox(width: 8),
                // _buildFilterChip('Pendientes', 'pending'),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminService.getPymes(roleFilter: 'foundation'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Apply local filters if needed (though service filters by role)
                final foundations = snapshot.data!;
                // Example filter logic if we had verification status
                // final filtered = _selectedFilter == 'all' ? foundations : foundations.where(...); 

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: foundations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildFoundationCard(foundations[index]);
                  },
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
          Icon(Icons.volunteer_activism, size: 64, color: const Color(0xFF8B5A3C).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No hay fundaciones registradas',
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B5A3C).withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundationCard(Map<String, dynamic> foundation) {
    final imageUrl = foundation['logoUrl'] ?? foundation['coverImageUrl'];
    
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFF4F1EA),
          backgroundImage: (imageUrl != null && imageUrl.startsWith('http'))
              ? NetworkImage(imageUrl)
              : null,
          child: (imageUrl == null || !imageUrl.startsWith('http'))
              ? const Icon(Icons.volunteer_activism, color: Color(0xFF6F8F5E))
              : null,
        ),
        title: Text(
          foundation['companyName'] ?? foundation['name'] ?? 'Fundación',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3F2A),
          ),
        ),
        subtitle: Text(
          foundation['email'] ?? '',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6F8F5E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Activo',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF6F8F5E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
