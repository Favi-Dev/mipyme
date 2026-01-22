import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get dashboard stats
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final usersCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'client')
          .count()
          .get();
          
      final pymesCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'pyme')
          .count()
          .get();

      final foundationsCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'foundation')
          .count()
          .get();

      // For transactions and reports, we'll use placeholders or real collections if they exist
      // Assuming 'orders' collection exists for transactions
      final ordersCount = await _firestore.collection('orders').count().get();
      final reportsCount = await _firestore.collection('tickets').count().get();

      return {
        'users': usersCount.count ?? 0,
        'pymes': pymesCount.count ?? 0,
        'foundations': foundationsCount.count ?? 0,
        'transactions': ordersCount.count ?? 0,
        'reports': reportsCount.count ?? 0,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {
        'users': 0,
        'pymes': 0,
        'foundations': 0,
        'transactions': 0,
        'reports': 0,
      };
    }
  }

  // Get Recent Activity
  Stream<List<Map<String, dynamic>>> getRecentActivity() {
    // Combining streams is complex, for now let's just show latest users
    return _firestore
        .collection('users')
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

  // Get All Pymes and Foundations (with optional filter)
  Stream<List<Map<String, dynamic>>> getPymes({String? roleFilter}) {
    List<String> roles = roleFilter != null ? [roleFilter] : ['pyme', 'foundation'];
    
    return _firestore
        .collection('users')
        .where('role', whereIn: roles)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get All Clients
  Stream<List<Map<String, dynamic>>> getClients() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
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
    await _firestore.collection('users').doc(userId).update({
      'isSuspended': suspend,
    });
  }
}
