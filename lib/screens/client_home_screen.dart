import 'package:flutter/material.dart';
import '../models/vitrina_data.dart';
import '../services/product_service.dart';
import 'client_pyme_detail_screen.dart';

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
  String _searchQuery = '';
  final Set<String> _followedPymes = {};
  final Set<String> _selectedTags = {};

  final List<Map<String, dynamic>> _allPymes = [
    {
      'name': 'Metamorfosis',
      'category': 'Reciclaje Textil',
      'category_key': 'Metamorfosis',
      'rating': '5.0',
      'distance': '0.3 km',
      'image': 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=800&q=80',
      'tags': ['Reciclaje', 'Sustentable', 'Moda'],
      'isOpen': true,
    },
    {
      'name': 'Farmayuda',
      'category': 'Salud y Bienestar',
      'category_key': 'Salud, belleza y bienestar',
      'rating': '4.9',
      'distance': '0.5 km',
      'image': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=800&q=80',
      'tags': ['Farmacia', 'Medicamentos'],
      'isOpen': true,
    },
    {
      'name': 'Zapatería Los Robles',
      'category': 'Comercio/Retail',
      'category_key': 'Comercio/retail',
      'rating': '4.9',
      'distance': '0.8 km',
      'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=800&q=80',
      'tags': ['Calzado', 'Cuero', 'Reparación'],
      'isOpen': true,
    },
    {
      'name': 'Fundación Los Robles',
      'category': 'Educación y Cultura',
      'category_key': 'Educación y cultura',
      'rating': '5.0',
      'distance': '1.2 km',
      'image': 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80',
      'tags': ['Reciclaje', 'Comunidad'],
      'isOpen': true,
    },
    {
      'name': 'Abogados & Asoc.',
      'category': 'Servicios Profesionales',
      'category_key': 'Servicios profesionales',
      'rating': '4.7',
      'distance': '2.0 km',
      'image': 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=800&q=80',
      'tags': ['Legal', 'Asesoría'],
      'isOpen': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredPymes {
    return _allPymes.where((pyme) {
      final matchesSearch = pyme['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pyme['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by tags if any are selected
      final matchesTags = _selectedTags.isEmpty || 
          (pyme['tags'] as List<String>).any((tag) => _selectedTags.contains(tag));

      if (widget.showFoundationsOnly) {
        // Filter for foundations (using category key or name for now as proxy)
        final isFoundation = pyme['category_key'] == 'Educación y cultura' || 
                             pyme['name'].toString().contains('Fundación');
        return matchesSearch && matchesTags && isFoundation;
      } else {
        // Filter OUT foundations for the main home screen
        final isFoundation = pyme['category_key'] == 'Educación y cultura' || 
                             pyme['name'].toString().contains('Fundación');
        return matchesSearch && matchesTags && !isFoundation;
      }
    }).toList();
  }

  void _showNotifications() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.local_offer, color: theme.colorScheme.primary),
              title: const Text('Nueva oferta en Farmayuda'),
              subtitle: const Text('20% de descuento en vitaminas.'),
            ),
            ListTile(
              leading: Icon(Icons.event, color: theme.colorScheme.secondary),
              title: const Text('Evento Fundación Los Robles'),
              subtitle: const Text('Mañana a las 10:00 AM.'),
            ),
          ],
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

  void _showFilterDialog() {
    final theme = Theme.of(context);
    // Extract all unique tags
    final allTags = _allPymes
        .expand((pyme) => pyme['tags'] as List<String>)
        .toSet()
        .toList();

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
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
                Text(
                  widget.showFoundationsOnly ? 'Fundaciones' : 'Hola, Joaquín',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.showFoundationsOnly)
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12, color: theme.colorScheme.onPrimary.withOpacity(0.9)),
                      const SizedBox(width: 4),
                      Text(
                        'Providencia, Santiago',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
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
              onPressed: _showNotifications,
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
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: widget.showFoundationsOnly ? 'Buscar fundación...' : '¿Qué buscas hoy?',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
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
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: _showFilterDialog,
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

            // Featured Offers (Hide if showing foundations only)
            if (!widget.showFoundationsOnly) ...[
              _buildSectionHeader(context, 'Ofertas para ti', showViewAll: false),
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
                      'assets/images/logo el roble calzados.jpg',
                    ),
                    const SizedBox(width: 16),
                    _buildOfferCard(
                      context,
                      'Farmayuda',
                      'Descuentos en Recetas',
                      'Salud',
                      const Color(0xFFE63946),
                      Icons.medical_services,
                      'assets/images/logo farmayuda.jpg',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Upcoming Events (Only for Foundations)
            if (widget.showFoundationsOnly) ...[
              _buildSectionHeader(context, 'Eventos Próximos', showViewAll: false),
              const SizedBox(height: 16),
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildOfferCard(
                      context,
                      'Fundación Los Robles',
                      'Campaña de Reciclaje',
                      'Evento',
                      theme.colorScheme.primary,
                      Icons.event,
                      'assets/images/Logo los robles.jpg',
                    ),
                    const SizedBox(width: 16),
                    _buildOfferCard(
                      context,
                      'Fundación Esperanza',
                      'Colecta Anual',
                      'Evento',
                      theme.colorScheme.tertiary,
                      Icons.volunteer_activism,
                      'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=800&q=80',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Nearby Pymes / Foundations List
            _buildSectionHeader(context, widget.showFoundationsOnly ? 'Fundaciones Disponibles' : 'Pymes en tu zona'),
            const SizedBox(height: 16),
            _buildPymesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPymesList() {
    final pymes = _filteredPymes;

    if (pymes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No se encontraron resultados',
            style: TextStyle(color: Colors.grey[600]),
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
      {'icon': Icons.local_shipping, 'label': 'Logística', 'key': 'Transporte y logística'},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return GestureDetector(
            onTap: () {
              if (index != 0) {
                // Update global mock data to simulate selecting a Pyme of this category
                VitrinaData.setCategory(categories[index]['key'] as String);
                ProductService().loadMockProductsForCategory(categories[index]['key'] as String);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientPymeDetailScreen(),
                  ),
                );
              }
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

  Widget _buildOfferCard(BuildContext context, String pymeName, String offer,
      String tag, Color color, IconData icon, String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Update global mock data based on the card clicked
        if (pymeName == 'Fundación Los Robles') {
          VitrinaData.setCategory('Educación y cultura');
          ProductService().loadMockProductsForCategory('Educación y cultura');
        } else if (pymeName == 'Farmayuda') {
          VitrinaData.setCategory('Salud, belleza y bienestar');
          ProductService().loadMockProductsForCategory('Salud, belleza y bienestar');
        } else if (pymeName == 'Zapatería Los Robles') {
          VitrinaData.setCategory('Comercio/retail');
          ProductService().loadMockProductsForCategory('Comercio/retail');
        } else if (pymeName == 'Metamorfosis') {
          VitrinaData.setCategory('Metamorfosis');
          ProductService().loadMockProductsForCategory('Metamorfosis');
        } else {
           // Default fallback or try to match by category if passed
           // For now, we just keep current or default
        }

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
            image: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl)
                : AssetImage(imageUrl) as ImageProvider,
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (pyme.containsKey('category_key')) {
          VitrinaData.setCategory(pyme['category_key']);
          ProductService().loadMockProductsForCategory(pyme['category_key']);
        }
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
                  child: pyme['image'].startsWith('http')
                      ? Image.network(
                          pyme['image'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          pyme['image'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_followedPymes.contains(pyme['name'])) {
                          _followedPymes.remove(pyme['name']);
                        } else {
                          _followedPymes.add(pyme['name']);
                        }
                      });
                    },
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
                      child: Icon(
                        _followedPymes.contains(pyme['name']) ? Icons.favorite : Icons.favorite_border,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
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
                          color: const Color(0xFF333333).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFF333333), size: 14),
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
                            child: _buildTag(context, tag),
                          )),
                      _buildTag(context, 'S+ Partner', color: Theme.of(context).colorScheme.primary),
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

  Widget _buildTag(BuildContext context, String text, {Color? color}) {
    final theme = Theme.of(context);
    final tagColor = color ?? theme.textTheme.bodyMedium?.color ?? Colors.grey[600];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: tagColor!.withOpacity(0.3)),
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
