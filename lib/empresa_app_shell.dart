import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/empresa/empresa_dashboard_screen.dart';
import 'screens/empresa/empresa_stores_screen.dart';
import 'screens/empresa/empresa_collaborators_screen.dart';

class EmpresaAppShell extends StatefulWidget {
  const EmpresaAppShell({super.key});

  @override
  State<EmpresaAppShell> createState() => _EmpresaAppShellState();
}

class _EmpresaAppShellState extends State<EmpresaAppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    EmpresaDashboardScreen(),
    EmpresaStoresScreen(),
    EmpresaCollaboratorsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
              color: const Color(0xFFF4F1EA).withValues(alpha: 0.85),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF6F8F5E),
              unselectedItemColor: const Color(0xFF2F3F2A).withValues(alpha: 0.5),
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Tiendas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Colaboradores',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
