import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Tu ayuda echa raíces aquí',
      description:
          'Conecta con fundaciones locales. Cada aporte se transforma en talleres y bienestar para quienes más lo necesitan.',
      imageAsset: 'assets/images/onboarding_1.png',
      icon: Icons.volunteer_activism,
    ),
    OnboardingContent(
      title: 'Un ciclo donde todos ganan',
      description:
          'Al donar, desbloqueas beneficios exclusivos. Es nuestra forma de agradecerte por impulsar el cambio social.',
      imageAsset: 'assets/images/onboarding_2.png',
      icon: Icons.sync_rounded, // Changed icon to represent cycle
    ),
    OnboardingContent(
      title: 'Descubre tesoros en tu barrio',
      description:
          'Usa tus beneficios en Pymes locales. Desde artesanías hasta cafeterías, apoya el talento de tu comunidad.',
      imageAsset: 'assets/images/onboarding_3.png',
      icon: Icons.storefront, // Changed icon to represent local shop
    ),
    OnboardingContent(
      title: 'Sigue el impacto real',
      description:
          'Visualiza las metas de recaudación y celebra cada vez que completamos una misión juntos. Transparencia total.',
      imageAsset: 'assets/images/onboarding_4.png',
      icon: Icons.trending_up, // Changed icon to represent metrics/goals
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo superior (crema #fcf1d9)
      backgroundColor: const Color(0xFFFCF1D9),
      body: Stack(
        children: [
          // Contenido Principal (PageView)
          PageView.builder(
            controller: _pageController,
            itemCount: _contents.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _OnboardingPage(
                content: _contents[index],
                colorScheme: colorScheme,
              );
            },
          ),

          // Indicadores (Puntos) - Arriba al centro
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _contents.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF2F3F2A)
                        : const Color(0xFF2F3F2A).withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          // Botón Saltar - Arriba a la derecha
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _goToLogin,
              child: Text(
                'Saltar',
                style: TextStyle(
                  color: const Color(0xFF2F3F2A).withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Botón de Acción (Flecha o "Únete al cambio") - Abajo
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: _currentPage == _contents.length - 1
                ? SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _goToRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Únete al cambio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomRight,
                    child: FloatingActionButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: colorScheme.primary,
                      elevation: 4,
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String imageAsset;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.icon,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingContent content;
  final ColorScheme colorScheme;

  const _OnboardingPage({
    required this.content,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Altura de la ola (parte inferior)
    final bottomHeight = size.height * 0.45;

    return Stack(
      children: [
        // 1. Imagen / Ilustración (Parte Superior)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: bottomHeight - 50, // Dejar que se solape un poco con la ola
          child: Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      content.imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Fondo con Ola (Parte Inferior)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: bottomHeight,
          child: ClipPath(
            clipper: WaveClipper(),
            child: Container(
              color: colorScheme.primary, // Verde Oscuro (Deep Leaf Green)
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary, // Blanco Cálido
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onPrimary.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Clipper para la forma de ola
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    // Empezamos un poco más abajo del borde superior izquierdo
    path.lineTo(0, 40);

    // Primer punto de control y punto final para la primera curva (bajada)
    var firstControlPoint = Offset(size.width / 4, 80);
    var firstEndPoint = Offset(size.width / 2, 40);

    // Segundo punto de control y punto final para la segunda curva (subida)
    var secondControlPoint = Offset(size.width * 3 / 4, 0);
    var secondEndPoint = Offset(size.width, 40);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    // Cerramos el path hacia abajo
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
