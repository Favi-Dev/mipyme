import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPymeManagementScreen extends StatelessWidget {
  const AdminPymeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            'Gestión de Pymes',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Activas'),
              Tab(text: 'Pendientes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPymeList(context, active: true),
            _buildPymeList(context, active: false),
          ],
        ),
      ),
    );
  }

  Widget _buildPymeList(BuildContext context, {required bool active}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildPymeTile(context, index, active);
      },
    );
  }

  Widget _buildPymeTile(BuildContext context, int index, bool active) {
    final theme = Theme.of(context);
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
            image: DecorationImage(
              image: NetworkImage('https://picsum.photos/seed/${index + 50}/100/100'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          active ? 'Pyme Activa ${index + 1}' : 'Solicitud Pyme ${index + 1}',
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Categoría • Dirección',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: active
            ? Icon(Icons.check_circle, color: theme.colorScheme.secondary)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: theme.colorScheme.secondary),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.error),
                    onPressed: () {},
                  ),
                ],
              ),
      ),
    );
  }
}
