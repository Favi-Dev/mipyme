import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';
// Note: We'll likely need to refactor these screens to accept pymeId or create Admin versions
import 'pyme_vitrina_settings_screen.dart'; 
import 'pyme_products_screen.dart';
import 'pyme_events_screen.dart';

class AdminPymeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pymeData;

  const AdminPymeDetailScreen({super.key, required this.pymeData});

  @override
  State<AdminPymeDetailScreen> createState() => _AdminPymeDetailScreenState();
}

class _AdminPymeDetailScreenState extends State<AdminPymeDetailScreen> {
  late bool _isSuspended;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _isSuspended = widget.pymeData['isSuspended'] == true;
  }

  Future<void> _toggleSuspension(bool value) async {
    try {
      await _adminService.suspendUser(widget.pymeData['id'], value);
      setState(() {
        _isSuspended = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Pyme suspendida' : 'Suspensión levantada'),
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
    final theme = Theme.of(context);
    final pyme = widget.pymeData;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(pyme['name'] ?? 'Detalle de Pyme'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
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
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.store, size: 40, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pyme['name'] ?? 'Sin Nombre',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    pyme['email'] ?? 'Sin Email',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Suspension Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.report_problem, color: theme.colorScheme.error),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suspender Cuenta',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Deshabilita el acceso y visibilidad',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSuspended,
                    onChanged: _toggleSuspension,
                    activeColor: theme.colorScheme.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Gestión de Contenido',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    builder: (context) => PymeVitrinaSettingsScreen(pymeId: widget.pymeData['id']),
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
                    builder: (context) => PymeProductsScreen(pymeId: widget.pymeData['id']),
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
                    builder: (context) => PymeEventsScreen(pymeId: widget.pymeData['id']),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
