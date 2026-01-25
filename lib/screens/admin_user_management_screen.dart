import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, suspended

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Usuarios',
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
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(value: 'suspended', child: Text('Suspendidos')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags Row (Optional visual aid alongside Popup)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Suspendidos', 'suspended'),
              ],
            ),
          ),
          
          // Search Bar styled
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A)),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6F8F5E)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _adminService.getClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final users = snapshot.data ?? [];
                
                final filteredUsers = users.where((u) {
                  final name = (u['name'] ?? '').toString().toLowerCase();
                  final email = (u['email'] ?? '').toString().toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = name.contains(query) || email.contains(query);
                  
                  if (_selectedFilter == 'suspended') {
                    return matchesSearch && (u['isSuspended'] == true);
                  }
                  return matchesSearch;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildUserTile(context, filteredUsers[index]);
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
          Icon(Icons.person_off_outlined, size: 64, color: const Color(0xFF8B5A3C).withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No se encontraron usuarios',
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B5A3C).withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    final userId = user['id'];
    final name = user['name'] ?? 'Sin Nombre';
    final email = user['email'] ?? 'Sin Email';
    final isSuspended = user['isSuspended'] == true;

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
          backgroundColor: isSuspended 
              ? Colors.red.withOpacity(0.1) 
              : const Color(0xFFF4F1EA),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: GoogleFonts.poppins(
              color: isSuspended ? Colors.red : const Color(0xFF6F8F5E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3F2A),
            decoration: isSuspended ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          email,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) async {
            if (value == 'ban') {
              _toggleSuspension(context, userId, !isSuspended);
            } else if (value == 'details') {
              _showUserDetails(context, user);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ban',
              child: Row(
                children: [
                  Icon(
                    isSuspended ? Icons.check_circle_outline : Icons.block,
                    color: isSuspended ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSuspended ? 'Activar Cuenta' : 'Suspender Cuenta',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  Text('Ver Detalles', style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSuspension(BuildContext context, String userId, bool suspend) async {
    try {
      await _adminService.suspendUser(userId, suspend);
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              suspend ? 'Usuario suspendido' : 'Usuario activado',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: suspend ? Colors.redAccent : const Color(0xFF6F8F5E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => AdminUserDetailScreen(userData: user),
       ),
     );
  }
}
