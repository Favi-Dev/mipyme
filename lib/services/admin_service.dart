import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final usersCount = await _firestore
          .collection('clients')
          .count()
          .get();
          
      final pymesCount = await _firestore
          .collection('pymes')
          .count()
          .get();

      final foundationsCount = await _firestore
          .collection('foundations')
          .count()
          .get();

      // Calculate financial stats
      double totalIncome = 0;
      double totalRevenue = 0;
      final paymentsSnapshot = await _firestore.collection('payments').where('type', whereIn: ['donation', 'product_sale']).get();
      
      for (var doc in paymentsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        totalIncome += amount;
        
        // For accurate revenue, we should ideally fetch each Pyme's commission rate, 
        // but for a fast dashboard stat, assuming an average of 10% is common 
        // if not denormalized in the payment doc. 
        // We'll calculate a fast estimate of 10% here to avoid N+1 queries.
        // In a real prod environment, 'commissionRate' or 'commissionAmount' should be saved inside each 'payment' document by the Cloud Function.
        totalRevenue += amount * 0.10; 
      }

      final reportsCount = await _firestore.collection('tickets').count().get();

      return {
        'users': usersCount.count ?? 0,
        'pymes': pymesCount.count ?? 0,
        'foundations': foundationsCount.count ?? 0,
        'transactions': paymentsSnapshot.docs.length,
        'reports': reportsCount.count ?? 0,
        'totalIncome': totalIncome.toInt(),
        'totalRevenue': totalRevenue.toInt(),
      };
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return {
        'users': 0,
        'pymes': 0,
        'foundations': 0,
        'transactions': 0,
        'reports': 0,
        'totalIncome': 0,
        'totalRevenue': 0,
      };
    }
  }

  // Get Recent Activity
  Stream<List<Map<String, dynamic>>> getRecentActivity() {
    return _firestore
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': 'user_registered',
          'title': 'Nuevo Usuario Registrado',
          'subtitle': data['name'] ?? 'Usuario',
          'time': data['createdAt'],
          'role': data['role'],
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getPymes({String? roleFilter}) {
    String collectionName = roleFilter == 'foundation' ? 'foundations' : 'pymes';
    // Si necesitas todo, requeriría RxDart para combinar. Pero AdminPymeManagement y FoundationManagement lo llaman con filtro.
    return _firestore
        .collection(collectionName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['role'] = collectionName == 'foundations' ? 'foundation' : 'pyme';
        return data;
      }).toList();
    });
  }

  // Get All Clients
  Stream<List<Map<String, dynamic>>> getClients() {
    return _firestore
        .collection('clients')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['role'] = 'client';
        return data;
      }).toList();
    });
  }

  // Get Tickets
  Stream<List<Map<String, dynamic>>> getTickets() {
    return _firestore
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Resolve Ticket
  Future<void> resolveTicket(String ticketId) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'status': 'solved',
      'solvedAt': FieldValue.serverTimestamp(),
    });
    // Todo: Trigger notification
  }

  // Suspend User
  Future<void> suspendUser(String userId, bool suspend) async {
    await _firestore.collection('clients').doc(userId).update({
      'isSuspended': suspend,
    });
  }
}
