import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/order_model.dart';
import 'reservation_service.dart';
import 'client_service.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  double _couponDiscount = 0;
  String? _appliedCouponCode;
  final ClientService _clientService = ClientService();

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  
  double get discount => _couponDiscount;
  
  double get total => (subtotal - _couponDiscount) < 0 ? 0 : (subtotal - _couponDiscount);

  String? get currentPymeId {
    if (_items.isEmpty) return null;
    return _items.first.product.pymeId;
  }

  Future<void> addToCart(Product product, {DateTime? scheduledTime}) async {
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
          final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
          await ReservationService().bookSlot(product.pymeId, product.id, userId, scheduledTime);
        } catch (e) {
          rethrow; // Propagate error (e.g. "Slot taken")
        }
      }
      _items.add(CartItem(product: product, scheduledTime: scheduledTime));
    }
    notifyListeners();
  }

  Future<void> removeFromCart(Product product, {DateTime? scheduledTime}) async {
    final index = _items.indexWhere((item) => 
      item.product.id == product.id && item.scheduledTime == scheduledTime
    );
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        // If removing the item completely, release the reservation if it exists
        if (scheduledTime != null) {
          await ReservationService().cancelReservation(product.id, scheduledTime);
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

  Future<void> clearCart() async {
    // Release all reservations (User abandoned cart)
    for (var item in _items) {
      if (item.scheduledTime != null) {
        await ReservationService().cancelReservation(item.product.id, item.scheduledTime!);
      }
    }
    _items.clear();
    _couponDiscount = 0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  // Método Seguro: Crea la orden en 'pending' y devuelve el ID para cobrarla
  Future<String> createPendingOrder() async {
    if (_items.isEmpty) throw Exception('El carrito está vacío');
    if (currentPymeId == null) throw Exception('Error en datos de la Pyme');

    final order = OrderModel(
      id: '', // Se generará en Firestore
      clientId: FirebaseAuth.instance.currentUser?.uid ?? '',
      pymeId: currentPymeId!,
      items: _items.map((item) => OrderItem(
        productId: item.product.id,
        productName: item.product.name,
        quantity: item.quantity,
        price: item.product.price,
        total: item.total,
        scheduledTime: item.scheduledTime,
      )).toList(),
      subtotal: subtotal,
      discount: _couponDiscount,
      total: total,
      couponCode: _appliedCouponCode,
      status: 'pending_payment', // ESTADO CLAVE PARA SEGURIDAD
      createdAt: DateTime.now(),
    );

    // Creamos la orden via ClientService y obtenemos su ID
    return await _clientService.createOrder(order);
  }

  // Método final: Limpia el carrito localmente tras éxito confirmado
  void finalizeCart() {
    _items.clear();
    _couponDiscount = 0;
    _appliedCouponCode = null;
    notifyListeners();
  }

  // DEPRECATED: Usado antiguamente para flujo inseguro. Mantener temporalmente si se requiere.
  Future<void> checkout() async {
    // ... Legacy implementation ...
    await createPendingOrder();
    finalizeCart();
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
