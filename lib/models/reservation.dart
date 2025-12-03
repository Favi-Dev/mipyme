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
}
