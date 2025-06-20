import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'user_stats_service.dart';
import '../models/vehicle.dart';

class UserActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add vehicle to view history with better error handling
  static Future<void> addToViewHistory(Vehicle vehicle) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('Cannot add to view history: No user logged in');
      return;
    }

    try {
      debugPrint(
          'Adding vehicle ${vehicle.id} to view history for user $userId');

      final viewHistoryRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('viewHistory')
          .doc(vehicle.id);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(viewHistoryRef);

        if (snapshot.exists) {
          // Update existing entry
          final currentData = snapshot.data() ?? {};
          final viewCount = (currentData['viewCount'] as int? ?? 0) + 1;

          transaction.update(viewHistoryRef, {
            'viewCount': viewCount,
            'lastViewedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
              'Updated view count for vehicle ${vehicle.id}: $viewCount');
        } else {
          // Create new entry
          transaction.set(viewHistoryRef, {
            'vehicleId': vehicle.id,
            'vehicleData': vehicle.toJson(),
            'viewCount': 1,
            'firstViewedAt': FieldValue.serverTimestamp(),
            'lastViewedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
              'Created new view history entry for vehicle ${vehicle.id}');

          // Update viewed count in statistics (don't await to avoid blocking)
          UserStatsService.updateViewedCount().catchError((e) {
            debugPrint('Error updating viewed count: $e');
          });
        }
      });
    } catch (e) {
      debugPrint('Error adding to view history: $e');
    }
  }

  // Get recently viewed vehicles
  static Future<List<Vehicle>> getRecentlyViewed({int limit = 10}) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('viewHistory')
          .orderBy('lastViewedAt', descending: true)
          .limit(limit)
          .get();

      final vehicles = <Vehicle>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final vehicleData = data['vehicleData'] as Map<String, dynamic>?;
          if (vehicleData != null) {
            vehicles.add(Vehicle.fromJson(vehicleData));
          }
        } catch (e) {
          debugPrint('Error parsing vehicle from view history: $e');
        }
      }

      debugPrint('Retrieved ${vehicles.length} recently viewed vehicles');
      return vehicles;
    } catch (e) {
      debugPrint('Error getting recently viewed: $e');
      return [];
    }
  }

  // Stream recently viewed vehicles with better error handling
  static Stream<List<Vehicle>> getRecentlyViewedStream({int limit = 5}) {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('No user ID available for recently viewed stream');
      return Stream.value([]);
    }

    debugPrint('Setting up recently viewed stream for user: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('viewHistory')
        .orderBy('lastViewedAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in recently viewed stream: $error');
          return null;
        })
        .where((snapshot) =>
            snapshot.docs.isNotEmpty) // ✅ FIX: Check docs instead of null
        .map((snapshot) {
          final vehicles = <Vehicle>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final vehicleData = data['vehicleData'] as Map<String, dynamic>?;
              if (vehicleData != null) {
                vehicles.add(Vehicle.fromJson(vehicleData));
              }
            } catch (e) {
              debugPrint('Error parsing vehicle from stream: $e');
            }
          }

          debugPrint('Loaded ${vehicles.length} recently viewed vehicles');
          return vehicles;
        });
  }

  // Clear view history
  static Future<void> clearViewHistory() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('viewHistory')
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('View history cleared');
    } catch (e) {
      debugPrint('Error clearing view history: $e');
    }
  }

  // Get view count for a specific vehicle
  static Future<int> getVehicleViewCount(String vehicleId) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return 0;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('viewHistory')
          .doc(vehicleId)
          .get();

      if (doc.exists) {
        return doc.data()?['viewCount'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting vehicle view count: $e');
      return 0;
    }
  }

  // ✅ FIX: Enhanced comparison tracking with duplicate prevention
  static Future<void> addComparisonRecord(
      String vehicle1Id, String vehicle2Id) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('Cannot add comparison record: No user logged in');
      return;
    }

    try {
      // Create consistent comparison ID regardless of order
      final sortedIds = [vehicle1Id, vehicle2Id]..sort();
      final comparisonId = '${sortedIds[0]}_vs_${sortedIds[1]}';

      debugPrint('Adding comparison record: $comparisonId for user $userId');

      final comparisonRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('comparisons')
          .doc(comparisonId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(comparisonRef);

        if (snapshot.exists) {
          // Update existing comparison with new timestamp
          final currentData = snapshot.data() ?? {};
          final comparisonCount =
              (currentData['comparisonCount'] as int? ?? 0) + 1;

          transaction.update(comparisonRef, {
            'comparisonCount': comparisonCount,
            'lastComparedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint(
              'Updated comparison count for $comparisonId: $comparisonCount');
        } else {
          // Create new comparison record
          transaction.set(comparisonRef, {
            'vehicle1Id': sortedIds[0],
            'vehicle2Id': sortedIds[1],
            'comparisonCount': 1,
            'firstComparedAt': FieldValue.serverTimestamp(),
            'lastComparedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          debugPrint('Created new comparison record: $comparisonId');

          // Update comparison count in statistics only for new comparisons
          UserStatsService.updateComparedCount().catchError((e) {
            debugPrint('Error updating compared count: $e');
          });
        }
      });
    } catch (e) {
      debugPrint('Error adding comparison record: $e');
      rethrow;
    }
  }

  // ✅ ADD: Get total unique comparisons count
  static Future<int> getTotalComparisonsCount() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return 0;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('comparisons')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting total comparisons count: $e');
      return 0;
    }
  }

  // ✅ ADD: Clear comparison history
  static Future<void> clearComparisonHistory() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('comparisons')
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Comparison history cleared');
    } catch (e) {
      debugPrint('Error clearing comparison history: $e');
    }
  }

  // Get comparison history
  static Future<List<Map<String, dynamic>>> getComparisonHistory(
      {int limit = 10}) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('comparisons')
          .orderBy('comparedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting comparison history: $e');
      return [];
    }
  }
}
