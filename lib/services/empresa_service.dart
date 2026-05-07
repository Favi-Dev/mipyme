import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_profile.dart';

/// Servicio para gestionar las operaciones del rol Empresa:
/// crear tiendas (pymes hijas), crear jefes de tienda, y obtener métricas agregadas.
class EmpresaService {
  final _fs = FirebaseFirestore.instance;

  // ─── Tiendas ───

  /// Obtiene todas las tiendas (pymes) de una empresa específica.
  Stream<List<UserProfile>> getStoresByEmpresa(String empresaId) {
    return _fs
        .collection('pymes')
        .where('parentEmpresaId', isEqualTo: empresaId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Crea una nueva tienda (documento en 'pymes') vinculada a la empresa.
  Future<String> createStore({
    required String empresaId,
    required String name,
    required String category,
    String? description,
    String? location,
    String? hours,
  }) async {
    final docRef = _fs.collection('pymes').doc();
    await docRef.set({
      'name': name,
      'email': '', // Se puede llenar después
      'role': 'pyme',
      'category': category,
      'description': description ?? '',
      'location': location ?? '',
      'hours': hours ?? '',
      'parentEmpresaId': empresaId,
      'createdAt': FieldValue.serverTimestamp(),
      'supporterCount': 0,
      'commissionRate': 0.10,
    });
    return docRef.id;
  }

  /// Actualiza datos de una tienda.
  Future<void> updateStore(String storeId, Map<String, dynamic> data) async {
    await _fs.collection('pymes').doc(storeId).update(data);
  }

  // ─── Colaboradores (Store Managers) ───

  /// Obtiene todos los store managers de una empresa.
  Stream<List<UserProfile>> getStoreManagersByEmpresa(String empresaId) {
    return _fs
        .collection('store_managers')
        .where('parentEmpresaId', isEqualTo: empresaId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Crea un nuevo store manager llamando a una Cloud Function.
  /// Esto evita que la sesión del administrador actual (Empresa) se cierre.
  Future<String> createStoreManager({
    required String empresaId,
    required String email,
    required String password,
    required String name,
    required String assignedStoreId,
    required String assignedStoreName,
    String? rut,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createStoreManager');
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
        'name': name,
        'assignedStoreId': assignedStoreId,
        'assignedStoreName': assignedStoreName,
        'rut': rut ?? '',
      });

      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return data['uid'] as String;
      } else {
        throw Exception(data['message'] ?? 'Error desconocido desde el servidor');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Código de error de Cloud Functions: ${e.code}');
      debugPrint('Detalles del error: ${e.message}');
      throw Exception(e.message ?? 'Fallo al contactar el servidor');
    } catch (e) {
      throw Exception('Excepción al crear colaborador: $e');
    }
  }

  /// Actualiza la tienda asignada a un store manager.
  Future<void> reassignStoreManager(String managerId, String newStoreId, String newStoreName) async {
    await _fs.collection('store_managers').doc(managerId).update({
      'assignedStoreId': newStoreId,
      'assignedStoreName': newStoreName,
    });
  }

  // ─── Métricas Agregadas ───

  /// Obtiene las ventas totales de todas las tiendas de una empresa.
  Future<Map<String, dynamic>> getAggregatedMetrics(String empresaId) async {
    // Obtener IDs de las tiendas
    final storesSnap = await _fs
        .collection('pymes')
        .where('parentEmpresaId', isEqualTo: empresaId)
        .get();

    final storeIds = storesSnap.docs.map((d) => d.id).toList();

    if (storeIds.isEmpty) {
      return {
        'totalSales': 0.0,
        'totalOrders': 0,
        'storeCount': 0,
        'topStores': <Map<String, dynamic>>[],
      };
    }

    double totalSales = 0;
    int totalOrders = 0;
    List<Map<String, dynamic>> storeMetrics = [];

    // Iterar por cada tienda y obtener pagos aprobados
    for (final storeId in storeIds) {
      final paymentsSnap = await _fs
          .collection('payments')
          .where('pymeId', isEqualTo: storeId)
          .where('status', isEqualTo: 'approved')
          .get();

      double storeSales = 0;
      for (final doc in paymentsSnap.docs) {
        storeSales += (doc.data()['transaction_amount'] ?? 0).toDouble();
      }

      final storeData = storesSnap.docs.firstWhere((d) => d.id == storeId).data();
      storeMetrics.add({
        'storeId': storeId,
        'storeName': storeData['name'] ?? 'Sin nombre',
        'sales': storeSales,
        'orders': paymentsSnap.docs.length,
      });

      totalSales += storeSales;
      totalOrders += paymentsSnap.docs.length;
    }

    // Ordenar por ventas descendente
    storeMetrics.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'storeCount': storeIds.length,
      'topStores': storeMetrics.take(10).toList(),
    };
  }
}
