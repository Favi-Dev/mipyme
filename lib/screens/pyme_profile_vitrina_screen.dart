import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'pyme_offers_management_screen.dart';
import 'pyme_vitrina_settings_screen.dart';
import '../services/product_service.dart';
import '../services/pyme_service.dart';
import '../models/product.dart';
import 'pyme_products_screen.dart';
import '../widgets/supporter_counter.dart';

class PymeProfileVitrinaScreen extends StatefulWidget {
  const PymeProfileVitrinaScreen({super.key});

  @override
  State<PymeProfileVitrinaScreen> createState() =>
      _PymeProfileVitrinaScreenState();
}

class _PymeProfileVitrinaScreenState extends State<PymeProfileVitrinaScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProductService _productService = ProductService();
  final PymeService _pymeService = PymeService();
  Stream<List<Product>>? _productsStream;
  Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _productsStream = _productService.getProductsByPyme(user.uid);
      _userStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
    }
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

    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F1EA),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F1EA),
            body: Center(child: Text('No se encontró información del perfil')),
          );
        }

        final profile = UserProfile.fromMap(data, snapshot.data!.id);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F1EA), // Warm White background
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
                    backgroundColor: const Color(0xFF2F3F2A),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings, color: Color(0xFFF4F1EA)),
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
                        profile.name,
                        style: const TextStyle(
                          color: Color(0xFFF4F1EA),
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
                          (profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty)
                              ? (profile.coverImageUrl!.startsWith('http')
                                  ? Image.network(
                                      profile.coverImageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      profile.coverImageUrl!,
                                      fit: BoxFit.cover,
                                    ))
                              : Container(color: Colors.grey[800]),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle('Descripción', const Color(0xFF2F3F2A)),
                              // TODO: Connect supporter count to real data
                              const SupporterCounter(count: 0), 
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.description ?? 'Sin descripción',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                          ),
                      const SizedBox(height: 24),

                      // Offers Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Ofertas', const Color(0xFF2F3F2A)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF6F8F5E)),
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
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _pymeService.getOffersByPyme(FirebaseAuth.instance.currentUser!.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                             return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                          }
                          final offers = snapshot.data ?? [];
                          if (offers.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No hay ofertas creadas.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                            );
                          }
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: offers.map((offer) {
                                final iconData = offer['iconCodePoint'] != null 
                                    ? IconData(offer['iconCodePoint'], fontFamily: 'MaterialIcons') 
                                    : Icons.local_offer;
                                final colorVal = offer['colorValue'] != null ? Color(offer['colorValue']) : const Color(0xFF6F8F5E);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildOfferCard(
                                    icon: iconData,
                                    title: offer['title'] ?? 'Sin título',
                                    description: offer['description'] ?? '',
                                    color: colorVal.withOpacity(0.2),
                                    iconColor: colorVal,
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 24),

                      // Products Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Productos', const Color(0xFF2F3F2A)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF6F8F5E)),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PymeProductsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<Product>>(
                        stream: _productsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          final products = snapshot.data ?? [];
                          if (products.isEmpty) {
                            return Text('No hay productos registrados', style: TextStyle(color: const Color(0xFF2F3F2A).withValues(alpha: 0.5)));
                          }
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: products.map((product) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildProductCard(product),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Hours Section
                      _buildSectionTitle('Horarios', const Color(0xFF2F3F2A)),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time, profile.hours ?? 'Por definir', const Color(0xFF2F3F2A).withOpacity(0.7)),
                      const SizedBox(height: 24),

                      // Contact Section
                      _buildSectionTitle('Contacto', const Color(0xFF2F3F2A)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (profile.webUrl != null && profile.webUrl!.isNotEmpty)
                            _buildSocialButton(Icons.language, 'Web', () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ir a: ${profile.webUrl}'),
                                  backgroundColor: const Color(0xFF8B5A3C),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }, const Color(0xFF2F3F2A)),
                          if (profile.instagramHandle != null && profile.instagramHandle!.isNotEmpty)
                            _buildSocialButton(Icons.camera_alt, 'Instagram', () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Ir a: ${profile.instagramHandle}'),
                                  backgroundColor: const Color(0xFF8B5A3C),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }, const Color(0xFF2F3F2A)),
                          if (profile.whatsappNumber != null && profile.whatsappNumber!.isNotEmpty)
                            _buildSocialButton(Icons.message, 'WhatsApp', () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Ir a: ${profile.whatsappNumber}'),
                                  backgroundColor: const Color(0xFF6F8F5E),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }, const Color(0xFF6F8F5E)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      _buildSectionTitle('Ubicación', const Color(0xFF2F3F2A)),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          Icons.location_on, profile.location ?? 'Sin dirección registrada', const Color(0xFF2F3F2A).withOpacity(0.7)),
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
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F3F2A).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFFFFFFF),
                backgroundImage: (profile.logoUrl != null && profile.logoUrl!.isNotEmpty)
                    ? (profile.logoUrl!.startsWith('http')
                        ? NetworkImage(profile.logoUrl!)
                        : AssetImage(profile.logoUrl!) as ImageProvider)
                    : const AssetImage('assets/images/placeholder_logo.png') as ImageProvider, // Fallback
              ),
            ),
          ),
        ],
      ),
    );
      },
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
      width: 160,
      height: 140, 
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2F3F2A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.05),
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
                color: const Color(0xFFF4F1EA),
                child: Icon(Icons.image_not_supported, color: const Color(0xFF2F3F2A).withOpacity(0.3)),
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
                    color: Color(0xFF2F3F2A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF6F8F5E),
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
            style: TextStyle(color: const Color(0xFF2F3F2A).withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
