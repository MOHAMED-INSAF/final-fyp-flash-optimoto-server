import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's UID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // ✅ FIX: Enhanced user document initialization with better error handling
  static Future<void> initializeUserDocument(User user,
      {String? firstName, String? lastName}) async {
    if (user.uid.isEmpty) return;

    try {
      debugPrint('🔄 Initializing user document for: ${user.uid}');

      final userDoc = _firestore.collection('users').doc(user.uid);

      // Check if document already exists
      DocumentSnapshot? docSnapshot;
      try {
        docSnapshot = await userDoc.get();
      } catch (e) {
        debugPrint('⚠️ Error checking existing document: $e');
        // Continue with creation
      }

      if (docSnapshot?.exists == true) {
        debugPrint('ℹ️ User document already exists');
        return;
      }

      // ✅ FIX: Safe document creation with proper data structure
      final userData = {
        'profile': {
          'email': user.email ?? '',
          'displayName': user.displayName ?? firstName ?? '',
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'statistics': {
          'wishlistCount': 0,
          'viewedVehiclesCount': 0,
          'comparedVehiclesCount': 0,
          'searchesCount': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'preferences': {
          'notifications': true,
          'darkMode': false,
          'newsletter': true,
          'language': 'en',
          'autoSaveSearches': true,
        }
      };

      await userDoc.set(userData);
      debugPrint('✅ User document initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing user document: $e');
      // Don't rethrow to avoid breaking the authentication flow
    }
  }

  // ✅ FIX: Enhanced profile retrieval with error handling
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) {
      debugPrint('⚠️ No current user ID available');
      return null;
    }

    try {
      debugPrint('🔄 Getting user profile for: $currentUserId');
      final doc =
          await _firestore.collection('users').doc(currentUserId!).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final profile = data['profile'] as Map<String, dynamic>?;
        debugPrint('✅ Profile retrieved successfully');
        return profile;
      } else {
        debugPrint('ℹ️ No profile document found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(
      Map<String, dynamic> profileData) async {
    if (currentUserId == null) return;

    try {
      // ✅ FIX: Safe profile update with merge
      await _firestore.collection('users').doc(currentUserId!).update({
        'profile': {
          ...profileData,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
      debugPrint('✅ User profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // Stream user profile data
  static Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .snapshots()
        .handleError((error) {
      debugPrint('❌ Error in profile stream: $error');
      return null;
    }).map((doc) {
      try {
        if (doc.exists && doc.data() != null) {
          return doc.data()?['profile'] as Map<String, dynamic>?;
        }
        return null;
      } catch (e) {
        debugPrint('❌ Error parsing profile data: $e');
        return null;
      }
    });
  }

  // Update user preferences
  static Future<void> updateUserPreferences(
      Map<String, dynamic> preferences) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId!).update({
        'preferences': preferences,
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User preferences updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user preferences: $e');
      rethrow;
    }
  }

  // Get user preferences
  static Future<Map<String, dynamic>?> getUserPreferences() async {
    if (currentUserId == null) return null;

    try {
      final doc =
          await _firestore.collection('users').doc(currentUserId!).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()?['preferences'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user preferences: $e');
      return null;
    }
  }

  // Stream user preferences
  static Stream<Map<String, dynamic>?> getUserPreferencesStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId!)
        .snapshots()
        .handleError((error) {
      debugPrint('❌ Error in preferences stream: $error');
      return null;
    }).map((doc) {
      try {
        if (doc.exists && doc.data() != null) {
          return doc.data()?['preferences'] as Map<String, dynamic>?;
        }
        return null;
      } catch (e) {
        debugPrint('❌ Error parsing preferences data: $e');
        return null;
      }
    });
  }

  // Get reference to user document
  static DocumentReference? getUserDocRef() {
    if (currentUserId == null) return null;
    return _firestore.collection('users').doc(currentUserId!);
  }

  // Get reference to any collection
  static CollectionReference getCollection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  // Batch write operations
  static WriteBatch batch() {
    return _firestore.batch();
  }

  // Transaction operations
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) {
    return _firestore.runTransaction(updateFunction);
  }
}
