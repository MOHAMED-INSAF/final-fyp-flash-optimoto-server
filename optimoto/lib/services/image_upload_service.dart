import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  // Get current user ID
  static String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Show dialog to select image source
  static Future<ImageSource?> showImageSourceDialog(
      BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Update profile image
  static Future<String?> updateProfileImage(
      {required ImageSource source}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Pick image from selected source
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null; // User cancelled
      }

      // Get app documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String profilesDir = path.join(appDir.path, 'profiles');

      // Create profiles directory if it doesn't exist
      final Directory profilesDirObj = Directory(profilesDir);
      if (!await profilesDirObj.exists()) {
        await profilesDirObj.create(recursive: true);
      }

      // Delete old profile image if exists
      await deleteProfileImage(userId);

      // Create new filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = path.extension(pickedFile.path);
      final String newFileName = 'profile_${userId}_$timestamp$fileExtension';
      final String newFilePath = path.join(profilesDir, newFileName);

      // Copy the picked file to app directory
      final File newFile = await File(pickedFile.path).copy(newFilePath);

      // Save path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_$userId', newFile.path);

      debugPrint('Profile image saved: ${newFile.path}');
      return newFile.path;
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      rethrow;
    }
  }

  // Get profile image path
  static Future<String?> getProfileImagePath(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? imagePath = prefs.getString('profile_image_$userId');

      // Check if file exists
      if (imagePath != null && await File(imagePath).exists()) {
        return imagePath;
      } else {
        // Clean up invalid path
        if (imagePath != null) {
          await prefs.remove('profile_image_$userId');
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error getting profile image path: $e');
      return null;
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage(String userId) async {
    try {
      // Get current image path
      final String? currentImagePath = await getProfileImagePath(userId);

      if (currentImagePath != null) {
        // Delete the file
        final File imageFile = File(currentImagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
          debugPrint('Deleted old profile image: $currentImagePath');
        }
      }

      // Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_$userId');

      return true;
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
      return false;
    }
  }

  // Clean up old profile images (call periodically)
  static Future<void> cleanupOldImages() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String profilesDir = path.join(appDir.path, 'profiles');
      final Directory profilesDirObj = Directory(profilesDir);

      if (!await profilesDirObj.exists()) {
        return;
      }

      // Get all profile image files
      final List<FileSystemEntity> files = await profilesDirObj.list().toList();
      final DateTime cutoffDate =
          DateTime.now().subtract(const Duration(days: 30));

      for (final FileSystemEntity file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            try {
              await file.delete();
              debugPrint('Cleaned up old profile image: ${file.path}');
            } catch (e) {
              debugPrint('Error deleting old image ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  // Get image file size
  static Future<int> getImageFileSize(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting image file size: $e');
      return 0;
    }
  }

  // Check if image path is valid
  static Future<bool> isValidImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final File file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get total storage used by profile images
  static Future<int> getTotalStorageUsed() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String profilesDir = path.join(appDir.path, 'profiles');
      final Directory profilesDirObj = Directory(profilesDir);

      if (!await profilesDirObj.exists()) {
        return 0;
      }

      int totalSize = 0;
      final List<FileSystemEntity> files = await profilesDirObj.list().toList();

      for (final FileSystemEntity file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage used: $e');
      return 0;
    }
  }
}
