import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../models/vitrina_data.dart';
import 'pyme_add_product_screen.dart';
import 'pyme_orders_screen.dart';

class PymeProductsScreen extends StatefulWidget {
  final String? pymeId; // Optional: For admin use
  const PymeProductsScreen({super.key, this.pymeId});

  @override
  State<PymeProductsScreen> createState() => _PymeProductsScreenState();
}

class _PymeProductsScreenState extends State<PymeProductsScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  late TabController _tabController;

  String get _targetPymeId => widget.pymeId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If it's a foundation, we show tabs (Products and Orders)
    // If it's a regular pyme, we show just Products (Orders are in the nav bar)
    // Wait, the requirement said "en la barra de navegacion inferior del rol de fundacion... elimines la seccion de pedidos y la incluyas en la screen de productos".
    // This implies for Pymes, it might stay the same? Or should I change it for everyone?
    // "del rol de fundacion" implies specifically/only for foundation role.
    
    final bool showTabs = VitrinaData.isFoundation;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      appBar: AppBar(
        title: Text(
          showTabs ? 'Gestión' : 'Mis Productos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF2F3F2A),
        foregroundColor: const Color(0xFFF4F1EA),
        bottom: showTabs 
          ? TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF6F8F5E),
              labelColor: const Color(0xFFF4F1EA),
              unselectedLabelColor: const Color(0xFFF4F1EA).withOpacity(0.5),
              tabs: const [
                Tab(text: 'Productos'),
                Tab(text: 'Pedidos'),
              ],
            )
          : null,
      ),
      body: showTabs
        ? TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(),
              const PymeOrdersScreen(showAppBar: false),
            ],
          )
        : _buildProductList(),
      floatingActionButton: showTabs
        ? AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              // Only show FAB on Products tab (index 0)
              if (_tabController.index == 0) {
                return _buildFab();
              }
              return const SizedBox.shrink();
            },
          )
        : _buildFab(),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
        stream: _productService.getProductsByPyme(_targetPymeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }

          final allProducts = snapshot.data ?? [];
          final products = allProducts.where((p) => p.customAttributes['is_event'] != 'true').toList();

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 150,
                    color: const Color(0xFF2F3F2A).withValues(alpha: 0.3),
                  ),
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
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 90,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          );
        },
      );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
        onPressed: () async {
          if (VitrinaData.isFoundation) {
            // Foundations can only add Products here (Events are in a separate tab)
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PymeAddProductScreen(
                    isService: false,
                    pymeId: _targetPymeId,
                  )),
            );
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
                    builder: (context) => PymeAddProductScreen(
                      isService: isService,
                      pymeId: _targetPymeId,
                    )),
              );
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
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PymeAddProductScreen(
                  product: product, 
                  isService: product.isService,
                  pymeId: _targetPymeId,
                )),
            );
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
                  child: (product.imageUrl.isNotEmpty)
                      ? Image.network(
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
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFF4F1EA),
                          child: Icon(Icons.image_not_supported,
                              color: const Color(0xFF2F3F2A).withOpacity(0.3)),
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
                                        onTap: () async {
                                          Navigator.pop(context);
                                          // Navigate to edit screen with product
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PymeAddProductScreen(
                                                isService: product.isService,
                                                product: product,
                                                pymeId: _targetPymeId,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Color(0xFF8B5A3C)),
                                        title: Text('Eliminar', style: GoogleFonts.poppins(color: const Color(0xFF2F3F2A))),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text('¿Eliminar producto?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                              content: Text(
                                                'Esta acción no se puede deshacer.',
                                                style: GoogleFonts.poppins(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(ctx);
                                                    try {
                                                      await _productService.deleteProduct(product.id);
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Producto eliminado')),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Error al eliminar: $e')),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  child: Text('Eliminar', style: GoogleFonts.poppins(color: const Color(0xFF8B5A3C))),
                                                ),
                                              ],
                                            ),
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
                              'Stock: ${product.totalStock}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF6F8F5E),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (product.hasVariants) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F3F2A).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.variants.length} variantes',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF2F3F2A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE3B58F).withOpacity(0.3),
          highlightColor: const Color(0xFFF4F1EA),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 124,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
