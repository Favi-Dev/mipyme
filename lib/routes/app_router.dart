import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_service.dart';
import '../models/user_profile.dart';

// Screens
import '../screens/login_screen.dart';
import '../screens/client_home_screen.dart';
import '../screens/client_map_screen.dart';
import '../screens/client_cart_screen.dart';
import '../screens/client_qr_screen.dart';
import '../screens/client_profile_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/register_screen.dart';
import '../screens/donation_screen.dart';
import '../screens/client_pyme_detail_screen.dart';
import '../screens/client_subscription_screen.dart';
import '../models/user_profile.dart';
import '../pyme_app_shell.dart';
import '../admin_app_shell.dart';
import '../empresa_app_shell.dart';

// Definición de las claves del navegador para mantener el estado
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Busca el documento del usuario en las 4 colecciones posibles
Future<DocumentSnapshot?> _findUserDocumentForRouter(String uid) async {
  final fs = FirebaseFirestore.instance;
  final clientDoc = await fs.collection('clients').doc(uid).get();
  if (clientDoc.exists) return clientDoc;
  final pymeDoc = await fs.collection('pymes').doc(uid).get();
  if (pymeDoc.exists) return pymeDoc;
  final foundationDoc = await fs.collection('foundations').doc(uid).get();
  if (foundationDoc.exists) return foundationDoc;
  final adminDoc = await fs.collection('admins').doc(uid).get();
  if (adminDoc.exists) return adminDoc;
  final empresaDoc = await fs.collection('empresas').doc(uid).get();
  if (empresaDoc.exists) return empresaDoc;
  final storeManagerDoc = await fs.collection('store_managers').doc(uid).get();
  if (storeManagerDoc.exists) return storeManagerDoc;
  return null;
}

// Rutas que no requieren sesión activa
const _publicRoutes = ['/onboarding', '/login', '/register'];

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.uri.path;

      // Si no hay sesión y va a ruta privada, verificar si ya vio el onboarding
      if (user == null) {
        if (location == '/onboarding') {
          // Verificar si ya vio el onboarding
          final prefs = await SharedPreferences.getInstance();
          final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
          if (hasSeen) return '/login'; // Saltar onboarding
          return null; // Mostrar onboarding
        }
        if (_publicRoutes.contains(location)) return null; // permitir
        return '/login';
      }

      // Si hay sesión y va a onboarding/login, redirigir según rol
      if (_publicRoutes.contains(location)) {
        final doc = await _findUserDocumentForRouter(user.uid);
        if (doc == null) return null; // sin doc, dejar pasar
        final data = doc.data() as Map<String, dynamic>;
        final roleStr = data['role'] as String? ?? 'client';
        switch (roleStr) {
          case 'pyme': return '/pyme/home';
          case 'foundation': return '/pyme/home';
          case 'admin': return '/admin/home';
          case 'empresa': return '/empresa/home';
          case 'storeManager': return '/pyme/home'; // Reutiliza la UI de Pyme
          default: return '/client/home';
        }
      }

      return null; // sin redirección
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pyme/home',
        builder: (context, state) => const PymeAppShell(),
      ),
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminAppShell(),
      ),
      GoRoute(
        path: '/empresa/home',
        builder: (context, state) => const EmpresaAppShell(),
      ),
      
      // Enrutamiento Shell para el BottomNavigationBar del Cliente
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/client/home',
            builder: (context, state) => const ClientHomeScreen(),
            routes: [
              GoRoute(
                path: 'donation',
                builder: (context, state) => const DonationScreen(),
              ),
              GoRoute(
                path: 'pyme_detail',
                builder: (context, state) {
                   // When navigating to pyme_detail via go_router, passing extra objects
                   final extra = state.extra as Map<String, dynamic>?;
                   final String pymeId = extra?['pymeId'] as String? ?? '';
                   final UserProfile? pymeDataNullable = extra?['pymeData'] as UserProfile?;
                   // Fallback instance to satisfy non-null UI if state missing
                   final UserProfile pymeData = pymeDataNullable ?? UserProfile(
                     id: pymeId,
                     name: 'Cargando...',
                     email: '',
                     role: UserRole.pyme,
                     createdAt: DateTime.now(),
                   );
                   return ClientPymeDetailScreen(pymeId: pymeId, pymeData: pymeData);
                }
              ),
              GoRoute(
                path: 'subscription',
                builder: (context, state) => const ClientSubscriptionScreen(),
              ),
            ]
          ),
          GoRoute(
            path: '/client/foundations',
            builder: (context, state) => const ClientHomeScreen(showFoundationsOnly: true),
          ),
          GoRoute(
            path: '/client/map',
            builder: (context, state) => const ClientMapScreen(),
          ),
          GoRoute(
            path: '/client/cart',
            builder: (context, state) => const ClientCartScreen(),
          ),
          GoRoute(
            path: '/client/qr',
            builder: (context, state) => const ClientQrScreen(),
          ),
          GoRoute(
            path: '/client/profile',
            builder: (context, state) => const ClientProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

// Widget Shell que contiene la barra de navegación inferior
class ScaffoldWithBottomNavBar extends StatelessWidget {
  const ScaffoldWithBottomNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final String location = state.uri.path;
    if (location.startsWith('/client/home')) return 0;
    if (location.startsWith('/client/foundations')) return 1;
    if (location.startsWith('/client/map')) return 2;
    if (location.startsWith('/client/cart')) return 3;
    if (location.startsWith('/client/qr')) return 4;
    if (location.startsWith('/client/profile')) return 5;
    return 0; // Default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/client/home');
        break;
      case 1:
        context.go('/client/foundations');
        break;
      case 2:
        context.go('/client/map');
        break;
      case 3:
        context.go('/client/cart');
        break;
      case 4:
        context.go('/client/qr');
        break;
      case 5:
        context.go('/client/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.85),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            currentIndex: _calculateSelectedIndex(context),
            onTap: (int idx) => _onItemTapped(idx, context),
            unselectedItemColor: const Color(0xFF2F3F2A).withValues(alpha: 0.5),
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              const BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Fundaciones'),
              const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
              BottomNavigationBarItem(
                icon: Consumer<CartService>(
                  builder: (context, cart, child) {
                    return Badge(
                      label: Text('${cart.itemCount}'),
                      isLabelVisible: cart.itemCount > 0,
                      child: const Icon(Icons.shopping_cart),
                    );
                  },
                ),
                label: 'Carrito',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Mi QR'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }
}
