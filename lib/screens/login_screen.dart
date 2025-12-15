import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../client_app_shell.dart';
import '../pyme_app_shell.dart';
import '../admin_app_shell.dart';
import 'register_screen.dart';
import '../models/vitrina_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final role = await AuthService.login(email, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (role != null) {
      Widget destination;
      switch (role) {
        case UserRole.client:
          destination = const ClientAppShell();
          break;
        case UserRole.pyme:
          VitrinaData.isFoundationUser = false;
          VitrinaData.setCategory('Comercio/retail');
          destination = const PymeAppShell();
          break;
        case UserRole.foundation:
          VitrinaData.isFoundationUser = true;
          VitrinaData.setCategory('Educación y cultura');
          destination = const PymeAppShell();
          break;
        case UserRole.admin:
          destination = const AdminAppShell();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales incorrectas'),
          backgroundColor: Color(0xFF8B5A3C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1D9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/LOGOSOYPLUS.jpg', height: 200),
              const SizedBox(height: 24),
              Text(
                'Únete a SoyPlus',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2F3F2A),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Color(0xFF2F3F2A)),
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF2F3F2A)),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6F8F5E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Color(0xFF2F3F2A)),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF2F3F2A)),
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF2F3F2A).withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6F8F5E), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF2F3F2A).withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F8F5E),
                    foregroundColor: const Color(0xFFF4F1EA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF4F1EA),
                          ),
                        )
                      : Text(
                          'Iniciar Sesión',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Regístrate',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF6F8F5E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Quick Access Demo Buttons
              Column(
                children: [
                  Text(
                    'Accesos Rápidos (Demo)',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2F3F2A).withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAccessButton(
                        context,
                        'Cliente',
                        Icons.person,
                        const Color(0xFF6F8F5E),
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientAppShell()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAccessButton(
                        context,
                        'Pyme',
                        Icons.storefront,
                        const Color(0xFF8B5A3C),
                        () {
                          VitrinaData.setCategory('Comercio/retail');
                          VitrinaData.isFoundationUser = false;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PymeAppShell()),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAccessButton(
                        context,
                        'Fundación',
                        Icons.volunteer_activism,
                        const Color(0xFF2F3F2A),
                        () {
                          VitrinaData.setCategory('Educación y cultura');
                          VitrinaData.isFoundationUser = true;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PymeAppShell()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
