import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'screens/client_home_screen.dart';
import 'screens/client_marketplace_screen.dart';
import 'screens/client_cart_screen.dart';
import 'screens/client_qr_screen.dart';
import 'screens/client_profile_screen.dart';

class ClientAppShell extends StatefulWidget {
  const ClientAppShell({super.key});

  @override
  State<ClientAppShell> createState() => _ClientAppShellState();
}

class _ClientAppShellState extends State<ClientAppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ClientHomeScreen(),
    const ClientMarketplaceScreen(),
    const ClientCartScreen(),
    const ClientQrScreen(),
    const ClientProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed hardcoded background color to use Theme
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // Light background for nav
        selectedItemColor: const Color(0xFFFF6B6B), // Playful Red
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Mercado'),
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
    );
  }
}
