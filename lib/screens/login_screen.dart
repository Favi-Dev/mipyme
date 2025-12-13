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
          destination = const PymeAppShell();
          break;
        case UserRole.foundation:
          VitrinaData.isFoundationUser = true;
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
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2DA),
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
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Iniciar Sesión'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: theme.textTheme.bodyMedium,
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
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
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
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAccessButton(
                        context,
                        'Cliente',
                        Icons.person,
                        theme.colorScheme.primary,
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
                        theme.colorScheme.secondary,
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
                        theme.colorScheme.tertiary,
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
