import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/vehicle_service.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import 'vehicle_details_page.dart';

class AdvancedFilterPage extends StatefulWidget {
  const AdvancedFilterPage({super.key});

  @override
  State<AdvancedFilterPage> createState() => _AdvancedFilterPageState();
}

class _AdvancedFilterPageState extends State<AdvancedFilterPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final VehicleService _vehicleService = VehicleService();

  // Text search controllers
  final TextEditingController _nameSearchController = TextEditingController();
  final TextEditingController _brandSearchController = TextEditingController();

  // Enhanced filters for your existing API
  RangeValues _priceRange = const RangeValues(0, 100000);
  RangeValues _mileageRange = const RangeValues(0, 50);
  String? _selectedFuelType;
  String? _selectedBodyType;
  String? _selectedDriveTrain;
  String _selectedPurpose = 'Urban';
  String? _selectedBrand;

  // Advanced search options
  RangeValues _yearRange = const RangeValues(2015, 2024);
  String _sortBy = 'relevance';
  final Set<String> _excludedBrands = {};
  double _maxBudget = 100000;
  bool _fuelEfficientOnly = false;
  bool _safetyRatedOnly = false;

  // Results
  bool _isLoading = false;
  List<Vehicle> _results = [];
  bool _hasSearched = false;

  // Enhanced filter options
  final List<String> _sortOptions = [
    'relevance',
    'price_low_to_high',
    'price_high_to_low',
    'mileage_best',
    'newest_first',
    'name_a_to_z',
    'brand_a_to_z'
  ];

  // Filter options (these match your existing Flask API)
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
  final List<String> _brands = [
    'All',
    'Toyota',
    'Honda',
    'Ford',
    'Chevrolet',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Hyundai',
    'Kia',
    'Mazda',
    'Subaru'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _nameSearchController.dispose();
    _brandSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Advanced Vehicle Search',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.tune), text: 'Filters'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'Smart'),
            Tab(icon: Icon(Icons.list), text: 'Results'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _saveCurrentSearch,
            tooltip: 'Save Search',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildFiltersTab(),
                _buildSmartFiltersTab(),
                _buildResultsTab(),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    int activeFilters = _countActiveFilters();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '$activeFilters filters active',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          if (_results.isNotEmpty)
            Text(
              '${_results.length} vehicles found',
              style: GoogleFonts.inter(
                color: AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔍 Search by Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameSearchController,
            decoration: InputDecoration(
              hintText:
                  'Search vehicle name (e.g., "Camry", "Model 3", "F-150")',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _nameSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _nameSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('🏭 Search by Brand'),
          const SizedBox(height: 8),
          TextField(
            controller: _brandSearchController,
            decoration: InputDecoration(
              hintText: 'Search brand name (e.g., "Toyota", "Tesla", "BMW")',
              prefixIcon: const Icon(Icons.business),
              suffixIcon: _brandSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _brandSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('🎯 Purpose & Use Case'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _purposes.map((purpose) {
              final icons = {
                'Urban': Icons.location_city,
                'Touring': Icons.route,
                'Racing': Icons.sports_motorsports,
              };
              return ChoiceChip(
                avatar: Icon(icons[purpose], size: 16),
                label: Text(purpose),
                selected: _selectedPurpose == purpose,
                onSelected: (selected) {
                  setState(() => _selectedPurpose = purpose);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('💰 Budget Range'),
          _buildBudgetSlider(),
          const SizedBox(height: 24),
          _buildSectionTitle('⚡ Quick Search Suggestions'),
          _buildQuickSearchCards(),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('💰 Price Range'),
          _buildRangeSlider(
            'Price',
            _priceRange,
            0,
            100000,
            (values) => setState(() => _priceRange = values),
            prefix: '\$',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('⛽ Fuel Economy (MPG)'),
          _buildRangeSlider(
            'MPG',
            _mileageRange,
            0,
            50,
            (values) => setState(() => _mileageRange = values),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('📅 Model Year'),
          _buildRangeSlider(
            'Year',
            _yearRange,
            2015,
            2024,
            (values) => setState(() => _yearRange = values),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('🏭 Brand'),
          _buildDropdown(
            'Select Brand',
            _selectedBrand,
            _brands,
            (value) => setState(() => _selectedBrand = value),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('⛽ Fuel Type'),
          _buildDropdown(
            'Select Fuel Type',
            _selectedFuelType,
            _fuelTypes,
            (value) => setState(() => _selectedFuelType = value),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('🚗 Body Type'),
          _buildDropdown(
            'Select Body Type',
            _selectedBodyType,
            _bodyTypes,
            (value) => setState(() => _selectedBodyType = value),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('🔄 Drive Train'),
          _buildDropdown(
            'Select Drive Train',
            _selectedDriveTrain,
            _driveTrains,
            (value) => setState(() => _selectedDriveTrain = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartFiltersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🧠 Smart Recommendations'),
          const SizedBox(height: 8),
          _buildPersonalizedSuggestions(),
          const SizedBox(height: 24),
          _buildSectionTitle('🎯 One-Click Filters'),
          _buildQuickFilterGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('⚙️ Advanced Options'),
          _buildAdvancedToggleOptions(),
          const SizedBox(height: 24),
          _buildSectionTitle('📊 Sort Results By'),
          _buildSortOptions(),
          const SizedBox(height: 24),
          _buildSectionTitle('🚫 Exclude Brands'),
          _buildExcludeBrandsSection(),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No search performed yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your filters and tap "Search Vehicles"',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No vehicles found',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildVehicleCard(_results[index]);
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildRangeSlider(
    String label,
    RangeValues values,
    double min,
    double max,
    Function(RangeValues) onChanged, {
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
              divisions: 20,
              labels: RangeLabels(
                '$prefix${values.start.round()}',
                '$prefix${values.end.round()}',
              ),
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$prefix${values.start.round()}'),
                Text('$prefix${values.end.round()}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          decoration: const InputDecoration(border: InputBorder.none),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBudgetSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget: \$${_maxBudget.toInt()}'),
                Text('Monthly: ~\$${(_maxBudget / 60).toInt()}'),
              ],
            ),
            Slider(
              value: _maxBudget,
              min: 5000,
              max: 100000,
              divisions: 19,
              label: '\$${_maxBudget.toInt()}',
              onChanged: (value) {
                setState(() {
                  _maxBudget = value;
                  _priceRange = RangeValues(0, value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchCards() {
    final suggestions = [
      {
        'title': 'Eco-Friendly',
        'subtitle': 'Hybrid & Electric',
        'icon': Icons.eco
      },
      {
        'title': 'Family Car',
        'subtitle': 'SUV & Minivan',
        'icon': Icons.family_restroom
      },
      {'title': 'Luxury', 'subtitle': 'Premium brands', 'icon': Icons.diamond},
      {
        'title': 'Sports',
        'subtitle': 'Performance cars',
        'icon': Icons.sports_motorsports
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => _applyQuickSearch(suggestion['title'] as String),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(suggestion['icon'] as IconData,
                          color: AppTheme.primaryColor, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        suggestion['title'] as String,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        suggestion['subtitle'] as String,
                        style: GoogleFonts.inter(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalizedSuggestions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight.withOpacity(0.1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text('Based on your preferences:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _buildSuggestionChip('Fuel efficient vehicles (30+ MPG)', Icons.eco),
          _buildSuggestionChip(
              'Under \$30,000 budget friendly', Icons.attach_money),
          _buildSuggestionChip(
              'Japanese reliability (Toyota, Honda)', Icons.verified),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _applySuggestion(text),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14))),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterGrid() {
    final quickFilters = [
      {
        'name': 'Best MPG',
        'action': () => _mileageRange = const RangeValues(35, 50)
      },
      {
        'name': 'Under \$25K',
        'action': () => _priceRange = const RangeValues(0, 25000)
      },
      {
        'name': 'Luxury \$50K+',
        'action': () => _priceRange = const RangeValues(50000, 100000)
      },
      {'name': 'Electric Only', 'action': () => _selectedFuelType = 'Electric'},
      {'name': 'SUVs Only', 'action': () => _selectedBodyType = 'SUV'},
      {
        'name': 'New (2023+)',
        'action': () => _yearRange = const RangeValues(2023, 2024)
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: quickFilters.length,
      itemBuilder: (context, index) {
        final filter = quickFilters[index];
        return ActionChip(
          label: Text(filter['name'] as String),
          onPressed: () {
            (filter['action'] as VoidCallback)();
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildAdvancedToggleOptions() {
    return Column(
      children: [
        SwitchListTile(
          title:
              Text('Fuel Efficient Only (30+ MPG)', style: GoogleFonts.inter()),
          subtitle: Text('Show only high-efficiency vehicles',
              style: GoogleFonts.inter(fontSize: 12)),
          value: _fuelEfficientOnly,
          onChanged: (value) => setState(() => _fuelEfficientOnly = value),
        ),
        SwitchListTile(
          title: Text('Safety Rated Only', style: GoogleFonts.inter()),
          subtitle: Text('Show only 4+ star safety rated vehicles',
              style: GoogleFonts.inter(fontSize: 12)),
          value: _safetyRatedOnly,
          onChanged: (value) => setState(() => _safetyRatedOnly = value),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    final sortLabels = {
      'relevance': '🎯 Best Match',
      'price_low_to_high': '💰 Price: Low to High',
      'price_high_to_low': '💎 Price: High to Low',
      'mileage_best': '⛽ Best Fuel Economy',
      'newest_first': '📅 Newest First',
      'name_a_to_z': '🔤 Name A-Z',
      'brand_a_to_z': '🏭 Brand A-Z',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Sort by',
              ),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(sortLabels[option] ?? option),
                );
              }).toList(),
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcludeBrandsSection() {
    return Column(
      children: [
        Text('Tap brands to exclude from results',
            style: GoogleFonts.inter(color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _brands.where((brand) => brand != 'All').map((brand) {
            final isExcluded = _excludedBrands.contains(brand);
            return FilterChip(
              label: Text(brand),
              selected: isExcluded,
              selectedColor: Colors.red.withOpacity(0.2),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _excludedBrands.add(brand);
                  } else {
                    _excludedBrands.remove(brand);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyQuickSearch(String type) {
    setState(() {
      switch (type) {
        case 'Eco-Friendly':
          _selectedFuelType = 'Electric';
          _mileageRange = const RangeValues(30, 50);
          break;
        case 'Family Car':
          _selectedBodyType = 'SUV';
          _selectedPurpose = 'Urban';
          break;
        case 'Luxury':
          _priceRange = const RangeValues(50000, 100000);
          _selectedBrand = 'BMW';
          break;
        case 'Sports':
          _selectedBodyType = 'Coupe';
          _selectedPurpose = 'Racing';
          break;
      }
    });
  }

  void _applySuggestion(String suggestion) {
    setState(() {
      if (suggestion.contains('30+ MPG')) {
        _mileageRange = const RangeValues(30, 50);
        _fuelEfficientOnly = true;
      } else if (suggestion.contains('\$30,000')) {
        _priceRange = const RangeValues(0, 30000);
      } else if (suggestion.contains('Japanese')) {
        _selectedBrand = 'Toyota';
      }
    });
  }

  void _saveCurrentSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search saved! (Feature coming soon)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear All'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchVehicles,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Search Vehicles'),
            ),
          ),
        ],
      ),
    );
  }

  int _countActiveFilters() {
    int count = 0;
    if (_nameSearchController.text.isNotEmpty) count++;
    if (_brandSearchController.text.isNotEmpty) count++;
    if (_priceRange.start > 0 || _priceRange.end < 100000) count++;
    if (_mileageRange.start > 0 || _mileageRange.end < 50) count++;
    if (_yearRange.start > 2015 || _yearRange.end < 2024) count++;
    if (_selectedFuelType != null && _selectedFuelType != 'All') count++;
    if (_selectedBodyType != null && _selectedBodyType != 'All') count++;
    if (_selectedDriveTrain != null && _selectedDriveTrain != 'All') count++;
    if (_selectedBrand != null && _selectedBrand != 'All') count++;
    if (_excludedBrands.isNotEmpty) count++;
    if (_fuelEfficientOnly) count++;
    if (_safetyRatedOnly) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _nameSearchController.clear();
      _brandSearchController.clear();
      _priceRange = const RangeValues(0, 100000);
      _mileageRange = const RangeValues(0, 50);
      _yearRange = const RangeValues(2015, 2024);
      _selectedFuelType = null;
      _selectedBodyType = null;
      _selectedDriveTrain = null;
      _selectedBrand = null;
      _selectedPurpose = 'Urban';
      _excludedBrands.clear();
      _fuelEfficientOnly = false;
      _safetyRatedOnly = false;
      _sortBy = 'relevance';
      _maxBudget = 100000;
      _results.clear();
      _hasSearched = false;
    });
  }

  Future<void> _searchVehicles() async {
    setState(() => _isLoading = true);

    try {
      final nameSearch = _nameSearchController.text.trim();
      final brandSearch = _brandSearchController.text.trim();

      final filters = {
        'nameSearch': nameSearch,
        'brandSearch': brandSearch,
        'minPrice': _priceRange.start,
        'maxPrice': _priceRange.end,
        'minMileage': _mileageRange.start,
        'maxMileage': _mileageRange.end,
        'minYear': _yearRange.start.round(),
        'maxYear': _yearRange.end.round(),
        'purpose': _selectedPurpose,
        'fuelType': _selectedFuelType == 'All' ? null : _selectedFuelType,
        'bodyType': _selectedBodyType == 'All' ? null : _selectedBodyType,
        'driveTrain': _selectedDriveTrain == 'All' ? null : _selectedDriveTrain,
        'brand': _selectedBrand == 'All' ? null : _selectedBrand,
        'excludedBrands': _excludedBrands.toList(),
        'fuelEfficientOnly': _fuelEfficientOnly,
        'safetyRatedOnly': _safetyRatedOnly,
        'sortBy': _sortBy,
      };

      debugPrint('=== Advanced Search Starting ===');
      debugPrint('Name Search: "$nameSearch"');
      debugPrint('Brand Search: "$brandSearch"');
      debugPrint('Other Filters: $filters');

      String searchType = 'vehicles';
      if (nameSearch.isNotEmpty && brandSearch.isNotEmpty) {
        searchType = 'vehicles matching "$nameSearch" from "$brandSearch"';
      } else if (nameSearch.isNotEmpty) {
        searchType = 'vehicles matching "$nameSearch"';
      } else if (brandSearch.isNotEmpty) {
        searchType = 'vehicles from "$brandSearch"';
      }

      var results = await _vehicleService.getRecommendations(filters);

      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });

      _tabController.animateTo(3);

      if (mounted) {
        String message;
        if (results.isNotEmpty) {
          message = 'Found ${results.length} $searchType';
        } else {
          message = 'No $searchType found';
          if (nameSearch.isNotEmpty || brandSearch.isNotEmpty) {
            message += '. Try:\n';
            if (nameSearch.isNotEmpty) {
              message += '• Different spelling of "$nameSearch"\n';
              message += '• Shorter search terms\n';
            }
            if (brandSearch.isNotEmpty) {
              message += '• Check brand name spelling\n';
            }
            message += '• Broader search criteria';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: results.isNotEmpty ? Colors.green : Colors.orange,
            duration: Duration(seconds: results.isNotEmpty ? 3 : 5),
            action: results.isNotEmpty
                ? SnackBarAction(
                    label: 'View',
                    onPressed: () => _tabController.animateTo(3),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _isLoading = false;
        _hasSearched = true;
        _results.clear();
      });

      if (mounted) {
        String errorMessage = 'Search failed';

        if (e.toString().contains('NoMatchingVehiclesException')) {
          errorMessage =
              e.toString().replaceAll('NoMatchingVehiclesException: ', '');
        } else {
          errorMessage = 'Search failed: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsPage(vehicle: vehicle),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      vehicle.brand,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_gas_station,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.fuelType,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.speed,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${vehicle.mileage} MPG',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${vehicle.price.toStringAsFixed(0)}',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                      fontSize: 18,
                    ),
                  ),
                  if (vehicle.score > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(vehicle.score * 100).toInt()}% match',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
