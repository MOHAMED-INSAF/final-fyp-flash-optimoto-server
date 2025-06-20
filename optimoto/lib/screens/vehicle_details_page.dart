import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../services/wishlist_service.dart';
import '../services/user_activity_service.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  bool _isInWishlist = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
    _trackView();
  }

  Future<void> _checkWishlistStatus() async {
    final isInWishlist = await WishlistService.isInWishlist(widget.vehicle.id);
    if (mounted) {
      setState(() {
        _isInWishlist = isInWishlist;
      });
    }
  }

  Future<void> _trackView() async {
    await UserActivityService.addToViewHistory(widget.vehicle);
  }

  Future<void> _toggleWishlist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isInWishlist) {
        await WishlistService.removeFromWishlist(widget.vehicle.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from wishlist'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await WishlistService.addToWishlist(widget.vehicle);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to wishlist!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      setState(() {
        _isInWishlist = !_isInWishlist;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Vehicle Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryLight,
                          AppTheme.primaryDark,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 120,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  // Heart button overlay on the image
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : _toggleWishlist,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : Icon(
                                _isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isInWishlist
                                    ? AppTheme.error
                                    : AppTheme.textSecondary,
                                size: 28,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vehicle Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Name and Brand
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              widget.vehicle.brand,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price Tag
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Price',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '\$${widget.vehicle.price.toStringAsFixed(0)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Match Score
                  if (widget.vehicle.score > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Match Score',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '${(widget.vehicle.score * 100).toInt()}% Match with your preferences',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Basic Specifications Section
                  Text(
                    'Basic Information',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSpecCard(
                        icon: Icons.local_gas_station,
                        title: 'Fuel Type',
                        value: widget.vehicle.fuelType,
                      ),
                      _buildSpecCard(
                        icon: Icons.speed,
                        title: 'Mileage',
                        value:
                            '${widget.vehicle.mileage.toStringAsFixed(0)} MPG',
                      ),
                      if (widget.vehicle.bodyType != null)
                        _buildSpecCard(
                          icon: Icons.car_repair,
                          title: 'Body Type',
                          value: widget.vehicle.bodyType!,
                        ),
                      if (widget.vehicle.driveTrain != null)
                        _buildSpecCard(
                          icon: Icons.settings_input_component,
                          title: 'Drive Train',
                          value: widget.vehicle.driveTrain!,
                        ),
                      _buildSpecCard(
                        icon: Icons.category,
                        title: 'Type',
                        value: widget.vehicle.type,
                      ),
                      if (widget.vehicle.year != null)
                        _buildSpecCard(
                          icon: Icons.calendar_today,
                          title: 'Year',
                          value: widget.vehicle.year.toString(),
                        ),
                    ],
                  ),

                  // Engine & Performance
                  const SizedBox(height: 24),
                  Text(
                    'Engine & Performance',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSpecCard(
                        icon: Icons.speed,
                        title: '0-60 mph',
                        value: '5.3 sec',
                      ),
                      _buildSpecCard(
                        icon: Icons.power,
                        title: 'Horsepower',
                        value: '288 hp',
                      ),
                      _buildSpecCard(
                        icon: Icons.architecture,
                        title: 'Engine',
                        value: '2.0L Turbo',
                      ),
                      _buildSpecCard(
                        icon: Icons.sync_alt,
                        title: 'Transmission',
                        value: '8-Speed Auto',
                      ),
                    ],
                  ),

                  // Dimensions & Capacity
                  const SizedBox(height: 24),
                  Text(
                    'Dimensions & Capacity',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSpecCard(
                        icon: Icons.straighten,
                        title: 'Length',
                        value: '185.7 in',
                      ),
                      _buildSpecCard(
                        icon: Icons.height,
                        title: 'Height',
                        value: '56.3 in',
                      ),
                      _buildSpecCard(
                        icon: Icons.airline_seat_recline_normal,
                        title: 'Seating',
                        value: '5 Passengers',
                      ),
                      _buildSpecCard(
                        icon: Icons.luggage,
                        title: 'Cargo',
                        value: '15.1 cu.ft',
                      ),
                    ],
                  ),

                  // Safety & Technology
                  const SizedBox(height: 24),
                  Text(
                    'Safety & Technology',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSpecCard(
                        icon: Icons.security,
                        title: 'Safety Rating',
                        value: '5-Star NCAP',
                      ),
                      _buildSpecCard(
                        icon: Icons.screen_lock_landscape,
                        title: 'Display',
                        value: '12.3" Screen',
                      ),
                      _buildSpecCard(
                        icon: Icons.surround_sound,
                        title: 'Audio',
                        value: 'Premium Sound',
                      ),
                      _buildSpecCard(
                        icon: Icons.mobile_friendly,
                        title: 'Connectivity',
                        value: 'Apple/Android',
                      ),
                    ],
                  ),

                  // Warranty & Service
                  const SizedBox(height: 24),
                  Text(
                    'Warranty & Service',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildWarrantyItem(
                          'Basic Warranty',
                          '4 years / 50,000 miles',
                        ),
                        const Divider(height: 16),
                        _buildWarrantyItem(
                          'Powertrain',
                          '6 years / 70,000 miles',
                        ),
                        const Divider(height: 16),
                        _buildWarrantyItem(
                          'Maintenance',
                          '3 years / 36,000 miles',
                        ),
                        const Divider(height: 16),
                        _buildWarrantyItem(
                          'Roadside Assistance',
                          '4 years / Unlimited',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Additional Features Section
                  Text(
                    'Key Features',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureChip('Advanced Safety'),
                      _buildFeatureChip('Navigation System'),
                      _buildFeatureChip('Bluetooth'),
                      _buildFeatureChip('Backup Camera'),
                      _buildFeatureChip('Keyless Entry'),
                      _buildFeatureChip('Climate Control'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions
                  Container(
                    margin: const EdgeInsets.only(top: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quick Actions',
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
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _toggleWishlist,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _isInWishlist
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                      ),
                                label: Text(
                                  _isInWishlist ? 'Saved' : 'Save',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isInWishlist
                                      ? AppTheme.error
                                      : AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Contact dealer functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Contact feature coming soon!'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                ),
                                label: Text(
                                  'Contact',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Share functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share feature coming soon!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.share_outlined,
                            size: 20,
                          ),
                          label: Text(
                            'Share Vehicle',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: AppTheme.textSecondary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2), // ✅ FIX: Remove const
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.primaryColor,
        ),
      ),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      side: BorderSide(
        color: AppTheme.primaryColor.withOpacity(0.2),
      ),
    );
  }

  Widget _buildWarrantyItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
