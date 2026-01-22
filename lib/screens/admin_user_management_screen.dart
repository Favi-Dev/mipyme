import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Gestión de Usuarios',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
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
                  return name.contains(query) || email.contains(query);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No se encontraron usuarios'));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
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

  Widget _buildUserTile(BuildContext context, Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final userId = user['id'];
    final name = user['name'] ?? 'Sin Nombre';
    final email = user['email'] ?? 'Sin Email';
    final isSuspended = user['isSuspended'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuspended ? theme.colorScheme.error : theme.colorScheme.secondary,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondary),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            decoration: isSuspended ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          email,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
          onSelected: (value) async {
            if (value == 'ban') {
              _toggleSuspension(context, userId, !isSuspended);
            } else if (value == 'details') {
              // Show details (could use a simple dialog)
              _showUserDetails(context, user);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ban',
              child: Text(isSuspended ? 'Activar Cuenta' : 'Suspender Cuenta', style: theme.textTheme.bodyMedium),
            ),
            PopupMenuItem(
              value: 'details',
              child: Text('Ver Detalles', style: theme.textTheme.bodyMedium),
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
          SnackBar(content: Text(suspend ? 'Usuario suspendido' : 'Usuario activado')),
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
