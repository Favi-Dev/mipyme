import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Soporte y Tickets',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
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
              color: const Color(0xFF2C2C3E),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: index % 3 == 0 ? Colors.red : (index % 3 == 1 ? Colors.orange : Colors.green),
                  width: 4,
                ),
              ),
            ),
            child: ListTile(
              title: Text(
                'Ticket #${1000 + index}',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Problema con el inicio de sesión...',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              trailing: Text(
                index % 3 == 0 ? 'Alta' : (index % 3 == 1 ? 'Media' : 'Baja'),
                style: GoogleFonts.poppins(
                  color: index % 3 == 0 ? Colors.red : (index % 3 == 1 ? Colors.orange : Colors.green),
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
