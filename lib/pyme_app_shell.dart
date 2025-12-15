import 'package:flutter/material.dart';
import 'models/vitrina_data.dart';
import 'screens/pyme_metrics_screen.dart';
import 'screens/pyme_validation_scanner_screen.dart';
import 'screens/pyme_products_screen.dart';
import 'screens/pyme_profile_vitrina_screen.dart';
import 'screens/pyme_events_screen.dart';
import 'screens/pyme_profile_screen.dart';

class PymeAppShell extends StatefulWidget {
  const PymeAppShell({super.key});

  @override
  State<PymeAppShell> createState() => _PymeAppShellState();
}

class _PymeAppShellState extends State<PymeAppShell> {
  int _selectedIndex = 0;

  List<Widget> get _screens {
    if (VitrinaData.isFoundation) {
      return const [
        PymeProfileVitrinaScreen(),
        PymeProductsScreen(),
        PymeEventsScreen(),
        PymeValidationScannerScreen(),
        PymeMetricsScreen(),
        PymeProfileScreen(),
      ];
    }
    return const [
      PymeProfileVitrinaScreen(),
      PymeProductsScreen(),
      PymeValidationScannerScreen(),
      PymeMetricsScreen(),
      PymeProfileScreen(),
    ];
  }

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
        backgroundColor: const Color(0xFFF4F1EA),
        selectedItemColor: const Color(0xFF6F8F5E),
        unselectedItemColor: const Color(0xFF2F3F2A).withOpacity(0.5),
        items: VitrinaData.isFoundation
            ? const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront),
                  label: 'Mi Vitrina',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2),
                  label: 'Productos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Eventos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner),
                  label: 'Validación',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  label: 'Métricas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ]
            : const <BottomNavigationBarItem>[
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
