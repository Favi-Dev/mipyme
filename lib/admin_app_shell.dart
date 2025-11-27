import 'package:flutter/material.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_pyme_management_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/admin_support_screen.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell({super.key});

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminPymeManagementScreen(),
    const AdminUserManagementScreen(),
    const AdminSupportScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Pymes'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Soporte'),
        ],
      ),
    );
  }
}
