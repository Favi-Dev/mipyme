import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Devuelve el ID de la pyme/tienda que debe gestionar este usuario.
///
/// - Si el usuario es un `storeManager`, retorna su `assignedStoreId`.
/// - Si es `pyme` o `foundation`, retorna su propio uid.
/// - Retorna `null` si no hay usuario logueado.
Future<String?> getActivePymeId() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  // Revisar si es un store manager
  final smDoc = await FirebaseFirestore.instance
      .collection('store_managers')
      .doc(user.uid)
      .get();

  if (smDoc.exists) {
    final data = smDoc.data();
    final assignedStoreId = data?['assignedStoreId'] as String?;
    if (assignedStoreId != null && assignedStoreId.isNotEmpty) {
      return assignedStoreId;
    }
  }

  // Para pyme, foundation o empresa, usar su propio uid
  return user.uid;
}

/// Versión síncrona: retorna el uid actual (fallback).
/// Usar solo cuando no se puede hacer await.
String getActivePymeIdSync() {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
}
