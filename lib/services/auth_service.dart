import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

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
        if (!user.emailVerified) {
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Por favor verifica tu correo electrónico para continuar.',
          );
        }

        // Fetch user role from Firestore
      // Update FCM Token and other logic...
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
            String? token = await NotificationService().getToken();
            if (token != null) {
                await _firestore.collection('users').doc(user.uid).update({
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
        rethrow;
      }
      print(e.toString());
      return null;
    } catch (e) {
      print(e.toString());
      return null;
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

        await _firestore.collection('users').doc(user.uid).set(userProfile.toMap());

        // Save FCM Token
        String? token = await NotificationService().getToken();
        if (token != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
          });
        }
        
        await user.sendEmailVerification();
        await _auth.signOut(); // Sign out until verified

        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
