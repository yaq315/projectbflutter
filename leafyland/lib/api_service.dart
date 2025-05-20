
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Helper method for making GET requests
  static Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data from $endpoint: ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Helper method for making POST requests
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 422) {
        // Handle validation errors
        final errors = json.decode(response.body)['errors'];
        throw Exception(errors?.values.first?.first ?? 'Validation failed');
      } else {
        throw Exception('Failed to post data: ${response.body}');
      }
    } catch (e) {
      throw Exception('Post request failed: $e');
    }
  }

 
  // جلب جميع الفئات
static Future<List<dynamic>> getCategories() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // إذا كان الرد يأتي كـ List مباشرة
      if (data is List) {
        print(data);
        return data;
      }
      // إذا كان الرد يأتي كـ Map يحتوي على List
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Categories request failed: $e');
  }
}

static Future<List<dynamic>> getPopularProducts() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // إذا كان الرد يأتي كـ List مباشرة
      if (data is List) {
        return data;
      }
      // إذا كان الرد يأتي كـ Map يحتوي على List
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Products request failed: $e');
  }
}

  // جلب جميع المنتجات (لصفحة See All)
static Future<List<dynamic>> getAllProducts() async {
  final response = await http.get(
    Uri.parse('$baseUrl/products'),
    headers: {'Accept': 'application/json'},
  ).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    // التعديل هنا👇
    return data['data'] ?? [];
  } else {
    throw Exception('Failed to load all products: ${response.statusCode}');
  }
}

  // User login with improved error handling
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await post('login', {
        'email': email,
        'password': password,
        'device_name': 'flutter_web',
      });

      if (response is Map<String, dynamic> && response.containsKey('access_token')) {
        return response;
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // User registration
  static Future<dynamic> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    return await post('register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirmPassword,
    });
  }
// في ملف api_service.dart
static Future<List<dynamic>> getProductsByCategory(int categoryId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId/products'), // Removed extra /api
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Failed to load products - Status: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load products: $e');
  }
}


static Future<Map<String, dynamic>> getProductDetails(int productId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product details: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Product details request failed: $e');
  }
}



static Future<List<dynamic>> getCartItems(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['items'] ?? [];
    } else {
      throw Exception('Failed to load cart items: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Cart request failed: $e');
  }
}

static Future<void> addToCart(String token, int productId, int quantity, {String size = 'medium'}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
        'size': size,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('Failed to add to cart: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Add to cart failed: $e');
  }
}

// static Future<void> updateCartItem(String token, int cartItemId, int quantity) async {
//   try {
//     final response = await http.put(
//       Uri.parse('$baseUrl/cart/$cartItemId'),
//       headers: {
//         'Accept': 'application/json',
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//       body: json.encode({
//         'quantity': quantity,
//       }),
//     ).timeout(const Duration(seconds: 10));

//     if (response.statusCode != 200) {
//       throw Exception('Failed to update cart item: ${response.statusCode}');
//     }
//   } catch (e) {
//     throw Exception('Update cart item failed: $e');
//   }
// }

// static Future<void> removeCartItem(String token, int cartItemId) async {
//   try {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/cart/$cartItemId'),
//       headers: {
//         'Accept': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     ).timeout(const Duration(seconds: 10));

//     if (response.statusCode != 200) {
//       throw Exception('Failed to remove cart item: ${response.statusCode}');
//     }
//   } catch (e) {
//     throw Exception('Remove cart item failed: $e');
//   }
// }
  
}