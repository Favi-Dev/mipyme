import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class ReservationService extends ChangeNotifier {
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  final CollectionReference _reservationsCollection =
      FirebaseFirestore.instance.collection('reservations');

  // Check availability (Real implementation)
  Future<bool> isSlotAvailable(String productId, DateTime time) async {
    // Simple check: is there any confirmed reservation for this product at this time?
    // Note: This requires exact time matching. In a real app, you might check ranges.
    final snapshot = await _reservationsCollection
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'confirmed')
        .where('scheduledTime', isEqualTo: Timestamp.fromDate(time))
        .get();
    
    return snapshot.docs.isEmpty;
  }

  Future<void> bookSlot(String pymeId, String productId, String userId, DateTime time) async {
    if (!await isSlotAvailable(productId, time)) {
      throw Exception('Este horario ya ha sido reservado por otro usuario.');
    }
    
    final reservation = Reservation(
      id: '', // Firestore will generate ID
      pymeId: pymeId,
      productId: productId,
      userId: userId,
      scheduledTime: time,
      status: 'confirmed',
    );

    await _reservationsCollection.add(reservation.toMap());
    notifyListeners();
  }

  Future<void> cancelReservation(String productId, DateTime time) async {
    // Find the reservation to cancel
    final snapshot = await _reservationsCollection
        .where('productId', isEqualTo: productId)
        .where('scheduledTime', isEqualTo: Timestamp.fromDate(time))
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete(); // Or update status to 'cancelled'
    }
    notifyListeners();
  }
  
  Stream<List<DateTime>> getTakenSlots(String productId, DateTime date) {
    // Define start and end of the day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _reservationsCollection
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'confirmed')
        .where('scheduledTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledTime', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['scheduledTime'] as Timestamp).toDate();
          }).toList();
        });
  }
}
