import 'product.dart';

class CartItem {
  final Product product;
  final ProductVariant? selectedVariant;
  int quantity;
  final DateTime? scheduledTime;

  CartItem({
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
    this.scheduledTime,
  });

  double get unitPrice => selectedVariant?.getPrice(product.price) ?? product.price;
  double get total => unitPrice * quantity;

  /// Human-readable label for the variant, e.g. "Rojo / M"
  String get variantLabel => selectedVariant?.label ?? '';
}
