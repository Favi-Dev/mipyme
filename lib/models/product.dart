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
}
