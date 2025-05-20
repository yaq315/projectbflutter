import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartBadge extends StatefulWidget {
  final VoidCallback? onPressed;

  const CartBadge({Key? key, this.onPressed}) : super(key: key);

  @override
  _CartBadgeState createState() => _CartBadgeState();
}

class _CartBadgeState extends State<CartBadge> {
  int _itemCount = 0;
  final String _cartStorageKey = 'saved_cart_items';

  @override
  void initState() {
    super.initState();
    _loadCartItemCount();
  }

  Future<void> _loadCartItemCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCart = prefs.getString(_cartStorageKey);
      
      if (savedCart != null && savedCart.isNotEmpty) {
        final List<dynamic> decodedCart = json.decode(savedCart);
        setState(() {
          _itemCount = decodedCart.fold(0, (sum, item) => sum + (item['quantity'] as int));
        });
      }
    } catch (e) {
      debugPrint('Error loading cart count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: widget.onPressed,
        ),
        if (_itemCount > 0)
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
                '$_itemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}