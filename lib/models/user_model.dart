import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String address;
  final String? phoneNumber;
  final String? profileImageUrl;
  final bool hasLocalImage; // Flag to indicate if the profile image is local

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    this.phoneNumber,
    this.profileImageUrl,
    this.hasLocalImage = false,
  }) {
    // Validate data in debug mode
    assert(email.isNotEmpty, 'Email cannot be empty');
    assert(name.isNotEmpty, 'Name cannot be empty');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('=== CREATING USER MODEL FROM JSON ===');
    debugPrint('JSON data: $json');

    // Extract values with validation
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final address = json['address'] as String? ?? '';
    final phoneNumber = json['phoneNumber'] as String?;
    final profileImageUrl = json['profileImageUrl'] as String?;
    final hasLocalImage = json['hasLocalImage'] as bool? ?? false;

    // Log extracted values
    debugPrint('Extracted ID: $id');
    debugPrint('Extracted name: $name');
    debugPrint('Extracted email: $email');
    debugPrint('Extracted address: $address');
    debugPrint('Extracted phoneNumber: $phoneNumber');
    debugPrint('Extracted profileImageUrl: $profileImageUrl');
    debugPrint('Extracted hasLocalImage: $hasLocalImage');

    // Create and return model
    return UserModel(
      id: id,
      name: name,
      email: email,
      address: address,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      hasLocalImage: hasLocalImage,
    );
  }

  Map<String, dynamic> toJson() {
    debugPrint('=== CONVERTING USER MODEL TO JSON ===');
    debugPrint('User ID: $id');
    debugPrint('User name: $name');
    debugPrint('User email: $email');

    final json = {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'hasLocalImage': hasLocalImage,
    };

    debugPrint('Generated JSON: $json');
    return json;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? address,
    String? phoneNumber,
    String? profileImageUrl,
    bool? hasLocalImage,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasLocalImage: hasLocalImage ?? this.hasLocalImage,
    );
  }
}
