import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'user_stats_service.dart';
import '../models/vehicle.dart';
import 'notification_service.dart'; // ✅ ADD: Import notification service

class WishlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add vehicle to Firestore wishlist
  static Future<void> addToWishlist(Vehicle vehicle) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('Cannot add to wishlist: No user logged in');
      return;
    }

    try {
      debugPrint('Adding vehicle ${vehicle.id} to wishlist for user $userId');

      final wishlistRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(vehicle.id);

      await wishlistRef.set({
        'vehicleId': vehicle.id,
        'vehicleData': vehicle.toJson(),
        'addedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update wishlist count in statistics
      await UserStatsService.updateWishlistCount(1);

      // ✅ NEW: Create notification for wishlist addition
      await NotificationService.createWishlistAlert(vehicle);

      debugPrint('Added vehicle ${vehicle.id} to wishlist');
    } catch (e) {
      debugPrint('Error adding to wishlist: $e');
      rethrow;
    }
  }

  // Remove vehicle from Firestore wishlist
  static Future<void> removeFromWishlist(String vehicleId) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('Cannot remove from wishlist: No user logged in');
      return;
    }

    try {
      debugPrint('Removing vehicle $vehicleId from wishlist for user $userId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(vehicleId)
          .delete();

      // Update wishlist count in statistics
      await UserStatsService.updateWishlistCount(-1);
      debugPrint('Removed vehicle $vehicleId from wishlist');
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
      rethrow;
    }
  }

  // Get all wishlist vehicles from Firestore
  static Future<List<Vehicle>> getWishlistVehicles() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .orderBy('addedAt', descending: true)
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
          debugPrint('Error parsing vehicle from wishlist: $e');
        }
      }

      debugPrint('Retrieved ${vehicles.length} vehicles from wishlist');
      return vehicles;
    } catch (e) {
      debugPrint('Error getting wishlist vehicles: $e');
      return [];
    }
  }

  // Stream wishlist vehicles (real-time updates)
  static Stream<List<Vehicle>> getWishlistStream() {
    final userId = FirebaseService.currentUserId;
    if (userId == null) {
      debugPrint('No user ID available for wishlist stream');
      return Stream.value([]);
    }

    debugPrint('Setting up wishlist stream for user: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint('Error in wishlist stream: $error');
      return null;
    }).map((snapshot) {
      final vehicles = <Vehicle>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final vehicleData = data['vehicleData'] as Map<String, dynamic>?;
          if (vehicleData != null) {
            vehicles.add(Vehicle.fromJson(vehicleData));
          }
        } catch (e) {
          debugPrint('Error parsing vehicle from wishlist stream: $e');
        }
      }

      debugPrint('Loaded ${vehicles.length} vehicles from wishlist stream');
      return vehicles;
    });
  }

  // Check if vehicle is in wishlist
  static Future<bool> isInWishlist(String vehicleId) async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(vehicleId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking wishlist status: $e');
      return false;
    }
  }

  // Clear entire wishlist
  static Future<void> clearWishlist() async {
    final userId = FirebaseService.currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset wishlist count
      await UserStatsService.resetAllStats();
      debugPrint('Wishlist cleared');
    } catch (e) {
      debugPrint('Error clearing wishlist: $e');
      rethrow;
    }
  }

  // Debug method to test wishlist functionality
  static Future<void> debugWishlistStatus() async {
    final userId = FirebaseService.currentUserId;
    debugPrint('=== Wishlist Debug Info ===');
    debugPrint('Current User ID: $userId');

    if (userId != null) {
      try {
        final wishlistVehicles = await getWishlistVehicles();
        debugPrint('Wishlist contains ${wishlistVehicles.length} vehicles:');
        for (final vehicle in wishlistVehicles) {
          debugPrint('- ${vehicle.name} (ID: ${vehicle.id})');
        }
      } catch (e) {
        debugPrint('Error getting wishlist: $e');
      }
    }
    debugPrint('=== End Wishlist Debug ===');
  }
}
