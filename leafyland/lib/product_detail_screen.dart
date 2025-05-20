import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import 'cart_screen.dart';
import 'dart:convert'; 

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<dynamic> _productFuture;
  int _quantity = 1;
  bool _isAddingToCart = false;
  int _cartItemCount = 0;
  final String _cartStorageKey = 'saved_cart_items';

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProductDetails();
    _loadCartItemCount();
  }

  Future<dynamic> _loadProductDetails() async {
    try {
      final response = await ApiService.getProductDetails(widget.productId);
      return response;
    } catch (e) {
      throw Exception('Failed to load product details: $e');
    }
  }

  Future<void> _loadCartItemCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCart = prefs.getString(_cartStorageKey);
      
      if (savedCart != null && savedCart.isNotEmpty) {
        final List<dynamic> decodedCart = json.decode(savedCart);
        setState(() {
          _cartItemCount = decodedCart.fold(0, (sum, item) => sum + (item['quantity'] as int));
        });
      }
    } catch (e) {
      debugPrint('Error loading cart count: $e');
    }
  }

 Future<void> _addToCart(int productId, int quantity) async {
  setState(() {
    _isAddingToCart = true;
  });

  try {
    // Get current cart items
    final prefs = await SharedPreferences.getInstance();
    final savedCart = prefs.getString(_cartStorageKey);
    List<Map<String, dynamic>> cartItems = [];

    if (savedCart != null && savedCart.isNotEmpty) {
      cartItems = List<Map<String, dynamic>>.from(json.decode(savedCart));
    }

    // Check if product already exists in cart
    final existingIndex = cartItems.indexWhere((item) => item['id'] == productId);

    if (existingIndex >= 0) {
      // Update quantity if product exists
      setState(() {
        cartItems[existingIndex]['quantity'] += quantity;
      });
    } else {
      // Get current product details with error handling
      final productData = await _productFuture;
      Map<String, dynamic> product;

      try {
        if (productData is Map<String, dynamic>) {
          if (productData.containsKey('data')) {
            product = productData['data'];
          } else if (productData.containsKey('product')) {
            product = productData['product'];
          } else {
            product = productData;
          }
        } else {
          product = {};
        }

        // Validate and format image URL
        String imageUrl = product['image']?.toString() ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          // Add your base URL here if needed
          imageUrl = 'http://10.0.2.2:8000$imageUrl';
        }

        // Add new product to cart with complete details
        cartItems.add({
          'id': productId,
          'name': product['name']?.toString() ?? 'Unknown Product',
          'price': double.tryParse(product['price']?.toString() ?? '0') ?? 0.0,
          'image': imageUrl,
          'quantity': quantity,
          // Add additional product details if needed
          'stock': product['stock'] ?? 0,
          'sku': product['sku'] ?? '',
        });

        debugPrint('Added product to cart: ${product['name']}');
        debugPrint('Image URL: $imageUrl');
      } catch (e) {
        debugPrint('Error processing product data: $e');
        throw Exception('Failed to process product details');
      }
    }

    // Save updated cart
    await prefs.setString(_cartStorageKey, json.encode(cartItems));

    // Update UI
    setState(() {
      _cartItemCount = cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $quantity ${quantity > 1 ? 'items' : 'item'} to cart'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            ).then((_) => _loadCartItemCount()); // Refresh cart count when returning
          },
        ),
      ),
    );
  } catch (e) {
    debugPrint('Add to cart error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to add to cart: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  } finally {
    setState(() {
      _isAddingToCart = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading product',
                    style: GoogleFonts.cairo(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _productFuture = _loadProductDetails();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final productData = snapshot.data;
        Map<String, dynamic> product;

        if (productData is Map<String, dynamic>) {
          if (productData.containsKey('data')) {
            product = productData['data'];
          } else if (productData.containsKey('product')) {
            product = productData['product'];
          } else {
            product = productData;
          }
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: const Center(child: Text('Invalid product data format')),
          );
        }

        if (product.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: const Center(child: Text('No product data available')),
          );
        }

        if (product['name'] == null || product['price'] == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Missing basic product information')),
          );
        }

        return _buildProductDetail(product);
      },
    );
  }

  Widget _buildProductDetail(Map<String, dynamic> product) {
    final stock = product['stock'] != null
        ? int.tryParse(product['stock'].toString()) ?? 0
        : 0;

    final price = product['price'] != null
        ? double.tryParse(product['price'].toString()) ?? 0.0
        : 0.0;

    final originalPrice = product['is_on_sale'] == true
        ? double.tryParse(product['original_price']?.toString() ?? '0') ?? 0.0
        : null;

    final rating = product['rating']?.toDouble() ?? 0.0;
    final description = product['description']?.toString() ?? 'No description available';

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // IconButton(
          //   icon: const Icon(Icons.favorite_border),
          //   onPressed: () {
          //     // Add to favorites
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-image-${product['id']}',
              child: CachedNetworkImage(
                imageUrl: product['image'] ?? '',
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.photo, size: 100),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? 'Unnamed',
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (rating > 0)
                        Chip(
                          backgroundColor: Colors.amber.withOpacity(0.2),
                          label: Row(
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.amber),
                              ),
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${price.toStringAsFixed(2)} JOD',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (originalPrice != null)
                        ...[
                          const SizedBox(width: 12),
                          Text(
                            '${originalPrice.toStringAsFixed(2)} JOD',
                            style: const TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${((originalPrice - price) / originalPrice * 100).toStringAsFixed(0)}% OFF',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Availability:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        stock > 0 ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 16,
                          color: stock > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stock > 0) ...[
                        const SizedBox(width: 16),
                        Text(
                          '($stock available)',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() {
                              _quantity--;
                            });
                          }
                        },
                      ),
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (stock == 0 || _quantity < stock) {
                            setState(() {
                              _quantity++;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot exceed available stock'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  Text(
                    'Description',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),
                  const Divider(),
                  if (product['care_instructions'] != null && product['care_instructions'].toString().isNotEmpty)
                    _buildInfoSection('Care Instructions', product['care_instructions'].toString()),
                  if (product['usage'] != null && product['usage'].toString().isNotEmpty)
                    _buildInfoSection('Usage', product['usage'].toString()),
                  if (product['specifications'] != null && product['specifications'].toString().isNotEmpty)
                    _buildInfoSection('Specifications', product['specifications'].toString()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: stock > 0 ? Colors.green[700] : Colors.grey,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: stock > 0 ? () => _addToCart(product['id'], _quantity) : null,
          child: _isAddingToCart
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  stock > 0 ? 'Add to Cart' : 'Out of Stock',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }
}