import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification.dart';
import '../models/vehicle.dart'; // ✅ ADD: Missing import for Vehicle class
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(),
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_notification',
                child: Row(
                  children: [
                    Icon(Icons.notification_add),
                    SizedBox(width: 8),
                    Text('Test Notification'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.getNotificationsStream(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: GoogleFonts.inter(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationsList(notifications);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you about vehicle updates and new features',
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createTestNotification(),
            icon: const Icon(Icons.add_alert),
            label: const Text('Create Test Notification'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead
                ? Colors.white
                : AppTheme.primaryColor.withOpacity(0.05),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.montserrat(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _getNotificationColor(notification.type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleNotificationAction(value, notification),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: notification.isRead ? 'mark_unread' : 'mark_read',
                    child: Row(
                      children: [
                        Icon(notification.isRead
                            ? Icons.mark_email_unread
                            : Icons.mark_email_read),
                        const SizedBox(width: 8),
                        Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.wishlistAlert:
        return AppTheme.error;
      case NotificationType.newGuide:
        return AppTheme.info;
      case NotificationType.searchSuggestion:
        return AppTheme.primaryColor;
      case NotificationType.featureAnnouncement:
        return AppTheme.success;
      case NotificationType.priceAlert:
        return AppTheme.warning;
      case NotificationType.maintenanceReminder:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.wishlistAlert:
        return Icons.favorite;
      case NotificationType.newGuide:
        return Icons.menu_book;
      case NotificationType.searchSuggestion:
        return Icons.search;
      case NotificationType.featureAnnouncement:
        return Icons.new_releases;
      case NotificationType.priceAlert:
        return Icons.local_offer;
      case NotificationType.maintenanceReminder:
        return Icons.build;
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read if unread
    if (!notification.isRead) {
      NotificationService.markAsRead(notification.id);
    }

    // Navigate based on action URL
    if (notification.actionUrl != null) {
      _navigateToAction(notification.actionUrl!);
    }
  }

  void _navigateToAction(String actionUrl) {
    // Simple routing based on action URL
    if (actionUrl.startsWith('/wishlist')) {
      Navigator.pushNamed(context, '/home'); // Will go to wishlist tab
    } else if (actionUrl.startsWith('/guides')) {
      Navigator.pushNamed(context, '/guides');
    } else if (actionUrl.startsWith('/find_vehicle')) {
      Navigator.pushNamed(context, '/home'); // Will go to find tab
    }
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        NotificationService.markAsRead(notification.id);
        break;
      case 'mark_unread':
        // Would need to implement markAsUnread in service
        break;
      case 'delete':
        NotificationService.deleteNotification(notification.id);
        break;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'test_notification':
        _createTestNotification();
        break;
    }
  }

  void _markAllAsRead() {
    NotificationService.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
            'This will permanently delete all notifications. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _createTestNotification() {
    final notifications = [
      () => NotificationService.createWishlistAlert(
            // Create a dummy vehicle for testing
            Vehicle(
              id: 'test1',
              name: 'Tesla Model 3',
              brand: 'Tesla',
              price: 45000,
              type: 'Sedan',
              mileage: 120,
              fuelType: 'Electric',
              score: 0.95,
              imageUrl: '',
            ),
          ),
      () => NotificationService.createNewGuideNotification(
            guideTitle: 'Electric Vehicle Charging Guide',
            guideCategory: 'Electric Vehicles',
            guideId: '2',
          ),
      () => NotificationService.createFeatureAnnouncement(
            featureName: 'Advanced Search',
            description: 'Now search by name, brand, and more filters!',
            actionUrl: '/find_vehicle',
          ),
    ];

    // Create a random test notification
    notifications[DateTime.now().millisecond % notifications.length]();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification created!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
