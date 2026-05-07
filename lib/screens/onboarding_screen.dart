import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          'Conecta con fundaciones locales. Cada aporte se transforma en progreso real para quienes más lo necesitan.',
      imageAsset: 'assets/images/onboarding_1.png',
      color: const Color(0xFF6F8F5E),
    ),
    OnboardingContent(
      title: 'Un ciclo donde todos ganan',
      description:
          'Al donar, mejoras tu entorno y desbloqueas beneficios exclusivos. Es nuestra forma de darte las gracias.',
      imageAsset: 'assets/images/onboarding_2.png',
      color: const Color(0xFF8B5A3C),
    ),
    OnboardingContent(
      title: 'Descubre tesoros en tu barrio',
      description:
          'Usa tus beneficios en Pymes locales. Desde cafeterías hasta talleres, apoya el talento de tu comunidad.',
      imageAsset: 'assets/images/onboarding_3.png',
      color: const Color(0xFF2F3F2A),
    ),
    OnboardingContent(
      title: 'Sigue el impacto real',
      description:
          'Visualiza metas de recaudación y celebra cada vez que completamos una misión juntos. Transparencia total.',
      imageAsset: 'assets/images/onboarding_4.png',
      color: const Color(0xFF6F8F5E),
    ),
  ];

  Future<void> _goToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA), // Cream background
      body: Stack(
        children: [
          // Dynamic Animated Background Decorator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            top: _currentPage.isEven ? -50 : -100,
            right: _currentPage.isEven ? -50 : null,
            left: !_currentPage.isEven ? -50 : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _contents[_currentPage].color.withOpacity(0.15),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 10),
                    child: TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        'Saltar',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F3F2A).withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _contents.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildPageContent(_contents[index], index);
                    },
                  ),
                ),
                
                // Bottom Control Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _contents.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _contents.length - 1) {
                              _goToLogin();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _contents[_currentPage].color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage == _contents.length - 1
                                ? 'Comenzar Ahora'
                                : 'Siguiente',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingContent content, int index) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedScale(
              scale: _currentPage == index ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _currentPage == index ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 500),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      content.imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          AnimatedSlide(
            offset: _currentPage == index ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutQuint,
            child: AnimatedOpacity(
              opacity: _currentPage == index ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Column(
                children: [
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F3F2A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF2F3F2A).withOpacity(0.7),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _contents[_currentPage].color
            : _contents[_currentPage].color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String imageAsset;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.color,
  });
}
