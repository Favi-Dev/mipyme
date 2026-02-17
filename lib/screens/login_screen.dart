import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../services/seeding_service.dart';
import '../client_app_shell.dart';
import '../pyme_app_shell.dart';
import '../admin_app_shell.dart';
import 'register_screen.dart';
import 'subscription_blocker_screen.dart';
import 'guest_foundations_screen.dart';
import '../models/vitrina_data.dart';
import '../models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userProfile = await _authService.login(email, password);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (userProfile != null) {
        Widget destination;
        switch (userProfile.role) {
          case UserRole.client:
            // Check subscription status for clients
            if (userProfile.isSubscribed) {
              destination = const ClientAppShell();
            } else {
              destination = const SubscriptionBlockerScreen();
            }
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
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String message = 'Error al iniciar sesión: ${e.message}';
      
      SnackBarAction? action;
      
      if (e.code == 'email-not-verified') {
        message = 'Por favor verifica tu correo electrónico para iniciar sesión.';
        action = SnackBarAction(
          label: 'REENVIAR',
          textColor: const Color(0xFFF4F1EA),
          onPressed: () async {
            try {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              
              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa tu correo y contraseña para reenviar.')),
                );
                return;
              }

              await _authService.resendVerificationEmail(email, password);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Correo de verificación enviado. Revisa tu bandeja de entrada.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al reenviar: $e')),
                );
              }
            }
          },
        );
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Credenciales incorrectas';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: const Color(0xFF8B5A3C),
          action: action,
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (!mounted) return; // Prevent setState if unmounted
      setState(() => _isLoading = false);
      print('Login error: $e'); // Log for debugging

      String message = 'Error inesperado';
      if (e is FirebaseAuthException) { // Re-check if it was missed by the on clause or wrapped
        if (e.code == 'email-not-verified') {
             message = 'Por favor verifica tu correo electrónico antes de iniciar sesión';
        } else if (e.code == 'invalid-credential') {
             message = 'Credenciales incorrectas';
        }
      }
      
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B5A3C)),
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
              Image.asset('assets/images/LOGOSOYPLUS.png', height: 200),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3F2A),
                    fontSize: 20,
                  ),
                  children: [
                    const TextSpan(text: '¡Bienvenido de nuevo a '),
                    TextSpan(
                      text: 'SoyPlus',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const TextSpan(text: '!'),
                  ],
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
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GuestFoundationsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.volunteer_activism, color: Color(0xFF8B5A3C)),
                label: Text(
                  'Donar como Invitado',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B5A3C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
