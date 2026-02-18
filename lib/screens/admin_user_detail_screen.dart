import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import 'pyme_vitrina_settings_screen.dart'; 
import 'pyme_products_screen.dart';
import 'pyme_events_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AdminUserDetailScreen({super.key, required this.userData});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late bool _isSuspended;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _isSuspended = widget.userData['isSuspended'] == true;
  }

  Future<void> _toggleSuspension(bool value) async {
    try {
      await _adminService.suspendUser(widget.userData['id'], value);
      setState(() {
        _isSuspended = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Cuenta suspendida' : 'Suspensión levantada'),
            backgroundColor: value ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final user = widget.userData;
    final role = user['role'];
    final isPymeOrFoundation = role == 'pyme' || role == 'foundation';
    final isClient = role == 'client';

    String dateStr = 'N/A';
    if (user['createdAt'] != null) {
      if (user['createdAt'] is Timestamp) {
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format((user['createdAt'] as Timestamp).toDate());
      } else if (user['createdAt'] is String) {
        // Try parsing if string
        dateStr = user['createdAt'];
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA), // Match screenshot background
      appBar: AppBar(
        // title: Text(user['name'] ?? 'Detalle de Usuario'), // No data in title in screenshot
        backgroundColor: const Color(0xFFF4F1EA),
        foregroundColor: const Color(0xFF2F3F2A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF2F3F2A).withOpacity(0.1),
                    child: Icon(
                      isClient ? Icons.person : (role == 'foundation' ? Icons.volunteer_activism : Icons.store),
                      size: 40, 
                      color: const Color(0xFF2F3F2A)
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user['name'] ?? 'Sin Nombre',
                    style: GoogleFonts.poppins(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F3F2A)
                    ),
                  ),
                  Text(
                    user['email'] ?? 'Sin Email',
                    style: GoogleFonts.poppins(
                      fontSize: 14, 
                      color: const Color(0xFF2F3F2A).withOpacity(0.7)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Suspension Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5A3C).withOpacity(0.3)),
                boxShadow: const [
                   // Screenshot looks flat inside a container but has border
                ],
                // In screenshot: background seems slightly beige/greyish inside container, let's keep it simple
                color: const Color(0xFFF4F1EA).withOpacity(0.5), // Using default bg for now
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFF8B5A3C)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suspender Cuenta',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2F3F2A)),
                        ),
                        Text(
                          'Deshabilita el acceso y visibilidad',
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF2F3F2A).withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSuspended,
                    onChanged: _toggleSuspension,
                    activeThumbColor: const Color(0xFF6F8F5E), // Green when active? Or error color? Screenshot has grey when off.
                    // Let's use standard colors, user can refine.
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (isPymeOrFoundation) ...[
              Text(
                'Gestión de Contenido',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2F3F2A), fontSize: 16),
              ),
              const SizedBox(height: 16),

              _buildActionTile(
                context,
                icon: Icons.edit,
                title: 'Editar Perfil',
                subtitle: 'Información general, logo, descripción',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PymeVitrinaSettingsScreen(pymeId: widget.userData['id']),
                    ),
                  );
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.shopping_bag,
                title: 'Gestionar Productos',
                subtitle: 'Editar catálogo de productos',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PymeProductsScreen(pymeId: widget.userData['id']),
                    ),
                  );
                },
              ),
              _buildActionTile(
                context,
                icon: Icons.event,
                title: 'Gestionar Eventos/Talleres',
                subtitle: 'Editar calendario de actividades',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PymeEventsScreen(pymeId: widget.userData['id']),
                    ),
                  );
                },
              ),
            ] else if (isClient) ...[
               Text(
                'Información del Cliente',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2F3F2A), fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildInfoTile(context, 'Rol', 'Cliente'),
              _buildInfoTile(context, 'ID', user['id']),
              _buildInfoTile(context, 'Fecha Registro', dateStr),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        color: Colors.white.withOpacity(0.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2F3F2A)),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2F3F2A))),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF2F3F2A).withOpacity(0.6))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF2F3F2A)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, String value) {
     return Container(
      margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: const Color(0xFF2F3F2A))),
          Text(value, style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7))),
        ],
      ),
    );
  }
}
