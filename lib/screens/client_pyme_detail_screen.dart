import 'package:flutter/foundation.dart';
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
import '../models/review.dart';
import '../services/cart_service.dart';
import '../services/client_service.dart';
import '../widgets/supporter_counter.dart';
import '../widgets/donation_content.dart';
import 'package:go_router/go_router.dart';
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

  // Buscador de productos del catálogo
  final TextEditingController _productSearchController = TextEditingController();
  String _productSearchQuery = '';

  bool get _isFoundation => widget.pymeData.role == UserRole.foundation;
  String get _pymeName => widget.pymeData.name;

  late Future<List<Product>> _productsFuture;
  late Future<List<Map<String, dynamic>>> _offersFuture;
  late Stream<QuerySnapshot> _reviewsStream;
  late Future<UserProfile?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.getProductsByPyme(widget.pymeId).first;
    _offersFuture = _getOffersStream().first;
    _reviewsStream = FirebaseFirestore.instance
        .collection(_isFoundation ? 'foundations' : 'pymes')
        .doc(widget.pymeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
    _userProfileFuture = _pymeService.getUserProfile(widget.pymeId);
  }

  Future<void> _launchUrl(String urlString) async {
    String finalUrl = urlString.trim();
    if (finalUrl.isEmpty) return;

    // Add scheme if missing
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    final Uri url = Uri.parse(finalUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falló al abrir la aplicación o enlace externo')),
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
    final collection = _isFoundation ? 'foundations' : 'pymes';
    return FirebaseFirestore.instance
        .collection(collection)
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
        onDonate: _processDonation,
      ),
    );
  }

  Future<void> _processDonation(double amount, bool isMonthly) async {
    // Navigator.pop(context); // Close modal first? Or keep it open with loader?
    // Keeping it open might be better. Let's close it if we want full screen loader or show loader in dialog.
    // The original code uses a Dialog for loading which covers everything.
    // If I pop here, the modal closes and we are back to pyme details showing a loading dialog. That's fine.
    if (context.mounted && context.canPop()) {
      context.pop();
    }

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
                  onPressed: () {
                    if (context.mounted && context.canPop()) context.pop();
                  },
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
            .listen((snapshot) async {
              if (snapshot.docs.isNotEmpty && mounted) {
                 if (context.mounted && context.canPop()) context.pop(); // Cerrar Dialog de Espera
                 try {
                   await _clientService.addPoints(amount);
                 } catch (e) {
                   debugPrint('Error otorgando puntos por donación: $e');
                 }
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
              if (context.mounted && context.canPop()) context.pop(); // Close Success Dialog
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
              onPressed: () {
                if (context.mounted && context.canPop()) context.pop(false);
              }, // No
              child: const Text('Cancelar'),
            ),
             ElevatedButton(
              onPressed: () {
                if (context.mounted && context.canPop()) context.pop(true);
              }, // Sí
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
    _productSearchController.dispose();
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
                    onPressed: () {
                      if (context.mounted && context.canPop()) context.pop();
                    },
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
                           // Navigate to Cart Screen using go_router
                           context.go('/client/home/cart');
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
                      maxWidth: MediaQuery.of(context).size.width - 150, // Less aggressive constraint
                    ),
                    child: Text(
                      _pymeName,
                      maxLines: 2, // Allow 2 lines
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith( // Smaller title for fit
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
                      Hero(
                        tag: 'pyme_cover_${widget.pymeId}',
                        child: (widget.pymeData.coverImageUrl != null && widget.pymeData.coverImageUrl!.startsWith('http'))
                            ? Image.network(
                                widget.pymeData.coverImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                widget.pymeData.coverImageUrl ?? 'assets/images/placeholder.jpg',
                                fit: BoxFit.cover,
                              ),
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
                          FutureBuilder<UserProfile?>(
                            future: _userProfileFuture,
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
                      FutureBuilder<List<Product>>(
                        future: _productsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          final products = snapshot.data ?? [];

                          // Filtrar eventos
                          final now = DateTime.now();
                          final eventProducts = products
                              .where((p) => _isEventProduct(p))
                              .where((p) {
                                final eventDate = _eventDateTime(p);
                                final hasSeats = p.stock > 0 && (p.stock - p.registeredCount) > 0;
                                return hasSeats && (eventDate == null || !eventDate.isBefore(now));
                              })
                              .toList()
                            ..sort((a, b) {
                              final aDate = _eventDateTime(a) ?? DateTime(2100);
                              final bDate = _eventDateTime(b) ?? DateTime(2100);
                              return aDate.compareTo(bDate);
                            });

                          // Filtrar no-eventos
                          final nonEventProducts = products.where((p) => !_isEventProduct(p)).toList();

                          // Separar servicios y productos físicos
                          final serviceProducts = nonEventProducts.where((p) => p.isService).toList();
                          final physicalProducts = nonEventProducts.where((p) => !p.isService).toList();

                          // Aplicar búsqueda del usuario
                          List<Product> filterBySearch(List<Product> list) {
                            if (_productSearchQuery.isEmpty) return list;
                            final q = _productSearchQuery.toLowerCase();
                            return list.where((p) {
                              if (p.name.toLowerCase().contains(q)) return true;
                              if (p.category.toLowerCase().contains(q)) return true;
                              return p.customAttributes.values.any(
                                (v) => v.toString().toLowerCase().contains(q)
                              );
                            }).toList();
                          }

                          final filteredServices = filterBySearch(serviceProducts);
                          final filteredPhysical = filterBySearch(physicalProducts);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ofertas (solo Pymes)
                              if (!_isFoundation) ...[
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _offersFuture,
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

                              // Próximos Eventos
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

                              // Buscador de productos y servicios
                              if (nonEventProducts.isNotEmpty) ...[
                                TextField(
                                  controller: _productSearchController,
                                  onChanged: (val) => setState(() => _productSearchQuery = val),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar productos o servicios...',
                                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                                    suffixIcon: _productSearchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _productSearchController.clear();
                                              setState(() => _productSearchQuery = '');
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerLowest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Sección: Productos
                              if (filteredPhysical.isNotEmpty) ...[
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
                                    children: filteredPhysical.map((product) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildProductCard(product),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Sección: Servicios
                              if (filteredServices.isNotEmpty) ...[
                                Text(
                                  'Servicios',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: filteredServices.map((product) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _buildProductCard(product),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Si hay búsqueda activa sin resultados
                              if (_productSearchQuery.isNotEmpty &&
                                  filteredPhysical.isEmpty &&
                                  filteredServices.isEmpty &&
                                  nonEventProducts.isNotEmpty) ...[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Text(
                                      'Sin resultados para "$_productSearchQuery"',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
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
                      _buildSchedule(widget.pymeData.hours ?? '09:00 - 18:00'),
                      // _buildInfoRow(Icons.access_time, widget.pymeData.hours ?? '09:00 - 18:00'),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.location_on,
                        widget.pymeData.location ?? 'Sin dirección',
                        onTap: widget.pymeData.location != null && widget.pymeData.location!.isNotEmpty ? () async {
                          final query = Uri.encodeComponent(widget.pymeData.location!);
                          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        } : null,
                      ),
                      const SizedBox(height: 24),

                      // Contact Buttons
                      Wrap(
                        alignment: WrapAlignment.spaceAround,
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildContactButton(
                            Icons.language,
                            'Sitio Web',
                            const Color(0xFF6F8F5E),
                            () {
                               String web = widget.pymeData.webUrl ?? '';
                               if (web.isEmpty) web = 'www.google.com';
                               _launchUrl(web);
                            },
                          ),
                          _buildContactButton(
                            Icons.camera_alt,
                            'Instagram',
                            const Color(0xFF8B5A3C),
                            () {
                               String insta = widget.pymeData.instagramHandle ?? '';
                               if (insta.isEmpty) insta = 'instagram.com';
                               else if (!insta.contains('instagram.com')) {
                                  // Clean @ if user put it
                                  insta = insta.replaceAll('@', '').trim();
                                  insta = 'instagram.com/$insta';
                               }
                               _launchUrl(insta);
                            },
                          ),
                          _buildContactButton(
                            Icons.message,
                            'WhatsApp',
                            const Color(0xFF6F8F5E),
                            () {
                               String wa = widget.pymeData.whatsappNumber ?? '';
                               if (wa.isEmpty) wa = '56912345678';
                               // Clean anything that is not a number or plus
                               wa = wa.replaceAll(RegExp(r'[^\d+]'), '');
                               if (!wa.startsWith('+')) {
                                   if (wa.length == 9 && !wa.startsWith('569')) {
                                       wa = '569$wa'; // assume chile if 9 digits
                                   } else if (wa.startsWith('9') && wa.length == 8) {
                                       wa = '569$wa';
                                   } else if (!wa.startsWith('56')) {
                                       // generic fallback
                                       wa = '56$wa';
                                   }
                               }
                               _launchUrl('https://wa.me/$wa');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Reviews Section
                      _buildReviewsSection(theme),
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

  Widget _buildReviewsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opiniones de Clientes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      widget.pymeData.averageRating != null
                          ? widget.pymeData.averageRating!.toStringAsFixed(1)
                          : '0.0',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${widget.pymeData.reviewCount ?? 0})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_userId != null)
              TextButton.icon(
                onPressed: _showReviewDialog,
                icon: const Icon(Icons.rate_review, size: 18),
                label: const Text('Calificar'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _reviewsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Aún no hay reseñas. ¡Sé el primero en opinar sobre $_pymeName!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            final reviews = snapshot.data!.docs.map((doc) =>
               ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

            return Column(
              children: reviews.map((review) => _buildReviewCard(review, theme)).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showReviewDialog() {
    int _rating = 5;
    final TextEditingController _commentController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Dejar una Reseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            _rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu opinión sobre el servicio...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (_commentController.text.trim().isEmpty) return;

                    setDialogState(() => _isSubmitting = true);

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) throw Exception('Usuario no autenticado');

                      // 1. Guardar la reseña
                      final newReview = ReviewModel(
                        id: '',
                        userId: user.uid,
                        userName: user.displayName ?? 'Usuario',
                        rating: _rating.toDouble(),
                        comment: _commentController.text.trim(),
                        createdAt: DateTime.now(),
                      );

                      final collection = _isFoundation ? 'foundations' : 'pymes';
                      final pymeRef = FirebaseFirestore.instance.collection(collection).doc(widget.pymeId);

                      await pymeRef.collection('reviews').add(newReview.toMap());

                      // 2. Actualizar promedio
                      await FirebaseFirestore.instance.runTransaction((transaction) async {
                        final doc = await transaction.get(pymeRef);
                        if (doc.exists) {
                          final data = doc.data()!;
                          final double currentRating = data['averageRating']?.toDouble() ?? 0.0;
                          final int currentCount = data['reviewCount'] ?? 0;

                          final newCount = currentCount + 1;
                          final newRating = ((currentRating * currentCount) + _rating) / newCount;

                          transaction.update(pymeRef, {
                            'averageRating': newRating,
                            'reviewCount': newCount,
                          });

                           // Se actualizará en tiempo real a través de los Streams de Firebase
                           // No podemos mutar properties finales de widget.pymeData
                        }
                      });

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Gracias por tu reseña!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                        setDialogState(() => _isSubmitting = false);
                      }
                    }
                  },
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enviar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
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


  void _showEventDetail(Product event) {
    bool isParticipating = false; // State to track participation
    bool isLoadingParticipation = true;
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    // Check participation status
    if (user != null) {
      FirebaseFirestore.instance
          .collection('products')
          .doc(event.id)
          .collection('participants')
          .doc(user.uid)
          .get()
          .then((doc) {
        if (doc.exists) {
            // Check if widget is mounted before calling setState
            // Since we are inside a builder, we might need a StatefulBuilder's setState
            // But this function is inside the main state, so we can use a local variable
            // and update it inside the StatefulBuilder of the modal.
            isParticipating = true;
        }
        isLoadingParticipation = false;
      });
    } else {
        isLoadingParticipation = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {

          // Trigger the check once if needed, but since we did it outside,
          // we might just need to update the state once the future completes.
          // Better approach: Move the logic inside here or use a FutureBuilder.

          if (user != null && isLoadingParticipation) {
               FirebaseFirestore.instance
                  .collection('products')
                  .doc(event.id)
                  .collection('participants')
                  .doc(user.uid)
                  .get()
                  .then((doc) {
                    if (context.mounted) {
                        setStateModal(() {
                            isParticipating = doc.exists;
                            isLoadingParticipation = false;
                        });
                    }
               });
          }

          final eventDateStr = event.customAttributes['event_date'];
          DateTime? eventDate;
          if (eventDateStr != null) {
              try {
                  eventDate = DateTime.parse(eventDateStr);
              } catch (_) {
                try {
                  // Intentar formato dd/MM/yyyy
                  final parts = eventDateStr.split('/');
                  if (parts.length == 3) {
                    eventDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                  }
                } catch (__) {}
              }
          }
          final eventTimeStr = event.customAttributes['event_time'];
          if (eventDate != null && eventTimeStr != null) {
            try {
              final parts = eventTimeStr.split(':');
              eventDate = DateTime(
                eventDate!.year,
                eventDate!.month,
                eventDate!.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
            } catch (_) {}
          }
          final eventLocation = event.customAttributes['event_location'] ?? 'Ubicación por definir';
          final isFree = event.customAttributes['is_free'] == 'true' || event.price == 0;
          final requiresRegistration = event.customAttributes['require_registration'] == 'true';
          final capacity = event.stock;
          final remainingSeats = capacity - event.registeredCount;
          final hasSeats = capacity > 0 && remainingSeats > 0;


          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
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
                      Hero(
                        tag: 'event_${event.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            event.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 300,
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.event, size: 50, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        event.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Descripción del evento
                      if (event.description.isNotEmpty) ...[
                        Text(
                          event.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Indicador gratuito / con inscripción
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFree
                                  ? const Color(0xFF6F8F5E).withOpacity(0.15)
                                  : theme.colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isFree
                                    ? const Color(0xFF6F8F5E)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFree ? Icons.check_circle_outline : Icons.how_to_reg,
                                  size: 14,
                                  color: isFree ? const Color(0xFF6F8F5E) : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isFree ? 'Gratuito' : 'Con inscripción',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isFree ? const Color(0xFF6F8F5E) : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Detalles: fecha, hora, lugar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                            children: [
                                if (eventDate != null) ...[
                                    Row(
                                        children: [
                                            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                                            const SizedBox(width: 12),
                                            Text(
                                                'Fecha: ${eventDate.day}/${eventDate.month}/${eventDate.year}',
                                                style: theme.textTheme.bodyLarge,
                                            ),
                                        ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                        children: [
                                            Icon(Icons.access_time, color: theme.colorScheme.primary),
                                            const SizedBox(width: 12),
                                            Text(
                                                'Hora: ${eventDate.hour}:${eventDate.minute.toString().padLeft(2, '0')}',
                                                style: theme.textTheme.bodyLarge,
                                            ),
                                        ],
                                    ),
                                     const SizedBox(height: 12),
                                ],
                                Row(
                                    children: [
                                        Icon(Icons.location_on, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Text(
                                                'Lugar: $eventLocation',
                                                style: theme.textTheme.bodyLarge,
                                            ),
                                        ),
                                    ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                    children: [
                                        Icon(Icons.people_alt_outlined, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Text(
                                            hasSeats ? 'Cupos: $remainingSeats de $capacity' : 'Sin cupos disponibles',
                                            style: theme.textTheme.bodyLarge,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                      ),
                      const SizedBox(height: 100),
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
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isLoadingParticipation || isParticipating || !hasSeats) ? null : () async {
                         if (user == null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Debes iniciar sesión para participar')),
                             );
                             return;
                         }

                         setStateModal(() => isLoadingParticipation = true);

                         try {
                            if (eventDate != null && eventDate!.isBefore(DateTime.now())) {
                              throw Exception('Este evento ya finalizo.');
                            }

                            final eventRef = FirebaseFirestore.instance.collection('products').doc(event.id);
                            final participantRef = eventRef.collection('participants').doc(user.uid);
                            final participationRef = FirebaseFirestore.instance
                                .collection('clients')
                                .doc(user.uid)
                                .collection('participations')
                                .doc(event.id);

                            await FirebaseFirestore.instance.runTransaction((transaction) async {
                              final eventSnapshot = await transaction.get(eventRef);
                              final participantSnapshot = await transaction.get(participantRef);

                              if (!eventSnapshot.exists) {
                                throw Exception('Evento no disponible.');
                              }
                              if (participantSnapshot.exists) {
                                throw Exception('Ya estas inscrito en este evento.');
                              }

                              final eventData = eventSnapshot.data() as Map<String, dynamic>;
                              final capacity = (eventData['stock'] as num?)?.toInt() ?? 0;
                              final registeredCount = (eventData['registeredCount'] as num?)?.toInt() ?? 0;
                              if (capacity <= 0 || registeredCount >= capacity) {
                                throw Exception('Este evento no tiene cupos disponibles.');
                              }

                              transaction.update(eventRef, {
                                'registeredCount': FieldValue.increment(1),
                              });
                              transaction.set(participantRef, {
                                'userId': user.uid,
                                'registeredAt': FieldValue.serverTimestamp(),
                                'email': user.email,
                                'pymeId': event.pymeId,
                                'eventName': event.name,
                                'eventDate': eventDate,
                              });
                              transaction.set(participationRef, {
                                'eventId': event.id,
                                'eventName': event.name,
                                'eventDate': eventDate,
                                'pymeId': event.pymeId,
                                'pymeName': widget.pymeData.name,
                                'registeredAt': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                            });

                            setStateModal(() {
                                isParticipating = true;
                                isLoadingParticipation = false;
                            });

                             ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(
                                     content: Text('¡Te has inscrito al evento!'),
                                     backgroundColor: Color(0xFF6F8F5E),
                                 ),
                             );

                         } catch (e) {
                             setStateModal(() => isLoadingParticipation = false);
                             ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Error al inscribirse: $e')),
                             );
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isParticipating ? Colors.grey : theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLoadingParticipation
                            ? 'Cargando...'
                            : (isParticipating ? 'Inscrito' : (!hasSeats ? 'Sin cupos' : 'Participar')),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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

  void _showProductDetail(Product product) {
    int quantity = 1;
    final theme = Theme.of(context);

    // Variant selection state
    final Map<String, String> selectedAttributes = {};
    ProductVariant? selectedVariant;

    // Filtrar atributos relevantes (excluir campos internos de evento/servicio)
    const excludedKeys = {
      'is_event', 'event_date', 'event_location', 'event_time',
      'allow_quote', 'require_registration', 'is_free',
    };
    final attributes = product.customAttributes.entries.where((e) {
      final key = e.key.toLowerCase();
      return !excludedKeys.contains(key) && e.value.toString().isNotEmpty;
    }).toList();

    // Helper to find matching variant
    ProductVariant? findVariant(Map<String, String> selected) {
      if (!product.hasVariants) return null;
      if (selected.length != product.variantAxes.length) return null;
      try {
        return product.variants.firstWhere((v) {
          return selected.entries.every((e) => v.attributes[e.key] == e.value);
        });
      } catch (_) {
        return null;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentPrice = selectedVariant?.getPrice(product.price) ?? product.price;
          final currentStock = selectedVariant?.stock ?? (product.hasVariants ? 0 : product.stock);

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
                            '\$${(currentPrice * quantity).toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Variant Selectors
                      if (product.hasVariants) ...[
                        ...product.variantAxes.map((axis) {
                          final axisName = axis['name'] ?? '';
                          final values = (axis['values'] ?? '').split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  axisName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: values.map((value) {
                                    final isSelected = selectedAttributes[axisName] == value;
                                    return ChoiceChip(
                                      label: Text(value),
                                      selected: isSelected,
                                      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                                      labelStyle: TextStyle(
                                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      side: BorderSide(
                                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedAttributes[axisName] = value;
                                          } else {
                                            selectedAttributes.remove(axisName);
                                          }
                                          selectedVariant = findVariant(selectedAttributes);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Stock indicator for selected variant
                        if (selectedVariant != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: currentStock > 0
                                  ? const Color(0xFF6F8F5E).withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  currentStock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                                  size: 18,
                                  color: currentStock > 0 ? const Color(0xFF6F8F5E) : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentStock > 0
                                      ? '$currentStock disponibles'
                                      : 'Sin stock',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: currentStock > 0 ? const Color(0xFF6F8F5E) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (product.hasVariants)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Selecciona las opciones',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

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

                      // Attributes (only for non-variant products)
                      if (!product.hasVariants && attributes.isNotEmpty) ...[
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
                          onPressed: (product.hasVariants && selectedVariant == null) || currentStock == 0
                              ? null
                              : () async {
                            // Check Subscription Status first
                            bool isSubscribed = false;
                            try {
                              isSubscribed = await _clientService.getSubscriptionStatus().first;
                            } catch (e) {
                              debugPrint('Error checking subscription: $e');
                            }

                            if (!isSubscribed) {
                              if (!mounted) return;
                              if (context.canPop()) context.pop();

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Beneficio Exclusivo'),
                                  content: const Text('Para adquirir productos o inscribirte en talleres, necesitas ser Beneficiario Plus.'),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancelar'),
                                      onPressed: () {
                                        if (context.mounted && context.canPop()) context.pop();
                                      }
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        foregroundColor: theme.colorScheme.onPrimary,
                                      ),
                                      child: const Text('Suscribirse (\$2.000)'),
                                      onPressed: () {
                                        if (context.mounted && context.canPop()) context.pop();
                                        context.go('/client/home/subscription');
                                      },
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            for (int i = 0; i < quantity; i++) {
                              context.read<CartService>().addToCart(product, variant: selectedVariant);
                            }

                            if (context.mounted && context.canPop()) context.pop();
                            final variantText = selectedVariant != null ? ' (${selectedVariant!.label})' : '';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Agregado $quantity$variantText al carrito'),
                                backgroundColor: const Color(0xFFA7C957),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            product.hasVariants && selectedVariant == null
                                ? 'Selecciona opciones'
                                : (currentStock == 0 ? 'Sin stock' : 'Agregar al Carrito'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
         if (isEvent) {
             _showEventDetail(product);
         } else if (isQuote || isService) {
            // Mostrar detalle del servicio primero (Fix 4)
            _showServiceDetail(product);
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
                      if (isEvent) {
                          _showEventDetail(product);
                          return;
                      }
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
                              debugPrint('Error checking subscription: $e');
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

  /// Muestra el detalle de un servicio y al final ofrece el botón "Solicitar Cotización"
  void _showServiceDetail(Product product) {
    final theme = Theme.of(context);
    final isQuote = product.customAttributes['allow_quote'] == 'true';

    const excludedKeys = {
      'is_event', 'event_date', 'event_location', 'event_time',
      'allow_quote', 'require_registration', 'is_free',
    };
    final attributes = product.customAttributes.entries.where((e) {
      final key = e.key.toLowerCase();
      return !excludedKeys.contains(key) && e.value.toString().isNotEmpty;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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
                  // Imagen del servicio
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      product.imageUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 260,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.design_services, size: 60, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Etiqueta "Servicio"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.design_services, size: 14, color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          'Servicio',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nombre y precio / "Cotizar"
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
                      const SizedBox(width: 12),
                      Text(
                        isQuote ? 'A cotizar' : '\$${product.price.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isQuote ? theme.colorScheme.secondary : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  if (product.description.isNotEmpty) ...[
                    Text(
                      'Descripción',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Atributos del servicio
                  if (attributes.isNotEmpty) ...[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
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
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

            // Botón de acción al final
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cierra modal de detalle
                    _showQuoteDialog(product); // Abre diálogo de cotización
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isQuote ? 'Solicitar Cotización' : 'Reservar Servicio',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
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

  Widget _buildSchedule(String hoursStr) {
    final theme = Theme.of(context);

    // If empty or simple string, allow fallback
    if (hoursStr.isEmpty) return const SizedBox.shrink();

    List<String> lines = hoursStr.split('\n').where((s) => s.trim().isNotEmpty).toList();

    // Check if it looks like a structured schedule (multiple lines)
    bool isMultiline = hoursStr.contains('\n');

    if (!isMultiline) {
      return _buildInfoRow(Icons.access_time, hoursStr);
    }

    // Further validation: checks if lines start with common day names or contain ':' in a way that implies key-value
    // For now, multiline is a good enough proxy given the edit screen enforces it.

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.access_time, color: theme.colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.map((line) {
              final parts = line.split(':');
              String day = parts[0].trim();
              String time = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

              if (parts.length == 1) {
                  day = line;
                  time = '';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90, // Fixed width to align columns
                      child: Text(
                        day,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        time,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: onTap != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onTap != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: row,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: row,
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
