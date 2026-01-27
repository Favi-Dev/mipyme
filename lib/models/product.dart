class Product {
  final String id;
  final String pymeId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String code;
  final int stock;
  final String category;
  final bool isService;
  final Map<String, dynamic> customAttributes;

  Product({
    required this.id,
    required this.pymeId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.code,
    required this.stock,
    required this.category,
    this.isService = false,
    this.customAttributes = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'pymeId': pymeId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'code': code,
      'stock': stock,
      'category': category,
      'isService': isService,
      'customAttributes': customAttributes,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      pymeId: map['pymeId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price'].toString()) ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      code: map['code'] ?? '',
      stock: (map['stock'] is int)
          ? (map['stock'] as int)
          : int.tryParse(map['stock'].toString()) ?? 0,
      category: map['category'] ?? '',
      isService: map['isService'] ?? false,
      customAttributes: Map<String, dynamic>.from(map['customAttributes'] ?? {}),
    );
  }
}
