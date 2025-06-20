import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/vehicle_service.dart';
import '../services/wishlist_service.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_details_page.dart';
import '../theme/app_theme.dart';

class FindVehiclePage extends StatefulWidget {
  const FindVehiclePage({super.key});

  @override
  State<FindVehiclePage> createState() => _FindVehiclePageState();
}

class _FindVehiclePageState extends State<FindVehiclePage> {
  final VehicleService _vehicleService = VehicleService();
  RangeValues _priceRangeValues = const RangeValues(0, 100000);
  RangeValues _mileageRangeValues = const RangeValues(0, 50);
  String? _selectedFuelType;
  String? _selectedBodyType;
  String? _selectedDriveTrain;
  int _numberOfVehicles = 5;
  String _selectedPurpose = 'Urban';
  bool _isLoading = false;
  List<Vehicle> _recommendations = [];
  String? _errorMessage;
  bool _hasSearched = false;

  final List<String> _purposes = ['Urban', 'Touring', 'Racing'];
  final List<String> _fuelTypes = [
    'All',
    'Gasoline',
    'Diesel',
    'Electric',
    'Hybrid',
    'Plug-in Hybrid'
  ];

  final List<String> _bodyTypes = [
    'All',
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Convertible',
    'Wagon',
    'Van',
    'Pickup Truck',
  ];

  final List<String> _driveTrains = [
    'All',
    'FWD (Front-Wheel Drive)',
    'RWD (Rear-Wheel Drive)',
    'AWD (All-Wheel Drive)',
    '4WD (Four-Wheel Drive)',
  ];

  final _formKey = GlobalKey<FormState>();
  String? _priceError;
  String? _mileageError;
  String? _purposeError;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      debugPrint('Testing connection to backend...');
      final vehicles = await _vehicleService.getVehicles();
      debugPrint(
          'Connection test successful: ${vehicles.length} vehicles found');
    } catch (e) {
      debugPrint('Connection test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backend connection failed: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _priceError = null;
      _mileageError = null;
      _purposeError = null;

      if (_priceRangeValues.start >= _priceRangeValues.end) {
        _priceError = 'Minimum price must be less than maximum price';
        isValid = false;
      }

      if (_mileageRangeValues.start >= _mileageRangeValues.end) {
        _mileageError = 'Minimum mileage must be less than maximum mileage';
        isValid = false;
      }

      if (_selectedPurpose.isEmpty) {
        _purposeError = 'Please select a purpose';
        isValid = false;
      }
    });
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Find Perfect Vehicle',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryDark,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_car,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Purpose'),
                      const SizedBox(height: 16),
                      Row(
                        children: _purposes
                            .map((purpose) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: ChoiceChip(
                                      label: Text(purpose),
                                      selected: _selectedPurpose == purpose,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedPurpose = purpose;
                                          _purposeError = null;
                                        });
                                      },
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      if (_purposeError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _purposeError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Price Range'),
                      _buildRangeSlider(
                        values: _priceRangeValues,
                        min: 0,
                        max: 100000,
                        divisions: 20,
                        prefix: '\$',
                        onChanged: (values) {
                          setState(() {
                            _priceRangeValues = values;
                            _priceError = null;
                          });
                        },
                      ),
                      if (_priceError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _priceError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Mileage (MPG)'),
                      _buildRangeSlider(
                        values: _mileageRangeValues,
                        min: 0,
                        max: 50,
                        divisions: 10,
                        onChanged: (values) {
                          setState(() {
                            _mileageRangeValues = values;
                            _mileageError = null;
                          });
                        },
                      ),
                      if (_mileageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _mileageError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Fuel Type'),
                      DropdownButtonFormField<String>(
                        value: _selectedFuelType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        hint: const Text('Select Fuel Type'),
                        items: _fuelTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedFuelType = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Body Type'),
                      DropdownButtonFormField<String>(
                        value: _selectedBodyType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        hint: const Text('Select Body Type'),
                        items: _bodyTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedBodyType = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Drive Train'),
                      DropdownButtonFormField<String>(
                        value: _selectedDriveTrain,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        hint: const Text('Select Drive Train'),
                        items: _driveTrains
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDriveTrain = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Number of Results'),
                      Slider(
                        value: _numberOfVehicles.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: _numberOfVehicles.toString(),
                        onChanged: (value) {
                          setState(() => _numberOfVehicles = value.round());
                        },
                      ),
                      Text(
                        'Show $_numberOfVehicles vehicles',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _getRecommendations,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Find Vehicles',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      if (_hasSearched && _recommendations.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Found ${_recommendations.length} vehicles',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._recommendations.map(
                            (vehicle) => _buildVehicleCard(context, vehicle)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRangeSlider({
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
    String prefix = '',
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RangeSlider(
              values: values,
              min: min,
              max: max,
              divisions: divisions,
              labels: RangeLabels(
                '$prefix${values.start.round()}',
                '$prefix${values.end.round()}',
              ),
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$prefix${values.start.round()}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '$prefix${values.end.round()}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getRecommendations() async {
    if (!_validateInputs()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('=== Starting Vehicle Search ===');

      final preferences = {
        'minPrice': _priceRangeValues.start,
        'maxPrice': _priceRangeValues.end,
        'minMileage': _mileageRangeValues.start,
        'maxMileage': _mileageRangeValues.end,
        'purpose': _selectedPurpose,
        'fuelType': _selectedFuelType == 'All' ? null : _selectedFuelType,
        'bodyType': _selectedBodyType == 'All' ? null : _selectedBodyType,
        'driveTrain': _selectedDriveTrain == 'All' ? null : _selectedDriveTrain,
      };

      debugPrint('Search preferences: $preferences');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Searching for vehicles...'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      final vehicles = await _vehicleService.getRecommendations(preferences);

      debugPrint('Search completed: ${vehicles.length} vehicles found');

      if (mounted) {
        String message;
        if (vehicles.isNotEmpty) {
          message = 'Found ${vehicles.length} vehicles matching your criteria';
        } else {
          message = 'No vehicles found';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: vehicles.isNotEmpty ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
            action: vehicles.isNotEmpty
                ? SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      Scrollable.ensureVisible(
                        context,
                        duration: const Duration(milliseconds: 500),
                      );
                    },
                  )
                : null,
          ),
        );

        setState(() {
          _recommendations = vehicles;
          _isLoading = false;
          _hasSearched = true;
        });

        if (vehicles.isEmpty) {
          setState(() {
            _errorMessage =
                'No vehicles found matching your criteria. Try adjusting your filters.';
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to find vehicles. Please try again.';
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Search failed. Please check your connection and try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _getRecommendations,
            ),
          ),
        );
      }
    }
  }

  Widget _buildVehicleCard(BuildContext context, Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showVehicleDetails(context, vehicle),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryLight.withOpacity(0.8),
                    AppTheme.primaryDark.withOpacity(0.9),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${(vehicle.score * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: FutureBuilder<bool>(
                      future: WishlistService.isInWishlist(vehicle.id),
                      builder: (context, snapshot) {
                        final isInWishlist = snapshot.data ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              try {
                                if (isInWishlist) {
                                  await WishlistService.removeFromWishlist(
                                      vehicle.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Removed from wishlist'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                } else {
                                  await WishlistService.addToWishlist(vehicle);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to wishlist!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                                setState(() {});
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInWishlist
                                  ? AppTheme.error
                                  : AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              vehicle.brand,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${vehicle.price.toStringAsFixed(0)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSpecChip(Icons.local_gas_station, vehicle.fuelType),
                      const SizedBox(width: 8),
                      _buildSpecChip(Icons.speed, '${vehicle.mileage} MPG'),
                      const SizedBox(width: 8),
                      _buildSpecChip(Icons.category, vehicle.type),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleDetailsPage(vehicle: vehicle),
        ),
      );
    }
  }
}
