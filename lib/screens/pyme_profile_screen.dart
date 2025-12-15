import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class PymeProfileScreen extends StatelessWidget {
  const PymeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2F3F2A),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF4F1EA),
        foregroundColor: const Color(0xFF2F3F2A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSectionTitle('Cuenta'),
          _buildOptionTile(
            icon: Icons.person_outline,
            title: 'Editar Perfil',
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          _buildOptionTile(
            icon: Icons.lock_outline,
            title: 'Cambiar Contraseña',
            onTap: () {
              // TODO: Navigate to change password
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Configuración'),
          _buildOptionTile(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          _buildOptionTile(
            icon: Icons.language,
            title: 'Idioma',
            subtitle: 'Español',
            onTap: () {
              // TODO: Change language
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Soporte'),
          _buildOptionTile(
            icon: Icons.help_outline,
            title: 'Ayuda y Soporte',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          _buildOptionTile(
            icon: Icons.info_outline,
            title: 'Términos y Condiciones',
            onTap: () {
              // TODO: Show terms
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5A3C).withOpacity(0.1),
              foregroundColor: const Color(0xFF8B5A3C),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6F8F5E).withOpacity(0.2),
            child: const Icon(Icons.store, size: 30, color: Color(0xFF6F8F5E)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Negocio',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2F3F2A),
                  ),
                ),
                Text(
                  'admin@minegocio.cl',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3F2A).withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2F3F2A),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6F8F5E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6F8F5E), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: const Color(0xFF2F3F2A),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}
