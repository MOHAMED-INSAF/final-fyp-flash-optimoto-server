import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class VehicleProvider extends ChangeNotifier {
  final VehicleService _vehicleService = VehicleService();

  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  List<Vehicle> _wishlistVehicles = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _lastFilters = {};

  // Getters
  List<Vehicle> get vehicles => _vehicles;
  List<Vehicle> get filteredVehicles => _filteredVehicles;
  List<Vehicle> get wishlistVehicles => _wishlistVehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get lastFilters => _lastFilters;

  // Load all vehicles
  Future<void> loadVehicles() async {
    try {
      _setLoading(true);
      _clearError();

      final vehicles = await _vehicleService.getVehicles();
      _vehicles = vehicles;
      _filteredVehicles = vehicles;

      debugPrint('✅ Loaded ${vehicles.length} vehicles');
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error loading vehicles: $e');
      _setError('Failed to load vehicles: $e');
      _setLoading(false);
    }
  }

  // Search vehicles with recommendations
  Future<void> searchVehicles(Map<String, dynamic> filters) async {
    try {
      _setLoading(true);
      _clearError();
      _lastFilters = Map.from(filters);

      final vehicles = await _vehicleService.getRecommendations(filters);
      _filteredVehicles = vehicles;

      debugPrint('✅ Found ${vehicles.length} vehicles matching filters');
      _setLoading(false);
    } catch (e) {
      debugPrint('❌ Error searching vehicles: $e');
      _setError('Search failed: $e');
      _setLoading(false);
    }
  }

  // Filter local vehicles
  void filterVehicles(Map<String, dynamic> filters) {
    try {
      _lastFilters = Map.from(filters);

      List<Vehicle> filtered = List.from(_vehicles);

      // Apply filters
      if (filters['minPrice'] != null && filters['maxPrice'] != null) {
        filtered = filtered
            .where((v) =>
                v.price >= filters['minPrice'] &&
                v.price <= filters['maxPrice'])
            .toList();
      }

      if (filters['fuelType'] != null && filters['fuelType'] != 'All') {
        filtered = filtered
            .where((v) =>
                v.fuelType.toLowerCase() ==
                filters['fuelType'].toString().toLowerCase())
            .toList();
      }

      if (filters['bodyType'] != null && filters['bodyType'] != 'All') {
        filtered = filtered
            .where((v) =>
                v.bodyType?.toLowerCase() ==
                filters['bodyType'].toString().toLowerCase())
            .toList();
      }

      if (filters['nameSearch'] != null &&
          filters['nameSearch'].toString().isNotEmpty) {
        final query = filters['nameSearch'].toString().toLowerCase();
        filtered = filtered
            .where((v) =>
                v.name.toLowerCase().contains(query) ||
                v.brand.toLowerCase().contains(query))
            .toList();
      }

      _filteredVehicles = filtered;
      debugPrint('✅ Filtered to ${filtered.length} vehicles');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error filtering vehicles: $e');
      _setError('Filter failed: $e');
    }
  }

  // Clear filters
  void clearFilters() {
    _filteredVehicles = List.from(_vehicles);
    _lastFilters.clear();
    _clearError();
    notifyListeners();
  }

  // Get vehicle by ID
  Vehicle? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadVehicles();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
