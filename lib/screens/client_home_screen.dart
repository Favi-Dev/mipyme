import 'package:flutter/material.dart';
import 'client_pyme_detail_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B6B),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, Joaquín',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Descubre lo mejor de tu barrio',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar cafeterías, tiendas...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Featured Offers
            _buildSectionHeader('Ofertas Destacadas'),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildOfferCard(
                    context,
                    'Café Eclipse',
                    '2x1 en Cappuccinos',
                    const Color(0xFFFFD93D),
                    Icons.coffee,
                  ),
                  const SizedBox(width: 12),
                  _buildOfferCard(
                    context,
                    'Librería Central',
                    '15% dcto. en Libros',
                    const Color(0xFF4ECDC4),
                    Icons.book,
                  ),
                  const SizedBox(width: 12),
                  _buildOfferCard(
                    context,
                    'Panadería La Rosa',
                    '3x2 en Medialunas',
                    const Color(0xFFFF6B6B),
                    Icons.bakery_dining,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nearby Pymes
            _buildSectionHeader('Pymes Cercanas'),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildPymeCard(context, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Ver todo',
          style: TextStyle(
            color: Color(0xFFFF6B6B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, String pymeName, String offer,
      Color color, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientPymeDetailScreen(),
          ),
        );
      },
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pymeName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPymeCard(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ClientPymeDetailScreen(),
          ),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                'https://picsum.photos/seed/${index + 10}/100/100',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pyme Local ${index + 1}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.star, color: Color(0xFFFFD93D), size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cafetería • A 1.2 km',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Av. Providencia 1234',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}