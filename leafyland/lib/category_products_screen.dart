import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryProductsScreenState createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentSortIndex = 0; // 0: Default, 1: Price Low to High, 2: Price High to Low

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final products = await ApiService.getProductsByCategory(widget.categoryId);

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load products: ${e.toString()}';
      });
    }
  }

  void _sortProducts(int index) {
    setState(() {
      _currentSortIndex = index;
      
      switch (index) {
        case 1: // Price Low to High
          _products.sort((a, b) {
            final priceA = double.tryParse(a['price'].toString()) ?? 0;
            final priceB = double.tryParse(b['price'].toString()) ?? 0;
            return priceA.compareTo(priceB);
          });
          break;
        case 2: // Price High to Low
          _products.sort((a, b) {
            final priceA = double.tryParse(a['price'].toString()) ?? 0;
            final priceB = double.tryParse(b['price'].toString()) ?? 0;
            return priceB.compareTo(priceA);
          });
          break;
        default: // Default sorting
          _products.sort((a, b) => a['id'].compareTo(b['id']));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: GoogleFonts.cairo(),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.sort),
            onSelected: _sortProducts,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text('Default Sorting'),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text('Price: High to Low'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: GoogleFonts.cairo(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new arrivals',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return _buildProductItem(_products[index]);
        },
      ),
    );
  }

Widget _buildProductItem(Map<String, dynamic> product) {
  final price = double.tryParse(product['price'].toString()) ?? 0.0;
  final originalPrice = product['is_on_sale'] == true
      ? double.tryParse(product['original_price'].toString())
      : null;
  final isOutOfStock = (int.tryParse(product['stock'].toString()) ?? 0) <= 0;

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: product['id']),
        ),
      );
    },
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product['image'] ?? '',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              if (product['is_on_sale'] == true)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SALE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isOutOfStock)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'No Name',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                
                // Price - التعديل هنا ليكون مشابهًا للصورة
                Row(
                  children: [
                    if (originalPrice != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '\$${originalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: originalPrice != null
                            ? Colors.red[600]  // لون السعر المخفض
                            : Colors.green[700], // لون السعر العادي
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Rating - يمكنك إزالته إذا لم يكن موجودًا في الصورة
                if (product['rating'] != null)
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        product['rating'].toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}