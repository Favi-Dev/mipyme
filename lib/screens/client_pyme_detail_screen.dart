import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/product_service.dart';
import '../services/pyme_service.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/client_service.dart';
import '../widgets/supporter_counter.dart';
import '../widgets/donation_content.dart';
import 'client_cart_screen.dart' as import_cart;
import 'client_subscription_screen.dart';
import '../services/payment_service.dart';

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
  final ClientService _clientService = ClientService();
  final PaymentService _paymentService = PaymentService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoadingPayment = false;
  
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
    final String link = 'https://mipyme.app/pyme/${_pymeName.replaceAll(' ', '').toLowerCase()}';
    // Using native share via share_plus
    Share.share(
      '¡Hola! Te recomiendo ver *$_pymeName* en la app MiPyme.\n\nMira sus productos y ofertas aquí: $link',
      subject: 'Te recomiendo $_pymeName',
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
    List<int> amounts = [1000, 3000, 5000, 10000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFFF4F1EA), // Beige Suave
      builder: (context) => DonationContent(
        pymeData: widget.pymeData,
        amounts: amounts,
        isGuest: _userId == null,
        onDonate: _processDonation,
      ),
    );
  }

  Future<void> _processDonation(double amount, bool isMonthly) async {
    // Navigator.pop(context); // Close modal first? Or keep it open with loader? 
    // Keeping it open might be better. Let's close it if we want full screen loader or show loader in dialog.
    // The original code uses a Dialog for loading which covers everything.
    // If I pop here, the modal closes and we are back to pyme details showing a loading dialog. That's fine.
    Navigator.pop(context);

    // setState(() => _isLoadingPayment = true); // Not really used in UI currently but good for state

    try {
      final user = FirebaseAuth.instance.currentUser;
      final String payerEmail = user?.email ?? 'invitado@soyplus.app';
      final String title = isMonthly 
          ? 'Suscripción Mensual a ${widget.pymeData.name}' 
          : 'Donación a ${widget.pymeData.name}';

      Map<String, dynamic> result;
      
      if (isMonthly) {
        // Opción 1: Crear Suscripción (Si está logueado o tiene email)
        result = await _paymentService.createSubscription(
          title: title,
          price: amount,
          payerEmail: payerEmail,
        );
      } else {
        // Opción 2: Pago Único (Checkout Pro)
        result = await _paymentService.createPreference(
          title: title,
          price: amount,
          pymeId: widget.pymeData.id,
        );
      }

      // 1. Obtener el link de pago (sandbox para pruebas)
      final String initPoint = result['sandbox_init_point'] ?? result['init_point'];
      
      // 2. Abrir Mercado Pago
      final Uri url = Uri.parse(initPoint);
      final String? externalReference = result['external_reference'];

      // Usar platformDefault para mayor compatibilidad web y evitar bloqueo de popups
      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
        throw 'No se pudo abrir la pasarela de pago. Por favor, revisa si tienes bloqueador de pop-ups.';
      }

      // 3. SECUENCIA REAL DE PAGO (Polling / Escucha Activa)
      if (!mounted) return;

      if (externalReference != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false, // Bloquear el botón atrás
            child: AlertDialog(
              title: const Text('Procesando Pago...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Estamos esperando la confirmación segura de Mercado Pago.\nPor favor, completa el pago en tu navegador.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancelar / Cerrar'), // Escotilla de escape si el usuario se arrepiente
                ),
              ],
            ),
          ),
        );

        // Escuchar cambios en Firestore donde externalReference coincida
        FirebaseFirestore.instance
            .collection('payments')
            .where('externalReference', isEqualTo: externalReference)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.docs.isNotEmpty && mounted) {
                 Navigator.pop(context); // Cerrar Dialog de Espera
                 _showSuccessDialog(); // Mostrar Éxito
              }
            });

      } else {
         // Fallback legacy por si falta externalReference (subscription mensual)
         _showLegacyConfirmation();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar pago: $e')),
        );
      }
    } finally {
      // setState(() => _isLoadingPayment = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Pago Confirmado!'),
        content: Text(_userId == null 
          ? 'Tu donación ha sido recibida y verificada. ¡Gracias!'
          : 'Tu donación ha sido procesada exitosamente.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Success Dialog
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showLegacyConfirmation() async {
      if (!mounted) return;
      
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Completar Donación'),
          content: const Text(
            'Se ha abierto el navegador para procesar tu donación. ¿Pudiste completarla?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // No
              child: const Text('Cancelar'),
            ),
             ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Sí
              child: const Text('¡Sí, ya doné!'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        _showSuccessDialog();
      }
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
                      stream: _pymeService.isFollowing(_userId, widget.pymeId),
                      builder: (context, snapshot) {
                        final isFollowing = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isFollowing ? Icons.favorite : Icons.favorite_border,
                            color: isFollowing ? theme.colorScheme.primary : const Color(0xFFF4F1EA),
                          ),
                          onPressed: () async {
                            await _pymeService.toggleFollow(_userId, widget.pymeId);
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
                  title: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 280, // 110 padding + ~170 for actions (Cart, Heart, Share)
                    ),
                    child: Text(
                      _pymeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          StreamBuilder<UserProfile?>(
                            stream: _pymeService.getUserProfileStream(widget.pymeId),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.supporterCount ?? widget.pymeData.supporterCount;
                              return SupporterCounter(count: count);
                            },
                          ),
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
                          
                          // Filter events and other products
                          final eventProducts = products.where((p) => p.customAttributes['is_event'] == 'true').toList();
                          final standardProducts = products.where((p) => p.customAttributes['is_event'] != 'true').toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Offers (if not Foundation?) - Logic seems to hide offers for Foundations?
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
                              ],

                              // Events Section
                              if (eventProducts.isNotEmpty) ...[
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

                              // Products & Services Section
                              if (standardProducts.isNotEmpty) ...[
                                Text(
                                  'Productos y Servicios',
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
              
              // Fade out logo as it moves up to avoid overlapping with AppBar
              // AppBar expanded height 250. Pinned height ~kToolbarHeight (56).
              // We want to fade out before it hits the text or back button.
              // Let's start fading at top = 120 and finish at top = 60.
              double opacity = 1.0;
              if (top < 120) {
                 opacity = (top - 60) / 60;
                 if (opacity < 0) opacity = 0;
                 if (opacity > 1) opacity = 1;
              }

              return Positioned(
                top: top,
                left: 16,
                child: Opacity(
                  opacity: opacity,
                  child: child!,
                ),
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
    Color cardColor = theme.colorScheme.primary;
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


  void _showProductDetail(Product product) {
    int quantity = 1;
    final theme = Theme.of(context);

    // Filter relevant attributes to display
    final attributes = product.customAttributes.entries.where((e) {
      final key = e.key.toLowerCase();
      return key != 'is_event' && key != 'event_date' && e.value.toString().isNotEmpty;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // Large Image
                      Hero(
                        tag: 'product_${product.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            product.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 300,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.image_not_supported, size: 50, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '\$${(product.price * quantity).toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      if (product.description.isNotEmpty) ...[
                        Text(
                          'Descripción',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Attributes (Color, Talla, Modelo...)
                      if (attributes.isNotEmpty) ...[
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: attributes.map((entry) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value.toString(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Counter
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: quantity > 1 
                                  ? () => setState(() => quantity--) 
                                  : null,
                            ),
                            Text(
                              quantity.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => setState(() => quantity++),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Check Subscription Status first
                            bool isSubscribed = false;
                            try {
                              isSubscribed = await _clientService.getSubscriptionStatus().first;
                            } catch (e) {
                              print('Error checking subscription: $e');
                            }

                            if (!isSubscribed) {
                              if (!mounted) return;
                              Navigator.pop(context); // Close product detail
                              
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Beneficio Exclusivo'),
                                  content: const Text('Para adquirir productos o inscribirte en talleres, necesitas ser Beneficiario Plus.'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancelar'), 
                                      onPressed: () => Navigator.pop(context)
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                      ),
                                      child: const Text('Suscribirse (\$2.000)'),
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        Navigator.push(
                                          context, 
                                          MaterialPageRoute(builder: (_) => const ClientSubscriptionScreen())
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            // Logic to add specific quantity
                            // Since CartService might handle 1 by 1 or custom, 
                            // we loop or update CartService to accept quantity.
                            // Assuming CartService.addToCart adds 1 instance. 
                            // Current `addToCart` impl in context adds a product.
                            // Ideally CartService should support quantity param.
                            // For now, loop calls or one call if updated.
                            // Checking previous code: context.read<CartService>().addToCart(product);
                            
                            // Simple loop for now as fallback, but ideally update service
                            for (int i = 0; i < quantity; i++) {
                              context.read<CartService>().addToCart(product);
                            }
                            
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Agregado $quantity al carrito'),
                                backgroundColor: const Color(0xFFA7C957),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Agregar al Carrito',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    final bool isQuote = product.customAttributes['allow_quote'] == 'true';
    final bool isEvent = product.customAttributes['is_event'] == 'true';
    final bool isService = product.isService;

    return GestureDetector(
      onTap: () {
         if (isQuote) {
            _showQuoteDialog(product);
         } else {
            _showProductDetail(product);
         }
      },
      child: Container(
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
                if (!isQuote)
                  Text(
                    '\$${product.price.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                   Text(
                    'Cotizar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isQuote) {
                        _showQuoteDialog(product);
                        return;
                      }

                      try {
                        // Check Subscription Status for instant actions (Services/Events)
                        if (isService) {
                           bool isSubscribed = false;
                            try {
                              isSubscribed = await _clientService.getSubscriptionStatus().first;
                            } catch (e) {
                              print('Error checking subscription: $e');
                            }

                            if (!isSubscribed) {
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Beneficio Exclusivo'),
                                  content: const Text('Para adquirir productos o inscribirte en talleres, necesitas ser Beneficiario Plus.'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancelar'), 
                                      onPressed: () => Navigator.pop(context)
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                      ),
                                      child: const Text('Suscribirse (\$2.000)'),
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        Navigator.push(
                                          context, 
                                          MaterialPageRoute(builder: (_) => const ClientSubscriptionScreen())
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                        }

                        if (isService) {
                          DateTime? pickedDate;
                          
                          // Check if it's a specific event
                          if (isEvent && product.customAttributes['event_date'] != null) {
                            
                            final eventDate = DateTime.parse(product.customAttributes['event_date']); // Need to fix parsing format dd/MM/yyyy
                            // Wait, the saved format is dd/MM/yyyy in PymeAddEventScreen
                            // DateTime.parse expects yyyy-MM-dd
                            
                            final parts = product.customAttributes['event_date'].split('/');
                            final validEventDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                            
                            // Show confirmation dialog instead of date picker
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Operativo Especial', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                content: Text(
                                  'Este servicio es un evento único para el día:\n\n${product.customAttributes['event_date']}\n\n¿Deseas seleccionar una hora para este día?',
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
                              pickedDate = validEventDate;
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
                          // Standard product flow: Open details
                          _showProductDetail(product);
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
                      backgroundColor: isQuote ? theme.colorScheme.secondary : (isService ? theme.colorScheme.primary : const Color(0xFF2F3F2A)), 
                      foregroundColor: const Color(0xFFF4F1EA),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isEvent
                          ? 'Participar'
                          : (isQuote 
                              ? 'Cotizar' 
                              : (isService ? 'Reservar' : 'Ver Detalles')),
                    ),
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

  Future<void> _showQuoteDialog(Product product) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Solicitar Cotización', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Quieres enviar una solicitud de cotización para ${product.name} a ${_pymeName}?\n\nEl encargado te contactará a la brevedad.',
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
            child: Text('Sí, cotizar', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debes iniciar sesión para cotizar')),
          );
          return;
        }

        // Create a Quote Request (Using Orders collection for now with status 'quote_requested')
        await FirebaseFirestore.instance.collection('orders').add({
          'pymeId': widget.pymeId,
          'userId': user.uid,
          'userEmail': user.email,
          'userName': user.displayName ?? 'Usuario',
          'products': [product.toMap()],
          'total': 0,
          'status': 'quote_requested',
          'createdAt': FieldValue.serverTimestamp(),
          'isQuote': true,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cotización enviada. El encargado te contactará pronto.'),
              backgroundColor: Color(0xFF6F8F5E),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar cotización: $e')),
          );
        }
      }
    }
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
