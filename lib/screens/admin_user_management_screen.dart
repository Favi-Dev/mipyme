import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

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
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildUserTile(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, int index) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondary,
          child: Text(
            'U${index + 1}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondary),
          ),
        ),
        title: Text(
          'Usuario ${index + 1}',
          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          'usuario${index + 1}@email.com',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'ban',
              child: Text('Suspender Cuenta', style: theme.textTheme.bodyMedium),
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
}
