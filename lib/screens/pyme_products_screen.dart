import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'pyme_add_product_screen.dart';

class PymeProductsScreen extends StatefulWidget {
  const PymeProductsScreen({super.key});

  @override
  State<PymeProductsScreen> createState() => _PymeProductsScreenState();
}

class _PymeProductsScreenState extends State<PymeProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
      ),
      body: _products.isEmpty
          ? const Center(child: Text('No tienes productos registrados.'))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  leading: Image.network(
                    product.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                  title: Text(product.name),
                  subtitle: Text('Stock: ${product.stock} | \$${product.price.toStringAsFixed(0)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    // Edit logic could go here
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PymeAddProductScreen()),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
