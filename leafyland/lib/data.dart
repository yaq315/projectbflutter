class Category {
  final int id;
  final String name;
  final String image;
  final String? description;

  Category({
    required this.id,
    required this.name,
    required this.image,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      image: _getFullImageUrl(json['image'] as String),
      description: json['description'] as String?,
    );
  }

  static String _getFullImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    // إصلاح المسار لضمان أنه يبدأ بشرطة مائلة
    final fixedPath = path.startsWith('/') ? path : '/$path';
    return 'http://localhost:8000$fixedPath';
  }
}

class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String price;
  final String originalPrice;
  final String image;
  final bool isFeatured;
  final bool isHot;
  final bool isOnSale;
  final int stock;
  final String? careInstructions; 
  final String? usage; 

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.image,
    required this.isFeatured,
    required this.isHot,
    required this.isOnSale,
    required this.stock,
    this.careInstructions,
    this.usage,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      price: json['price'],
      originalPrice: json['original_price'],
      image: json['image'],
      isFeatured: json['is_featured'],
      isHot: json['is_hot'],
      isOnSale: json['is_on_sale'],
      stock: json['stock'],
      careInstructions: json['care_instructions'],
      usage: json['usage'],
    );
  }
}