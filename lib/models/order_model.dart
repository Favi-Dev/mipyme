import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double total;
  final DateTime? scheduledTime;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
    this.scheduledTime,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      scheduledTime: map['scheduledTime'] != null 
          ? DateTime.tryParse(map['scheduledTime']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'total': total,
      'scheduledTime': scheduledTime?.toIso8601String(),
    };
  }
}

class OrderModel {
  final String id;
  final String clientId;
  final String pymeId;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String? couponCode;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.pymeId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.couponCode,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      clientId: map['clientId'] ?? '',
      pymeId: map['pymeId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      couponCode: map['couponCode'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'pymeId': pymeId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'couponCode': couponCode,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
