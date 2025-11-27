import 'package:flutter/material.dart';
import '../models/offer_data.dart';
import '../models/vitrina_data.dart';
import 'pyme_offers_management_screen.dart';
import 'pyme_vitrina_settings_screen.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'pyme_products_screen.dart';

class PymeProfileVitrinaScreen extends StatefulWidget {
  const PymeProfileVitrinaScreen({super.key});

  @override
  State<PymeProfileVitrinaScreen> createState() =>
      _PymeProfileVitrinaScreenState();
}

class _PymeProfileVitrinaScreenState extends State<PymeProfileVitrinaScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProductService _productService = ProductService();
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      _products = _productService.getProductsByPyme('pyme1');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using a light theme aesthetic for this screen as requested
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Light background
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: const Color(0xFFFF6B6B),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PymeVitrinaSettingsScreen(),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    VitrinaData.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3.0,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 110, bottom: 16),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        VitrinaData.coverImageUrl,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for better text visibility
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description Section
                      _buildSectionTitle('Descripción', Colors.black87),
                      const SizedBox(height: 8),
                      Text(
                        VitrinaData.description,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      // Offers Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Ofertas', Colors.black87),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PymeOffersManagementScreen(),
                                ),
                              );
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: OfferData.offers.map((offer) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildOfferCard(
                                icon: offer.icon,
                                title: offer.title,
                                description: offer.description,
                                color: offer.color.withOpacity(0.2),
                                iconColor: offer.color,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Products Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Productos', Colors.black87),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PymeProductsScreen(),
                                ),
                              );
                              _loadProducts();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_products.isEmpty)
                        const Text('No hay productos registrados', style: TextStyle(color: Colors.grey))
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _products.map((product) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildProductCard(product),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Hours Section
                      _buildSectionTitle('Horarios', Colors.black87),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time, VitrinaData.hours, Colors.black54),
                      const SizedBox(height: 24),

                      // Contact Section
                      _buildSectionTitle('Contacto', Colors.black87),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSocialButton(Icons.language, 'Web', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ir a: ${VitrinaData.webUrl}'),
                                backgroundColor: Colors.amber,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }, Colors.blue),
                          _buildSocialButton(Icons.camera_alt, 'Instagram', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Ir a: ${VitrinaData.instagramHandle}'),
                                backgroundColor: Colors.purpleAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }, Colors.purple),
                          _buildSocialButton(Icons.message, 'WhatsApp', () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Ir a: ${VitrinaData.whatsappNumber}'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      _buildSectionTitle('Ubicación', Colors.black87),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          Icons.location_on, VitrinaData.location, Colors.black54),
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating Logo Overlay
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              // Calculate position based on scroll
              // Initial position is 250 (header height) - 40 (half logo height)
              double top = 210.0;
              if (_scrollController.hasClients) {
                top -= _scrollController.offset;
              }
              return Positioned(
                top: top,
                left: 16,
                child: child!,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFFF6B6B),
                child: Icon(
                  Icons.coffee,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
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
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              product.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
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
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
