class ProductVariant {
  final String id;
  final Map<String, String> attributes; // {"Color": "Rojo", "Talla": "M"}
  final int stock;
  final double? priceOverride; // null = usa precio del producto padre

  ProductVariant({
    required this.id,
    required this.attributes,
    required this.stock,
    this.priceOverride,
  });

  double getPrice(double parentPrice) => priceOverride ?? parentPrice;

  String get label => attributes.values.join(' / ');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attributes': attributes,
      'stock': stock,
      if (priceOverride != null) 'priceOverride': priceOverride,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      attributes: Map<String, String>.from(map['attributes'] ?? {}),
      stock: (map['stock'] is int)
          ? (map['stock'] as int)
          : int.tryParse(map['stock'].toString()) ?? 0,
      priceOverride: map['priceOverride'] != null
          ? (map['priceOverride'] is num)
              ? (map['priceOverride'] as num).toDouble()
              : double.tryParse(map['priceOverride'].toString())
          : null,
    );
  }

  ProductVariant copyWith({
    String? id,
    Map<String, String>? attributes,
    int? stock,
    double? priceOverride,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      attributes: attributes ?? this.attributes,
      stock: stock ?? this.stock,
      priceOverride: priceOverride ?? this.priceOverride,
    );
  }
}

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
  final List<Map<String, String>> variantAxes; // [{name: "Color", values: "Rojo,Azul"}]
  final List<ProductVariant> variants;
  final int registeredCount;

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
    this.variantAxes = const [],
    this.variants = const [],
    this.registeredCount = 0,
  });

  bool get hasVariants => variants.isNotEmpty;

  int get totalStock => hasVariants
      ? variants.fold(0, (sum, v) => sum + v.stock)
      : stock;

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
      'variantAxes': variantAxes.map((a) => Map<String, String>.from(a)).toList(),
      'variants': variants.map((v) => v.toMap()).toList(),
      'registeredCount': registeredCount,
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
      variantAxes: (map['variantAxes'] as List<dynamic>?)
              ?.map((a) => Map<String, String>.from(a as Map))
              .toList() ??
          [],
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      registeredCount: (map['registeredCount'] is int)
          ? (map['registeredCount'] as int)
          : int.tryParse((map['registeredCount'] ?? '0').toString()) ?? 0,
    );
  }
}
