import 'package:flutter/material.dart';
import 'screens/pyme_metrics_screen.dart';
import 'screens/pyme_validation_scanner_screen.dart';
import 'screens/pyme_products_screen.dart';
import 'screens/pyme_profile_vitrina_screen.dart';

class PymeAppShell extends StatefulWidget {
  const PymeAppShell({super.key});

  @override
  State<PymeAppShell> createState() => _PymeAppShellState();
}

class _PymeAppShellState extends State<PymeAppShell> {
  int _selectedIndex = 0;

  List<Widget> get _screens => const [
    PymeProfileVitrinaScreen(),
    PymeProductsScreen(),
    PymeValidationScannerScreen(),
    PymeMetricsScreen(),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Mi Vitrina',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Validación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Métricas',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
