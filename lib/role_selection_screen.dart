import 'package:flutter/material.dart';
import 'pyme_app_shell.dart';
import 'client_app_shell.dart';
import 'admin_app_shell.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Icon(Icons.coffee, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                'Soy Pro Pyme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona tu perfil para ingresar',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              _buildRoleButton(
                context,
                'Cliente',
                'Busco ofertas y pymes',
                Icons.person,
                Colors.amber,
                const ClientAppShell(),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Pyme',
                'Gestiono mi negocio',
                Icons.storefront,
                Colors.deepPurpleAccent,
                const PymeAppShell(),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                'Administrador',
                'Gestión de plataforma',
                Icons.admin_panel_settings,
                Colors.cyanAccent,
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
      color: const Color(0xFF2C2C3E),
      borderRadius: BorderRadius.circular(16),
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
                  color: color.withOpacity(0.2),
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
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
