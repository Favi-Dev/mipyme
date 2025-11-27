import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';

class ClientMarketplaceScreen extends StatefulWidget {
  const ClientMarketplaceScreen({super.key});

  @override
  State<ClientMarketplaceScreen> createState() => _ClientMarketplaceScreenState();
}

class _ClientMarketplaceScreenState extends State<ClientMarketplaceScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _allProducts = _productService.getProducts();
      _categories = _productService.getCategories();
      _filterProducts();
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesCategory = _selectedCategory == null || product.category == _selectedCategory;
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterProducts();
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
                      _filterProducts();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ..._categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                          _filterProducts();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image_not_supported)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () {
                      try {
                        _cartService.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Agregado al carrito'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
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
}
