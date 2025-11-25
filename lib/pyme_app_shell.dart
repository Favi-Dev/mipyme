import 'package:flutter/material.dart';
import 'screens/pyme_metrics_screen.dart';
import 'screens/pyme_validation_scanner_screen.dart';
import 'screens/pyme_offers_management_screen.dart';
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
    PymeOffersManagementScreen(),
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
        type: BottomNavigationBarType.fixed, // Needed for 4+ items
        backgroundColor: const Color(0xFF1E1E2C),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Mi Vitrina',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Ofertas',
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
