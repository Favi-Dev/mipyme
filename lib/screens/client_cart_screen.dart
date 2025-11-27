import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';

class ClientCartScreen extends StatefulWidget {
  const ClientCartScreen({super.key});

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    setState(() {});
  }

  void _showCouponDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canjear Cupón QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Simulación de escaneo de QR.'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Código del Cupón',
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
            onPressed: () {
              // Mock logic: If code is "QR10000", apply 10000 discount
              if (controller.text == 'QR10000') {
                bool applied = _cartService.applyCoupon('QR10000', 10000);
                Navigator.pop(context);
                if (applied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cupón aplicado con éxito!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo aplicar el cupón.')),
                  );
                }
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código inválido.')),
                );
              }
            },
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _cartService.clearCart(),
          ),
        ],
      ),
      body: _cartService.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Tu carrito está vacío',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartService.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartService.items[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _buildSummarySection(),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${item.product.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _cartService.removeFromCart(item.product),
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    try {
                      _cartService.addToCart(item.product);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('\$${_cartService.subtotal.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Descuento Cupón'),
              Text(
                '-\$${_cartService.discount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.green),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_cartService.total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showCouponDialog,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Escanear Cupón'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Mock Payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pasarela de pago no implementada aún.')),
                    );
                  },
                  child: const Text('Pagar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
