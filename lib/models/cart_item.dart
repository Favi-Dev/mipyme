import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  final DateTime? scheduledTime;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.scheduledTime,
  });

  double get total => product.price * quantity;
}
