import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailsPage extends StatelessWidget {
  final dynamic product;

  const ProductDetailsPage({super.key, required this.product});


  double _getPrice() {
    if (product['price'] == null) return 0.0;
    if (product['price'] is String) {
      return double.tryParse(product['price']) ?? 0.0;
    }
    return (product['price'] as num).toDouble();
  }

  
  double? _getOriginalPrice() {
    if (product['is_on_sale'] != true) return null;
    if (product['original_price'] == null) return null;
    if (product['original_price'] is String) {
      return double.tryParse(product['original_price']);
    }
    return (product['original_price'] as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final price = _getPrice();
    final originalPrice = _getOriginalPrice();
    final rating = product['rating']?.toString() ?? '0.0';
    final stockStatus = (product['stock'] ?? 0) > 0 ? 'In Stock' : 'Out of Stock';
    final stockColor = (product['stock'] ?? 0) > 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details', 
               style: GoogleFonts.cairo()),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added to cart!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: product['image'] ?? 'http://127.0.0.1:8000/api/products',
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),

          
            Text(
              product['name'] ?? 'Product',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                if (originalPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      '\$${originalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // التقييم والمخزون
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 5),
                Text(rating, style: GoogleFonts.cairo(fontSize: 16)),
                const SizedBox(width: 20),
                Text(
                  stockStatus,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: stockColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // الوصف
            Text(
              'Description',
              style: GoogleFonts.cairo(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['description'] ?? 'No description available.',
              style: GoogleFonts.cairo(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // زر الإضافة للسلة
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product['name'] ?? 'Product'} added to cart!'),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}