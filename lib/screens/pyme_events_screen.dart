import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'pyme_add_event_screen.dart';

class PymeEventsScreen extends StatefulWidget {
  const PymeEventsScreen({super.key});

  @override
  State<PymeEventsScreen> createState() => _PymeEventsScreenState();
}

class _PymeEventsScreenState extends State<PymeEventsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      // Filter products that are marked as events
      _events = _productService.getProductsByPyme('pyme1')
          .where((p) => p.customAttributes['is_event'] == 'true')
          .toList();
    });
  }

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
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    final text = '¡Te invito al evento *${event.name}*!%0A%0A📅 $date%0A📍 $location%0A%0AInscríbete aquí: $link';
                    _launchUrl('https://wa.me/?text=$text');
                  },
                ),
                _buildShareOption(
                  icon: Icons.email,
                  label: 'Correo',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    final subject = 'Invitación: ${event.name}';
                    final body = 'Hola,%0A%0ATe invito a participar en el evento ${event.name}.%0A%0ACuando: $date%0ADonde: $location%0A%0AMás información: $link';
                    _launchUrl('mailto:?subject=$subject&body=$body');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    Color color = Colors.grey,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          'Mis Eventos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes eventos registrados.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return _buildEventCard(event);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PymeAddEventScreen(),
            ),
          );
          _loadEvents();
        },
        backgroundColor: const Color(0xFF0056D2),
        icon: const Icon(Icons.add),
        label: Text(
          'Nuevo Evento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEventCard(Product event) {
    final date = event.customAttributes['event_date'] ?? 'Fecha no definida';
    final time = event.customAttributes['event_time'] ?? 'Hora no definida';
    final location = event.customAttributes['event_location'] ?? 'Ubicación no definida';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              event.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.event, size: 50, color: Colors.grey),
              ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Evento',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0056D2),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit, color: Colors.blue),
                                  title: Text('Editar Evento', style: GoogleFonts.poppins()),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // TODO: Navigate to edit event screen
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.share, color: Colors.green),
                                  title: Text('Compartir', style: GoogleFonts.poppins()),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _shareEvent(event);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: Text('Eliminar', style: GoogleFonts.poppins()),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // TODO: Implement delete logic
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Evento eliminado')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      location,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
