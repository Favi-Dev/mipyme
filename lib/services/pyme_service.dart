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
        // Extract Pyme ID from path: users/{pymeId}/offers/{offerId}
        final parentPath = doc.reference.parent.path; // users/xyz/offers
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

  // Toggle follow status
  Future<void> toggleFollow(String userId, String pymeId) async {
    final docRef = _usersCollection.doc(userId).collection('following').doc(pymeId);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({'followedAt': FieldValue.serverTimestamp()});
    }
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
    return FirebaseFirestore.instance
        .collection('orders')
        .where('pymeId', isEqualTo: pymeId)
        .snapshots()
        .map((snapshot) {
      int totalOrders = 0;
      double totalSales = 0;
      int completedOrders = 0;
      int pendingOrders = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalOrders++;
        if (data['status'] == 'completed') {
          completedOrders++;
          totalSales += (data['total'] ?? 0);
        } else if (data['status'] == 'pending') {
          pendingOrders++;
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalSales': totalSales,
        'completedOrders': completedOrders,
        'pendingOrders': pendingOrders,
      };
    });
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

