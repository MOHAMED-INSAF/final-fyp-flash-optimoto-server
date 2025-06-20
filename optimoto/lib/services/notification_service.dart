import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../models/notification.dart';
import '../models/vehicle.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new notification
  static Future<void> createNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());

      debugPrint('Notification created: $title');
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  // Get all notifications for user
  static Future<List<AppNotification>> getNotifications(
      {int limit = 50}) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  // Stream notifications (real-time)
  static Stream<List<AppNotification>> getNotificationsStream(
      {int limit = 50}) {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data()))
            .toList());
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return 0;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // Stream unread count
  static Stream<int> getUnreadCountStream() {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  // === SPECIFIC NOTIFICATION CREATORS ===

  // Wishlist alert when vehicle is added
  static Future<void> createWishlistAlert(Vehicle vehicle) async {
    await createNotification(
      title: 'Vehicle Added to Wishlist',
      body: '${vehicle.name} has been added to your wishlist',
      type: NotificationType.wishlistAlert,
      data: {
        'vehicleId': vehicle.id,
        'vehicleName': vehicle.name,
        'price': vehicle.price,
      },
      actionUrl: '/wishlist',
    );
  }

  // Price alert for wishlist vehicles
  static Future<void> createPriceAlert(Vehicle vehicle, double oldPrice) async {
    final discount = oldPrice - vehicle.price;
    final percentageOff = (discount / oldPrice * 100).round();

    await createNotification(
      title: 'Price Drop Alert! 🎉',
      body:
          '${vehicle.name} is now \$${vehicle.price.toStringAsFixed(0)} ($percentageOff% off)', // ✅ FIX: Remove unnecessary braces
      type: NotificationType.priceAlert,
      data: {
        'vehicleId': vehicle.id,
        'vehicleName': vehicle.name,
        'newPrice': vehicle.price,
        'oldPrice': oldPrice,
        'discount': discount,
      },
      actionUrl: '/vehicle_details/${vehicle.id}',
    );
  }

  // New guide notification
  static Future<void> createNewGuideNotification({
    required String guideTitle,
    required String guideCategory,
    required String guideId,
  }) async {
    await createNotification(
      title: 'New Guide Available! 📚',
      body: 'Check out "$guideTitle" in $guideCategory',
      type: NotificationType.newGuide,
      data: {
        'guideId': guideId,
        'guideTitle': guideTitle,
        'category': guideCategory,
      },
      actionUrl: '/guides/$guideId',
    );
  }

  // Search suggestion based on user behavior
  static Future<void> createSearchSuggestion({
    required String suggestion,
    required String reason,
  }) async {
    await createNotification(
      title: 'Vehicle Recommendation 🎯',
      body: 'Based on your preferences: $suggestion',
      type: NotificationType.searchSuggestion,
      data: {
        'suggestion': suggestion,
        'reason': reason,
      },
      actionUrl: '/find_vehicle',
    );
  }

  // Feature announcement
  static Future<void> createFeatureAnnouncement({
    required String featureName,
    required String description,
    String? actionUrl,
  }) async {
    await createNotification(
      title: 'New Feature: $featureName ✨',
      body: description,
      type: NotificationType.featureAnnouncement,
      data: {
        'featureName': featureName,
        'description': description,
      },
      actionUrl: actionUrl,
    );
  }

  // Maintenance reminder
  static Future<void> createMaintenanceReminder({
    required String vehicleName,
    required String maintenanceType,
    required int mileage,
  }) async {
    await createNotification(
      title: 'Maintenance Reminder 🔧',
      body:
          'Time for $maintenanceType on your $vehicleName (${mileage}k miles)',
      type: NotificationType.maintenanceReminder,
      data: {
        'vehicleName': vehicleName,
        'maintenanceType': maintenanceType,
        'mileage': mileage,
      },
      actionUrl: '/guides',
    );
  }

  // === HELPER METHODS FOR AUTOMATED NOTIFICATIONS ===

  // Send welcome notifications for new users
  static Future<void> sendWelcomeNotifications() async {
    await Future.delayed(const Duration(seconds: 2));

    await createFeatureAnnouncement(
      featureName: 'Welcome to OptiMoto!',
      description:
          'Discover the perfect vehicle with our AI-powered recommendations',
      actionUrl: '/find_vehicle',
    );

    await Future.delayed(const Duration(seconds: 1));

    await createNewGuideNotification(
      guideTitle: 'First-Time Car Buyer\'s Complete Guide',
      guideCategory: 'Buying Guide',
      guideId: '1',
    );
  }

  // Send daily tips
  static Future<void> sendDailyTip() async {
    final tips = [
      {
        'title': 'Daily Tip: Check Your Tire Pressure',
        'body': 'Proper tire pressure improves fuel efficiency by up to 3%',
      },
      {
        'title': 'Daily Tip: Regular Oil Changes',
        'body':
            'Change your oil every 5,000-7,500 miles for optimal engine health',
      },
      {
        'title': 'Daily Tip: EV Charging',
        'body': 'Charge your EV to 80% for daily use to preserve battery life',
      },
    ];

    final tip = tips[DateTime.now().day % tips.length];

    await createNotification(
      title: tip['title']!,
      body: tip['body']!,
      type: NotificationType.maintenanceReminder,
      actionUrl: '/guides',
    );
  }
}
