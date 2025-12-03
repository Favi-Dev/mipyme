import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'reservation_service.dart';

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

  void addToCart(Product product, {DateTime? scheduledTime}) {
    // Check if product is from the same store
    if (_items.isNotEmpty && _items.first.product.pymeId != product.pymeId) {
      throw Exception('Solo puedes agregar productos de una misma tienda.');
    }

    // Find item with same product ID AND same scheduled time (if any)
    final index = _items.indexWhere((item) => 
      item.product.id == product.id && item.scheduledTime == scheduledTime
    );

    if (index != -1) {
      if (scheduledTime != null) {
        throw Exception('Ya tienes este horario reservado en tu carrito.');
      }
      _items[index].quantity++;
    } else {
      if (scheduledTime != null) {
        // Try to book the slot globally
        try {
          ReservationService().bookSlot(product.pymeId, product.id, 'currentUser', scheduledTime);
        } catch (e) {
          rethrow; // Propagate error (e.g. "Slot taken")
        }
      }
      _items.add(CartItem(product: product, scheduledTime: scheduledTime));
    }
    notifyListeners();
  }

  void removeFromCart(Product product, {DateTime? scheduledTime}) {
    final index = _items.indexWhere((item) => 
      item.product.id == product.id && item.scheduledTime == scheduledTime
    );
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        // If removing the item completely, release the reservation if it exists
        if (scheduledTime != null) {
          ReservationService().cancelReservation(product.id, scheduledTime);
        }
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
    // Release all reservations (User abandoned cart)
    for (var item in _items) {
      if (item.scheduledTime != null) {
        ReservationService().cancelReservation(item.product.id, item.scheduledTime!);
      }
    }
    _items.clear();
    _couponDiscount = 0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  void checkout() {
    // Confirm purchase. Reservations remain 'confirmed' (or 'pending' -> 'confirmed').
    // We do NOT cancel them.
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
