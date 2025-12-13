import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/offer_data.dart';
import '../models/vitrina_data.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/supporter_counter.dart';

class ClientPymeDetailScreen extends StatefulWidget {
  const ClientPymeDetailScreen({super.key});

  @override
  State<ClientPymeDetailScreen> createState() => _ClientPymeDetailScreenState();
}

class _ClientPymeDetailScreenState extends State<ClientPymeDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProductService _productService = ProductService();
  bool _isFollowing = false;
  List<Product> _products = [];

  List<Product> get _eventProducts => _products.where((p) => p.customAttributes['is_event'] == 'true' || (VitrinaData.isFoundation && p.isService)).toList();
  List<Product> get _standardProducts => _products.where((p) => p.customAttributes['is_event'] != 'true' && (!VitrinaData.isFoundation || !p.isService)).toList();

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
              'Compartir ${VitrinaData.name}',
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
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    // Generates a link like https://mipyme.app/pyme/pyme1
                    final String link = 'https://mipyme.app/pyme/${VitrinaData.name.replaceAll(' ', '').toLowerCase()}';
                    _launchUrl('https://wa.me/?text=¡Hola!%20Te%20recomiendo%20ver%20*${VitrinaData.name}*%20en%20la%20app%20MiPyme.%0A%0AMira%20sus%20productos%20y%20ofertas%20aquí:%20$link');
                  },
                ),
                _buildShareOption(
                  icon: Icons.email,
                  label: 'Correo',
                  color: const Color(0xFFBC4749), // Café
                  onTap: () {
                    Navigator.pop(context);
                    final String link = 'https://mipyme.app/pyme/${VitrinaData.name.replaceAll(' ', '').toLowerCase()}';
                    _launchUrl('mailto:?subject=Te%20recomiendo%20${VitrinaData.name}&body=Hola,%0A%0AEchale%20un%20vistazo%20a%20${VitrinaData.name}.%20Tienen%20cosas%20increíbles.%0A%0AVer%20perfil:%20$link');
                  },
                ),
                _buildShareOption(
                  icon: Icons.more_horiz,
                  label: 'Más',
                  color: const Color(0xFFA7C957), // Verde Claro
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
    Color color = Colors.grey,
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
                    'Donar a ${VitrinaData.name}',
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
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                    color: Colors.black.withValues(alpha: 0.05),
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
                    value: VitrinaData.currentDonations / VitrinaData.donationGoal,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: const Color(0xFFFFD700), // Gold for progress
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${VitrinaData.currentDonations.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700), // Gold
                        ),
                      ),
                      Text(
                        'Meta: \$${VitrinaData.donationGoal.toStringAsFixed(0)}',
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
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF386641), // Verde Hoja Profundo
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isMonthly ? 'Suscribirse Mensualmente' : 'Realizar Donación',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: _isFollowing ? theme.colorScheme.primary : Colors.white,
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
                          backgroundColor: _isFollowing ? theme.colorScheme.primary : Colors.grey,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _showShareOptions,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    VitrinaData.name,
                    style: theme.textTheme.titleLarge?.copyWith(
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
                      VitrinaData.coverImageUrl.startsWith('http')
                          ? Image.network(
                              VitrinaData.coverImageUrl,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
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
                          SupporterCounter(count: VitrinaData.supporterCount),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        VitrinaData.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (VitrinaData.isFoundation) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showDonationModal,
                            icon: const Icon(Icons.volunteer_activism, color: Colors.white),
                            label: Text(
                              'Donar a esta Fundación',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF386641), // Verde Hoja Profundo
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
                      if (!VitrinaData.isFoundation) ...[
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
                      ] else if (_eventProducts.isNotEmpty) ...[
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
                            children: _eventProducts.map((product) {
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
                      if (_standardProducts.isNotEmpty) ...[
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
                            children: _standardProducts.map((product) {
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
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
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
                            () => _launchUrl('https://www.google.com'),
                          ),
                          _buildContactButton(
                            Icons.camera_alt,
                            'Instagram',
                            Colors.purpleAccent,
                            () => _launchUrl('https://www.instagram.com'),
                          ),
                          _buildContactButton(
                            Icons.message,
                            'WhatsApp',
                            Colors.green,
                            () => _launchUrl('https://wa.me/56912345678'),
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
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: VitrinaData.logoUrl.startsWith('http')
                    ? NetworkImage(VitrinaData.logoUrl)
                    : AssetImage(VitrinaData.logoUrl) as ImageProvider,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildClientOfferCard({required Offer offer}) {
    final theme = Theme.of(context);
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
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            offer.description,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
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
                    style: theme.textTheme.bodySmall?.copyWith(
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
    final theme = Theme.of(context);
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      backgroundColor: product.isService ? theme.colorScheme.primary : const Color(0xFF386641), // Verde Hoja Profundo
                      foregroundColor: Colors.white,
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
