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
        toolbarHeight: 70,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              backgroundColor: Colors.white24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hola, Joaquín',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 12, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 4),
                    Text(
                      'Providencia, Santiago',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar & Filter
            Row(
              children: [
                Expanded(
                  child: Container(
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
                    child: TextField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '¿Qué buscas hoy?',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFFFF6B6B)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Categories
            _buildCategories(),
            const SizedBox(height: 24),

            // Featured Offers
            _buildSectionHeader('Ofertas para ti', showViewAll: false),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildOfferCard(
                    context,
                    'Zapatería Los Robles',
                    '20% dcto. en Botas',
                    'Calzado',
                    const Color(0xFF8D6E63),
                    Icons.shopping_bag,
                    'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=500&q=60',
                  ),
                  const SizedBox(width: 16),
                  _buildOfferCard(
                    context,
                    'Clínica Dental Sonrisas',
                    'Limpieza 2x1',
                    'Salud',
                    const Color(0xFF4ECDC4),
                    Icons.medical_services,
                    'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?auto=format&fit=crop&w=500&q=60',
                  ),
                  const SizedBox(width: 16),
                  _buildOfferCard(
                    context,
                    'Transportes Veloz',
                    '10% dcto. Mudanzas',
                    'Logística',
                    const Color(0xFFFF6B6B),
                    Icons.local_shipping,
                    'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?auto=format&fit=crop&w=500&q=60',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Nearby Pymes
            _buildSectionHeader('Pymes en tu zona'),
            const SizedBox(height: 16),
            _buildNearbyPymesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyPymesList() {
    final List<Map<String, dynamic>> pymes = [
      {
        'name': 'Salón Glamour',
        'category': 'Salud y Belleza',
        'rating': '4.9',
        'distance': '0.5 km',
        'image': 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=500&q=60',
        'tags': ['Peluquería', 'Manicure'],
        'isOpen': true,
      },
      {
        'name': 'Zapatería Los Robles',
        'category': 'Comercio/Retail',
        'rating': '4.9',
        'distance': '0.8 km',
        'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=500&q=60',
        'tags': ['Calzado', 'Cuero', 'Reparación'],
        'isOpen': true,
      },
      {
        'name': 'Confecciones Mary',
        'category': 'Oficios y Manufactura',
        'rating': '4.8',
        'distance': '1.5 km',
        'image': 'https://images.unsplash.com/photo-1528578577235-b963df6db908?auto=format&fit=crop&w=500&q=60',
        'tags': ['Costura', 'Arreglos'],
        'isOpen': true,
      },
      {
        'name': 'Abogados & Asoc.',
        'category': 'Servicios Profesionales',
        'rating': '4.7',
        'distance': '2.0 km',
        'image': 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?auto=format&fit=crop&w=500&q=60',
        'tags': ['Legal', 'Asesoría'],
        'isOpen': false,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pymes.length,
      itemBuilder: (context, index) {
        return _buildPymeCard(context, pymes[index]);
      },
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.grid_view_rounded, 'label': 'Todo'},
      {'icon': Icons.store_mall_directory, 'label': 'Comercio/Retail'},
      {'icon': Icons.restaurant_menu, 'label': 'Alimentos y Gastronomía'},
      {'icon': Icons.business_center, 'label': 'Servicios Profesionales'},
      {'icon': Icons.spa, 'label': 'Salud, Belleza y Bienestar'},
      {'icon': Icons.construction, 'label': 'Oficios y Manufactura'},
      {'icon': Icons.school, 'label': 'Educación y Cultura'},
      {'icon': Icons.local_shipping, 'label': 'Transporte y Logística'},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF6B6B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFFF6B6B).withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    categories[index]['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    categories[index]['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[600],
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showViewAll = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2D3436),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        if (showViewAll)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Ver todo',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, String pymeName, String offer,
      String tag, Color color, IconData icon, String imageUrl) {
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
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        pymeName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPymeCard(BuildContext context, Map<String, dynamic> pyme) {
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
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    pyme['image'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Color(0xFFFF6B6B),
                      size: 20,
                    ),
                  ),
                ),
                if (pyme['isOpen'])
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ABIERTO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pyme['name'],
                        style: const TextStyle(
                          color: Color(0xFF2D3436),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD93D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFFFD93D), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              pyme['rating'],
                              style: const TextStyle(
                                color: Color(0xFFB7950B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.storefront,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        pyme['category'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        pyme['distance'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...(pyme['tags'] as List<String>).map((tag) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildTag(tag),
                          )),
                      _buildTag('S+ Partner', color: const Color(0xFFFF6B6B)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {Color? color}) {
    final tagColor = color ?? Colors.grey[600];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: tagColor!.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        color: tagColor.withOpacity(0.05),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tagColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
