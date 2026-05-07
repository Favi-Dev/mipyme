import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';
import 'admin_user_detail_screen.dart';

class AdminPymeManagementScreen extends StatefulWidget {
  final String roleFilter; // 'pyme' or 'foundation'

  const AdminPymeManagementScreen({
    super.key,
    this.roleFilter = 'pyme',
  });

  @override
  State<AdminPymeManagementScreen> createState() => _AdminPymeManagementScreenState();
}

class _AdminPymeManagementScreenState extends State<AdminPymeManagementScreen> {
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'all'; // all, active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          widget.roleFilter == 'pyme' ? 'Pymes' : 'Fundaciones',
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
              const PopupMenuItem(value: 'active', child: Text('Activas')),
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
                _buildFilterChip('Activas', 'active'),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminService.getPymes(roleFilter: widget.roleFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];
                
                // Aplicar filtros locales si es necesario (ej: active)
                // Nota: Esto asume que el stream trae todo. Si el stream ya filtra, esto es redundante pero seguro.
                final filteredUsers = _selectedFilter == 'active' 
                    ? users.where((u) => u['isSuspended'] != true).toList()
                    : users;

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
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
          Icon(Icons.store_mall_directory_outlined, size: 64, color: const Color(0xFF8B5A3C).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No hay registros encontrados',
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B5A3C).withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final imageUrl = user['logoUrl'] ?? user['coverImageUrl'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminUserDetailScreen(
              userData: user,
            ),
          ),
        );
      },
      child: Container(
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
                ? Icon(
                    widget.roleFilter == 'pyme' ? Icons.store : Icons.volunteer_activism,
                    color: const Color(0xFF6F8F5E),
                  )
                : null,
          ),
          title: Text(
            user['commercialName'] ?? user['companyName'] ?? user['name'] ?? 'Pyme',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F3F2A),
            ),
          ),
          subtitle: Text(
            user['email'] ?? '',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
