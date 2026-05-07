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
import 'pyme_events_screen.dart';
import '../widgets/supporter_counter.dart';
import '../models/vitrina_data.dart';

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
      final collection = VitrinaData.isFoundation ? 'foundations' : 'pymes';
      _userStream = FirebaseFirestore.instance.collection(collection).doc(user.uid).snapshots();
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
          return _buildEmptySkeleton(context);
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
                        icon: const Icon(Icons.notifications_none, color: Color(0xFFF4F1EA)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No tienes notificaciones nuevas')),
                          );
                        },
                      ),
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
                      title: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200), // Reduce width slightly or use screen width calc
                        child: Text(
                          profile.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF4F1EA),
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Slightly reduce size for long names
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      titlePadding: const EdgeInsets.only(left: 110, bottom: 16, right: 16),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          (profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty)
                              ? (profile.coverImageUrl!.startsWith('http')
                                  ? Image.network(
                                      profile.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
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
                              // Connected supporter count to real data
                              SupporterCounter(count: profile.supporterCount), 
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profile.description ?? 'Sin descripción',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                          ),
                      const SizedBox(height: 24),

                      // Reordered for Foundation: Offers -> Events -> Products

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

                      // StreamBuilder for ALL products (Events + Regular Products)
                      StreamBuilder<List<Product>>(
                        stream: _productsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          
                          final allProducts = snapshot.data ?? [];
                          
                          final now = DateTime.now();
                          final events = allProducts
                              .where((p) => _isEventProduct(p))
                              .where((p) {
                                final eventDate = _eventDateTime(p);
                                return eventDate == null || !eventDate.isBefore(now);
                              })
                              .toList()
                            ..sort((a, b) {
                              final aDate = _eventDateTime(a) ?? DateTime(2100);
                              final bDate = _eventDateTime(b) ?? DateTime(2100);
                              return aDate.compareTo(bDate);
                            });

                          final inventoryItems = allProducts.where((p) => !_isEventProduct(p)).toList();
                          final physicalProducts = inventoryItems.where((p) => !p.isService).toList();
                          final serviceProducts = inventoryItems.where((p) => p.isService).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Events Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle('Eventos', const Color(0xFF2F3F2A)),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF6F8F5E)),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (c) => const PymeEventsScreen()));
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (events.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('No hay eventos próximos.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: events.map((event) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildEventCard(event),
                                      );
                                    }).toList(),
                                  ),
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
                                          builder: (context) => const PymeProductsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (physicalProducts.isEmpty)
                                Text('No hay productos registrados', style: TextStyle(color: const Color(0xFF2F3F2A).withValues(alpha: 0.5)))
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: physicalProducts.map((product) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildProductCard(product),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle('Servicios', const Color(0xFF2F3F2A)),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF6F8F5E)),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const PymeProductsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (serviceProducts.isEmpty)
                                Text('No hay servicios registrados', style: TextStyle(color: const Color(0xFF2F3F2A).withValues(alpha: 0.5)))
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: serviceProducts.map((product) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildProductCard(product),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          );
                        }
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
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 16,
                        runSpacing: 16,
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
              child: ClipOval(
                child: (profile.logoUrl != null && profile.logoUrl!.isNotEmpty)
                    ? (profile.logoUrl!.startsWith('http')
                        ? Image.network(
                            profile.logoUrl!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/LOGOSOYPLUS.png',
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          )
                        : Image.asset(
                            profile.logoUrl!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          ))
                    : Image.asset(
                        'assets/images/LOGOSOYPLUS.png',
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
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
    final isQuote = product.customAttributes['allow_quote'] == 'true';
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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInventoryBadge(
                      isQuote ? 'Cotizar' : '\$${product.price.toStringAsFixed(0)}',
                      const Color(0xFF6F8F5E),
                    ),
                    if (product.isService)
                      _buildInventoryBadge('Servicio', const Color(0xFF2F3F2A)),
                    if (product.hasVariants)
                      _buildInventoryBadge('${product.variants.length} variantes', const Color(0xFF8B5A3C)),
                    _buildInventoryBadge('Stock ${product.totalStock}', const Color(0xFF6F8F5E)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Product event) {
    final eventDate = _eventDateTime(event);
    final remainingSeats = event.stock - event.registeredCount;

    return Container(
      width: 200,
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
            child: event.imageUrl.isNotEmpty
                ? Image.network(
                    event.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: const Color(0xFFF4F1EA),
                      child: const Icon(Icons.event, size: 40, color: Color(0xFF6F8F5E)),
                    ),
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    color: const Color(0xFFF4F1EA),
                    child: const Icon(Icons.event, size: 40, color: Color(0xFF6F8F5E)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2F3F2A),
                  ),
                ),
                const SizedBox(height: 4),
                if (eventDate != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6F8F5E)),
                      const SizedBox(width: 4),
                      Text(
                        '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                        style: TextStyle(
                          color: const Color(0xFF2F3F2A).withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                 if (event.price > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '\$${event.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF6F8F5E),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  remainingSeats > 0 ? '$remainingSeats cupos' : 'Sin cupos',
                  style: TextStyle(
                    color: remainingSeats > 0 ? const Color(0xFF6F8F5E) : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  bool _isEventProduct(Product product) {
    return product.customAttributes['is_event'].toString().toLowerCase() == 'true';
  }

  DateTime? _eventDateTime(Product event) {
    final dateStr = event.customAttributes['event_date'];
    if (dateStr == null) return null;
    try {
      final parts = dateStr.toString().split('/');
      if (parts.length == 3) {
        final timeParts = event.customAttributes['event_time']?.toString().split(':');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
          timeParts != null && timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0,
          timeParts != null && timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0,
        );
      }
      return DateTime.parse(dateStr.toString());
    } catch (_) {
      return null;
    }
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

  Widget _buildEmptySkeleton(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.store, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 20, width: 160, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Container(height: 14, width: 100, color: Colors.grey[200]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6F8F5E).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.store_outlined, size: 48, color: Color(0xFF6F8F5E)),
                          const SizedBox(height: 12),
                          const Text(
                            '¡Completa tu Vitrina!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F3F2A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu perfil de vitrina aún no tiene información. Ve a Configuración para agregar tu nombre, descripción, horarios y más.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PymeVitrinaSettingsScreen(),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Completar mi Vitrina'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F8F5E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
