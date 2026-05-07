import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/product_service.dart';
import '../services/pyme_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';

class ClientMarketplaceScreen extends StatefulWidget {
  const ClientMarketplaceScreen({super.key});

  @override
  State<ClientMarketplaceScreen> createState() => _ClientMarketplaceScreenState();
}

class _ClientMarketplaceScreenState extends State<ClientMarketplaceScreen> {
  final ProductService _productService = ProductService();
  final PymeService _pymeService = PymeService();
  
  String? _selectedCategory;
  String _selectedInventoryType = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado SoyPlus'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...ProductService.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTypeChip('all', 'Todo'),
                const SizedBox(width: 8),
                _buildTypeChip('products', 'Productos'),
                const SizedBox(width: 8),
                _buildTypeChip('services', 'Servicios'),
                const SizedBox(width: 8),
                _buildTypeChip('events', 'Eventos'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Grid
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allProducts = snapshot.data ?? [];
                
                // Filter products
                final filteredProducts = allProducts.where((product) {
                  final matchesCategory = _selectedCategory == null || product.category == _selectedCategory;
                  final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      product.description.toLowerCase().contains(_searchQuery.toLowerCase());
                  final isEvent = _isEventProduct(product);
                  final matchesType = _selectedInventoryType == 'all' ||
                      (_selectedInventoryType == 'products' && !isEvent && !product.isService) ||
                      (_selectedInventoryType == 'services' && !isEvent && product.isService) ||
                      (_selectedInventoryType == 'events' && isEvent);
                  if (isEvent) {
                    final eventDate = _eventDateTime(product);
                    if (eventDate != null && eventDate.isBefore(DateTime.now())) {
                      return false;
                    }
                  }
                  return matchesCategory && matchesSearch && matchesType;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedInventoryType == value,
      onSelected: (_) {
        setState(() => _selectedInventoryType = value);
      },
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme) {
    final isEvent = _isEventProduct(product);
    final isService = product.isService && !isEvent;
    final isQuote = product.customAttributes['allow_quote'] == 'true';
    final canAddDirectly = !isEvent && !isService && !isQuote && !product.hasVariants;
    final remainingSeats = product.stock - product.registeredCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.image_not_supported, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isQuote ? 'Cotizar' : '\$${product.price.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isService || isEvent)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isEvent
                          ? (remainingSeats > 0 ? '$remainingSeats cupos' : 'Sin cupos')
                          : 'Servicio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isEvent && remainingSeats <= 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (product.hasVariants)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.tune, size: 12, color: theme.colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          '${product.variants.length} opciones',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () async {
                      if (!canAddDirectly) {
                        await _openProductVitrina(product);
                        return;
                      }
                      try {
                        await context.read<CartService>().addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Agregado al carrito'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: theme.colorScheme.secondary,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    child: Text(canAddDirectly ? 'Agregar' : 'Ver vitrina'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductVitrina(Product product) async {
    final pymeData = await _pymeService.getPymeById(product.pymeId);
    if (!mounted) return;
    if (pymeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la vitrina')),
      );
      return;
    }
    context.go('/client/home/pyme_detail', extra: {
      'pymeId': product.pymeId,
      'pymeData': pymeData,
    });
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
}
