import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pyme_service.dart';
import '../models/user_profile.dart';
import 'pyme_vitrina_settings_screen.dart';
import 'pyme_support_screen.dart';
import 'login_screen.dart';
import 'client_payment_methods_screen.dart';

class PymeProfileScreen extends StatefulWidget {
  const PymeProfileScreen({super.key});

  @override
  State<PymeProfileScreen> createState() => _PymeProfileScreenState();
}

class _PymeProfileScreenState extends State<PymeProfileScreen> {
  final PymeService _pymeService = PymeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  void _changePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: const Text(
            'Se enviará un correo electrónico a tu dirección registrada para restablecer tu contraseña.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final email = _auth.currentUser?.email;
                if (email != null) {
                  await _auth.sendPasswordResetEmail(email: email);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Correo enviado a $email')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Enviar Correo'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Términos y Condiciones'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Términos y Condiciones de Uso', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('• El uso de esta aplicación está sujeto a las leyes vigentes.', style: TextStyle(fontSize: 14)),
              Text('• Respetamos tu privacidad y datos personales.', style: TextStyle(fontSize: 14)),
              Text('• Las transacciones son seguras y procesadas por proveedores confiables.', style: TextStyle(fontSize: 14)),
              SizedBox(height: 10),
              Text('Para más detalles, visita nuestro sitio web oficial.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const SizedBox();

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
      body: FutureBuilder<UserProfile?>(
        future: _pymeService.getPymeById(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;
          if (userData == null) {
             return const Center(child: Text('Error al cargar el perfil'));
          }
          
          final companyName = userData.name;
          final email = userData.email;
          final logoUrl = userData.logoUrl;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProfileHeader(companyName, email, logoUrl),
              const SizedBox(height: 24),
              _buildSectionTitle('Cuenta'),
              _buildOptionTile(
                icon: Icons.person_outline,
                title: 'Editar Perfil',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PymeVitrinaSettingsScreen(),
                    ),
                  );
                  setState(() {}); // Refresh after edit
                },
              ),
              _buildOptionTile(
                icon: Icons.credit_card,
                title: 'Métodos de Pago',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClientPaymentMethodsScreen()),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contraseña',
                onTap: () {
                  _changePassword(context);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Configuración'),
              SwitchListTile(
                  title: Text(
                    'Notificaciones',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: const Color(0xFF2F3F2A),
                    ),
                  ),
                  value: true, 
                  activeColor: const Color(0xFF6F8F5E),
                  onChanged: (val) {},
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F8F5E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Color(0xFF6F8F5E), size: 20),
                  ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Soporte'),
              _buildOptionTile(
                icon: Icons.help_outline,
                title: 'Ayuda y Soporte',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PymeSupportScreen()),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.info_outline,
                title: 'Términos y Condiciones',
                onTap: () {
                   _showTerms(context);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5A3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? logoUrl) {
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
            backgroundImage: logoUrl != null && logoUrl.isNotEmpty
                ? NetworkImage(logoUrl)
                : null,
            child: logoUrl == null || logoUrl.isEmpty
                ? const Icon(Icons.store, size: 30, color: Color(0xFF6F8F5E))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2F3F2A),
                  ),
                ),
                Text(
                  email,
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
