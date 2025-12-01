import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  double _couponDiscount = 0;
  String? _appliedCouponCode;

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  
  double get discount => _couponDiscount;
  
  double get total => (subtotal - _couponDiscount) < 0 ? 0 : (subtotal - _couponDiscount);

  String? get currentPymeId {
    if (_items.isEmpty) return null;
    return _items.first.product.pymeId;
  }

  void addToCart(Product product) {
    // Check if product is from the same store
    if (_items.isNotEmpty && _items.first.product.pymeId != product.pymeId) {
      throw Exception('Solo puedes agregar productos de una misma tienda.');
    }

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      // If cart becomes empty, reset coupon
      if (_items.isEmpty) {
        _couponDiscount = 0;
        _appliedCouponCode = null;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _couponDiscount = 0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  bool applyCoupon(String code, double amount) {
    // Condition: Single store (already enforced by addToCart)
    if (_items.isEmpty) return false;

    // Condition: Coupon not already used (Mock check)
    if (_appliedCouponCode == code) return false;

    // Condition: "All or nothing" logic is handled in the total calculation.
    // If total < coupon, the user "loses" the difference, effectively using the whole coupon.
    
    _couponDiscount = amount;
    _appliedCouponCode = code;
    notifyListeners();
    return true;
  }
}
