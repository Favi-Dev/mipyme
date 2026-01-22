import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- Addresses ---
  Stream<List<Map<String, dynamic>>> getAddresses() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .add(addressData);
  }

  Future<void> deleteAddress(String addressId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  // --- Orders (History) ---
  Stream<List<OrderModel>> getOrders() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('orders')
        .where('clientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> createOrder(OrderModel order) async {
    if (currentUserId == null) return;
    
    final orderData = order.toMap();
    // Override/Ensure server fields
    orderData['clientId'] = currentUserId;
    orderData['createdAt'] = FieldValue.serverTimestamp();
    
    await _firestore.collection('orders').add(orderData);
  }

  // --- Coupon ---
  Stream<bool> getMonthlyCouponStatus() {
    if (currentUserId == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.data()?['monthlyCouponRedeemed'] ?? false);
  }

  Future<void> redeemCoupon() async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).set({
      'monthlyCouponRedeemed': true,
    }, SetOptions(merge: true));
  }

  Future<void> checkAndResetMonthlyCoupon() async {
    if (currentUserId == null) return;

    final docRef = _firestore.collection('users').doc(currentUserId);
    final snapshot = await docRef.get();
    
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final isSubscribed = data['isSubscribed'] ?? false;
    
    // If not subscribed, no need to reset anything yet
    if (!isSubscribed) return;

    final subscriptionTimestamp = data['subscriptionDate'] as Timestamp?;
    // If no subscription date is found (legacy), we can't calculate cycles correctly.
    // Assume now is the start or handle as error. For now, return.
    if (subscriptionTimestamp == null) return;

    final subscriptionDate = subscriptionTimestamp.toDate();
    final lastResetTimestamp = data['lastCouponResetDate'] as Timestamp?;
    final now = DateTime.now();

    // 1. Check if we are past the first month (delay)
    // Coupon is available starting from: SubscriptionDate + 1 Month
    final firstCouponDate = DateTime(subscriptionDate.year, subscriptionDate.month + 1, subscriptionDate.day);
    
    if (now.isBefore(firstCouponDate)) {
      // Still in the first month "grace period" / delay. No coupon should be active.
      // We ensure the coupon is marked as 'redeemed' (unavailable) or handle it in UI.
      // Ideally, we don't touch the DB here, just let the UI block it.
      return;
    }

    // 2. Calculate the start of the current billing/coupon cycle
    // Cycle N starts at: SubscriptionDate + N months
    int monthsDiff = (now.year - subscriptionDate.year) * 12 + now.month - subscriptionDate.month;
    if (now.day < subscriptionDate.day) {
      monthsDiff--;
    }
    
    // The start date of the current cycle the user is in
    final currentCycleStart = DateTime(subscriptionDate.year, subscriptionDate.month + monthsDiff, subscriptionDate.day);

    bool needsReset = false;

    if (lastResetTimestamp == null) {
      // Never reset before, and we are past the first month -> Reset now
      needsReset = true;
    } else {
      final lastResetDate = lastResetTimestamp.toDate();
      // If the last reset happened BEFORE the current cycle started, 
      // it means we are in a new cycle and the user hasn't got their new coupon yet.
      if (lastResetDate.isBefore(currentCycleStart)) {
        needsReset = true;
      }
    }

    if (needsReset) {
      await docRef.set({
        'monthlyCouponRedeemed': false,
        'lastCouponResetDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<DateTime?> getSubscriptionDate() {
    if (currentUserId == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
          final ts = doc.data()?['subscriptionDate'] as Timestamp?;
          return ts?.toDate();
        });
  }

  // --- Settings ---
  Stream<Map<String, dynamic>> getSettings() {
    if (currentUserId == null) return Stream.value({});
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.data()?['settings'] ?? {});
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).set({
      'settings': {key: value}
    }, SetOptions(merge: true));
  }

  // --- Subscription ---
  Stream<bool> getSubscriptionStatus() {
    if (currentUserId == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.data()?['isSubscribed'] ?? false);
  }

  Future<void> subscribe() async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).set({
      'isSubscribed': true,
      'subscriptionDate': FieldValue.serverTimestamp(),
      'monthlyCouponRedeemed': false, // Reset coupon on new subscription
    }, SetOptions(merge: true));
  }

  // --- Support ---
  Future<void> createTicket(String issueType, String description) async {
    if (currentUserId == null) return;
    await _firestore.collection('tickets').add({
      'clientId': currentUserId,
      'issueType': issueType,
      'description': description,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
