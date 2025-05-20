import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../widgets/category_item.dart';
import '../widgets/product_card.dart';
import '../category_products_screen.dart';
import '../product_detail_screen.dart';
import '../allcategoriesscreen.dart';
import '../allproductsscreen.dart';
import '../cart_screen.dart';
import '../profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<dynamic> _categories = [];
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  // int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    // _loadCartItemCount();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final categories = await ApiService.getCategories();
      final products = await ApiService.getPopularProducts();

      setState(() {
        _categories = categories;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(), 
      home: Scaffold(
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? _buildErrorWidget()
                : _buildMainContent(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Colors.green[700],
        title: Text(
          'LeafyLand',
          style: GoogleFonts.cairo(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildErrorWidget() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );

Widget _buildMainContent() {
  return RefreshIndicator(
    onRefresh: _loadData,
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildPromoBanner(),  // أبقيت البانر الترويجي
          _buildCategoriesSection(),
          _buildProductsSection(),
        ],
      ),
    ),
  );
}

// يمكنك حذف دالة _buildSearchBar() بالكامل أو تعليقها
  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search plants...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
          ],
        ),
      );

  Widget _buildPromoBanner() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/61.jpg',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );

  Widget _buildCategoriesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Categories'),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return CategoryItem(
                  name: category['name'],
                  imageUrl: category['image'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryProductsScreen(
                          categoryId: category['id'],
                          categoryName: category['name'],
                        ),
                      ),
                    );
                    setState(() => _currentIndex = 1);
                  },
                );
              },
            ),
          ),
        ],
      );

  Widget _buildProductsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Popular Products'),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return ProductCard(
                  name: product['name'],
                  imageUrl: product['image'],
                  price: double.tryParse(product['price'].toString()) ?? 0.0,
                  originalPrice: product['is_on_sale'] == true
                      ? double.tryParse(product['original_price'].toString())
                      : null,
                  isOnSale: product['is_on_sale'] == true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: product['id']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () {
              if (title == 'Categories') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AllCategoriesScreen()),
                );
              } else if (title == 'Popular Products') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllProductsScreen()),
                );
              }
            },
            child: Text(
              'See All',
              style: GoogleFonts.cairo(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

 BottomNavigationBar _buildBottomNavigationBar() {
  return BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) {
      if (index == 1) {
        // If Shop is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AllProductsScreen()),
        );
      } else if (index == 2) {
        // If Profile is clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      } else {
        // Otherwise just change the index
        setState(() => _currentIndex = index);
      }
    },
    selectedItemColor: Colors.green[700],
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag), label: 'Shop'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}
}