import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientSupportScreen extends StatelessWidget {
  const ClientSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F3F2A),
      appBar: AppBar(
        title: Text('Ayuda y Soporte', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 80, color: Color(0xFFF4F1EA)),
            const SizedBox(height: 24),
            Text(
              '¿Necesitas ayuda?',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFF4F1EA)),
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos aquí para ayudarte con cualquier problema o duda que tengas sobre SoyPlus.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: const Color(0xFFF4F1EA).withOpacity(0.8)),
            ),
            const SizedBox(height: 40),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Correo Electrónico',
              subtitle: 'favi.dev@example.com',
              onTap: () => _launchUrl('mailto:favi.dev@example.com'),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.code,
              title: 'GitHub',
              subtitle: 'github.com/Favi-Dev',
              onTap: () => _launchUrl('https://github.com/Favi-Dev'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F3F2A).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3F2A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2F3F2A), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2F3F2A)),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A).withOpacity(0.7), fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
