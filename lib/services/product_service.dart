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
  static List<Product> _products = [];

  ProductService() {
    if (_products.isEmpty) {
      loadMockProductsForCategory('Comercio/retail');
    }
  }

  void loadMockProductsForCategory(String category) {
    _products.clear();
    switch (category) {
      case 'Comercio/retail':
        _products.addAll([
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
            customAttributes: {'talla': '40', 'color': 'Negro', 'material': 'Cuero'},
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
            customAttributes: {'talla': '42', 'color': 'Café', 'material': 'Cuero'},
          ),
        ]);
        break;
      case 'Alimentos y gastronomía':
        _products.addAll([
          Product(
            id: '3',
            pymeId: 'pyme1',
            name: 'Cappuccino Italiano',
            description: 'Café espresso con leche vaporizada y espuma.',
            price: 2500,
            imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?auto=format&fit=crop&w=500&q=60',
            code: 'CAF001',
            stock: 100,
            category: 'Alimentos y gastronomía',
            customAttributes: {'ingredientes': 'Café, Leche', 'porcion': '250ml'},
          ),
          Product(
            id: '4',
            pymeId: 'pyme1',
            name: 'Torta de Zanahoria',
            description: 'Porción de torta casera con frosting de queso crema.',
            price: 3500,
            imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=500&q=60',
            code: 'PAS001',
            stock: 15,
            category: 'Alimentos y gastronomía',
            customAttributes: {'ingredientes': 'Zanahoria, Harina, Nueces', 'dietetico': 'Vegetariano'},
          ),
        ]);
        break;
      case 'Servicios profesionales':
        _products.addAll([
          Product(
            id: '5',
            pymeId: 'pyme1',
            name: 'Consulta Legal Inicial',
            description: 'Revisión de antecedentes y orientación jurídica básica.',
            price: 50000,
            imageUrl: 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&w=500&q=60',
            code: 'LEG001',
            stock: 10,
            category: 'Servicios profesionales',
            customAttributes: {'modalidad': 'Online', 'duracion': '1 hora'},
          ),
          Product(
            id: '6',
            pymeId: 'pyme1',
            name: 'Redacción de Contrato',
            description: 'Elaboración de contrato de trabajo o arriendo.',
            price: 80000,
            imageUrl: 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=500&q=60',
            code: 'LEG002',
            stock: 5,
            category: 'Servicios profesionales',
            customAttributes: {'modalidad': 'Remoto', 'duracion': '3 días hábiles'},
          ),
        ]);
        break;
      case 'Salud, belleza y bienestar':
        _products.addAll([
          Product(
            id: '7',
            pymeId: 'pyme1',
            name: 'Paracetamol 500mg',
            description: 'Analgésico y antipirético. Caja de 16 comprimidos.',
            price: 1500,
            imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=500&q=60',
            code: 'FAR001',
            stock: 100,
            category: 'Salud, belleza y bienestar',
            customAttributes: {'laboratorio': 'Genérico', 'receta': 'No'},
          ),
          Product(
            id: '8',
            pymeId: 'pyme1',
            name: 'Protector Solar FPS 50+',
            description: 'Protección alta contra rayos UVA/UVB. Hipoalergénico.',
            price: 12990,
            imageUrl: 'https://images.unsplash.com/photo-1556228720-19875c4b84b2?auto=format&fit=crop&w=500&q=60',
            code: 'FAR002',
            stock: 30,
            category: 'Salud, belleza y bienestar',
            customAttributes: {'laboratorio': 'SunCare', 'receta': 'No'},
          ),
        ]);
        break;
      case 'Oficios y manufactura':
        _products.addAll([
          Product(
            id: '9',
            pymeId: 'pyme1',
            name: 'Mesa de Centro Roble',
            description: 'Mesa de centro rústica hecha con madera recuperada.',
            price: 150000,
            imageUrl: 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=500&q=60',
            code: 'MUE001',
            stock: 3,
            category: 'Oficios y manufactura',
            customAttributes: {'tiempo_entrega': '2 semanas', 'garantia': '1 año'},
          ),
          Product(
            id: '10',
            pymeId: 'pyme1',
            name: 'Restauración de Silla',
            description: 'Servicio de lijado, barnizado y retapizado.',
            price: 40000,
            imageUrl: 'https://images.unsplash.com/photo-1503602642458-2321114458ed?auto=format&fit=crop&w=500&q=60',
            code: 'SER001',
            stock: 5,
            category: 'Oficios y manufactura',
            customAttributes: {'tiempo_entrega': '1 semana', 'garantia': '6 meses'},
          ),
        ]);
        break;
      case 'Educación y cultura':
        _products.addAll([
          Product(
            id: '11',
            pymeId: 'pyme1',
            name: 'Charla: Reciclaje en Casa',
            description: 'Aprende a separar tus residuos correctamente. Evento único con expertos.',
            price: 5000,
            imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?auto=format&fit=crop&w=500&q=60',
            code: 'EDU001',
            stock: 50,
            category: 'Educación y cultura',
            customAttributes: {
              'nivel': 'Básico', 
              'horario': '10:00 - 12:00',
              'is_event': 'true',
              'event_date': DateTime.now().add(const Duration(days: 10)).toIso8601String(), // Event in 10 days
            },
          ),
          Product(
            id: '12',
            pymeId: 'pyme1',
            name: 'Taller de Compostaje',
            description: 'Curso práctico de 4 sesiones para crear tu propia compostera.',
            price: 25000,
            imageUrl: 'https://images.unsplash.com/photo-1581578017093-cd30fce4eeb7?auto=format&fit=crop&w=500&q=60',
            code: 'EDU002',
            stock: 15,
            category: 'Educación y cultura',
            customAttributes: {'nivel': 'Intermedio', 'horario': 'Sábados 15:00'},
          ),
        ]);
        break;
      case 'Transporte y logística':
        _products.addAll([
          Product(
            id: '13',
            pymeId: 'pyme1',
            name: 'Flete Pequeño (Camioneta)',
            description: 'Traslado de cajas y muebles pequeños dentro de la comuna.',
            price: 25000,
            imageUrl: 'https://images.unsplash.com/photo-1605218427368-35b08968e094?auto=format&fit=crop&w=500&q=60',
            code: 'FLE001',
            stock: 50,
            category: 'Transporte y logística',
            customAttributes: {'capacidad': '500kg', 'cobertura': 'Santiago Centro'},
          ),
          Product(
            id: '14',
            pymeId: 'pyme1',
            name: 'Mudanza Depto 1D',
            description: 'Servicio completo con peonetas para departamento de 1 dormitorio.',
            price: 120000,
            imageUrl: 'https://images.unsplash.com/photo-1600518464441-9154a4dea21b?auto=format&fit=crop&w=500&q=60',
            code: 'MUD001',
            stock: 20,
            category: 'Transporte y logística',
            customAttributes: {'capacidad': 'Camión 3/4', 'cobertura': 'Región Metropolitana'},
          ),
        ]);
        break;
      case 'Metamorfosis':
        _products.addAll([
          Product(
            id: '15',
            pymeId: 'pyme1',
            name: 'Chaqueta Denim Reciclada',
            description: 'Chaqueta de mezclilla intervenida con parches y bordados únicos.',
            price: 45000,
            imageUrl: 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?auto=format&fit=crop&w=500&q=60',
            code: 'META001',
            stock: 1,
            category: 'Reciclaje Textil',
            customAttributes: {'talla': 'M', 'material': 'Denim Reciclado', 'pieza_unica': 'Sí'},
          ),
          Product(
            id: '16',
            pymeId: 'pyme1',
            name: 'Bolso Tote Patchwork',
            description: 'Bolso resistente hecho con retazos de telas de alta calidad.',
            price: 18000,
            imageUrl: 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=500&q=60',
            code: 'META002',
            stock: 5,
            category: 'Reciclaje Textil',
            customAttributes: {'material': 'Algodón/Lino', 'dimensiones': '40x35cm'},
          ),
        ]);
        break;
    }
  }

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
