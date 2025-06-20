import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/vehicle_service.dart' as service;

class Vehicle {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String type;
  final double mileage;
  final String fuelType;
  final double score;
  final String imageUrl;
  final String? bodyType;
  final String? driveTrain;
  final int? year;

  Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.type,
    required this.mileage,
    required this.fuelType,
    required this.score,
    required this.imageUrl,
    this.bodyType,
    this.driveTrain,
    this.year,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    try {
      return Vehicle(
        id: json['id']?.toString() ??
            json['vehicle_id']?.toString() ??
            json['_id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name']?.toString() ??
            json['model']?.toString() ??
            '${json['make'] ?? 'Unknown'} ${json['model'] ?? 'Vehicle'}',
        brand:
            json['brand']?.toString() ?? json['make']?.toString() ?? 'Unknown',
        price: _parseDouble(json['price']),
        type: json['type']?.toString() ??
            json['vehicle_type']?.toString() ??
            json['body']?.toString() ??
            'Unknown',
        mileage: _parseDouble(json['mileage']),
        fuelType: json['fuel_type']?.toString() ??
            json['fuelType']?.toString() ??
            json['fuel']?.toString() ??
            'Unknown',
        score: _parseDouble(json['score'] ?? json['match_score'] ?? 0.8),
        imageUrl:
            json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
        bodyType: json['body_type']?.toString() ??
            json['bodyType']?.toString() ??
            json['body']?.toString(),
        driveTrain: json['drive_train']?.toString() ??
            json['driveTrain']?.toString() ??
            json['drivetrain']?.toString(),
        year:
            json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      );
    } catch (e) {
      debugPrint('Error parsing vehicle JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'type': type,
      'mileage': mileage,
      'fuel_type': fuelType,
      'score': score,
      'image_url': imageUrl,
      'body_type': bodyType,
      'drive_train': driveTrain,
      'year': year,
    };
  }

  // Add a method to fetch vehicles from API
  static Future<List<Vehicle>> fetchVehicles() async {
    try {
      // Use VehicleService.baseUrl instead of hardcoded localhost
      final response = await http
          .get(Uri.parse('${service.VehicleService.baseUrl}/vehicles'));

      if (response.statusCode == 200) {
        // ✅ Fix: Handle the correct response structure from Flask
        final dynamic responseData = json.decode(response.body);
        List<dynamic> data;

        if (responseData is Map<String, dynamic>) {
          data = responseData['vehicles'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          debugPrint('Unexpected response format: $responseData');
          throw Exception('Unexpected response format');
        }

        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        debugPrint('Failed to load vehicles: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      throw Exception('Error fetching vehicles: $e');
    }
  }
}
