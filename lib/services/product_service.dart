import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  static const List<String> categories = [
    'Comercio/retail',
    'Alimentos y gastronomía',
    'Servicios profesionales',
    'Salud, belleza y bienestar',
    'Oficios y manufactura',
    'Educación y cultura',
    'Transporte y logistica',
  ];

  // Get products stream
  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _productsCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  // Get products by Pyme ID
  Stream<List<Product>> getProductsByPyme(String pymeId) {
    return _productsCollection
        .where('pymeId', isEqualTo: pymeId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add product
  Future<void> addProduct(Product product) {
    return _productsCollection.add(product.toMap());
  }

  // Update product
  Future<void> updateProduct(Product product) {
    return _productsCollection.doc(product.id).update(product.toMap());
  }

  // Delete product
  Future<void> deleteProduct(String productId) {
    return _productsCollection.doc(productId).delete();
  }

  // Delete all products by Pyme ID
  Future<void> deleteAllProductsByPyme(String pymeId) async {
    final snapshot = await _productsCollection.where('pymeId', isEqualTo: pymeId).get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
