import 'package:flutter/foundation.dart';
import '../models/reservation.dart';

class ReservationService extends ChangeNotifier {
  static final ReservationService _instance = ReservationService._internal();
  factory ReservationService() => _instance;
  ReservationService._internal();

  final List<Reservation> _reservations = [];

  // Mock checking availability
  bool isSlotAvailable(String productId, DateTime time) {
    return !_reservations.any((r) => 
      r.productId == productId && 
      r.status != 'cancelled' &&
      r.scheduledTime.year == time.year &&
      r.scheduledTime.month == time.month &&
      r.scheduledTime.day == time.day &&
      r.scheduledTime.hour == time.hour &&
      r.scheduledTime.minute == time.minute
    );
  }

  void bookSlot(String pymeId, String productId, String userId, DateTime time) {
    if (!isSlotAvailable(productId, time)) {
      throw Exception('Este horario ya ha sido reservado por otro usuario.');
    }
    _reservations.add(Reservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pymeId: pymeId,
      productId: productId,
      userId: userId,
      scheduledTime: time,
      status: 'confirmed', 
    ));
    notifyListeners();
  }

  void cancelReservation(String productId, DateTime time) {
     final index = _reservations.indexWhere((r) => 
      r.productId == productId && 
      r.scheduledTime.year == time.year &&
      r.scheduledTime.month == time.month &&
      r.scheduledTime.day == time.day &&
      r.scheduledTime.hour == time.hour &&
      r.scheduledTime.minute == time.minute
    );
    if (index != -1) {
      _reservations.removeAt(index); 
      notifyListeners();
    }
  }
  
  List<DateTime> getTakenSlots(String productId, DateTime date) {
    return _reservations
      .where((r) => 
        r.productId == productId && 
        r.status != 'cancelled' &&
        r.scheduledTime.year == date.year &&
        r.scheduledTime.month == date.month &&
        r.scheduledTime.day == date.day)
      .map((r) => r.scheduledTime)
      .toList();
  }
}
