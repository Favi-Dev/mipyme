import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F3F2A),
      appBar: AppBar(
        title: Text('Configuración', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('General'),
          _buildSwitchTile('Notificaciones', 'Recibir alertas de ofertas y pedidos', _notifications, (val) => setState(() => _notifications = val)),
          _buildSwitchTile('Modo Oscuro', 'Cambiar la apariencia de la app', _darkMode, (val) => setState(() => _darkMode = val)),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Cuenta'),
          _buildActionTile('Editar Perfil', Icons.person_outline, () {}),
          _buildActionTile('Cambiar Contraseña', Icons.lock_outline, () {}),
          _buildActionTile('Privacidad y Seguridad', Icons.security, () {}),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4F1EA),
                foregroundColor: const Color(0xFF2F3F2A),
                elevation: 0,
                side: const BorderSide(color: Color(0xFF2F3F2A)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Cerrar Sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFF4F1EA)),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF2F3F2A).withOpacity(0.1), blurRadius: 5)],
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2F3F2A))),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6E6E6A))),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2F3F2A),
        trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF6F8F5E) : null),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF2F3F2A).withOpacity(0.1), blurRadius: 5)],
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2F3F2A)),
        onTap: onTap,
      ),
    );
  }

}
