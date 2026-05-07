import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, pyme, foundation, admin, empresa, storeManager }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;
  
  // Client specific
  final bool isSubscribed;
  final DateTime? subscriptionDate;
  final bool monthlyCouponRedeemed;
  final int points;
  final List<String> badges;

  // Pyme/Foundation specific
  final String? category;
  final String? description;
  final String? coverImageUrl;
  final String? logoUrl;
  final String? hours;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? webUrl;
  final String? instagramHandle;
  final String? whatsappNumber;
  final List<String>? tags;
  
  // Foundation specific
  final double? donationGoal;
  final String? donationGoalDescription;
  final double? currentDonations;
  final String? donationAlias;
  final String? donationCbu;

  // Bank Account Info (Pyme & Foundation)
  final String? bankName;
  final String? bankAccountType;
  final String? bankAccountNumber;
  final String? bankAccountHolderRut; // Usually same as company RUT but could be different

  // Metrics
  final int supporterCount;
  final double? averageRating;
  final int? reviewCount;
  
  // Financial
  final double? commissionRate; // % de comisión (ej: 0.05 para 5%) 

  // Empresa / StoreManager hierarchy
  final String? parentEmpresaId;   // ID de la empresa padre (para tiendas y storeManagers)
  final String? assignedStoreId;   // ID de la tienda asignada (solo storeManager)
  final String? assignedStoreName; // Nombre legible de la tienda asignada

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isSubscribed = false,
    this.subscriptionDate,
    this.monthlyCouponRedeemed = false,
    this.points = 0,
    this.badges = const [],
    this.category,
    this.description,
    this.coverImageUrl,
    this.logoUrl,
    this.hours,
    this.location,
    this.latitude,
    this.longitude,
    this.webUrl,
    this.instagramHandle,
    this.whatsappNumber,
    this.tags,
    this.donationGoal,
    this.donationGoalDescription,
    this.currentDonations,
    this.donationAlias,
    this.donationCbu,
    this.bankName,
    this.bankAccountType,
    this.bankAccountNumber,
    this.bankAccountHolderRut,
    this.supporterCount = 0,
    this.averageRating,
    this.reviewCount,
    this.commissionRate,
    this.parentEmpresaId,
    this.assignedStoreId,
    this.assignedStoreName,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: _stringToRole(map['role'] ?? 'client'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSubscribed: map['isSubscribed'] ?? false,
      subscriptionDate: (map['subscriptionDate'] as Timestamp?)?.toDate(),
      monthlyCouponRedeemed: map['monthlyCouponRedeemed'] ?? false,
      points: map['points'] ?? 0,
      badges: (map['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: map['category'],
      description: map['description'],
      coverImageUrl: map['coverImageUrl'],
      logoUrl: map['logoUrl'],
      hours: map['hours'],
      location: map['location'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      webUrl: map['webUrl'],
      instagramHandle: map['instagramHandle'],
      whatsappNumber: map['whatsappNumber'],
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      donationGoal: ((map['donationGoal'] as num?)?.toDouble() == 5000000.0 && map['fundraisingGoal'] != null)
          ? (map['fundraisingGoal'] as num?)?.toDouble()
          : ((map['donationGoal'] as num?)?.toDouble() ?? (map['fundraisingGoal'] as num?)?.toDouble()),
      donationGoalDescription: map['donationGoalDescription'] ?? map['fundraisingDescription'],
      currentDonations: (map['currentDonations'] as num?)?.toDouble(),
      donationAlias: map['donationAlias'],
      donationCbu: map['donationCbu'],
      bankName: map['bankName'],
      bankAccountType: map['bankAccountType'],
      bankAccountNumber: map['bankAccountNumber'],
      bankAccountHolderRut: map['bankAccountHolderRut'],
      supporterCount: map['supporterCount'] ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble(),
      reviewCount: map['reviewCount'] as int?,
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0.10, // 10% por defecto si no tiene
      parentEmpresaId: map['parentEmpresaId'],
      assignedStoreId: map['assignedStoreId'],
      assignedStoreName: map['assignedStoreName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSubscribed': isSubscribed,
      'subscriptionDate': subscriptionDate != null ? Timestamp.fromDate(subscriptionDate!) : null,
      'monthlyCouponRedeemed': monthlyCouponRedeemed,
      'points': points,
      'badges': badges,
      'category': category,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'logoUrl': logoUrl,
      'hours': hours,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'webUrl': webUrl,
      'instagramHandle': instagramHandle,
      'whatsappNumber': whatsappNumber,
      'tags': tags,
      'donationGoal': donationGoal,
      'donationGoalDescription': donationGoalDescription,
      'currentDonations': currentDonations,
      'donationAlias': donationAlias,
      'donationCbu': donationCbu,
      'bankName': bankName,
      'bankAccountType': bankAccountType,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountHolderRut': bankAccountHolderRut,
      'commissionRate': commissionRate,
      if (parentEmpresaId != null) 'parentEmpresaId': parentEmpresaId,
      if (assignedStoreId != null) 'assignedStoreId': assignedStoreId,
      if (assignedStoreName != null) 'assignedStoreName': assignedStoreName,
    };
  }

  static UserRole _stringToRole(String roleStr) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == roleStr,
      orElse: () => UserRole.client,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserProfile &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
