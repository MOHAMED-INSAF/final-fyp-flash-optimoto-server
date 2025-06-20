import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';

class ImageUploadWidget extends StatefulWidget {
  final String userId;
  final double size;
  final VoidCallback? onImageChanged;
  final bool showEditButton;

  const ImageUploadWidget({
    super.key,
    required this.userId,
    this.size = 100,
    this.onImageChanged,
    this.showEditButton = true,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingImage();
  }

  Future<void> _loadExistingImage() async {
    final imagePath =
        await ImageUploadService.getProfileImagePath(widget.userId);
    if (mounted) {
      setState(() {
        _imagePath = imagePath;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Show source selection dialog
      final ImageSource? source =
          await ImageUploadService.showImageSourceDialog(context);
      if (source == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update profile image
      final String? newImagePath =
          await ImageUploadService.updateProfileImage(source: source);

      if (newImagePath != null) {
        setState(() {
          _imagePath = newImagePath;
        });

        // Notify parent widget
        widget.onImageChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile picture'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content:
            const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        final bool success =
            await ImageUploadService.deleteProfileImage(widget.userId);

        if (success) {
          setState(() {
            _imagePath = null;
          });

          widget.onImageChanged?.call();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture removed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error removing image: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Profile Image Circle
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: _isLoading
                ? Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _imagePath != null
                    ? Image.file(
                        File(_imagePath!),
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
          ),
        ),

        // Edit Button
        if (widget.showEditButton && !_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _pickImage();
                      break;
                    case 'remove':
                      _removeImage();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Change Picture'),
                      ],
                    ),
                  ),
                  if (_imagePath != null)
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove Picture',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withOpacity(0.8),
            AppTheme.primaryDark.withOpacity(0.8),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Colors.white,
      ),
    );
  }
}

// Simple version for home page header
class SimpleProfileImage extends StatefulWidget {
  final String userId;
  final double size;

  const SimpleProfileImage({
    super.key,
    required this.userId,
    this.size = 40,
  });

  @override
  State<SimpleProfileImage> createState() => _SimpleProfileImageState();
}

class _SimpleProfileImageState extends State<SimpleProfileImage> {
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadExistingImage();
  }

  @override
  void didUpdateWidget(SimpleProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadExistingImage();
    }
  }

  Future<void> _loadExistingImage() async {
    final imagePath =
        await ImageUploadService.getProfileImagePath(widget.userId);
    if (mounted) {
      setState(() {
        _imagePath = imagePath;
      });
    }
  }

  // Public method to refresh image from outside
  void refreshImage() {
    _loadExistingImage();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/profile').then((_) {
          // Refresh image when returning from profile
          _loadExistingImage();
        });
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _imagePath != null
              ? Image.file(
                  File(_imagePath!),
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
