import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _totalAmount = 0.0;
  final String _cartStorageKey = 'saved_cart_items';

  @override
  void initState() {
    super.initState();
    _loadCartItems();
     _debugPrintCartData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCartItems();
  }

Future<void> _loadCartItems() async {
  debugPrint('Loading cart items...');
  setState(() => _isLoading = true);
  
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedCart = prefs.getString(_cartStorageKey);
    
    if (savedCart != null && savedCart.isNotEmpty) {
      final List<dynamic> decodedCart = json.decode(savedCart);
      setState(() {
        _cartItems = decodedCart.map((item) {
          // تأكد من تحويل السعر إلى رقم
          dynamic price = item['price'];
          double parsedPrice = 0.0;
          
          if (price is int) {
            parsedPrice = price.toDouble();
          } else if (price is double) {
            parsedPrice = price;
          } else if (price is String) {
            parsedPrice = double.tryParse(price) ?? 0.0;
          }

          return {
            'id': item['id'],
            'name': item['name'],
            'price': parsedPrice, // استخدم القيمة المحولة
            'image': item['image'],
            'quantity': item['quantity'],
          };
        }).toList();
        _calculateTotal();
      });
      debugPrint('Loaded cart items: $_cartItems');
    } else {
      debugPrint('No cart items found in storage');
    }
  } catch (e) {
    debugPrint('Error loading cart: $e');
    _showErrorSnackbar('Failed to load cart items');
  } finally {
    setState(() => _isLoading = false);
  }
}
  Future<void> _saveCartItems() async {
    debugPrint('Saving cart items: $_cartItems');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartStorageKey, json.encode(_cartItems));
  }

  void _calculateTotal() {
    double total = _cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
    setState(() => _totalAmount = total);
    _saveCartItems();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
        _calculateTotal();
      });
    } else {
      _removeItem(index);
    }
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
      _calculateTotal();
    });
    _showSuccessSnackbar('Item removed from cart');
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _totalAmount = 0.0;
    });
    _saveCartItems();
    _showSuccessSnackbar('Cart cleared successfully');
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _navigateToCheckout() {
    if (_cartItems.isEmpty) {
      _showErrorSnackbar('Your cart is empty');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cartItems: _cartItems,
          totalAmount: _totalAmount + 5.0,
          onOrderSuccess: _clearCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearCart();
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) => _buildCartItem(_cartItems[index], index),
                      ),
                    ),
                    _buildTotalSection(),
                  ],
                ),
    );
  }

  Future<void> _debugPrintCartData() async {
  final prefs = await SharedPreferences.getInstance();
  final savedCart = prefs.getString(_cartStorageKey);
  
  if (savedCart != null) {
    debugPrint('Cart Data: $savedCart');
    try {
      final decoded = json.decode(savedCart);
      debugPrint('Decoded Cart: $decoded');
    } catch (e) {
      debugPrint('Error decoding cart: $e');
    }
  } else {
    debugPrint('No cart data found');
  }
}

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: GoogleFonts.poppins(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Add some items to get started', style: GoogleFonts.poppins(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildCartItem(Map<String, dynamic> item, int index) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image with better error handling
               Hero(
            tag: 'product-image-${item['id']}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[100],
                child: item['image']?.isNotEmpty == true
                    ? Image.network(
                        item['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image load error: $error');
                          return _buildErrorImage();
                        },
                      )
                    : _buildErrorImage(),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['name'] ?? 'Unknown Product',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${item['price']?.toStringAsFixed(2) ?? '0.00'} JOD',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _updateQuantity(index, item['quantity'] + 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _updateQuantity(index, item['quantity'] - 1),
              ),
            ],
          ),

          // Delete Button
          IconButton(
            icon: Icon(Icons.delete_outline, 
              color: Colors.red[400], 
              size: 24),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    ),
  );
}

Widget _buildErrorImage() {
  return Center(
    child: Icon(
      Icons.image_not_supported_outlined,
      size: 30,
      color: Colors.grey[400],
    ),
  );
}
  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.poppins(fontSize: 16)),
              Text('jod ${_totalAmount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipping', style: GoogleFonts.poppins(fontSize: 16)),
              Text('jod 5.00', style: GoogleFonts.poppins(fontSize: 16)),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('jod ${(_totalAmount + 5.00).toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Proceed to Checkout', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}