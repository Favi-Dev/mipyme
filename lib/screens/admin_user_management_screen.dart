import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gestión de Usuarios',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar usuario...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4ECDC4),
          child: Text(
            'U${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          'Usuario ${index + 1}',
          style: GoogleFonts.poppins(color: Colors.black87),
        ),
        subtitle: Text(
          'usuario${index + 1}@email.com',
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
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
