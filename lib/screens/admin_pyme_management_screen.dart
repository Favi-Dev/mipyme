import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_pyme_detail_screen.dart';

class AdminPymeManagementScreen extends StatelessWidget {
  final String? roleFilter;
  
  const AdminPymeManagementScreen({super.key, this.roleFilter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminService = AdminService();
    
    String title = 'Gestión de Pymes y Fundaciones';
    if (roleFilter == 'pyme') title = 'Gestión de Pymes';
    if (roleFilter == 'foundation') title = 'Gestión de Fundaciones';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: _PymeList(adminService: adminService, roleFilter: roleFilter),
    );
  }
}

class _PymeList extends StatelessWidget {
  final AdminService adminService;
  final String? roleFilter;

  const _PymeList({required this.adminService, this.roleFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: adminService.getPymes(roleFilter: roleFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pymes = snapshot.data ?? [];
        if (pymes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_mall_directory,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay pymes registradas',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pymes.length,
          itemBuilder: (context, index) {
            final pyme = pymes[index];
            return _PymeTile(pyme: pyme, adminService: adminService);
          },
        );
      },
    );
  }
}

class _PymeTile extends StatelessWidget {
  final Map<String, dynamic> pyme;
  final AdminService adminService;

  const _PymeTile({
    required this.pyme,
    required this.adminService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pymeId = pyme['id'];
    final name = pyme['companyName'] ?? pyme['name'] ?? 'Sin Nombre';
    final category = pyme['category'] ?? 'Sin Categoría';
    final address = pyme['address'] ?? 'Sin Dirección';
    final isSuspended = pyme['isSuspended'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.store, color: theme.colorScheme.primary),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$category • $address',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isSuspended
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Suspendido',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminPymeDetailScreen(
                pymeData: pyme,
              ),
            ),
          );
        },
      ),
    );
  }
}
