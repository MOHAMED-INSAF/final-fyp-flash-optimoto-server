import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../services/user_activity_service.dart';

class CompareVehiclesPage extends StatefulWidget {
  const CompareVehiclesPage({super.key});

  @override
  State<CompareVehiclesPage> createState() => _CompareVehiclesPageState();
}

class _CompareVehiclesPageState extends State<CompareVehiclesPage> {
  Vehicle? _vehicle1;
  Vehicle? _vehicle2;
  List<Vehicle> _availableVehicles = [];
  bool _isLoading = true;
  String? _errorMessage;
  final VehicleService _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔄 Loading vehicles for comparison...');

      final vehicles = await _vehicleService.getVehicles().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection.');
        },
      );

      if (vehicles.isEmpty) {
        throw Exception('No vehicles available for comparison');
      }

      setState(() {
        _availableVehicles = vehicles;
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${vehicles.length} vehicles for comparison');
    } catch (e) {
      debugPrint('❌ Error loading vehicles for comparison: $e');

      try {
        final fallbackVehicles = _createSampleVehicles();
        setState(() {
          _availableVehicles = fallbackVehicles;
          _isLoading = false;
          _errorMessage = 'Using offline data. Check your internet connection.';
        });
        debugPrint('🔄 Using fallback sample vehicles');
      } catch (fallbackError) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load vehicles: ${e.toString()}';
        });
      }
    }
  }

  List<Vehicle> _createSampleVehicles() {
    return [
      Vehicle(
        id: 'sample1',
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
        year: 2024,
      ),
      Vehicle(
        id: 'sample2',
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
        year: 2024,
      ),
      Vehicle(
        id: 'sample3',
        name: 'Honda CR-V',
        brand: 'Honda',
        price: 32000,
        type: 'SUV',
        mileage: 30,
        fuelType: 'Gasoline',
        score: 0.85,
        imageUrl: '',
        bodyType: 'SUV',
        driveTrain: 'AWD',
        year: 2024,
      ),
      Vehicle(
        id: 'sample4',
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
        year: 2024,
      ),
      Vehicle(
        id: 'sample5',
        name: 'Ford Mustang',
        brand: 'Ford',
        price: 35000,
        type: 'Coupe',
        mileage: 24,
        fuelType: 'Gasoline',
        score: 0.79,
        imageUrl: '',
        bodyType: 'Coupe',
        driveTrain: 'RWD',
        year: 2024,
      ),
    ];
  }

  Future<void> _refreshData() async {
    debugPrint('🔄 Refreshing vehicle data...');
    await _loadVehicles();
  }

  void _clearComparison() {
    setState(() {
      _vehicle1 = null;
      _vehicle2 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compare Vehicles',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_vehicle1 != null || _vehicle2 != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearComparison,
              tooltip: 'Clear Selection',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _errorMessage!.contains('offline')
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _errorMessage!.contains('offline')
                      ? Colors.orange.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _errorMessage!.contains('offline')
                        ? Icons.wifi_off
                        : Icons.error_outline,
                    color: _errorMessage!.contains('offline')
                        ? Colors.orange.shade600
                        : Colors.red.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: _errorMessage!.contains('offline')
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _refreshData,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        color: _errorMessage!.contains('offline')
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight.withOpacity(0.1),
                  AppTheme.primaryDark.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Select Two Vehicles to Compare',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildVehicleSelector(
                        'Choose First Vehicle',
                        _vehicle1,
                        (vehicle) => setState(() => _vehicle1 = vehicle),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.compare_arrows,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildVehicleSelector(
                        'Choose Second Vehicle',
                        _vehicle2,
                        (vehicle) => setState(() => _vehicle2 = vehicle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _vehicle1 != null && _vehicle2 != null
                    ? _buildComparison()
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Loading vehicles for comparison...',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    _trackComparison();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildVehicleCard(_vehicle1!)),
              const SizedBox(width: 16),
              Expanded(child: _buildVehicleCard(_vehicle2!)),
            ],
          ),
          const SizedBox(height: 24),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Future<void> _trackComparison() async {
    if (_vehicle1 != null && _vehicle2 != null) {
      try {
        await UserActivityService.addComparisonRecord(
            _vehicle1!.id, _vehicle2!.id);
        debugPrint(
            'Tracked comparison: ${_vehicle1!.name} vs ${_vehicle2!.name}');
      } catch (e) {
        debugPrint('Error tracking comparison: $e');
      }
    }
  }

  Widget _buildVehicleSelector(
    String hint,
    Vehicle? selectedVehicle,
    Function(Vehicle) onSelect,
  ) {
    return GestureDetector(
      onTap: () => _showVehicleSelectionDialog((vehicle) {
        onSelect(vehicle);
        if (_vehicle1 != null && _vehicle2 != null) {
          _trackComparison();
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedVehicle != null
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedVehicle != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: selectedVehicle.imageUrl.isNotEmpty
                    ? Image.network(
                        selectedVehicle.imageUrl,
                        height: 50,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedVehicle.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '\$${selectedVehicle.price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ] else ...[
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: vehicle.imageUrl.isNotEmpty
                ? Image.network(
                    vehicle.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.directions_car, size: 48),
                      );
                    },
                  )
                : Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.directions_car, size: 48),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${vehicle.price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final comparisons = [
      ComparisonRow('Brand', _vehicle1!.brand, _vehicle2!.brand),
      ComparisonRow('Type', _vehicle1!.type, _vehicle2!.type),
      ComparisonRow('Body Type', _vehicle1!.bodyType ?? 'N/A',
          _vehicle2!.bodyType ?? 'N/A'),
      ComparisonRow('Drive Train', _vehicle1!.driveTrain ?? 'N/A',
          _vehicle2!.driveTrain ?? 'N/A'),
      ComparisonRow('Fuel Type', _vehicle1!.fuelType, _vehicle2!.fuelType),
      ComparisonRow(
        'Mileage',
        '${_vehicle1!.mileage} ${_vehicle1!.fuelType == 'Electric' ? 'miles' : 'mpg'}',
        '${_vehicle2!.mileage} ${_vehicle2!.fuelType == 'Electric' ? 'miles' : 'mpg'}',
      ),
      ComparisonRow(
        'Price',
        '\$${_vehicle1!.price.toStringAsFixed(0)}',
        '\$${_vehicle2!.price.toStringAsFixed(0)}',
      ),
      if (_vehicle1!.year != null && _vehicle2!.year != null)
        ComparisonRow(
          'Year',
          _vehicle1!.year.toString(),
          _vehicle2!.year.toString(),
        ),
      if (_vehicle1!.score > 0 && _vehicle2!.score > 0)
        ComparisonRow(
          'Score',
          '${(_vehicle1!.score * 100).toStringAsFixed(0)}%',
          '${(_vehicle2!.score * 100).toStringAsFixed(0)}%',
        ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Comparison',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...comparisons.map((row) => _buildComparisonRow(row)),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(ComparisonRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              row.label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value1,
              style: GoogleFonts.inter(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value2,
              style: GoogleFonts.inter(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select two vehicles to compare',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap on the selection boxes above to choose vehicles',
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_availableVehicles.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Load Vehicles'),
            ),
          ],
        ],
      ),
    );
  }

  void _showVehicleSelectionDialog(Function(Vehicle) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Text(
                'Select a Vehicle',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _availableVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Loading vehicles...',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _availableVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _availableVehicles[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions_car,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              vehicle.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '\$${vehicle.price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              onSelect(vehicle);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ComparisonRow {
  final String label;
  final String value1;
  final String value2;

  ComparisonRow(this.label, this.value1, this.value2);
}
