import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class PymeService {
  Future<DocumentReference> _getProfileRef(String id) async {
    final pymeDoc = await FirebaseFirestore.instance.collection('pymes').doc(id).get();
    if (pymeDoc.exists) return pymeDoc.reference;
    return FirebaseFirestore.instance.collection('foundations').doc(id);
  }

  // Get all Pymes (role == 'pyme')
  Stream<List<UserProfile>> getPymes() {
    return FirebaseFirestore.instance.collection('pymes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get all Foundations (role == 'foundation')
  Stream<List<UserProfile>> getFoundations() {
    return FirebaseFirestore.instance.collection('foundations')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get User Profile by ID (replacing Stream)
  Future<UserProfile?> getUserProfile(String userId) async {
    final ref = await _getProfileRef(userId);
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
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
    final ref = await _getProfileRef(id);
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Toggle follow status and update supporter count
  Future<void> toggleFollow(String userId, String pymeId) async {
    final userRef = FirebaseFirestore.instance.collection('clients').doc(userId).collection('following').doc(pymeId);
    final pymeRef = await _getProfileRef(pymeId);

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
    final ref = await _getProfileRef(pymeId);
    await ref.update({
      'supporterCount': FieldValue.increment(1),
    });
  }

  // Check if following
  Stream<bool> isFollowing(String userId, String pymeId) {
    return FirebaseFirestore.instance.collection('clients')
        .doc(userId)
        .collection('following')
        .doc(pymeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Get followed pymes IDs
  Stream<List<String>> getFollowedPymeIds(String userId) {
    return FirebaseFirestore.instance.collection('clients')
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

  // Paginated orders fetch — returns 20 results at a time for performance
  Future<List<Map<String, dynamic>>> getOrdersForPymePaginated(
    String pymeId, {
    DocumentSnapshot? lastDocument,
    int pageSize = 20,
  }) async {
    var query = FirebaseFirestore.instance
        .collection('orders')
        .where('pymeId', isEqualTo: pymeId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['_snapshot'] = doc;
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
      }
      return data;
    }).toList();
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
    final ref = await _getProfileRef(pymeId);
    await ref.update(data);
  }

  // Get Pyme Metrics — reads from 'orders' with status 'completed' as the source of truth
  Stream<Map<String, dynamic>> getPymeMetrics(String pymeId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('pymeId', isEqualTo: pymeId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      double totalSales = 0;
      int completedOrders = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSales += (data['total'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'totalSales': totalSales,
        'completedOrders': completedOrders,
        'pendingOrders': 0, // Fetched separately in the UI
        'totalOrders': completedOrders,
      };
    });
  }

  // Get Pyme Metrics filtered by a date range
  Stream<Map<String, dynamic>> getPymeMetricsForRange(String pymeId, DateTime from) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('pymeId', isEqualTo: pymeId)
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .snapshots()
        .map((snapshot) {
      double totalSales = 0;
      int completedOrders = snapshot.docs.length;
      for (var doc in snapshot.docs) {
        totalSales += (doc.data()['total'] as num?)?.toDouble() ?? 0.0;
      }
      return {
        'totalSales': totalSales,
        'completedOrders': completedOrders,
        'pendingOrders': 0,
        'totalOrders': completedOrders,
      };
    });
  }

  // Get Last 7 Days Sales — reads completed orders
  Stream<List<double>> getSevenDaysSales(String pymeId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
    final startOf7DaysAgo = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    return FirebaseFirestore.instance
        .collection('orders')
        .where('pymeId', isEqualTo: pymeId)
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOf7DaysAgo))
        .snapshots()
        .map((snapshot) {
      List<double> dailyTotals = List.filled(7, 0.0);
      final now = DateTime.now();
      final todayStr = DateTime(now.year, now.month, now.day);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;

        final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
        final difference = todayStr.difference(date).inDays;

        int index = 6 - difference;
        if (index >= 0 && index <= 6) {
          dailyTotals[index] += (data['total'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return dailyTotals;
    });
  }

  // Get Last 7 Days Donation Count (for Foundation)
  Stream<List<double>> getSevenDaysDonationCount(String pymeId) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
    final startOf7DaysAgo = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    return FirebaseFirestore.instance
        .collection('payments')
        .where('pymeId', isEqualTo: pymeId)
        .where('status', isEqualTo: 'approved')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOf7DaysAgo))
        .snapshots()
        .map((snapshot) {
      
      List<double> dailyCounts = List.filled(7, 0.0);
      final now = DateTime.now();
      final todayStr = DateTime(now.year, now.month, now.day);
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;
        
        final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
        final difference = todayStr.difference(date).inDays;
        
        int index = 6 - difference;
        if (index >= 0 && index <= 6) {
          dailyCounts[index] += 1.0; // Contar la cantidad de donaciones
        }
      }

      return dailyCounts;
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
    await FirebaseFirestore.instance.collection('clients').doc(userId).set({
      'monthlyCouponRedeemed': true,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    // Attempt client first
    var doc = await FirebaseFirestore.instance.collection('clients').doc(userId).get();
    if (!doc.exists) {
      // Attempt pyme/foundation
      final ref = await _getProfileRef(userId);
      doc = (await ref.get()) as DocumentSnapshot<Map<String, dynamic>>;
    }
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  // --- Offers Management ---
  Stream<List<Map<String, dynamic>>> getOffersByPyme(String pymeId) async* {
    final ref = await _getProfileRef(pymeId);
    yield* ref
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
  Stream<List<Map<String, dynamic>>> getEventsByPyme(String pymeId) async* {
    final ref = await _getProfileRef(pymeId);
    yield* ref
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
    final ref = await _getProfileRef(pymeId);
    if (offerData['isSpecial'] == true) {
      final batch = FirebaseFirestore.instance.batch();
      final specialOffersQuery = await ref.collection('offers').where('isSpecial', isEqualTo: true).get();

      for (var doc in specialOffersQuery.docs) {
        batch.update(doc.reference, {'isSpecial': false});
      }

      final newDocRef = ref.collection('offers').doc();
      batch.set(newDocRef, offerData);
      
      await batch.commit();
    } else {
      await ref.collection('offers').add(offerData);
    }
  }

  // Update Offer
  Future<void> updateOffer(String pymeId, String offerId, Map<String, dynamic> offerData) async {
    final ref = await _getProfileRef(pymeId);
    if (offerData['isSpecial'] == true) {
      final batch = FirebaseFirestore.instance.batch();
      final specialOffersQuery = await ref.collection('offers').where('isSpecial', isEqualTo: true).get();

      for (var doc in specialOffersQuery.docs) {
        if (doc.id != offerId) {
          batch.update(doc.reference, {'isSpecial': false});
        }
      }

      batch.update(ref.collection('offers').doc(offerId), offerData);
      await batch.commit();
    } else {
      await ref.collection('offers').doc(offerId).update(offerData);
    }
  }

  // Delete Offer
  Future<void> deleteOffer(String pymeId, String offerId) async {
    final ref = await _getProfileRef(pymeId);
    await ref.collection('offers').doc(offerId).delete();
  }

  // Delete All Offers (When changing category)
  Future<void> deleteAllOffersByPyme(String pymeId) async {
    final ref = await _getProfileRef(pymeId);
    final snapshot = await ref.collection('offers').get();
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

