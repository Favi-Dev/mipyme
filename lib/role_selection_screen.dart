import 'package:flutter/material.dart';
import 'pyme_app_shell.dart';
import 'client_app_shell.dart';
import 'admin_app_shell.dart';
import 'models/vitrina_data.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Image.asset('assets/images/LOGOSOYPLUS.jpg', height: 200),
              const SizedBox(height: 24),
              Text(
                'Selecciona tu perfil para ingresar',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              _buildRoleButton(
                context,
                'Cliente',
                'Busco ofertas y pymes',
                Icons.person,
                theme.colorScheme.primary,
                const ClientAppShell(),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Pyme',
                'Gestiono mi negocio',
                Icons.storefront,
                theme.colorScheme.secondary,
                const PymeAppShell(),
                onTap: () {
                  VitrinaData.setCategory('Comercio/retail');
                  VitrinaData.isFoundationUser = false;
                },
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Fundación',
                'Gestiono mi fundación',
                Icons.volunteer_activism,
                theme.colorScheme.tertiary,
                const PymeAppShell(),
                onTap: () {
                  VitrinaData.setCategory('Educación y cultura');
                  VitrinaData.isFoundationUser = true;
                },
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Administrador',
                'Gestión de plataforma',
                Icons.admin_panel_settings,
                theme.colorScheme.onSurface,
                const AdminAppShell(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String title, String subtitle,
      IconData icon, Color color, Widget destination, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
