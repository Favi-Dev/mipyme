import 'package:flutter/material.dart';
import 'pyme_app_shell.dart';
import 'client_app_shell.dart';
import 'admin_app_shell.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Icon(Icons.coffee, size: 80, color: Color(0xFFFF6B6B)),
              const SizedBox(height: 24),
              const Text(
                'SoyPlus',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona tu perfil para ingresar',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 48),
              _buildRoleButton(
                context,
                'Cliente',
                'Busco ofertas y pymes',
                Icons.person,
                const Color(0xFFFF6B6B),
                const ClientAppShell(),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Pyme',
                'Gestiono mi negocio',
                Icons.storefront,
                const Color(0xFF4ECDC4),
                const PymeAppShell(),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Administrador',
                'Gestión de plataforma',
                Icons.admin_panel_settings,
                const Color(0xFFFFD93D),
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
      IconData icon, Color color, Widget destination) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: () {
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
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.grey[300], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
