import 'package:flutter/material.dart';
import 'screens/client_home_screen.dart';
import 'screens/client_map_screen.dart';
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
    const ClientMapScreen(),
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
      backgroundColor: const Color(0xFF1E1E2C),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: const Color(0xFFE94560),
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Mi QR'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
