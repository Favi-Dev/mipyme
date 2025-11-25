import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Gestión de Usuarios',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2C2C3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildUserTile(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            'U${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          'Usuario ${index + 1}',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        subtitle: Text(
          'usuario${index + 1}@email.com',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ban',
              child: Text('Suspender Cuenta'),
            ),
            const PopupMenuItem(
              value: 'details',
              child: Text('Ver Detalles'),
            ),
          ],
        ),
      ),
    );
  }
}
