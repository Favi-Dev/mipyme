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
      name: 'Botines de Cuero Negro',
      description: 'Botines clásicos de cuero genuino, hechos a mano.',
      price: 45000,
      imageUrl: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?auto=format&fit=crop&w=500&q=60',
      code: 'BOT001',
      stock: 12,
      category: 'Comercio/retail',
    ),
    Product(
      id: '2',
      pymeId: 'pyme1',
      name: 'Zapatos Formales Café',
      description: 'Elegancia y comodidad para la oficina.',
      price: 38000,
      imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?auto=format&fit=crop&w=500&q=60',
      code: 'ZAP002',
      stock: 8,
      category: 'Comercio/retail',
    ),
    Product(
      id: '3',
      pymeId: 'pyme1',
      name: 'Kit de Limpieza',
      description: 'Incluye cepillo, betún y paño de microfibra.',
      price: 8500,
      imageUrl: 'https://images.unsplash.com/photo-1631125915902-d8abe92996e1?auto=format&fit=crop&w=500&q=60',
      code: 'KIT003',
      stock: 25,
      category: 'Comercio/retail',
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
