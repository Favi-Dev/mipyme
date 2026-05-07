import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'package:mipyme/models/vitrina_data.dart';
import 'package:mipyme/models/user_profile.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/widgets/soy_plus_button.dart';

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
        debugPrint('[DEBUG] Login exitoso. Rol detectado: ${userProfile.role}');
        switch (userProfile.role) {
          case UserRole.client:
            // Always allow clients to enter, checks will be done contextually
            context.go('/client/home');
            break;
          case UserRole.pyme:
            VitrinaData.isFoundationUser = false;
            VitrinaData.setCategory('Comercio/retail');
            context.go('/pyme/home');
            break;
          case UserRole.foundation:
            VitrinaData.isFoundationUser = true;
            VitrinaData.setCategory('Educación y cultura');
            context.go('/pyme/home');
            break;
          case UserRole.admin:
            context.go('/admin/home');
            break;
          case UserRole.empresa:
            context.go('/empresa/home');
            break;
          case UserRole.storeManager:
            // Reutiliza la UI de Pyme, cargará datos de su tienda asignada
            context.go('/pyme/home');
            break;
        }
      } else {
        // Login retornó null: las credenciales son válidas en Auth pero no hay documento en Firestore
        debugPrint('[DEBUG] Login null: no se encontró documento de usuario en Firestore para este UID');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu cuenta existe pero no tiene datos. Contacta al administrador o recrea los usuarios de prueba.'),
              backgroundColor: Color(0xFFD32F2F),
              duration: Duration(seconds: 6),
            ),
          );
        }
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
      } else if (e.code == 'user-not-found' || 
                 e.code == 'wrong-password' || 
                 e.code == 'invalid-credential' ||
                 e.code == 'INVALID_LOGIN_CREDENTIALS') { // Newer code
        message = 'Credenciales incorrectas. Verifique correo y contraseña.';
      } else {
        message = 'Error (${e.code}): ${e.message}'; // Show raw error if unknown
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: const Color(0xFFD32F2F), // Red for error visibility
          action: action,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Login generic error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Error inesperado: $e'), 
           backgroundColor: const Color(0xFFD32F2F)
         ),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1D9),
      body: Stack(
        children: [
          // White Wave Background
          Positioned.fill(
            child: CustomPaint(
              painter: WhiteWavePainter(),
            ),
          ),
          Center(
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
              SoyPlusButton(
                text: 'Iniciar Sesión',
                onPressed: _login,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: SoyPlusTypography.textTheme.bodyMedium?.copyWith(color: SoyPlusColors.primary),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(
                      'Regístrate',
                      style: SoyPlusTypography.textTheme.labelLarge?.copyWith(
                        color: SoyPlusColors.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
      ],
    ),
    );
  }
}

class WhiteWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height * 0.7); // Start at 70% height
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.65,
        size.width * 0.5, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.75,
        size.width, size.height * 0.7);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
