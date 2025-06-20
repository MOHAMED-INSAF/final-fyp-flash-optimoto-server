import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/user_stats_service.dart';
import '../services/user_activity_service.dart';
import '../services/firebase_service.dart';
import '../models/user_stats.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          final profile = authProvider.userProfile ?? {};

          if (user == null) {
            return _buildNotLoggedInState();
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryLight,
                          AppTheme.primaryDark,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImageUploadWidget(
                            userId: user.uid,
                            size: 120,
                            showEditButton: true,
                            onImageChanged: () {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                                    .trim()
                                    .isEmpty
                                ? user.displayName ?? 'User'
                                : '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                                    .trim(),
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            user.email ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      StreamBuilder<UserStats>(
                        stream: UserStatsService.getUserStatsStream(),
                        builder: (context, snapshot) {
                          final stats = snapshot.data ?? UserStats.empty();
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildStatCard(
                                          'Saved',
                                          '${stats.wishlistCount}',
                                          Icons.favorite_outline,
                                          AppTheme.error)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildStatCard(
                                          'Viewed',
                                          '${stats.viewedVehiclesCount}',
                                          Icons.visibility_outlined,
                                          AppTheme.success)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildStatCard(
                                          'Compared',
                                          '${stats.comparedVehiclesCount}',
                                          Icons.compare_arrows_outlined,
                                          AppTheme.info)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: _buildStatCard(
                                          'Searches',
                                          '${stats.searchesCount}',
                                          Icons.search_outlined,
                                          AppTheme.warning)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: 'Personal Information',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoTile(
                              'Name',
                              '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                                      .trim()
                                      .isEmpty
                                  ? user.displayName ?? 'Not set'
                                  : '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
                                      .trim()),
                          _buildInfoTile('Email', user.email ?? 'Not set'),
                          _buildInfoTile(
                              'Phone', profile['phone'] ?? 'Not set'),
                          _buildInfoTile(
                              'Member Since',
                              profile['createdAt'] != null
                                  ? _formatDate(profile['createdAt'])
                                  : 'Recently'),
                        ],
                      ),
                      _buildPreferencesSection(),
                      _buildRecentActivitySection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(authProvider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirebaseService.getUserPreferencesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildSection(
            title: 'Preferences',
            icon: Icons.settings_outlined,
            children: [
              Text('Unable to load preferences: ${snapshot.error}'),
            ],
          );
        }

        final preferences = snapshot.data ??
            {
              'notifications': true,
              'darkMode': false,
              'newsletter': true,
              'autoSaveSearches': true,
            };

        return _buildSection(
          title: 'Preferences',
          icon: Icons.settings_outlined,
          children: [
            _buildSwitchTile(
              'Notifications',
              'Receive updates and alerts',
              preferences['notifications'] as bool? ?? true,
              (value) => _updatePreference('notifications', value),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSwitchTile(
                  'Dark Mode',
                  'Switch to dark theme',
                  themeProvider.isDarkMode,
                  (value) => _updateDarkMode(value, themeProvider),
                );
              },
            ),
            _buildSwitchTile(
              'Newsletter',
              'Weekly car news and tips',
              preferences['newsletter'] as bool? ?? true,
              (value) => _updatePreference('newsletter', value),
            ),
            _buildSwitchTile(
              'Auto-save Searches',
              'Save search history automatically',
              preferences['autoSaveSearches'] as bool? ?? true,
              (value) => _updatePreference('autoSaveSearches', value),
            ),
          ],
        );
      },
    );
  }

  void _updateDarkMode(bool value, ThemeProvider themeProvider) async {
    try {
      await themeProvider.setDarkMode(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${value ? 'Dark' : 'Light'} mode enabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating dark mode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update theme: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updatePreference(String key, bool value) async {
    try {
      final currentPrefs = await FirebaseService.getUserPreferences() ?? {};
      currentPrefs[key] = value;
      await FirebaseService.updateUserPreferences(currentPrefs);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getPreferenceDisplayName(key)} ${value ? 'enabled' : 'disabled'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preference: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButtons(AuthProvider authProvider) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _navigateToEditProfile(),
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showStatisticsDetail(),
          icon: const Icon(Icons.analytics),
          label: const Text('View Detailed Statistics'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showClearHistoryDialog(),
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear Activity History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.warning,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _performLogout(authProvider),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline,
              size: 80, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Please log in to view your profile',
              style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login')),
        ],
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.pushNamed(context, '/profile_setup').then((_) => setState(() {}));
  }

  void _showStatisticsDetail() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Detailed Statistics'),
          ],
        ),
        content: StreamBuilder<UserStats>(
          stream: UserStatsService.getUserStatsStream(),
          builder: (context, snapshot) {
            final stats = snapshot.data ?? UserStats.empty();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailedStatItem(
                    'Vehicles Saved', '${stats.wishlistCount}', Icons.favorite),
                _buildDetailedStatItem('Vehicles Viewed',
                    '${stats.viewedVehiclesCount}', Icons.visibility),
                _buildDetailedStatItem('Vehicles Compared',
                    '${stats.comparedVehiclesCount}', Icons.compare_arrows),
                _buildDetailedStatItem('Searches Performed',
                    '${stats.searchesCount}', Icons.search),
                const SizedBox(height: 16),
                if (stats.lastUpdated != null)
                  Text('Last updated: ${_formatDateTime(stats.lastUpdated!)}',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary)),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warning),
            const SizedBox(width: 8),
            const Text('Clear Activity History'),
          ],
        ),
        content: const Text(
            'This will permanently delete all your activity history including viewed vehicles, comparisons, and search history. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _clearAllHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Clearing history...')
            ],
          ),
        ),
      );

      await Future.wait([
        UserActivityService.clearViewHistory(),
        UserActivityService.clearComparisonHistory(),
        UserStatsService.resetAllStats(),
      ]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Activity history cleared successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error clearing history: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _performLogout(AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await authProvider.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/welcome', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Logout failed: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Recently';
      DateTime date = timestamp is DateTime ? timestamp : timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getPreferenceDisplayName(String key) {
    switch (key) {
      case 'notifications':
        return 'Notifications';
      case 'darkMode':
        return 'Dark Mode';
      case 'newsletter':
        return 'Newsletter';
      case 'autoSaveSearches':
        return 'Auto-save Searches';
      default:
        return key;
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            Text(title,
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDetailedStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return _buildSection(
      title: 'Recent Activity',
      icon: Icons.history_outlined,
      children: [
        FutureBuilder<List<Vehicle>>(
          future: UserActivityService.getRecentlyViewed(limit: 3),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final recentVehicles = snapshot.data ?? [];
            if (recentVehicles.isEmpty) {
              return const Text('No recent activity');
            }
            return Column(
              children: recentVehicles.asMap().entries.map((entry) {
                final vehicle = entry.value;
                return _buildActivityTile(
                    'Viewed ${vehicle.name}', 'Recently', Icons.visibility);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityTile(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(time,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
