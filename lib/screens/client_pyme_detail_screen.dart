import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/offer_data.dart';
import '../models/vitrina_data.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class ClientPymeDetailScreen extends StatefulWidget {
  const ClientPymeDetailScreen({super.key});

  @override
  State<ClientPymeDetailScreen> createState() => _ClientPymeDetailScreenState();
}

class _ClientPymeDetailScreenState extends State<ClientPymeDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  bool _isFollowing = false;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
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
                backgroundColor: const Color(0xFFF7F9FC),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: _isFollowing ? const Color(0xFFFF6B6B) : Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFollowing = !_isFollowing;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isFollowing
                                ? '¡Ahora sigues a ${VitrinaData.name}!'
                                : 'Dejaste de seguir a ${VitrinaData.name}',
                          ),
                          backgroundColor: _isFollowing ? const Color(0xFFFF6B6B) : Colors.grey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    VitrinaData.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
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
                      // Description
                      Text(
                        'Descripción',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        VitrinaData.description,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Offers
                      Text(
                        'Ofertas Disponibles',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: OfferData.offers.map((offer) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildClientOfferCard(
                                offer: offer,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Products
                      if (_products.isNotEmpty) ...[
                        Text(
                          'Productos',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                      ],

                      // Info
                      Text(
                        'Información',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.access_time, VitrinaData.hours),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on, VitrinaData.location),
                      const SizedBox(height: 24),

                      // Contact Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildContactButton(
                            Icons.language,
                            'Sitio Web',
                            Colors.blueAccent,
                            () {},
                          ),
                          _buildContactButton(
                            Icons.camera_alt,
                            'Instagram',
                            Colors.purpleAccent,
                            () {},
                          ),
                          _buildContactButton(
                            Icons.message,
                            'WhatsApp',
                            Colors.green,
                            () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating Logo
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
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
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFFFD93D),
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

  Widget _buildClientOfferCard({required Offer offer}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [offer.color.withOpacity(0.9), offer.color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: offer.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(offer.icon, color: Colors.white, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DISPONIBLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            offer.description,
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usa tu cupón mensual aquí',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
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
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        _cartService.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agregado al carrito'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF4ECDC4),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
