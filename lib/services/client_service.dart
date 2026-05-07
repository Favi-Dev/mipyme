import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import 'pyme_service.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- Loyalty Points ---
  Future<void> addPoints(double amountSpent) async {
    if (currentUserId == null) return;

    int pointsEarned = (amountSpent / 100).floor();
    if (pointsEarned <= 0) return;

    try {
      await _firestore.collection('clients').doc(currentUserId).set({
        'points': FieldValue.increment(pointsEarned),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error adding points: $e');
    }
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {'name': name};
    if (phone != null) updates['phoneNumber'] = phone;

    await _firestore.collection('clients').doc(currentUserId).update(updates);
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
  }

  Future<void> updateProfilePhotoUrl(String photoUrl) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('clients').doc(currentUserId).update({
        'logoUrl': photoUrl,
      });
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    } catch (e) {
      debugPrint('Error updating profile photo URL: $e');
      rethrow;
    }
  }

  Future<void> updateCoverPhotoUrl(String photoUrl) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('clients').doc(currentUserId).update({
        'coverImageUrl': photoUrl,
      });
    } catch (e) {
      debugPrint('Error updating cover photo URL: $e');
      rethrow;
    }
  }

  // --- Notifications ---
  Stream<List<Map<String, dynamic>>> getNotifications() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // --- Addresses ---
  Stream<List<Map<String, dynamic>>> getAddresses() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('clients')
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

    final snapshot = await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('addresses')
        .get();

    if (snapshot.docs.isEmpty) {
      addressData['isDefault'] = true;
    } else if (!addressData.containsKey('isDefault')) {
      addressData['isDefault'] = false;
    }

    await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('addresses')
        .add(addressData);

    if (addressData['isDefault'] == true) {
      final parts = [
        addressData['address'],
        addressData['comuna'],
        addressData['region'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      await _firestore.collection('clients').doc(currentUserId).set({
        'location': parts,
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final addressesRef = _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('addresses');

    final snapshot = await addressesRef.get();

    for (var doc in snapshot.docs) {
      if (doc.id != addressId && (doc.data()['isDefault'] == true)) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    batch.update(addressesRef.doc(addressId), {'isDefault': true});

    final selectedDoc = await addressesRef.doc(addressId).get();
    if (selectedDoc.exists) {
      final data = selectedDoc.data()!;
      final parts = [
        data['address'],
        data['comuna'],
        data['region'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      batch.set(_firestore.collection('clients').doc(currentUserId), {
        'location': parts,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> newData) async {
    if (currentUserId == null) return;

    final docRef = _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('addresses')
        .doc(addressId);

    await docRef.update(newData);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists && docSnapshot.data()?['isDefault'] == true) {
      final data = docSnapshot.data()!;
      final parts = [
        data['address'],
        data['comuna'],
        data['region'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      await _firestore.collection('clients').doc(currentUserId).set({
        'location': parts,
      }, SetOptions(merge: true));
    }
  }

  // --- Payment Methods ---
  Stream<List<Map<String, dynamic>>> getPaymentMethods() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('payment_methods')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> addPaymentMethod(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    final snapshot = await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('payment_methods')
        .get();

    data['isDefault'] = snapshot.docs.isEmpty;

    await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('payment_methods')
        .add(data);
  }

  Future<void> deletePaymentMethod(String id) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('payment_methods')
        .doc(id)
        .delete();
  }

  Future<void> setDefaultPaymentMethod(String id) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final colRef = _firestore
        .collection('clients')
        .doc(currentUserId)
        .collection('payment_methods');
    final snapshot = await colRef.get();

    for (var doc in snapshot.docs) {
      if (doc.id == id) {
        batch.update(doc.reference, {'isDefault': true});
      } else if (doc.data()['isDefault'] == true) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }

    await batch.commit();
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

  Future<String> createOrder(OrderModel order) async {
    if (currentUserId == null) throw Exception("Usuario no autenticado");

    final orderData = order.toMap();
    orderData['clientId'] = currentUserId;
    orderData['createdAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('orders').add(orderData);
    await PymeService().incrementSupporterCount(order.pymeId);

    return docRef.id;
  }

  // --- Coupon ---
  Stream<bool> getMonthlyCouponStatus() {
    if (currentUserId == null) return Stream.value(false);
    return _firestore
        .collection('clients')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.data()?['monthlyCouponRedeemed'] ?? false);
  }

  Future<void> redeemCoupon() async {
    if (currentUserId == null) return;
    await _firestore.collection('clients').doc(currentUserId).set({
      'monthlyCouponRedeemed': true,
    }, SetOptions(merge: true));
  }

  Future<void> checkAndResetMonthlyCoupon() async {
    if (currentUserId == null) return;

    final docRef = _firestore.collection('clients').doc(currentUserId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final isSubscribed = data['isSubscribed'] ?? false;
    if (!isSubscribed) return;

    final subscriptionTimestamp = data['subscriptionDate'] as Timestamp?;
    if (subscriptionTimestamp == null) return;

    final subscriptionDate = subscriptionTimestamp.toDate();
    final lastResetTimestamp = data['lastCouponResetDate'] as Timestamp?;
    final now = DateTime.now();

    final firstCouponDate =
        DateTime(subscriptionDate.year, subscriptionDate.month + 1, subscriptionDate.day);

    if (now.isBefore(firstCouponDate)) {
      return;
    }

    int monthsDiff =
        (now.year - subscriptionDate.year) * 12 + now.month - subscriptionDate.month;
    if (now.day < subscriptionDate.day) {
      monthsDiff--;
    }

    final currentCycleStart = DateTime(
      subscriptionDate.year,
      subscriptionDate.month + monthsDiff,
      subscriptionDate.day,
    );

    bool needsReset = false;

    if (lastResetTimestamp == null) {
      needsReset = true;
    } else {
      final lastResetDate = lastResetTimestamp.toDate();
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
    return _firestore.collection('clients').doc(currentUserId).snapshots().map((doc) {
      final ts = doc.data()?['subscriptionDate'] as Timestamp?;
      return ts?.toDate();
    });
  }

  // --- Settings ---
  Stream<Map<String, dynamic>> getSettings() {
    if (currentUserId == null) return Stream.value({});
    return _firestore
        .collection('clients')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.data()?['settings'] ?? {});
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (currentUserId == null) return;
    await _firestore.collection('clients').doc(currentUserId).set({
      'settings': {key: value}
    }, SetOptions(merge: true));
  }

  // --- Subscription ---
  Stream<bool> getSubscriptionStatus() {
    if (currentUserId == null) return Stream.value(false);
    return _firestore
        .collection('clients')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.data()?['isSubscribed'] ?? false);
  }

  Future<void> subscribe() async {
    if (currentUserId == null) return;
    await _firestore.collection('clients').doc(currentUserId).set({
      'subscriptionRequestedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelSubscription() async {
    if (currentUserId == null) return;
    await _firestore.collection('clients').doc(currentUserId).update({
      'isSubscribed': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getPaymentHistory() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('transactions')
        .where('clientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'title': data['title'] ?? 'Pago',
                'amount': data['amount'] ?? 0,
                'date': (data['createdAt'] as Timestamp?)?.toDate(),
                'status': data['status'] ?? 'Completado',
              };
            }).toList());
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
