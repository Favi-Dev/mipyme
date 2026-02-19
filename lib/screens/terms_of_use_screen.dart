import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class TermsOfUseScreen extends StatefulWidget {
  const TermsOfUseScreen({super.key});

  @override
  State<TermsOfUseScreen> createState() => _TermsOfUseScreenState();
}

class _TermsOfUseScreenState extends State<TermsOfUseScreen> {
  final AuthService _authService = AuthService();

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
          'Tu cuenta será programada para eliminación en 30 días. Si inicias sesión durante este periodo, la eliminación se cancelará.\n\nEsta acción cerrará tu sesión actual de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _authService.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta programada para eliminación.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2F3F2A)),
        ),
        backgroundColor: const Color(0xFFF4F1EA),
        foregroundColor: const Color(0xFF2F3F2A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos de Uso y Privacidad',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2F3F2A)),
            ),
            const SizedBox(height: 16),
            _buildSection('1. Uso de la Aplicación', 'El uso de esta aplicación está sujeto a las leyes vigentes y a las normas de convivencia de la comunidad.'),
            _buildSection('2. Privacidad de Datos', 'Respetamos tu privacidad. Tus datos personales son utilizados únicamente para mejorar tu experiencia y no son compartidos con terceros sin tu consentimiento.'),
            _buildSection('3. Transacciones Seguras', 'Todas las transacciones realizadas a través de la aplicación son procesadas por proveedores de pago seguros y certificados.'),
            _buildSection('4. Responsabilidad del Usuario', 'Eres responsable de mantener la confidencialidad de tu cuenta y contraseña via acceso seguro.'),
            _buildSection('5. Cancelación de Cuenta', 'Tienes derecho a cancelar tu cuenta en cualquier momento. Al hacerlo, tus datos serán eliminados permanentemente después del periodo de retención legal.'),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            
            Text(
              'Zona de Peligro',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              'Si deseas eliminar tu cuenta permanentemente, puedes hacerlo aquí. Esta acción no se puede deshacer inmediatamente.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteAccount(context),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Eliminar Mi Cuenta', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(content, style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
