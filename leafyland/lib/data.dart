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
      id: json['id'],
      name: json['name'],
      image: json['image'] ?? 'http://127.0.0.1:8000/api/categories',
      description: json['description'],
    );
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
    );
  }

}