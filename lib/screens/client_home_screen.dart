import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/pyme_service.dart';
import '../services/client_service.dart';
import 'client_pyme_detail_screen.dart';
import 'donation_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final bool showFoundationsOnly;

  const ClientHomeScreen({
    super.key,
    this.showFoundationsOnly = false,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<UserProfile>> _pymeStream;
  String _searchQuery = '';
  // final Set<String> _followedPymes = {};
  final Set<String> _selectedTags = {};
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _pymeStream = widget.showFoundationsOnly 
        ? PymeService().getFoundations()
        : PymeService().getPymes();
  }

  void _showNotifications() {
    final theme = Theme.of(context);
    final clientService = ClientService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: clientService.getNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Text('Error al cargar notificaciones');
              }
              
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No tienes notificaciones nuevas.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isRead = notif['read'] ?? false;
                  // Handle Timestamp or fallback
                  // final timestamp = notif['createdAt'] ... 

                  return ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : theme.colorScheme.primary,
                    ),
                    title: Text(
                      notif['title'] ?? 'Notificación',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notif['body'] ?? ''),
                    onTap: () {
                      clientService.markNotificationAsRead(notif['id']);
                      // Optional: Navigate if notification has 'route' or 'data'
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(List<UserProfile> pymes) {
    final theme = Theme.of(context);
    // Extract all unique tags
    final allTags = <String>{};
    for (var pyme in pymes) {
      if (pyme.tags != null) {
        allTags.addAll(pyme.tags!);
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por etiquetas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          // Update main state as well to reflect changes immediately if needed
                          // or just wait until modal closes. Here we update main state too.
                          setState(() {}); 
                        },
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Aplicar Filtros'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 70,
        title: StreamBuilder<UserProfile?>(
          stream: FirebaseAuth.instance.currentUser != null
              ? PymeService().getUserProfileStream(FirebaseAuth.instance.currentUser!.uid)
              : Stream.value(null),
          builder: (context, userSnapshot) {
            final userProfile = userSnapshot.data;
            final isFoundationMode = widget.showFoundationsOnly;
            
            return Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: (userProfile?.logoUrl != null && userProfile!.logoUrl!.startsWith('http')) 
                      ? NetworkImage(userProfile.logoUrl!)
                      : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                  backgroundColor: const Color(0x3DF4F1EA),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !isFoundationMode 
                          ? 'Hola, ${userProfile?.name.split(' ').first ?? 'Invitado'}'
                          : 'Hola, ${userProfile?.name.split(' ').first ?? 'Invitado'}', // Show user name in both modes
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFF4F1EA),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                          children: [
                            if (!isFoundationMode)
                               Icon(Icons.location_on, size: 12, color: const Color(0xFFF4F1EA).withOpacity(0.9)),
                            if (!isFoundationMode)
                               const SizedBox(width: 4),

                            Expanded(
                              child: Text(
                                isFoundationMode 
                                  ? 'Apoya una fundación hoy ❤' 
                                  : (userProfile?.location ?? 'Ubicación no disponible'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFF4F1EA).withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1EA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.volunteer_activism, color: Color(0xFFF4F1EA)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonationScreen()),
                );
              },
              tooltip: 'Realizar Donación',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F1EA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFFF4F1EA)),
              onPressed: _showNotifications,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: FirebaseAuth.instance.currentUser != null
            ? PymeService().getFollowedPymeIds(FirebaseAuth.instance.currentUser!.uid)
            : Stream.value([]),
        builder: (context, followedSnapshot) {
          final followedIds = (followedSnapshot.data ?? []).toSet();

          return StreamBuilder<List<UserProfile>>(
            stream: _pymeStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final pymes = snapshot.data ?? [];
              
              // Sort Pymes: Followed first
              pymes.sort((a, b) {
                final aFollowed = followedIds.contains(a.id);
                final bFollowed = followedIds.contains(b.id);
                if (aFollowed && !bFollowed) return -1;
                if (!aFollowed && bFollowed) return 1;
                return 0;
              });
              
              // Filter logic
              final filteredPymes = pymes.where((pyme) {
            final name = pyme.name;
            final category = pyme.category ?? '';
            
            final matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                category.toLowerCase().contains(_searchQuery.toLowerCase());
            
            // Filter by tags if any are selected
            final tags = pyme.tags ?? [];
            final matchesTags = _selectedTags.isEmpty || 
                tags.any((tag) => _selectedTags.contains(tag));

            final matchesCategory = _selectedCategory == null || 
                _selectedCategory == 'Todo' || 
                category == _selectedCategory;

            return matchesSearch && matchesTags && matchesCategory;
          }).toList();

          return SingleChildScrollView(
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
                          color: const Color(0xFFF4F1EA),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2F3F2A).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF2F3F2A)),
                          decoration: InputDecoration(
                            hintText: widget.showFoundationsOnly ? 'Buscar fundación...' : '¿Qué buscas hoy?',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF2F3F2A).withOpacity(0.6)),
                            prefixIcon:
                                Icon(Icons.search, color: theme.colorScheme.primary),
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
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Color(0xFFF4F1EA)),
                        onPressed: () => _showFilterDialog(pymes),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Categories (Hide if showing foundations only)
                if (!widget.showFoundationsOnly) ...[
                  _buildCategories(context),
                  const SizedBox(height: 24),
                ],

                // Featured Offers (Dynamic)
                if (!widget.showFoundationsOnly) ...[
                  _buildSectionHeader(context, 'Ofertas para ti', showViewAll: false),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: PymeService().getSpecialOffersGlobal(),
                      builder: (context, offersSnapshot) {
                        if (offersSnapshot.hasError) {
                          // Likely missing index for collectionGroup query.
                          final error = offersSnapshot.error.toString();
                          debugPrint("Error fetching offers: $error");
                          
                          // Convert error to user friendly message or show link for dev
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.contains('failed-precondition') 
                                      ? 'Falta índice en Firebase. Revisa la consola.' 
                                      : 'No se pudieron cargar las ofertas.',
                                    style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        if (offersSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final allOffers = offersSnapshot.data ?? [];
                        
                        // Filter offers to only show those from the currently loaded pymes list
                        final validOffers = allOffers.where((offer) {
                          final pymeId = offer['pymeId'];
                          return pymes.any((p) => p.id == pymeId);
                        }).toList();
                        
                        if (validOffers.isEmpty) {
                           return Center(
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(Icons.local_offer_outlined, size: 40, color: theme.colorScheme.outline),
                                 Text('No hay ofertas destacadas hoy', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                               ],
                             ),
                           );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: validOffers.length,
                          itemBuilder: (context, index) {
                            final offer = validOffers[index];
                            final pymeId = offer['pymeId'];
                            
                            // Find the Pyme profile for this offer
                            final pyme = pymes.firstWhere(
                              (p) => p.id == pymeId,
                              orElse: () => UserProfile(id: 'unknown', name: 'Desconocido', email: '', role: UserRole.pyme, createdAt: DateTime.now()), // Dummy fallback
                            );

                            return GestureDetector(
                              onTap: () {
                                // Navigate to Pyme Detail or Offer Detail
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientPymeDetailScreen(
                                      pymeId: pyme.id,
                                      pymeData: pyme,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2F3F2A).withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Background Image (Pyme Logo as requested)
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: (pyme.logoUrl != null && pyme.logoUrl!.isNotEmpty)
                                            ? Image.network(
                                                pyme.logoUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                color: theme.colorScheme.primaryContainer,
                                                child: Icon(Icons.store, 
                                                  size: 60, 
                                                  color: theme.colorScheme.primary.withOpacity(0.3)
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    // Gradient Shadow for text visibility
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.2), // Subtle start
                                              Colors.black.withOpacity(0.8), // Dark bottom
                                            ],
                                            stops: const [0.5, 0.75, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Content
                                    Padding( 
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Top Row: Tag and Pyme Name
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'OFERTA ESPECIAL',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              Flexible(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 8.0),
                                                  child: Text(
                                                    pyme.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.95),
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      shadows: const [
                                                        Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black54)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // Bottom Row: Details
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                offer['title'] ?? 'Oferta',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45)
                                                  ],
                                                ),
                                              ),
                                              if (offer['description'] != null && offer['description'].toString().isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  offer['description'],
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 12,
                                                    height: 1.2,
                                                    shadows: const [
                                                      Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black45)
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              if (offer['price'] != null) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '\$${offer['price']}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],

                // Upcoming Events (Only for Foundations)
                if (widget.showFoundationsOnly) ...[
                  _buildSectionHeader(context, 'Eventos Próximos', showViewAll: false),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: StreamBuilder<List<Product>>(
                      stream: ProductService().getProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final allProducts = snapshot.data ?? [];
                        // Filter for events AND check if they belong to visible pymes/foundations
                        final events = allProducts.where((p) {
                          final isEvent = p.customAttributes['is_event'].toString() == 'true';
                          // Ensure we only show events for the currently loaded Pymes/Foundations
                          final belongsToVisiblePyme = pymes.any((user) => user.id == p.pymeId);
                          return isEvent && belongsToVisiblePyme;
                        }).toList();

                        if (events.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay eventos próximos.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            // Safe lookup because we filtered using the same list above
                            final pyme = pymes.firstWhere((p) => p.id == event.pymeId);

                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _buildOfferCard(
                                context,
                                pyme,
                                event.name,
                                event.description,
                                'Eventos',
                                theme.colorScheme.primary,
                                Icons.event,
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Nearby Pymes / Foundations List
                _buildSectionHeader(context, widget.showFoundationsOnly ? 'Fundaciones Disponibles' : 'Pymes en tu zona', showViewAll: false),
                const SizedBox(height: 16),
                _buildPymesList(filteredPymes),
              ],
            ),
            );
            }
          );
        }
      ),
    );
  }

  Widget _buildPymesList(List<UserProfile> pymes) {
    if (pymes.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.showFoundationsOnly ? Icons.volunteer_activism : Icons.storefront_outlined,
                size: 64,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron resultados',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty 
                  ? 'Intenta con otro término de búsqueda'
                  : 'No hay ${widget.showFoundationsOnly ? 'fundaciones' : 'pymes'} disponibles aún.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pymes.length,
      itemBuilder: (context, index) {
        return _buildPymeCard(context, pymes[index]);
      },
    );
  }

  Widget _buildCategories(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      {'icon': Icons.grid_view_rounded, 'label': 'Todo', 'key': 'Todo'},
      {'icon': Icons.store_mall_directory, 'label': 'Retail', 'key': 'Comercio/retail'},
      {'icon': Icons.restaurant_menu, 'label': 'Comida', 'key': 'Alimentos y gastronomía'},
      {'icon': Icons.business_center, 'label': 'Servicios', 'key': 'Servicios profesionales'},
      {'icon': Icons.spa, 'label': 'Salud', 'key': 'Salud, belleza y bienestar'},
      {'icon': Icons.construction, 'label': 'Oficios', 'key': 'Oficios y manufactura'},
      {'icon': Icons.school, 'label': 'Educación', 'key': 'Educación y cultura'},
      {'icon': Icons.local_shipping, 'label': 'Logística', 'key': 'Transporte y logistica'},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryKey = categories[index]['key'] as String;
          final isSelected = (_selectedCategory == null && index == 0) || _selectedCategory == categoryKey;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                if (index == 0) {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = categoryKey;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : theme.shadowColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      categories[index]['icon'] as IconData,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.6),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      height: 1.1,
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

  Widget _buildSectionHeader(BuildContext context, String title, {bool showViewAll = true}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
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
            child: Text(
              'Ver todo',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, UserProfile pyme, String title,
      String description, String tag, Color color, IconData icon) {
    // Prefer cover image for offer cards as they are wide, otherwise logo
    final String? imageUrl = pyme.coverImageUrl ?? pyme.logoUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientPymeDetailScreen(
              pymeId: pyme.id,
              pymeData: pyme,
            ),
          ),
        );
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF2F3F2A), // Fallback color
          image: imageUrl != null
              ? DecorationImage(
                  image: imageUrl.startsWith('http')
                      ? NetworkImage(imageUrl)
                      : AssetImage(imageUrl) as ImageProvider,
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    const Color(0xFF2F3F2A).withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                  onError: (exception, stackTrace) {
                    // Fail silently to background color
                  },
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F3F2A).withValues(alpha: 0.1),
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
                const Color(0xFF2F3F2A).withValues(alpha: 0.8),
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
                      color: const Color(0xFFF4F1EA).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF4F1EA).withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: const Color(0xFFF4F1EA), size: 20),
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
                        color: Color(0xFFF4F1EA),
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
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF4F1EA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xB3F4F1EA),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store, color: Color(0xB3F4F1EA), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        pyme.name,
                        style: const TextStyle(
                          color: Color(0xB3F4F1EA),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildPymeCard(BuildContext context, UserProfile pyme) {
    final theme = Theme.of(context);
    final String? imageUrl = pyme.coverImageUrl;
    // TODO: Connect with real schedule and rating logic
    final bool isOpen = true; 
    final String name = pyme.name;
    // Hide rating if not available in model
    // final bool showRating = false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientPymeDetailScreen(
              pymeId: pyme.id,
              pymeData: pyme,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F3F2A).withOpacity(0.1),
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
                  child: (imageUrl != null && imageUrl.startsWith('http'))
                      ? Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.store, size: 50, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 150,
                          width: double.infinity,
                          color: const Color(0xFF2F3F2A).withOpacity(0.1),
                          child: const Icon(Icons.store, size: 50, color: Colors.grey),
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StreamBuilder<bool>(
                    stream: FirebaseAuth.instance.currentUser != null 
                        ? PymeService().isFollowing(FirebaseAuth.instance.currentUser!.uid, pyme.id)
                        : Stream.value(false),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;
                      return GestureDetector(
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            PymeService().toggleFollow(user.uid, pyme.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F1EA),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2F3F2A).withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFollowing ? Icons.favorite : Icons.favorite_border,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      );
                    }
                  ),
                ),
                if (isOpen)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F8F5E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.access_time, color: Color(0xFFF4F1EA), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ABIERTO',
                            style: TextStyle(
                              color: Color(0xFFF4F1EA),
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
                        name,
                        style: const TextStyle(
                          color: Color(0xFF2F3F2A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      /* if (showRating)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F3F2A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFF8B5A3C), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '5.0',
                              style: const TextStyle(
                                color: Color(0xFF8B5A3C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ), */
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.storefront,
                          size: 16, color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          pyme.category ?? 'Sin categoría',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2F3F2A),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (pyme.location != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on,
                            size: 16, color: const Color(0xFF2F3F2A).withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pyme.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2F3F2A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...(pyme.tags ?? []).map((tag) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildTag(context, tag),
                            )),
                        _buildTag(context, 'S+ Partner', color: Theme.of(context).colorScheme.primary),
                      ],
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

  Widget _buildTag(BuildContext context, String text, {Color? color}) {
    final theme = Theme.of(context);
    final tagColor = color ?? theme.textTheme.bodyMedium?.color ?? const Color(0xFF2F3F2A).withOpacity(0.7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: tagColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        color: tagColor.withOpacity(0.05),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: tagColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
