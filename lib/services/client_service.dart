import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/order_model.dart';
import 'pyme_service.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> updateProfile({required String name, String? phone}) async {
    if (currentUserId == null) return;
    
    final Map<String, dynamic> updates = {'name': name};
    if (phone != null) updates['phoneNumber'] = phone; // Assuming phoneNumber field
    
    // Update Firestore
    await _firestore.collection('users').doc(currentUserId).update(updates);
    
    // Update Auth Profile
    await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
  }

  Future<void> updateProfileImage(File imageFile) async {
    if (currentUserId == null) return;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child(currentUserId!)
          .child('profile.jpg');
          
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      await _firestore.collection('users').doc(currentUserId).update({
        'logoUrl': downloadUrl, // Reusing logoUrl field as per UserProfile model usage
      });
      
      // Also update Auth profile for consistency
      await _auth.currentUser?.updatePhotoURL(downloadUrl);
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  // --- Notifications ---
  Stream<List<Map<String, dynamic>>> getNotifications() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
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
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

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
    
    // Check if it's the first address to set as default
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .get();
        
    if (snapshot.docs.isEmpty) {
      addressData['isDefault'] = true;
    } else {
      // If not specified, default to false. If specified, keep it.
      if (!addressData.containsKey('isDefault')) {
         addressData['isDefault'] = false;
      }
    }
    
    // Add to subcollection
    final docRef = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .add(addressData);
        
    // Update main profile location for quick access if it's default
    if (addressData['isDefault'] == true) {
      final parts = [
        addressData['address'],
        addressData['comuna'],
        addressData['region']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      await _firestore.collection('users').doc(currentUserId).set({
        'location': parts,
      }, SetOptions(merge: true));
    }
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

  Future<void> setDefaultAddress(String addressId) async {
    if (currentUserId == null) return;
    
    final batch = _firestore.batch();
    final addressesRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses');
        
    final snapshot = await addressesRef.get();
    
    // Unset all others
    for (var doc in snapshot.docs) {
      if (doc.id != addressId && (doc.data()['isDefault'] == true)) {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    
    // Set new default
    batch.update(addressesRef.doc(addressId), {'isDefault': true});
    
    // Also update main profile
    final selectedDoc = await addressesRef.doc(addressId).get();
    if (selectedDoc.exists) {
      final data = selectedDoc.data()!;
      final parts = [
        data['address'],
        data['comuna'],
        data['region']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      batch.set(_firestore.collection('users').doc(currentUserId), {
        'location': parts,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> newData) async {
    if (currentUserId == null) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('addresses')
        .doc(addressId);

    await docRef.update(newData);
    
    // Check if this address is default, if so, update profile location
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists && docSnapshot.data()?['isDefault'] == true) {
      final data = docSnapshot.data()!;
      final parts = [
        data['address'],
        data['comuna'],
        data['region']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

      await _firestore.collection('users').doc(currentUserId).set({
        'location': parts,
      }, SetOptions(merge: true));
    }
  }

  // --- Payment Methods ---
  Stream<List<Map<String, dynamic>>> getPaymentMethods() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('users')
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
    // If it's the first one, make it default automatically
    final snapshot = await _firestore
       .collection('users')
       .doc(currentUserId)
       .collection('payment_methods')
       .get();
       
    if (snapshot.docs.isEmpty) {
      data['isDefault'] = true;
    } else {
      data['isDefault'] = false; // Default to false unless specified
    }

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('payment_methods')
        .add(data);
  }

  Future<void> deletePaymentMethod(String id) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('payment_methods')
        .doc(id)
        .delete();
  }
  
  Future<void> setDefaultPaymentMethod(String id) async {
    if (currentUserId == null) return;
    
    final batch = _firestore.batch();
    final colRef = _firestore.collection('users').doc(currentUserId).collection('payment_methods');
    final snapshot = await colRef.get();

    for (var doc in snapshot.docs) {
      if (doc.id == id) {
        batch.update(doc.reference, {'isDefault': true});
      } else {
        if (doc.data()['isDefault'] == true) {
          batch.update(doc.reference, {'isDefault': false});
        }
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

  Future<void> createOrder(OrderModel order) async {
    if (currentUserId == null) return;
    
    final orderData = order.toMap();
    // Override/Ensure server fields
    orderData['clientId'] = currentUserId;
    orderData['createdAt'] = FieldValue.serverTimestamp();
    
    await _firestore.collection('orders').add(orderData);
    
    // Increment S+ Score for Pyme
    await PymeService().incrementSupporterCount(order.pymeId);
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
    
    // Log initial payment transaction (Simulated for this context)
    await _firestore.collection('transactions').add({
      'clientId': currentUserId,
      'type': 'subscription', // or 'payment'
      'title': 'Suscripción Usuario Premium',
      'amount': 2000,
      'status': 'Completado',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelSubscription() async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).update({
      'isSubscribed': false,
    });
  }
  
  Stream<List<Map<String, dynamic>>> getPaymentHistory() {
    if (currentUserId == null) return Stream.value([]);
    
    // Combine real orders with subscription transactions if possible. 
    // For simplicity, we'll fetch from a 'transactions' collection that we should start populating,
    // OR just use 'orders' and adapt them.
    // Let's use a unified 'transactions' stream if we want to include subscription payments.
    // If 'transactions' doesn't exist, we can return orders formatted.
    
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
