import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  String _getCollectionPath(UserRole role) {
    switch (role) {
      case UserRole.client: return 'clients';
      case UserRole.pyme: return 'pymes';
      case UserRole.foundation: return 'foundations';
      case UserRole.admin: return 'admins';
      case UserRole.empresa: return 'empresas';
      case UserRole.storeManager: return 'store_managers';
    }
  }

  Future<DocumentSnapshot?> _findUserDocument(String uid) async {
    final clientDoc = await _firestore.collection('clients').doc(uid).get();
    if (clientDoc.exists) return clientDoc;

    final pymeDoc = await _firestore.collection('pymes').doc(uid).get();
    if (pymeDoc.exists) return pymeDoc;

    final foundationDoc = await _firestore.collection('foundations').doc(uid).get();
    if (foundationDoc.exists) return foundationDoc;

    final adminDoc = await _firestore.collection('admins').doc(uid).get();
    if (adminDoc.exists) return adminDoc;

    final empresaDoc = await _firestore.collection('empresas').doc(uid).get();
    if (empresaDoc.exists) return empresaDoc;

    final storeManagerDoc = await _firestore.collection('store_managers').doc(uid).get();
    if (storeManagerDoc.exists) return storeManagerDoc;

    return null;
  }

  // --- TEST DATA GENERATOR ---
  Future<void> generateTestUsers() async {
    final testUsers = [
      {'email': 'admin@soyplus.cl', 'pass': '123456', 'role': UserRole.admin, 'name': 'Admin Principal'},
      {'email': 'cliente@soyplus.cl', 'pass': '123456', 'role': UserRole.client, 'name': 'Cliente Plus'},
      {'email': 'pyme@soyplus.cl', 'pass': '123456', 'role': UserRole.pyme, 'name': 'Pyme Ejemplo', 'category': 'Comercio', 'commissionRate': 0.08},
      {'email': 'fundacion@soyplus.cl', 'pass': '123456', 'role': UserRole.foundation, 'name': 'Fundación Activa', 'donationGoal': 5000000.0}
    ];

    for (var u in testUsers) {
      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: u['email'] as String,
          password: u['pass'] as String,
        );
        User? user = result.user;
        if (user != null) {
          final profile = UserProfile(
            id: user.uid,
            name: u['name'] as String,
            email: u['email'] as String,
            role: u['role'] as UserRole,
            createdAt: DateTime.now(),
            category: u['category'] as String?,
            donationGoal: u['donationGoal'] as double?,
            commissionRate: u['commissionRate'] as double?,
          );
          await _firestore.collection(_getCollectionPath(u['role'] as UserRole)).doc(user.uid).set(profile.toMap());
        }
      } catch (e) {
        // Ignorar si el usuario ya existe
      }
    }
    // Forzar cierre de sesión si se inició automáticamente
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
  }

  // Resend Verification Email
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
        await _auth.signOut();
      }
    } catch (e) {
      // If we signed in successfully but threw an error later, sign out
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      rethrow;
    }
  }

  // Login
  Future<UserProfile?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // In production all users must verify their email.
        // In debug mode we allow unverified logins to ease development.
        if (!kDebugMode && !user.emailVerified) {
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Por favor verifica tu correo electrónico para continuar.',
          );
        }

        // Fetch user role from Firestore
        // Fetch user role from Firestore
        DocumentSnapshot? userDoc = await _findUserDocument(user.uid);
        if (userDoc != null && userDoc.exists) {
            String? token = await NotificationService().getToken();
            if (token != null) {
                await userDoc.reference.update({
                'fcmToken': token,
                });
            }
            return UserProfile.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-not-verified') {
        await _auth.signOut();
      }
      rethrow;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Update User Name
  Future<void> updateUserName(String uid, String newName) async {
    try {
      // Update Auth Profile
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
      }
      
      // Update Firestore Profile
      DocumentSnapshot? userDoc = await _findUserDocument(uid);
      if (userDoc != null && userDoc.exists) {
        await userDoc.reference.update({
          'name': newName,
        });
      }
    } catch (e) {
      debugPrint('Error updating user name: $e');
      throw e;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user signed in');

      // Recommended: Mark as deleted in Firestore instead of hard delete immediately
      DocumentSnapshot? userDoc = await _findUserDocument(user.uid);
      if (userDoc != null && userDoc.exists) {
        await userDoc.reference.update({
          'deletedAt': FieldValue.serverTimestamp(),
          'status': 'scheduled_for_deletion',
        });
      }

      // Sign out
      await _auth.signOut();
      
      // Note: Actual deletion from Auth usually requires re-authentication.
      // For this implementation, we mark in Firestore and sign out.
      // If we want to fully delete the Auth user:
      // await user.delete(); 
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw e;
    }
  }

  // Register
  Future<bool> register(String email, String password, String name, UserRole role, {Map<String, dynamic>? additionalData}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Create UserProfile object
        // We construct a map first to merge additionalData, then use UserProfile to validate/serialize if we want,
        // but UserProfile requires all fields.
        // Easier to just construct the map using UserProfile logic or just ensure consistency.
        
        // Let's try to construct UserProfile.
        // But additionalData has keys that match UserProfile fields.
        
        final userProfile = UserProfile(
          id: user.uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
          // Client defaults
          isSubscribed: false,
          monthlyCouponRedeemed: false,
          // Pyme/Foundation fields from additionalData
          category: additionalData?['category'],
          description: additionalData?['description'],
          coverImageUrl: additionalData?['coverImageUrl'],
          logoUrl: additionalData?['logoUrl'],
          hours: additionalData?['hours'],
          location: additionalData?['location'],
          webUrl: additionalData?['webUrl'],
          instagramHandle: additionalData?['instagramHandle'],
          whatsappNumber: additionalData?['whatsappNumber'],
          // Foundation fields
          donationGoal: additionalData?['donationGoal'] is int ? (additionalData?['donationGoal'] as int).toDouble() : additionalData?['donationGoal'],
          currentDonations: 0.0,
          donationAlias: additionalData?['donationAlias'],
          donationCbu: additionalData?['donationCbu'],
          // Bank fields
          bankName: additionalData?['bankName'],
          bankAccountType: additionalData?['bankAccountType'],
          bankAccountNumber: additionalData?['bankAccountNumber'],
          bankAccountHolderRut: additionalData?['bankAccountHolderRut'],
        );

        String collectionPath = _getCollectionPath(role);
        await _firestore.collection(collectionPath).doc(user.uid).set(userProfile.toMap());

        // Save FCM Token
        String? token = await NotificationService().getToken();
        if (token != null) {
          await _firestore.collection(collectionPath).doc(user.uid).update({
            'fcmToken': token,
          });
        }
        
        await user.sendEmailVerification();
        await _auth.signOut(); // Sign out until verified

        return true;
      }
      return false;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}

