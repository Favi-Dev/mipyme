import 'package:flutter/material.dart';
import 'client_pyme_detail_screen.dart';
import '../models/vitrina_data.dart';
import '../services/product_service.dart';

class ClientMapScreen extends StatefulWidget {
  const ClientMapScreen({super.key});

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  // Mock data for map pins
  final List<Map<String, dynamic>> _mapPins = [
    {
      'id': '1',
      'name': 'Zapatería Los Robles',
      'category': 'Comercio',
      'category_key': 'Comercio/retail',
      'lat': 0.4,
      'lng': 0.3,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.shopping_bag,
      'image': 'assets/images/logo el roble calzados.jpg',
    },
    {
      'id': '2',
      'name': 'Farmayuda',
      'category': 'Salud',
      'category_key': 'Salud, belleza y bienestar',
      'lat': 0.6,
      'lng': 0.7,
      'color': const Color(0xFF4ECDC4),
      'icon': Icons.medical_services,
      'image': 'assets/images/logo farmayuda.jpg',
    },
    {
      'id': '3',
      'name': 'Fundación Los Robles',
      'category': 'Fundación',
      'category_key': 'Educación y cultura',
      'lat': 0.25,
      'lng': 0.6,
      'color': const Color(0xFFFF6B6B),
      'icon': Icons.volunteer_activism,
      'image': 'assets/images/Logo los robles.jpg',
    },
    {
      'id': '4',
      'name': 'Cafetería El Grano',
      'category': 'Comida',
      'category_key': 'Alimentos y gastronomía',
      'lat': 0.5,
      'lng': 0.4,
      'color': Colors.orange,
      'icon': Icons.restaurant,
      'image': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '5',
      'name': 'Estudio Jurídico Silva',
      'category': 'Servicios',
      'category_key': 'Servicios profesionales',
      'lat': 0.3,
      'lng': 0.2,
      'color': Colors.blueGrey,
      'icon': Icons.gavel,
      'image': 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '6',
      'name': 'Muebles Rústicos Chile',
      'category': 'Oficios',
      'category_key': 'Oficios y manufactura',
      'lat': 0.7,
      'lng': 0.3,
      'color': Colors.brown,
      'icon': Icons.handyman,
      'image': 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '7',
      'name': 'Fletes Rápidos Santiago',
      'category': 'Logística',
      'category_key': 'Transporte y logística',
      'lat': 0.55,
      'lng': 0.8,
      'color': Colors.indigo,
      'icon': Icons.local_shipping,
      'image': 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=500&q=60',
    },
    {
      'id': '8',
      'name': 'Metamorfosis',
      'category': 'Reciclaje Textil',
      'category_key': 'Metamorfosis',
      'lat': 0.35,
      'lng': 0.5,
      'color': Colors.teal,
      'icon': Icons.recycling,
      'image': 'assets/images/metamorfosis.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/mapa.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text(
                        'No se pudo cargar el mapa.\nReinicia la aplicación si acabas de agregar la imagen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // 2. Search Bar Overlay
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar en el mapa...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B6B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // 3. Pins
          ..._mapPins.map((pin) {
            return Positioned(
              top: MediaQuery.of(context).size.height * pin['lat'],
              left: MediaQuery.of(context).size.width * pin['lng'],
              child: GestureDetector(
                onTap: () => _showPymePreview(context, pin),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pin['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        pin['icon'],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        pin['name'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Center map or current location action
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Color(0xFFFF6B6B)),
      ),
    );
  }

  void _showPymePreview(BuildContext context, Map<String, dynamic> pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: pin['image'].startsWith('http')
                        ? NetworkImage(pin['image'])
                        : AssetImage(pin['image']) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                pin['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                pin['category'],
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  _navigateToPymeDetail(context, pin);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToPymeDetail(context, pin);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Ver Perfil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPymeDetail(BuildContext context, Map<String, dynamic> pin) {
    // Update global state for the selected Pyme
    if (pin.containsKey('category_key')) {
      VitrinaData.setCategory(pin['category_key']);
      ProductService().loadMockProductsForCategory(pin['category_key']);
    }
    
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientPymeDetailScreen(),
      ),
    );
  }
}
