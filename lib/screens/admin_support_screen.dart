import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Soporte y Tickets',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
            onPressed: () {
               Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
              border: Border(
                left: BorderSide(
                  color: index % 3 == 0 ? const Color(0xFFFF6B6B) : (index % 3 == 1 ? const Color(0xFFFFD93D) : const Color(0xFF4ECDC4)),
                  width: 4,
                ),
              ),
            ),
            child: ListTile(
              title: Text(
                'Ticket #${1000 + index}',
                style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Problema con el inicio de sesión...',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              trailing: Text(
                index % 3 == 0 ? 'Alta' : (index % 3 == 1 ? 'Media' : 'Baja'),
                style: GoogleFonts.poppins(
                  color: index % 3 == 0 ? const Color(0xFFFF6B6B) : (index % 3 == 1 ? Colors.orange : const Color(0xFF4ECDC4)),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
