import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:food_delivery_app/models/user_model.dart';
// import 'package:food_delivery_app/screens/auth/login_screen.dart';
// import 'package:food_delivery_app/services/auth_service.dart';
// import 'package:food_delivery_app/widgets/custom_button.dart';
// import 'package:food_delivery_app/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_drawer.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  File? _selectedImage;
  final _imagePicker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Optimized image picking with immediate UI update
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to 80% quality
        maxWidth: 800, // Limit width to 800px for smaller file size
        maxHeight: 800, // Limit height to 800px for smaller file size
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);

        // Update UI immediately with selected image
        setState(() {
          _selectedImage = imageFile;
          _isUploadingImage = true; // Show loading indicator
        });

        // Upload the image in background with local path for immediate UI update
        _uploadProfileImage(localImagePath: pickedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Optimized image upload with background processing
  Future<void> _uploadProfileImage({String? localImagePath}) async {
    if (_selectedImage == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userModel == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isUploadingImage = false;
        });
      }
      return;
    }

    try {
      // Pass the local image path for immediate UI update
      final success = await authService.uploadProfileImage(
        _selectedImage!,
        authService.userModel!.id,
        localImagePath: localImagePath,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _selectedImage =
                null; // Clear selected image after successful upload
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authService.error ?? 'Failed to update profile image',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userModel != null) {
      _nameController.text = authService.userModel!.name;
      _emailController.text = authService.userModel!.email;
      _addressController.text = authService.userModel!.address;
      _phoneController.text = authService.userModel!.phoneNumber ?? '';
    }
  }

  // Helper method to check if a URL error is related to Firebase Storage
  bool _isFirebaseStorageError(String? url) {
    if (url == null) return false;

    // Check if the URL is a Firebase Storage URL
    final isFirebaseStorageUrl =
        url.contains('firebasestorage.googleapis.com') ||
        url.contains('firebasestorage.app');

    // If it's not a Firebase Storage URL, we don't need to check further
    if (!isFirebaseStorageUrl) return false;

    // For Firebase Storage URLs, we can check if the URL is valid
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty; // This should never be true for valid URLs
    } catch (e) {
      // If parsing fails, it's definitely an error
      debugPrint('Error parsing URL: $e');
      return true;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.userModel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final updatedUser = authService.userModel!.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      final success = await authService.updateUserProfile(updatedUser);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.error ?? 'Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.userModel;
    final errorMessage = authService.error;

    if (user == null) {
      return const Center(child: Text('User not authenticated'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _loadUserData();
                }
              });
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile image
              Center(
                child: Stack(
                  children: [
                    // Profile image
                    _selectedImage != null
                        ? CircleAvatar(
                          radius: 60,
                          backgroundImage: FileImage(_selectedImage!),
                        )
                        : CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              user.profileImageUrl != null
                                  ? CachedNetworkImageProvider(
                                    user.profileImageUrl!,
                                    errorListener: (error) {
                                      // Log the specific error for debugging
                                      debugPrint(
                                        'CachedNetworkImage error: $error',
                                      );
                                    },
                                  )
                                  : null,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint(
                              'Error loading profile image: $exception',
                            );
                            // Check if this is a Firebase Storage error
                            if (exception.toString().contains(
                              'object-not-found',
                            )) {
                              debugPrint(
                                'Firebase Storage object-not-found error detected',
                              );
                            }
                          },
                          child:
                              user.profileImageUrl == null ||
                                      _isFirebaseStorageError(
                                        user.profileImageUrl,
                                      )
                                  ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  )
                                  : null,
                        ),
                    // Camera icon for editing
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(51),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    // Loading indicator when uploading image
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Error message if any
              if (errorMessage != null && errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // User info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Name:',
                      _isEditing
                          ? CustomTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          )
                          : Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      'E-mail:',
                      _isEditing
                          ? CustomTextField(
                            controller: _emailController,
                            hintText: 'Email',
                            enabled: false,
                          )
                          : Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      'Address:',
                      _isEditing
                          ? CustomTextField(
                            controller: _addressController,
                            hintText: 'Address',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          )
                          : Text(
                            user.address,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      'Phone:',
                      _isEditing
                          ? CustomTextField(
                            controller: _phoneController,
                            hintText: 'Phone Number',
                            keyboardType: TextInputType.phone,
                          )
                          : Text(
                            user.phoneNumber ?? 'Not provided',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (_isEditing)
                CustomButton(
                  text: 'Save Changes',
                  isLoading: authService.isLoading,
                  onPressed: _updateProfile,
                )
              else
                CustomButton(
                  text: 'Sign Out',
                  onPressed: _signOut,
                  backgroundColor: Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey.shade400)),
        ),
        Expanded(child: value),
      ],
    );
  }
}
