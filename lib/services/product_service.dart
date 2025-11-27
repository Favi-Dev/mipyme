import '../models/product.dart';

class ProductService {
  static const List<String> categories = [
    'Comercio/retail',
    'Alimentos y gastronomía',
    'Servicios profesionales',
    'Salud, belleza y bienestar',
    'Oficios y manufactura',
    'Educación y cultura',
    'Transporte y logistica',
  ];

  // Mock data
  static final List<Product> _products = [
    Product(
      id: '1',
      pymeId: 'pyme1',
      name: 'Café de Grano 250g',
      description: 'Café tostado artesanal, origen Colombia.',
      price: 8500,
      imageUrl: 'https://picsum.photos/seed/coffee/200/200',
      code: 'CAF001',
      stock: 20,
      category: 'Alimentos y gastronomía',
    ),
    Product(
      id: '2',
      pymeId: 'pyme1',
      name: 'Taza de Cerámica',
      description: 'Taza hecha a mano con diseño único.',
      price: 5000,
      imageUrl: 'https://picsum.photos/seed/mug/200/200',
      code: 'TAZ002',
      stock: 15,
      category: 'Comercio/retail',
    ),
    Product(
      id: '3',
      pymeId: 'pyme2',
      name: 'Pan Integral',
      description: 'Pan de masa madre 100% integral.',
      price: 3500,
      imageUrl: 'https://picsum.photos/seed/bread/200/200',
      code: 'PAN003',
      stock: 10,
      category: 'Alimentos y gastronomía',
    ),
  ];

  List<Product> getProducts() {
    return _products;
  }

  List<Product> getProductsByPyme(String pymeId) {
    return _products.where((p) => p.pymeId == pymeId).toList();
  }

  List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  void addProduct(Product product) {
    _products.add(product);
  }

  List<String> getCategories() {
    return categories;
  }
}
