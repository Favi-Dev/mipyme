import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload Profile Image
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      final ref = _storage.ref().child('user_profiles/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      if (kIsWeb) {
        await ref.putData(await imageFile.readAsBytes());
      } else {
        await ref.putFile(File(imageFile.path));
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Upload Cover Image
  Future<String?> uploadCoverImage(XFile imageFile, String userId) async {
    try {
      final ref = _storage.ref().child('user_profiles/$userId/cover_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      if (kIsWeb) {
        await ref.putData(await imageFile.readAsBytes());
      } else {
        await ref.putFile(File(imageFile.path));
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading cover image: $e');
      return null;
    }
  }

  // Upload Product Image
  Future<String?> uploadProductImage(XFile imageFile, String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId/image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      if (kIsWeb) {
        await ref.putData(await imageFile.readAsBytes());
      } else {
        await ref.putFile(File(imageFile.path));
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading product image: $e');
      return null;
    }
  }
}
