
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

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
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'] ?? [];
      } else {
        throw Exception('Failed to load all products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('All products request failed: $e');
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

  static Future<List<dynamic>> getProductsByCategory(int categoryId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/products?category_id=$categoryId'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? data['products'] ?? [];
    } else {
      throw Exception('Failed to load category products: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Category products request failed: $e');
  }
}

  
}