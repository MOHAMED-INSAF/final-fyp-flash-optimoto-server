import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  static String? _token;

  static Future<Map<String, dynamic>> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    _token = data['token'];
    return _token!;
  }

  static Future<List<dynamic>> getVehicles({
    String? type,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? year,
  }) async {
    final queryParams = {
      if (type != null) 'type': type,
      if (brand != null) 'brand': brand,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (year != null) 'year': year.toString(),
    };

    final response = await http.get(
      Uri.parse('$baseUrl/vehicles').replace(queryParameters: queryParams),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getWishlist() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wishlist'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getRecommendations({
    required double budgetMin,
    required double budgetMax,
    required double mileageMin,
    required double mileageMax,
    String fuel = 'Any',
    String body = 'Any',
    String drivetrain = 'Any',
    String purpose = 'Urban',
    int topN = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'mileage_min': mileageMin,
        'mileage_max': mileageMax,
        'fuel': fuel,
        'body': body,
        'drivetrain': drivetrain,
        'purpose': purpose,
        'top_n': topN,
      }),
    );

    final data = jsonDecode(response.body);
    return data['recommendations'];
  }
} 