import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class PymeService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Get all Pymes (role == 'pyme')
  Stream<List<UserProfile>> getPymes() {
    return _usersCollection
        .where('role', isEqualTo: 'pyme')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get all Foundations (role == 'foundation')
  Stream<List<UserProfile>> getFoundations() {
    return _usersCollection
        .where('role', isEqualTo: 'foundation')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get all public profiles (pyme and foundation)
  Stream<List<UserProfile>> getAllPublicProfiles() {
    return _usersCollection
        .where('role', whereIn: ['pyme', 'foundation'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get User Profile Stream by ID
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get Special Offers (Collection Group) - Only one per Pyme
  Stream<List<Map<String, dynamic>>> getSpecialOffersGlobal() {
    return FirebaseFirestore.instance
        .collectionGroup('offers')
        .where('isSpecial', isEqualTo: true)
        // .orderBy('createdAt', descending: true) // Requires Composite Index in Firebase Console
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        final pymeId = doc.reference.parent.parent?.id; 
        data['pymeId'] = pymeId;
        return data;
      }).toList();
    });
  }

  // Get Pyme by ID
  Future<UserProfile?> getPymeById(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Toggle follow status and update supporter count
  Future<void> toggleFollow(String userId, String pymeId) async {
    final userRef = _usersCollection.doc(userId).collection('following').doc(pymeId);
    final pymeRef = _usersCollection.doc(pymeId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final followDoc = await transaction.get(userRef);
      if (followDoc.exists) {
        transaction.delete(userRef);
        transaction.update(pymeRef, {
          'supporterCount': FieldValue.increment(-1),
        });
      } else {
        transaction.set(userRef, {'followedAt': FieldValue.serverTimestamp()});
        transaction.update(pymeRef, {
          'supporterCount': FieldValue.increment(1),
        });
      }
    });
  }

  // Increment Supporter Count (for Donations or Sales)
  Future<void> incrementSupporterCount(String pymeId) async {
    await _usersCollection.doc(pymeId).update({
      'supporterCount': FieldValue.increment(1),
    });
  }

  // Check if following
  Stream<bool> isFollowing(String userId, String pymeId) {
    return _usersCollection
        .doc(userId)
        .collection('following')
        .doc(pymeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Get followed pymes IDs
  Stream<List<String>> getFollowedPymeIds(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // --- Orders Management ---

  // Get orders for a specific Pyme
  Stream<List<Map<String, dynamic>>> getOrdersForPyme(String pymeId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('pymeId', isEqualTo: pymeId)
        // .orderBy('createdAt', descending: true) // Moved to client-side to avoid needing index
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return data;
      }).toList();
      
      // Sort client-side
      orders.sort((a, b) {
        final aTime = a['createdAt'] as DateTime? ?? DateTime(1970);
        final bTime = b['createdAt'] as DateTime? ?? DateTime(1970);
        return bTime.compareTo(aTime); // Descending
      });
      
      return orders;
    });
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  // Update Pyme Profile
  Future<void> updatePymeProfile(String pymeId, Map<String, dynamic> data) async {
    await _usersCollection.doc(pymeId).update(data);
  }

  // Get Pyme Metrics
  Stream<Map<String, dynamic>> getPymeMetrics(String pymeId) {
    // Combine Orders and Payments streams
    // This is a bit complex with RxDart, but with standard streams we can listen to both
    // For simplicity, let's just return a stream that combines the latest from both collections manually
    // or just listen to 'payments' for sales and 'orders' for pending.
    
    // Better approach: Query 'payments' for confirmed sales.
    return FirebaseFirestore.instance
        .collection('payments')
        .where('pymeId', isEqualTo: pymeId) // Ensure payments have pymeId
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((paymentSnapshot) {
          
      double totalSales = 0;
      int completedOrders = 0;
      
      for (var doc in paymentSnapshot.docs) {
        final data = doc.data();
        totalSales += (data['transaction_amount'] ?? 0);
        completedOrders++;
      }

      // We still need pending quotes from 'orders'
      // Since we can't easily combine streams here without rxdart, 
      // let's just return sales data here and handle pending orders in the UI widget 
      // or duplicate logic. 
      // Or, we can use a StreamGroup or async generator?
      
      return {
        'totalSales': totalSales,
        'completedOrders': completedOrders,
        'pendingOrders': 0, // Placeholder, will be fetched in UI or via different stream
        'totalOrders': completedOrders, // Confirmed orders
      };
    });
  }

  // Get Pending Orders Count
   Stream<int> getPendingOrdersCount(String pymeId) {
     return FirebaseFirestore.instance
         .collection('orders')
         .where('pymeId', isEqualTo: pymeId)
         .where('status', whereIn: ['pending', 'quote_requested'])
         .snapshots()
         .map((snapshot) => snapshot.docs.length);
   }

  // --- Validation ---
  Future<void> redeemCouponForUser(String userId) async {
    await _usersCollection.doc(userId).set({
      'monthlyCouponRedeemed': true,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  // --- Offers Management ---
  Stream<List<Map<String, dynamic>>> getOffersByPyme(String pymeId) {
    return _usersCollection
        .doc(pymeId)
        .collection('offers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // --- Events Management ---
  Stream<List<Map<String, dynamic>>> getEventsByPyme(String pymeId) {
    // For now, assuming events are stored in a subcollection 'events' in user doc,
    // OR they are products with isService=true and some event flag. 
    // BUT the user asked for modification in PymeAddProductScreen to remove services/events from there.
    // So distinct events should likely be in their own colelction or subcollection.
    // Let's assume subcollection 'events' for better structure as requested in 'Events Section'.
    
    return _usersCollection
        .doc(pymeId)
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  
  // Create Offer in pyme's subcollection
  Future<void> createOffer(String pymeId, Map<String, dynamic> offerData) async {
    // If offer is special, ensuring only one special offer exists
    if (offerData['isSpecial'] == true) {
      final batch = FirebaseFirestore.instance.batch();
      final specialOffersQuery = await _usersCollection
          .doc(pymeId)
          .collection('offers')
          .where('isSpecial', isEqualTo: true)
          .get();

      for (var doc in specialOffersQuery.docs) {
        batch.update(doc.reference, {'isSpecial': false});
      }

      final newDocRef = _usersCollection.doc(pymeId).collection('offers').doc();
      batch.set(newDocRef, offerData);
      
      await batch.commit();
    } else {
      await _usersCollection.doc(pymeId).collection('offers').add(offerData);
    }
  }

  // Update Offer
  Future<void> updateOffer(String pymeId, String offerId, Map<String, dynamic> offerData) async {
    // If setting as special, disable any other special offer first
    if (offerData['isSpecial'] == true) {
      final batch = FirebaseFirestore.instance.batch();
      final specialOffersQuery = await _usersCollection
          .doc(pymeId)
          .collection('offers')
          .where('isSpecial', isEqualTo: true)
          .get();

      for (var doc in specialOffersQuery.docs) {
        if (doc.id != offerId) {
          batch.update(doc.reference, {'isSpecial': false});
        }
      }

      batch.update(_usersCollection.doc(pymeId).collection('offers').doc(offerId), offerData);
      await batch.commit();
    } else {
      await _usersCollection.doc(pymeId).collection('offers').doc(offerId).update(offerData);
    }
  }

  // Delete Offer
  Future<void> deleteOffer(String pymeId, String offerId) async {
    await _usersCollection.doc(pymeId).collection('offers').doc(offerId).delete();
  }

  // Delete All Offers (When changing category)
  Future<void> deleteAllOffersByPyme(String pymeId) async {
    final snapshot = await _usersCollection.doc(pymeId).collection('offers').get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --- Support Tickets ---
  Future<void> createSupportTicket(Map<String, dynamic> ticketData) async {
    await FirebaseFirestore.instance.collection('support_tickets').add({
      ...ticketData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', // pending, in_progress, resolved
    });
  }

  Stream<List<Map<String, dynamic>>> getUserTickets(String userId) {
    return FirebaseFirestore.instance
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    });
  }
}

