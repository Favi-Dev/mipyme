import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'pyme_add_event_screen.dart';

class PymeEventsScreen extends StatefulWidget {
  final String? pymeId;
  const PymeEventsScreen({super.key, this.pymeId});

  @override
  State<PymeEventsScreen> createState() => _PymeEventsScreenState();
}

class _PymeEventsScreenState extends State<PymeEventsScreen> {
  final ProductService _productService = ProductService();
  String get _currentPymeId => widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación')),
        );
      }
    }
  }

  void _shareEvent(Product event) {
    final date = event.customAttributes['event_date'] ?? 'Fecha por definir';
    final location = event.customAttributes['event_location'] ?? 'Ubicación por definir';
    final String link = 'https://mipyme.app/evento/${event.id}';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compartir Evento',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(
                  icon: Icons.copy,
                  label: 'Copiar',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enlace copiado: $link')),
                    );
                  },
                ),
                _buildShareOption(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF6F8F5E),
                  onTap: () {
                    Navigator.pop(context);
                    final text = '¡Te invito al evento *${event.name}*!%0A%0A📅 $date%0A📍 $location%0A%0AInscríbete aquí: $link';
                    _launchUrl('https://wa.me/?text=$text');
                  },
                ),
                _buildShareOption(
                  icon: Icons.email,
                  label: 'Correo',
                  color: const Color(0xFF8B5A3C),
                  onTap: () {
                    // ...
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Mis Eventos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productService.getProductsByPyme(_currentPymeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data ?? [];
          final events = allProducts.where((p) => p.customAttributes['is_event'] == 'true').toList();

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy,
                      size: 64, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes eventos programados.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2F3F2A).withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PymeAddEventScreen(pymeId: widget.pymeId)),
          );
        },
        backgroundColor: const Color(0xFF6F8F5E),
        foregroundColor: const Color(0xFFF4F1EA),
        icon: const Icon(Icons.add),
        label: Text(
          'Nuevo Evento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEventCard(Product event) {
    final date = event.customAttributes['event_date'] ?? 'Fecha por definir';
    final time = event.customAttributes['event_time'] ?? 'Hora por definir';
    final location = event.customAttributes['event_location'] ?? 'Ubicación por definir';

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
           // Ensure clip behavior respects the rounded corners
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                event.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        // Sharing and Edit Buttons
                         Row(
                          children: [
                             IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF8B5A3C)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PymeAddEventScreen(event: event, pymeId: widget.pymeId),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, color: Color(0xFF6F8F5E)),
                              onPressed: () => _shareEvent(event),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8B5A3C)),
                    const SizedBox(width: 8),
                    Text(
                      '$date - $time',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2F3F2A).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFF8B5A3C)),
                    const SizedBox(width: 8),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF2F3F2A).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2F3F2A).withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF2F3F2A),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF2F3F2A),
            ),
          ),
        ],
      ),
    );
  }
}
