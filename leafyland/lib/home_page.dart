import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api_service.dart';
import 'category_products.dart';
import 'product_details_page.dart';

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
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoading) {
      _loadMoreProducts();
    }
  }

  void _addToCart() {
    setState(() {
      _cartItemCount++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product added to cart')),
    );
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

  Future<void> _loadMoreProducts() async {
    if (!_hasMore || _isLoading) return;

    try {
      setState(() => _isLoading = true);
      
      final moreProducts = await ApiService.getPopularProducts(page: _currentPage + 1);
      
      setState(() {
        if (moreProducts.isNotEmpty) {
          _products.addAll(moreProducts);
          _currentPage++;
        } else {
          _hasMore = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    backgroundColor: Colors.green[700],
    title: Text(
      'LeafyLand',
      style: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    actions: [
      // أيقونة البحث (تبقى كما هي)
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: _showSearchDialog,
      ),
      
      // أيقونة السلة مع العداد (التعديل هنا)
      Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => _showCartDialog(),
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
    ],
  );
}
Widget _buildBody() {
  if (_isLoading && _products.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_errorMessage.isNotEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: _loadData,
    child: SingleChildScrollView(
      child: Column(
        children: [
          _buildPromoBanner(),
          _buildCategoriesSection(),
          _buildHorizontalProductsSection(),
        ],
      ),
    ),
  );
}

Widget _buildHorizontalProductsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('Popular Products'),
      SizedBox(
        height: 250, // ارتفاع ثابت للقائمة الأفقية
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _products.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _products.length) {
              return _buildLoadingIndicator();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildProductCard(_products[index]),
            );
          },
        ),
      ),
      if (_isLoading && _products.isNotEmpty)
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
    ],
  );
}

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: '${ApiService.baseUrl}/storage/banners/61.jpg',
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            height: 150,
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            height: 150,
            child: const Icon(Icons.image_not_supported),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryProductsScreen(
                    categoryId: 0,
                    categoryName: 'All Products',
                  ),
                ),
              );
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

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categories'),
        SizedBox(
          height: 120,
          child: _categories.isEmpty
              ? const Center(child: Text('No categories available'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryItem(_categories[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              categoryId: category['id'],
              categoryName: category['name'],
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _getImageUrl(category['image']),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.category),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] ?? 'Category',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
Widget _buildProductCard(Map<String, dynamic> product) {
  final imageUrl = _getImageUrl(product['image']);
  final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
  final originalPrice = product['is_on_sale'] == true
      ? double.tryParse(product['original_price']?.toString() ?? '0') ?? 0.0
      : null;

  return Container(
    width: 180, // عرض ثابت لكل بطاقة منتج
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المنتج
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            // تفاصيل المنتج
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Product',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (originalPrice != null)
                    Text(
                      '\$${originalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.cairo(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: GoogleFonts.cairo(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
 
 
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        // يمكنك إضافة منطق للتنقل بين الصفحات هنا
      },
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Shop',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '${ApiService.baseUrl}/storage/placeholder.jpg';
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    if (imagePath.startsWith('/storage/')) {
      return '${ApiService.baseUrl}$imagePath';
    }
    return '${ApiService.baseUrl}/storage/$imagePath';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search Products"),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search for plants...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (query) {
            // يمكنك إضافة منطق البحث هنا
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // تنفيذ البحث
              Navigator.pop(context);
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

 void _showCartDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Shopping Cart"),
      content: _cartItemCount == 0
          ? const Text("Your cart is empty")
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("You have $_cartItemCount item(s) in your cart"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to full cart page
                    Navigator.pop(context);
                  },
                  child: const Text("View Cart"),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

}