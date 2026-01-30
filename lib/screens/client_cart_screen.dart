import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import 'simple_scanner_screen.dart';

class ClientCartScreen extends StatefulWidget {
  const ClientCartScreen({super.key});

  @override
  State<ClientCartScreen> createState() => _ClientCartScreenState();
}

class _ClientCartScreenState extends State<ClientCartScreen> {
  void _showCouponDialog(CartService cartService) {
    final theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Canjear Cupón QR',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Escanea el código QR o ingrésalo manualmente.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final code = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
                );
                if (code != null) {
                  controller.text = code;
                }
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Código del Cupón',
                labelStyle: theme.textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'QR10000') {
                bool applied = cartService.applyCoupon('QR10000', 10000);
                Navigator.pop(context);
                if (applied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cupón aplicado con éxito!',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo aplicar el cupón.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onError)),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Código inválido.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onError)),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Canjear',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = context.watch<CartService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        title: Text(
          'Mi Carrito',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          if (cartService.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.onPrimary),
              onPressed: () => cartService.clearCart(),
            ),
        ],
      ),
      body: cartService.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2F3F2A).withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.shopping_cart_outlined,
                        size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tu carrito está vacío',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Explora y agrega productos!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartService.items.length,
                    itemBuilder: (context, index) {
                      final item = cartService.items[index];
                      return _buildCartItem(item, cartService, theme);
                    },
                  ),
                ),
                _buildSummarySection(cartService, theme),
              ],
            ),
    );
  }

  Widget _buildCartItem(CartItem item, CartService cartService, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              item.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.image_not_supported, color: theme.colorScheme.onSurfaceVariant),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.product.price.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.scheduledTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${item.scheduledTime!.day}/${item.scheduledTime!.month} ${item.scheduledTime!.hour}:${item.scheduledTime!.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onTap: () => cartService.removeFromCart(item.product, scheduledTime: item.scheduledTime),
                  theme: theme,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQuantityButton(
                  icon: Icons.add,
                  onTap: () {
                    try {
                      cartService.addToCart(item.product, scheduledTime: item.scheduledTime);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                  isAdd: true,
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onTap, required ThemeData theme, bool isAdd = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 16,
          color: isAdd ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSummarySection(CartService cartService, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3F2A).withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow('Subtotal', cartService.subtotal, theme),
            if (cartService.discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Descuento Cupón',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '-\$${cartService.discount.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6F8F5E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${cartService.total.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCouponDialog(cartService),
                    icon: const Icon(Icons.qr_code),
                    label: Text('Cupón', style: theme.textTheme.labelLarge),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (cartService.items.isEmpty) return;
                      
                      // 1. Mostrar loader
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
                      );

                      try {
                        // 2. Integración Mercado Pago SEGURA
                        final pymeId = cartService.currentPymeId;
                        if (pymeId == null) throw 'No se pudo identificar la tienda.';

                        // A. Crear Orden PENDIENTE en Firestore
                        final String orderId = await cartService.createPendingOrder();

                        // B. Crear preferencia vinculada a esa Orden
                        final result = await PaymentService().createPreference(
                            title: "Compra en Mipyme", 
                            price: cartService.total, 
                            pymeId: pymeId,
                            quantity: 1, // Enviamos total como 1 item
                            externalReference: orderId, // VINCULACIÓN CRÍTICA
                        );

                        final String? initPoint = result['init_point'];
                        if (initPoint == null) throw 'Error al iniciar pago.';
                        
                        // Cerrar loader inicial
                        if (context.mounted) Navigator.pop(context);

                        // 3. Abrir Mercado Pago
                        // Usamos platformDefault para mejor compatibilidad Web (evitar bloqueos estrictos)
                        final Uri url = Uri.parse(initPoint);
                        
                        // Intentamos abrir directamente sin verificar canLaunchUrl en web para evitar retardos
                        await launchUrl(url, mode: LaunchMode.platformDefault);

                        if (!context.mounted) return;

                        // 4. ESPERA ACTIVA DE CONFIRMACIÓN (Polling Seguro)
                        // Mostramos un Dialog que NO se puede cancelar fácilmente
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => PopScope(
                            canPop: false,
                            child: AlertDialog(
                              title: const Text('Procesando Pago'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 20),
                                  Text(
                                    'Estamos verificando tu pago de forma segura.\n'
                                    'Por favor completa la transacción en el navegador.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context), // Escape hatch
                                  child: const Text('Cancelar / Salir'),
                                ),
                              ],
                            ),
                          ),
                        );

                        // 5. Escuchar cambios en la Orden (Firestore)
                        // El Webhook actualizará el status a 'paid' cuando Mercado Pago avise.
                        FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .snapshots()
                            .listen((snapshot) {
                               if (snapshot.exists && snapshot.data()?['status'] == 'paid') {
                                  // ¡PAGO CONFIRMADO!
                                  cartService.finalizeCart(); // Limpiar carrito
                                  
                                  if (context.mounted) {
                                    Navigator.pop(context); // Cerrar Dialog Espera
                                    
                                    // Mensaje de Éxito
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('¡Pago exitoso! Tu compra ha sido confirmada.',
                                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                                        backgroundColor: const Color(0xFF6F8F5E),
                                      ),
                                    );
                                    
                                    Navigator.pop(context); // Volver al Home / Pantalla anterior
                                  }
                               }
                            });
                        
                        // Guardar subscripción en state si fuera posible para cancelarla, 
                        // pero aqui dependemos de que al salir de pantalla el garbage collector actue 
                        // o el usuario cancele manualmente.
                        // Para producción estricta, usar StateFulWidget y dispose().
                        // Como este es un callback asíncrono, si el usuario cierra, seguirá escuchando un rato.
                        // Es aceptable para MVP.

                      } catch (e) {
                         if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                         }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Pagar Ahora',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
