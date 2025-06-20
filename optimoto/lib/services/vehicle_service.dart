import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/vehicle.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

class VehicleService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5001/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5001/api';
      }
    } catch (e) {
      debugPrint('Platform check error: $e');
    }
    return 'http://localhost:5001/api';
  }

  // ✅ Fix: Updated to handle text searches properly
  Future<List<Vehicle>> getRecommendations(Map<String, dynamic> filters) async {
    try {
      debugPrint('=== Getting Recommendations ===');
      debugPrint('Filters received: $filters');

      // ✅ CRITICAL FIX: Handle text searches properly
      final nameSearch = filters['nameSearch']?.toString().trim() ?? '';
      final brandSearch = filters['brandSearch']?.toString().trim() ?? '';

      debugPrint('Name search: "$nameSearch"');
      debugPrint('Brand search: "$brandSearch"');

      // If we have text searches, use text-based filtering
      if (nameSearch.isNotEmpty || brandSearch.isNotEmpty) {
        debugPrint('🔍 Using text-based search');
        return await _getFilteredVehicles(filters);
      }

      // ✅ Enhanced: Build query parameters for API call
      final queryParams = <String, String>{};

      // Add non-text filters to API query
      if (filters['purpose'] != null) {
        queryParams['purpose'] = filters['purpose'].toString();
      }
      if (filters['minPrice'] != null && filters['minPrice'] > 0) {
        queryParams['minPrice'] = filters['minPrice'].toString();
      }
      if (filters['maxPrice'] != null && filters['maxPrice'] < 100000) {
        queryParams['maxPrice'] = filters['maxPrice'].toString();
      }
      if (filters['minMileage'] != null && filters['minMileage'] > 0) {
        queryParams['minMpg'] = filters['minMileage'].toString();
      }
      if (filters['maxMileage'] != null && filters['maxMileage'] < 50) {
        queryParams['maxMpg'] = filters['maxMileage'].toString();
      }
      if (filters['fuelType'] != null && filters['fuelType'] != 'All') {
        queryParams['fuelType'] = filters['fuelType'].toString();
      }
      if (filters['bodyType'] != null && filters['bodyType'] != 'All') {
        queryParams['bodyType'] = filters['bodyType'].toString();
      }

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/recommendations').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      debugPrint('Making API request to: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('API Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> vehiclesData;

        if (responseData is Map<String, dynamic>) {
          vehiclesData = responseData['vehicles'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          vehiclesData = responseData;
        } else {
          throw Exception('Unexpected response format');
        }

        var vehicles =
            vehiclesData.map((json) => Vehicle.fromJson(json)).toList();

        // Apply client-side filtering for any remaining filters
        vehicles = _applyClientSideFiltering(vehicles, filters);

        debugPrint('Returning ${vehicles.length} vehicles after filtering');
        return vehicles;
      } else {
        // If API fails, fall back to text-based search
        debugPrint(
            'API failed with ${response.statusCode}, falling back to text search');
        return await _getFilteredVehicles(filters);
      }
    } catch (e) {
      debugPrint('Error in getRecommendations: $e');
      // Fall back to text-based search on any error
      return await _getFilteredVehicles(filters);
    }
  }

  // ✅ ENHANCED: Better local filtering with improved text search
  Future<List<Vehicle>> _getFilteredVehicles(
      Map<String, dynamic> filters) async {
    try {
      debugPrint('🔍 Performing text-based vehicle search');

      // Get all vehicles first
      List<Vehicle> allVehicles;

      try {
        // Try to get from API first
        allVehicles = await getVehicles();
        debugPrint('Retrieved ${allVehicles.length} vehicles from API');
      } catch (e) {
        debugPrint('API failed, creating sample vehicles: $e');
        // Create comprehensive sample data for text search testing
        allVehicles = _createSampleVehicles();
      }

      if (allVehicles.isEmpty) {
        throw NoMatchingVehiclesException('No vehicles available');
      }

      // ✅ CRITICAL FIX: Enhanced text search implementation
      final nameSearch =
          filters['nameSearch']?.toString().trim().toLowerCase() ?? '';
      final brandSearch =
          filters['brandSearch']?.toString().trim().toLowerCase() ?? '';

      List<Vehicle> filteredVehicles = allVehicles;

      // ✅ FIX: Improved name search
      if (nameSearch.isNotEmpty) {
        debugPrint('🔍 Filtering by name: "$nameSearch"');
        filteredVehicles = filteredVehicles.where((vehicle) {
          final vehicleName = vehicle.name.toLowerCase();
          // Check if any word in the search matches any word in the vehicle name
          final searchWords =
              nameSearch.split(' ').where((word) => word.isNotEmpty);
          final nameWords = vehicleName.split(' ');

          return searchWords.any((searchWord) =>
              nameWords.any((nameWord) => nameWord.contains(searchWord)) ||
              vehicleName.contains(searchWord));
        }).toList();

        debugPrint('After name filter: ${filteredVehicles.length} vehicles');
      }

      // ✅ FIX: Improved brand search
      if (brandSearch.isNotEmpty) {
        debugPrint('🔍 Filtering by brand: "$brandSearch"');
        filteredVehicles = filteredVehicles.where((vehicle) {
          final vehicleBrand = vehicle.brand.toLowerCase();
          // Check if search term matches brand name
          return vehicleBrand.contains(brandSearch) ||
              brandSearch.contains(vehicleBrand);
        }).toList();

        debugPrint('After brand filter: ${filteredVehicles.length} vehicles');
      }

      // Apply other filters
      filteredVehicles = _applyClientSideFiltering(filteredVehicles, filters);

      debugPrint('Final filtered vehicles count: ${filteredVehicles.length}');

      if (filteredVehicles.isEmpty &&
          (nameSearch.isNotEmpty || brandSearch.isNotEmpty)) {
        // Provide helpful feedback for text searches
        final searchTerms =
            [nameSearch, brandSearch].where((s) => s.isNotEmpty).join(' and ');
        throw NoMatchingVehiclesException(
            'No vehicles found matching "$searchTerms". Try different search terms or check spelling.');
      }

      return filteredVehicles;
    } catch (e) {
      debugPrint('Error in _getFilteredVehicles: $e');
      rethrow;
    }
  }

  // ✅ ENHANCED: Create sample vehicles for testing text search
  List<Vehicle> _createSampleVehicles() {
    return [
      // Toyota vehicles
      Vehicle(
          id: 'sample1',
          name: 'Toyota Camry',
          brand: 'Toyota',
          price: 28000,
          type: 'Sedan',
          mileage: 32,
          fuelType: 'Gasoline',
          score: 0.88,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'FWD',
          year: 2024),
      Vehicle(
          id: 'sample2',
          name: 'Toyota Corolla',
          brand: 'Toyota',
          price: 23000,
          type: 'Sedan',
          mileage: 35,
          fuelType: 'Gasoline',
          score: 0.85,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'FWD',
          year: 2024),
      Vehicle(
          id: 'sample3',
          name: 'Toyota RAV4',
          brand: 'Toyota',
          price: 32000,
          type: 'SUV',
          mileage: 30,
          fuelType: 'Gasoline',
          score: 0.87,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),
      Vehicle(
          id: 'sample4',
          name: 'Toyota Prius',
          brand: 'Toyota',
          price: 27000,
          type: 'Hatchback',
          mileage: 50,
          fuelType: 'Hybrid',
          score: 0.90,
          imageUrl: '',
          bodyType: 'Hatchback',
          driveTrain: 'FWD',
          year: 2024),

      // Honda vehicles
      Vehicle(
          id: 'sample5',
          name: 'Honda Accord',
          brand: 'Honda',
          price: 26000,
          type: 'Sedan',
          mileage: 33,
          fuelType: 'Gasoline',
          score: 0.86,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'FWD',
          year: 2024),
      Vehicle(
          id: 'sample6',
          name: 'Honda Civic',
          brand: 'Honda',
          price: 24000,
          type: 'Sedan',
          mileage: 36,
          fuelType: 'Gasoline',
          score: 0.84,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'FWD',
          year: 2024),
      Vehicle(
          id: 'sample7',
          name: 'Honda CR-V',
          brand: 'Honda',
          price: 31000,
          type: 'SUV',
          mileage: 29,
          fuelType: 'Gasoline',
          score: 0.85,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),
      Vehicle(
          id: 'sample8',
          name: 'Honda Pilot',
          brand: 'Honda',
          price: 38000,
          type: 'SUV',
          mileage: 25,
          fuelType: 'Gasoline',
          score: 0.83,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),

      // Tesla vehicles
      Vehicle(
          id: 'sample9',
          name: 'Tesla Model 3',
          brand: 'Tesla',
          price: 45000,
          type: 'Sedan',
          mileage: 120,
          fuelType: 'Electric',
          score: 0.95,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'RWD',
          year: 2024),
      Vehicle(
          id: 'sample10',
          name: 'Tesla Model Y',
          brand: 'Tesla',
          price: 52000,
          type: 'SUV',
          mileage: 115,
          fuelType: 'Electric',
          score: 0.93,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),
      Vehicle(
          id: 'sample11',
          name: 'Tesla Model S',
          brand: 'Tesla',
          price: 75000,
          type: 'Sedan',
          mileage: 110,
          fuelType: 'Electric',
          score: 0.97,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'AWD',
          year: 2024),

      // Ford vehicles
      Vehicle(
          id: 'sample12',
          name: 'Ford F-150',
          brand: 'Ford',
          price: 35000,
          type: 'Pickup Truck',
          mileage: 22,
          fuelType: 'Gasoline',
          score: 0.80,
          imageUrl: '',
          bodyType: 'Pickup Truck',
          driveTrain: '4WD',
          year: 2024),
      Vehicle(
          id: 'sample13',
          name: 'Ford Mustang',
          brand: 'Ford',
          price: 37000,
          type: 'Coupe',
          mileage: 24,
          fuelType: 'Gasoline',
          score: 0.79,
          imageUrl: '',
          bodyType: 'Coupe',
          driveTrain: 'RWD',
          year: 2024),
      Vehicle(
          id: 'sample14',
          name: 'Ford Explorer',
          brand: 'Ford',
          price: 33000,
          type: 'SUV',
          mileage: 26,
          fuelType: 'Gasoline',
          score: 0.78,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),
      Vehicle(
          id: 'sample15',
          name: 'Ford Escape',
          brand: 'Ford',
          price: 28000,
          type: 'SUV',
          mileage: 31,
          fuelType: 'Gasoline',
          score: 0.81,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'FWD',
          year: 2024),

      // BMW vehicles
      Vehicle(
          id: 'sample16',
          name: 'BMW 3 Series',
          brand: 'BMW',
          price: 42000,
          type: 'Sedan',
          mileage: 28,
          fuelType: 'Gasoline',
          score: 0.85,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'RWD',
          year: 2024),
      Vehicle(
          id: 'sample17',
          name: 'BMW X3',
          brand: 'BMW',
          price: 48000,
          type: 'SUV',
          mileage: 26,
          fuelType: 'Gasoline',
          score: 0.82,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),
      Vehicle(
          id: 'sample18',
          name: 'BMW X5',
          brand: 'BMW',
          price: 62000,
          type: 'SUV',
          mileage: 24,
          fuelType: 'Gasoline',
          score: 0.84,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),

      // Chevrolet vehicles
      Vehicle(
          id: 'sample19',
          name: 'Chevrolet Malibu',
          brand: 'Chevrolet',
          price: 25000,
          type: 'Sedan',
          mileage: 30,
          fuelType: 'Gasoline',
          score: 0.77,
          imageUrl: '',
          bodyType: 'Sedan',
          driveTrain: 'FWD',
          year: 2024),
      Vehicle(
          id: 'sample20',
          name: 'Chevrolet Equinox',
          brand: 'Chevrolet',
          price: 28000,
          type: 'SUV',
          mileage: 28,
          fuelType: 'Gasoline',
          score: 0.76,
          imageUrl: '',
          bodyType: 'SUV',
          driveTrain: 'AWD',
          year: 2024),
    ];
  }

  // ✅ NEW: Apply additional client-side filtering to API results
  List<Vehicle> _applyClientSideFiltering(
      List<Vehicle> vehicles, Map<String, dynamic> preferences) {
    try {
      List<Vehicle> filtered = vehicles.where((vehicle) {
        // Text search for name
        if (preferences['nameSearch'] != null &&
            preferences['nameSearch'].toString().isNotEmpty) {
          final searchTerm = preferences['nameSearch'].toString().toLowerCase();
          if (!vehicle.name.toLowerCase().contains(searchTerm)) {
            return false;
          }
        }

        // Text search for brand
        if (preferences['brandSearch'] != null &&
            preferences['brandSearch'].toString().isNotEmpty) {
          final searchTerm =
              preferences['brandSearch'].toString().toLowerCase();
          if (!vehicle.brand.toLowerCase().contains(searchTerm)) {
            return false;
          }
        }

        // Excluded brands
        if (preferences['excludedBrands'] != null) {
          final excludedBrands = preferences['excludedBrands'] as List<String>;
          if (excludedBrands.contains(vehicle.brand)) {
            return false;
          }
        }

        // Fuel efficient only
        if (preferences['fuelEfficientOnly'] == true && vehicle.mileage < 30) {
          return false;
        }

        // Year range
        if (preferences['minYear'] != null &&
            vehicle.year != null &&
            vehicle.year! < preferences['minYear']) {
          return false;
        }
        if (preferences['maxYear'] != null &&
            vehicle.year != null &&
            vehicle.year! > preferences['maxYear']) {
          return false;
        }

        return true;
      }).toList();

      // Apply sorting if specified
      if (preferences['sortBy'] != null) {
        switch (preferences['sortBy']) {
          case 'price_low_to_high':
            filtered.sort((a, b) => a.price.compareTo(b.price));
            break;
          case 'price_high_to_low':
            filtered.sort((a, b) => b.price.compareTo(a.price));
            break;
          case 'mileage_best':
            filtered.sort((a, b) => b.mileage.compareTo(a.mileage));
            break;
          case 'newest_first':
            filtered.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
            break;
          case 'name_a_to_z':
            filtered.sort((a, b) => a.name.compareTo(b.name));
            break;
          case 'brand_a_to_z':
            filtered.sort((a, b) => a.brand.compareTo(b.brand));
            break;
          default: // relevance
            filtered.sort((a, b) => b.score.compareTo(a.score));
        }
      }

      return filtered;
    } catch (e) {
      debugPrint('Error in client-side filtering: $e');
      return vehicles;
    }
  }

  // ✅ ENHANCED: Better error handling for getVehicles method
  Future<List<Vehicle>> getVehicles() async {
    try {
      debugPrint('=== Getting All Vehicles ===');
      debugPrint('Base URL: $baseUrl');

      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('Vehicles response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<dynamic> vehiclesData;

        if (responseData is Map<String, dynamic>) {
          vehiclesData = responseData['vehicles'] ?? responseData['data'] ?? [];
        } else if (responseData is List) {
          vehiclesData = responseData;
        } else {
          debugPrint('Unexpected response format: $responseData');
          throw Exception('Invalid response format from server');
        }

        debugPrint('Found ${vehiclesData.length} vehicles');

        // ✅ FIX: Better error handling for vehicle parsing
        final vehicles = <Vehicle>[];
        for (final vehicleJson in vehiclesData) {
          try {
            vehicles.add(Vehicle.fromJson(vehicleJson));
          } catch (e) {
            debugPrint('⚠️ Warning: Could not parse vehicle: $e');
            // Continue parsing other vehicles
          }
        }

        if (vehicles.isEmpty && vehiclesData.isNotEmpty) {
          throw Exception('Could not parse any vehicles from response');
        }

        return vehicles;
      } else if (response.statusCode == 404) {
        throw Exception(
            'Vehicle service not available. Please try again later.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        debugPrint('Error response: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to load vehicles (Error ${response.statusCode})');
      }
    } on TimeoutException {
      debugPrint('❌ Request timeout');
      throw Exception(
          'Request timed out. Please check your internet connection.');
    } on FormatException catch (e) {
      debugPrint('❌ JSON parsing error: $e');
      throw Exception('Invalid data format received from server');
    } catch (e) {
      debugPrint('❌ Error in getVehicles: $e');

      // ✅ FIX: Provide more specific error messages
      if (e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        throw Exception(
            'No internet connection. Please check your network settings.');
      } else if (e.toString().contains('Connection refused')) {
        throw Exception('Unable to connect to server. Please try again later.');
      } else {
        rethrow;
      }
    }
  }

  Future<void> addToWishlist(String vehicleId, String token) async {
    try {
      debugPrint('Adding vehicle $vehicleId to wishlist');

      final response = await http.post(
        Uri.parse('$baseUrl/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'vehicle_id': vehicleId}),
      );

      debugPrint('Add to wishlist response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add to wishlist');
      }
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String vehicleId, String token) async {
    try {
      debugPrint('Removing vehicle $vehicleId from wishlist');

      final response = await http.delete(
        Uri.parse('$baseUrl/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'vehicle_id': vehicleId}),
      );

      debugPrint('Remove from wishlist response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to remove from wishlist');
      }
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      rethrow;
    }
  }

  Future<List<Vehicle>> getWishlist(String token) async {
    try {
      debugPrint('Fetching user wishlist');

      final response = await http.get(
        Uri.parse('$baseUrl/wishlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Wishlist response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> vehiclesData = data['wishlist'] ?? [];
        return vehiclesData.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        debugPrint('Failed to get wishlist: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting wishlist: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> registerUser(
      String email, String password) async {
    try {
      debugPrint('Registering user: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Registration response: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error']};
      }
    } catch (e) {
      debugPrint('Error in registerUser: $e');
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      debugPrint('Logging in user: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Login response: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['access_token'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'error': data['error']};
      }
    } catch (e) {
      debugPrint('Error in loginUser: $e');
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }
}

class NoMatchingVehiclesException implements Exception {
  final String message;
  NoMatchingVehiclesException(this.message);

  @override
  String toString() => message;
}
