import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class SeedingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'clients';
      case UserRole.pyme:
        return 'pymes';
      case UserRole.foundation:
        return 'foundations';
      case UserRole.admin:
        return 'admins';
      case UserRole.empresa:
        return 'empresas';
      case UserRole.storeManager:
        return 'store_managers';
    }
  }

  Future<void> seedUsers() async {
    // SAFETY GUARD: seeding is only allowed in debug/dev builds
    assert(kDebugMode, 'SeedingService cannot be used in production builds.');
    if (!kDebugMode) return;
    // 1. Create Admin
    await _createUser(
      email: 'admin@soyplus.cl',
      password: 'Password123!',
      name: 'Administrador SoyPlus',
      role: UserRole.admin,
    );

    // 2. Create Pyme
    await _createUser(
      email: 'pyme@ejemplo.cl',
      password: 'Password123!',
      name: 'Zapatería Los Robles',
      role: UserRole.pyme,
      additionalData: {
        'category': 'Comercio/retail',
        'description': 'Calzado artesanal de cuero legítimo, hecho a mano con tradición y estilo.',
        'coverImageUrl': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=800&q=80',
        'logoUrl': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=200&q=80', // Using URL instead of asset for seeding to ensure it works
        'hours': 'Lun-Vie: 10:00 - 19:00\nSáb: 10:00 - 14:00',
        'location': 'Calle Los Robles 456, Providencia',
        'latitude': -33.426280,
        'longitude': -70.610580,
        'webUrl': 'www.zapaterialosrobles.cl',
        'instagramHandle': '@zapaterialosrobles',
        'whatsappNumber': '+56987654321',
        'tags': ['calzado', 'cuero', 'artesanal', 'moda'],
        'bankName': 'Banco de Chile',
        'bankAccountType': 'Cuenta Corriente',
        'bankAccountNumber': '123456789',
        'bankAccountHolderRut': '76.123.456-7',
      },
    );

    // 3. Create Foundation
    await _createUser(
      email: 'fundacion@ejemplo.cl',
      password: 'Password123!',
      name: 'Fundación Los Robles',
      role: UserRole.foundation,
      additionalData: {
        'category': 'Educación y cultura',
        'description': 'Fundación sin fines de lucro, que busca impulsar el reciclaje y el apoyo a bancos de trabajo.',
        'coverImageUrl': 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=800&q=80',
        'logoUrl': 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=200&q=80',
        'hours': 'Lun-Vie: 09:00 - 18:00',
        'location': 'Av. Providencia 1234, Oficina 505',
        'latitude': -33.426280,
        'longitude': -70.610580,
        'webUrl': 'www.fundacionlosrobles.cl',
        'instagramHandle': '@fundacionlosrobles',
        'whatsappNumber': '+56912345678',
        'tags': ['reciclaje', 'educación', 'comunidad'],
        'donationGoal': 5000000.0,
        'currentDonations': 1250000.0,
        'donationAlias': 'fundacion.losrobles.donar',
        'donationCbu': '0000003100000000000000',
        'bankName': 'Banco Estado',
        'bankAccountType': 'Cuenta Vista / RUT',
        'bankAccountNumber': '654321987',
        'bankAccountHolderRut': '65.432.198-K',
      },
    );
     // 4. Create Client
    await _createUser(
      email: 'cliente@ejemplo.cl',
      password: 'Password123!',
      name: 'Juan Pérez',
      role: UserRole.client,
      additionalData: {
        'isSubscribed': true,
        'subscriptionDate': DateTime.now(),
        'monthlyCouponRedeemed': false,
      },
    );
  }

  Future<void> _createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // 1. Create Auth User (or sign in if exists to update profile)
      UserCredential cred;
      try {
        cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        debugPrint('Created user: $email');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          debugPrint('User $email already exists, signing in to update profile...');
          cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
        } else {
          rethrow;
        }
      }

      if (cred.user != null) {
        final uid = cred.user!.uid;

        // 2. Create UserProfile
        final userProfile = UserProfile(
          id: uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          // Merge additional data
          isSubscribed: additionalData?['isSubscribed'] ?? false,
          subscriptionDate: additionalData?['subscriptionDate'],
          monthlyCouponRedeemed: additionalData?['monthlyCouponRedeemed'] ?? false,
          category: additionalData?['category'],
          description: additionalData?['description'],
          coverImageUrl: additionalData?['coverImageUrl'],
          logoUrl: additionalData?['logoUrl'],
          hours: additionalData?['hours'],
          location: additionalData?['location'],
          latitude: additionalData?['latitude'],
          longitude: additionalData?['longitude'],
          webUrl: additionalData?['webUrl'],
          instagramHandle: additionalData?['instagramHandle'],
          whatsappNumber: additionalData?['whatsappNumber'],
          tags: additionalData?['tags'],
          donationGoal: additionalData?['donationGoal'],
          currentDonations: additionalData?['currentDonations'],
          donationAlias: additionalData?['donationAlias'],
          donationCbu: additionalData?['donationCbu'],
          bankName: additionalData?['bankName'],
          bankAccountType: additionalData?['bankAccountType'],
          bankAccountNumber: additionalData?['bankAccountNumber'],
          bankAccountHolderRut: additionalData?['bankAccountHolderRut'],
        );

        // 3. Save to Firestore
        await _firestore.collection(_collectionForRole(role)).doc(uid).set(userProfile.toMap());
      debugPrint('Profile updated for $email');
      }
    } catch (e) {
      debugPrint('Error seeding user $email: $e');
    }
  }
}
