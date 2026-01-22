import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String pymeId;
  final String productId;
  final String userId;
  final DateTime scheduledTime;
  final String status; // 'confirmed', 'pending', 'cancelled'

  Reservation({
    required this.id,
    required this.pymeId,
    required this.productId,
    required this.userId,
    required this.scheduledTime,
    this.status = 'pending',
  });

  factory Reservation.fromMap(Map<String, dynamic> map, String id) {
    return Reservation(
      id: id,
      pymeId: map['pymeId'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pymeId': pymeId,
      'productId': productId,
      'userId': userId,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status,
    };
  }
}
