
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api_service.dart';
import '../product_detail_screen.dart';
import '../widgets/product_card.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({Key? key}) : super(key: key);

  @override
  _AllProductsScreenState createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  bool _isLoading = true;
  int _currentSortIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await ApiService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = List.from(products);
        _isLoading = false;
      });
      _sortProducts(_currentSortIndex);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    }
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filterProducts();
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product['name'].toString().toLowerCase().contains(query) ||
               product['description'].toString().toLowerCase().contains(query);
      }).toList();
    });
    _sortProducts(_currentSortIndex);
  }

  void _sortProducts(int index) {
    setState(() {
      _currentSortIndex = index;
      
      switch (index) {
        case 1: // Price Low to High
          _filteredProducts.sort((a, b) {
            final priceA = double.tryParse(a['price'].toString()) ?? 0;
            final priceB = double.tryParse(b['price'].toString()) ?? 0;
            return priceA.compareTo(priceB);
          });
          break;
        case 2: // Price High to Low
          _filteredProducts.sort((a, b) {
            final priceA = double.tryParse(a['price'].toString()) ?? 0;
            final priceB = double.tryParse(b['price'].toString()) ?? 0;
            return priceB.compareTo(priceA);
          });
          break;
        default: // Default sorting
          // Apply search filter if there's text in the search field
          if (_searchController.text.isNotEmpty) {
            _filterProducts();
          } else {
            _filteredProducts = List.from(_products);
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // Search will be triggered automatically through the listener
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No products available'
                                  : 'No products found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final price = double.tryParse(product['price'].toString()) ?? 0.0;
                          final originalPrice = product['is_on_sale'] == true
                              ? double.tryParse(product['original_price'].toString())
                              : null;

                          return ProductCard(
                            name: product['name'],
                            imageUrl: product['image'],
                            price: price,
                            originalPrice: originalPrice,
                            isOnSale: product['is_on_sale'] == true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(productId: product['id']),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}