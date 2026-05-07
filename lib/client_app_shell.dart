import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/cart_service.dart';
import 'screens/client_home_screen.dart';
import 'screens/client_map_screen.dart';
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
    const ClientHomeScreen(showFoundationsOnly: true),
    const ClientMapScreen(),
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
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
      ),
    );
  }
}
