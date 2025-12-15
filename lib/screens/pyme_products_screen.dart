import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../models/vitrina_data.dart';
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
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          'Mis Productos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
      ),
      body: _products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: const Color(0xFF2F3F2A).withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes productos registrados.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2F3F2A).withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (VitrinaData.isFoundation) {
            // Foundations can only add Products here (Events are in a separate tab)
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PymeAddProductScreen(isService: false)),
            );
            _loadProducts();
          } else {
            // Regular Pymes can choose between Product and Service
            final bool? isService = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('¿Qué deseas agregar?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.inventory_2, color: Color(0xFF6F8F5E)),
                      title: Text('Producto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('Artículo físico con stock', style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () => Navigator.pop(context, false),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF6F8F5E)),
                      title: Text('Servicio', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('Actividad con reserva de hora', style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              ),
            );

            if (isService != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PymeAddProductScreen(isService: isService)),
              );
              _loadProducts();
            }
          }
        },
        backgroundColor: const Color(0xFF6F8F5E),
        icon: const Icon(Icons.add, color: Color(0xFFF4F1EA)),
        label: Text(
          'Nuevo Item',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: const Color(0xFFF4F1EA)),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to edit screen
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFFF4F1EA),
                      child: Icon(Icons.image_not_supported,
                          color: const Color(0xFF2F3F2A).withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF2F3F2A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit, color: Color(0xFF6F8F5E)),
                                        title: Text('Editar', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A))),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Navigate to edit screen
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Color(0xFF8B5A3C)),
                                        title: Text('Eliminar', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A))),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: Implement delete logic
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Producto eliminado')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F1EA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.more_vert,
                                  size: 20, color: const Color(0xFF2F3F2A).withOpacity(0.6)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2F3F2A).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6F8F5E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stock: ${product.stock}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6F8F5E),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '\$${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2F3F2A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
