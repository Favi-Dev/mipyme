import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../services/pyme_service.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/supporter_counter.dart';
import 'client_cart_screen.dart' as import_cart;

class ClientPymeDetailScreen extends StatefulWidget {
  final String pymeId;
  final UserProfile pymeData;

  const ClientPymeDetailScreen({
    super.key,
    required this.pymeId,
    required this.pymeData,
  });

  @override
  State<ClientPymeDetailScreen> createState() => _ClientPymeDetailScreenState();
}

class _ClientPymeDetailScreenState extends State<ClientPymeDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProductService _productService = ProductService();
  final PymeService _pymeService = PymeService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  
  bool get _isFoundation => widget.pymeData.role == UserRole.foundation;
  String get _pymeName => widget.pymeData.name;

  @override
  void initState() {
    super.initState();
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
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  void _showShareOptions() {
    final theme = Theme.of(context);
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
              'Compartir $_pymeName',
              style: theme.textTheme.titleLarge?.copyWith(
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
                      const SnackBar(content: Text('Enlace copiado al portapapeles')),
                    );
                  },
                ),
                _buildShareOption(
                  icon: Icons.message, // WhatsApp icon usually
                  label: 'WhatsApp',
                  color: const Color(0xFF6F8F5E),
                  onTap: () {
                    Navigator.pop(context);
                    // Generates a link like https://mipyme.app/pyme/pyme1
                    final String link = 'https://mipyme.app/pyme/${_pymeName.replaceAll(' ', '').toLowerCase()}';
                    _launchUrl('https://wa.me/?text=¡Hola!%20Te%20recomiendo%20ver%20*$_pymeName*%20en%20la%20app%20MiPyme.%0A%0AMira%20sus%20productos%20y%20ofertas%20aquí:%20$link');
                  },
                ),
                _buildShareOption(
                  icon: Icons.email,
                  label: 'Correo',
                  color: const Color(0xFF8B5A3C), // Café
                  onTap: () {
                    Navigator.pop(context);
                    final String link = 'https://mipyme.app/pyme/${_pymeName.replaceAll(' ', '').toLowerCase()}';
                    _launchUrl('mailto:?subject=Te%20recomiendo%20$_pymeName&body=Hola,%0A%0AEchale%20un%20vistazo%20a%20$_pymeName.%20Tienen%20cosas%20increíbles.%0A%0AVer%20perfil:%20$link');
                  },
                ),
                _buildShareOption(
                  icon: Icons.more_horiz,
                  label: 'Más',
                  color: const Color(0xFF6F8F5E), // Verde Claro
                  onTap: () {
                    Navigator.pop(context);
                    // Standard share would go here
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
    Color color = const Color(0xFF2F3F2A),
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
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
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }



  Stream<List<Map<String, dynamic>>> _getOffersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.pymeId)
        .collection('offers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  void _showDonationModal() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isMonthly = false;
          int selectedAmount = 3000;
          final List<int> amounts = [1000, 3000, 5000, 10000];

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Donar a $_pymeName',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu aporte ayuda a continuar con nuestra labor.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Frequency Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isMonthly = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isMonthly ? theme.colorScheme.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isMonthly ? [
                                  BoxShadow(
                                    color: const Color(0xFF2F3F2A).withOpacity(0.1),
                                    blurRadius: 4,
                                  )
                                ] : null,
                              ),
                              child: Text(
                                'Única vez',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: !isMonthly ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isMonthly = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isMonthly ? theme.colorScheme.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isMonthly ? [
                                  BoxShadow(
                                    color: const Color(0xFF2F3F2A).withOpacity(0.1),
                                    blurRadius: 4,
                                  )
                                ] : null,
                              ),
                              child: Text(
                                'Mensual',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isMonthly ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount Selection
                  Text(
                    'Selecciona un monto',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ...amounts.map((amount) => ChoiceChip(
                        label: Text('\$${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'),
                        selected: selectedAmount == amount,
                        onSelected: (selected) {
                          if (selected) setState(() => selectedAmount = amount);
                        },
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selectedAmount == amount ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: selectedAmount == amount ? theme.colorScheme.primary : theme.colorScheme.outline,
                          ),
                        ),
                      )),
                      ChoiceChip(
                        label: const Text('Otro monto'),
                        selected: false,
                        onSelected: (_) {},
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Progress
                  Text(
                    'Meta de recaudación',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (widget.pymeData.currentDonations ?? 0) / (widget.pymeData.donationGoal ?? 100000),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: const Color(0xFF6F8F5E), // Light Green for progress
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(widget.pymeData.currentDonations ?? 0).toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6F8F5E), // Light Green
                        ),
                      ),
                      Text(
                        'Meta: \$${(widget.pymeData.donationGoal ?? 100000).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Payment Method Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Se utilizará tu método de pago registrado para realizar el aporte.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isMonthly 
                              ? '¡Gracias por suscribirte con \$${selectedAmount}/mes!' 
                              : '¡Gracias por tu donación de \$${selectedAmount}!'),
                            backgroundColor: const Color(0xFF6F8F5E),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F3F2A), // Verde Hoja Profundo
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isMonthly ? 'Suscribirse Mensualmente' : 'Realizar Donación',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF4F1EA),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                backgroundColor: theme.colorScheme.surface,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3F2A).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFF4F1EA)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                     margin: const EdgeInsets.symmetric(vertical: 8),
                     decoration: BoxDecoration(
                      color: const Color(0xFF2F3F2A).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Color(0xFFF4F1EA)),
                        onPressed: () {
                           // Navigate to Cart Screen (reusing the shell tab if possible, or pushing new)
                           // Pushing new is safer for "direct access" from detail view
                           Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (context) => const import_cart.ClientCartScreen()),
                           );
                        },
                      ),
                  ),
                  const SizedBox(width: 8),
                  if (_userId != null)
                    StreamBuilder<bool>(
                      stream: _pymeService.isFollowing(_userId!, widget.pymeId),
                      builder: (context, snapshot) {
                        final isFollowing = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isFollowing ? Icons.favorite : Icons.favorite_border,
                            color: isFollowing ? theme.colorScheme.primary : const Color(0xFFF4F1EA),
                          ),
                          onPressed: () async {
                            await _pymeService.toggleFollow(_userId!, widget.pymeId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    !isFollowing
                                        ? '¡Ahora sigues a $_pymeName!'
                                        : 'Dejaste de seguir a $_pymeName',
                                  ),
                                  backgroundColor: !isFollowing ? theme.colorScheme.primary : const Color(0xFF8B5A3C),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFFF4F1EA)),
                    onPressed: _showShareOptions,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    _pymeName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFF4F1EA),
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 3.0,
                          color: const Color(0xFF2F3F2A).withOpacity(0.54),
                        ),
                      ],
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(left: 110, bottom: 16),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      (widget.pymeData.coverImageUrl != null && widget.pymeData.coverImageUrl!.startsWith('http'))
                          ? Image.network(
                              widget.pymeData.coverImageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              widget.pymeData.coverImageUrl ?? 'assets/images/placeholder.jpg',
                              fit: BoxFit.cover,
                            ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF2F3F2A).withOpacity(0.54),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Descripción',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SupporterCounter(count: 0),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.pymeData.description ?? 'Sin descripción disponible.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_isFoundation) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showDonationModal,
                            icon: const Icon(Icons.volunteer_activism, color: Color(0xFFF4F1EA)),
                            label: Text(
                              'Donar a esta Fundación',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF4F1EA),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F3F2A), // Verde Hoja Profundo
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Offers or Events
                      StreamBuilder<List<Product>>(
                        stream: _productService.getProductsByPyme(widget.pymeId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          
                          final products = snapshot.data ?? [];
                          final eventProducts = products.where((p) => p.customAttributes['is_event'] == 'true' || (_isFoundation && p.isService)).toList();
                          final standardProducts = products.where((p) => p.customAttributes['is_event'] != 'true' && (!_isFoundation || !p.isService)).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_isFoundation) ...[
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: _getOffersStream(),
                                  builder: (context, offerSnapshot) {
                                    if (!offerSnapshot.hasData || offerSnapshot.data!.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    final offers = offerSnapshot.data!;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ofertas Disponibles',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: offers.map((offer) {
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
                                      ],
                                    );
                                  }
                                ),
                              ] else if (eventProducts.isNotEmpty) ...[
                                Text(
                                  'Próximos Eventos',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: eventProducts.map((product) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildProductCard(product),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Products
                              if (standardProducts.isNotEmpty) ...[
                                Text(
                                  'Productos',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: standardProducts.map((product) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildProductCard(product),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          );
                        },
                      ),

                      // Info
                      Text(
                        'Información',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.access_time, widget.pymeData.hours ?? '09:00 - 18:00'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.location_on, widget.pymeData.location ?? 'Sin dirección'),
                      const SizedBox(height: 24),

                      // Contact Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildContactButton(
                            Icons.language,
                            'Sitio Web',
                            const Color(0xFF6F8F5E),
                            () => _launchUrl(widget.pymeData.webUrl ?? 'https://www.google.com'),
                          ),
                          _buildContactButton(
                            Icons.camera_alt,
                            'Instagram',
                            const Color(0xFF8B5A3C),
                            () => _launchUrl(widget.pymeData.instagramHandle ?? 'https://www.instagram.com'),
                          ),
                          _buildContactButton(
                            Icons.message,
                            'WhatsApp',
                            const Color(0xFF6F8F5E),
                            () => _launchUrl('https://wa.me/${widget.pymeData.whatsappNumber ?? '56912345678'}'),
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
              decoration: BoxDecoration(
                color: const Color(0xFFF4F1EA),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F3F2A).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFF4F1EA),
                backgroundImage: (widget.pymeData.logoUrl != null && widget.pymeData.logoUrl!.startsWith('http'))
                    ? NetworkImage(widget.pymeData.logoUrl!)
                    : AssetImage(widget.pymeData.logoUrl ?? 'assets/images/placeholder.jpg') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildClientOfferCard({required Map<String, dynamic> offer}) {
    final theme = Theme.of(context);
    
    // Parse color
    Color cardColor = const Color(0xFFE76F51);
    if (offer['color'] != null) {
      try {
        if (offer['color'] is int) {
          cardColor = Color(offer['color']);
        } else {
          String hex = offer['color'].toString().replaceAll('#', '');
          if (hex.length == 6) hex = 'FF$hex';
          cardColor = Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    // Determine icon
    IconData icon = Icons.local_offer;
    final type = offer['type'];
    if (type == '2x1') icon = Icons.people;
    if (type == 'discount') icon = Icons.percent;
    if (type == 'limited') icon = Icons.timer;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withOpacity(0.9), cardColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
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
              Icon(icon, color: const Color(0xFFF4F1EA), size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3F2A).withOpacity(0.26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DISPONIBLE',
                  style: TextStyle(
                    color: Color(0xFFF4F1EA),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer['title'] ?? 'Oferta',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFFF4F1EA),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            offer['description'] ?? '',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFF4F1EA).withOpacity(0.9)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1EA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFF4F1EA), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usa tu cupón mensual aquí',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF4F1EA),
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
    final theme = Theme.of(context);
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
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
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_not_supported, color: theme.colorScheme.onSurfaceVariant),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (product.isService) {
                          DateTime? pickedDate;
                          
                          // Check if it's a specific event
                          if (product.customAttributes['is_event'] == 'true' && 
                              product.customAttributes['event_date'] != null) {
                            
                            final eventDate = DateTime.parse(product.customAttributes['event_date']);
                            
                            // Show confirmation dialog instead of date picker
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Operativo Especial', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                content: Text(
                                  'Este servicio es un evento único para el día:\n\n${eventDate.day}/${eventDate.month}/${eventDate.year}\n\n¿Deseas seleccionar una hora para este día?',
                                  style: theme.textTheme.bodyMedium
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancelar', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                                    child: Text('Continuar', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              pickedDate = eventDate;
                            }
                          } else {
                            // Standard service booking
                            pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: theme.colorScheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                          }
                          
                          if (pickedDate != null && mounted) {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: theme.colorScheme.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedTime != null && mounted) {
                              final scheduledTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              
                              context.read<CartService>().addToCart(product, scheduledTime: scheduledTime);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reserva agendada para el ${scheduledTime.day}/${scheduledTime.month} a las ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: const Color(0xFFA7C957), // Verde Claro
                                ),
                              );
                            }
                          }
                        } else {
                          context.read<CartService>().addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Agregado al carrito'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Color(0xFFA7C957), // Verde Claro
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          String errorMessage = e.toString().replaceAll('Exception: ', '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage, style: theme.textTheme.bodyMedium),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isService ? theme.colorScheme.primary : const Color(0xFF2F3F2A), // Verde Hoja Profundo
                      foregroundColor: const Color(0xFFF4F1EA),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      product.customAttributes['is_event'] == 'true'
                          ? 'Participar'
                          : (product.isService ? 'Reservar' : 'Comprar'),
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

  Widget _buildInfoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
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
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
