import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import '../models/user_stats.dart';

class UserStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user statistics with retry logic
  static Future<UserStats> getUserStats() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return UserStats.empty();

    try {
      debugPrint('Getting user stats for: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final statsData = data['statistics'] as Map<String, dynamic>? ?? {};
        return UserStats.fromJson(statsData);
      } else {
        debugPrint('User document not found, initializing...');
        // Initialize user document if it doesn't exist
        await _initializeUserStats(userId);
        return UserStats.empty();
      }
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return UserStats.empty();
    }
  }

  // Stream user statistics (real-time updates) with better error handling
  static Stream<UserStats> getUserStatsStream() {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('No user ID available for stats stream');
      return Stream.value(UserStats.empty());
    }

    debugPrint('Setting up stats stream for user: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in stats stream: $error');
          return null;
        })
        .where((snapshot) =>
            snapshot.data() != null) // ✅ FIX: Check data() instead of snapshot
        .map((doc) {
          try {
            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              final statsData =
                  data['statistics'] as Map<String, dynamic>? ?? {};
              debugPrint('Stats data loaded: $statsData');
              return UserStats.fromJson(statsData);
            } else {
              debugPrint('User document does not exist, returning empty stats');
              return UserStats.empty();
            }
          } catch (e) {
            debugPrint('Error parsing stats data: $e');
            return UserStats.empty();
          }
        });
  }

  // Initialize user stats if document doesn't exist
  static Future<void> _initializeUserStats(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'statistics': {
          'wishlistCount': 0,
          'viewedVehiclesCount': 0,
          'comparedVehiclesCount': 0,
          'searchesCount': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      debugPrint('User stats initialized for: $userId');
    } catch (e) {
      debugPrint('Error initializing user stats: $e');
    }
  }

  // Update wishlist count
  static Future<void> updateWishlistCount(int change) async {
    await _updateStatistic('wishlistCount', change);
  }

  // Update viewed vehicles count
  static Future<void> updateViewedCount() async {
    await _updateStatistic('viewedVehiclesCount', 1);
  }

  // Update compared vehicles count
  static Future<void> updateComparedCount() async {
    await _updateStatistic('comparedVehiclesCount', 1);
  }

  // Update search count
  static Future<void> updateSearchCount() async {
    await _updateStatistic('searchesCount', 1);
  }

  // Private method to update any statistic with retry logic
  static Future<void> _updateStatistic(String statName, int change) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // First ensure the document exists
      final docSnapshot = await userDocRef.get();
      if (!docSnapshot.exists) {
        await _initializeUserStats(userId);
      }

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final stats = data['statistics'] as Map<String, dynamic>? ?? {};
          final currentValue = stats[statName] as int? ?? 0;
          final newValue =
              (currentValue + change).clamp(0, double.infinity).toInt();

          transaction.update(userDocRef, {
            'statistics.$statName': newValue,
            'statistics.lastUpdated': FieldValue.serverTimestamp(),
          });

          debugPrint('Updated $statName: $currentValue -> $newValue');
        }
      });
    } catch (e) {
      debugPrint('Error updating $statName: $e');
    }
  }

  // Reset all statistics
  static Future<void> resetAllStats() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'statistics': {
          'wishlistCount': 0,
          'viewedVehiclesCount': 0,
          'comparedVehiclesCount': 0,
          'searchesCount': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      });
      debugPrint('All statistics reset');
    } catch (e) {
      debugPrint('Error resetting statistics: $e');
    }
  }

  // Get statistics for a date range
  static Future<Map<String, dynamic>> getStatsForPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return {};

    try {
      // This would require storing timestamped activity records
      // For now, return current stats
      final stats = await getUserStats();
      return {
        'period':
            '${startDate.toIso8601String()} - ${endDate.toIso8601String()}',
        'wishlistCount': stats.wishlistCount,
        'viewedVehiclesCount': stats.viewedVehiclesCount,
        'comparedVehiclesCount': stats.comparedVehiclesCount,
        'searchesCount': stats.searchesCount,
      };
    } catch (e) {
      debugPrint('Error getting stats for period: $e');
      return {};
    }
  }
}
