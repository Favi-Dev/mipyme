import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'client_payment_methods_screen.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B6B), width: 3),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/300'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Joaquin',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Plan Premium',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Menu Options
            _buildProfileOption(
              context,
              icon: Icons.confirmation_number,
              title: 'Mi Cupón',
              onTap: () {},
            ),
            _buildProfileOption(
              context,
              icon: Icons.history,
              title: 'Historial de Visitas',
              onTap: () {},
            ),
            _buildProfileOption(
              context,
              icon: Icons.payment,
              title: 'Métodos de Pago',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientPaymentMethodsScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () {},
            ),
            _buildProfileOption(
              context,
              icon: Icons.help,
              title: 'Ayuda y Soporte',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            _buildProfileOption(
              context,
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color == Colors.redAccent 
              ? Colors.redAccent.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.withOpacity(0.5), size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}
