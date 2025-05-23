import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A utility class to help with Firebase Storage operations and error handling
class FirebaseStorageHelper {
  /// Checks if a URL is a valid Firebase Storage URL
  static bool isValidStorageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    // Check if the URL is a Firebase Storage URL
    final isFirebaseStorageUrl =
        url.contains('firebasestorage.googleapis.com') ||
        url.contains('firebasestorage.app');

    // If it's not a Firebase Storage URL, we don't need to check further
    if (!isFirebaseStorageUrl) return false;

    // For Firebase Storage URLs, we can check if the URL is valid
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty; // Valid URLs must have a host
    } catch (e) {
      // If parsing fails, it's definitely an error
      debugPrint('Error parsing URL: $e');
      return false;
    }
  }

  /// Checks if a URL error is related to Firebase Storage
  static bool isFirebaseStorageError(String? url) {
    if (url == null) return false;
    return !isValidStorageUrl(url);
  }

  /// Checks if a file exists in Firebase Storage
  /// Returns true if the file exists, false otherwise
  static Future<bool> fileExists(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      // This will throw an error if the file doesn't exist
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('File does not exist at path: $path');
        return false;
      }
      // For other Firebase errors, log and return false
      debugPrint('Error checking if file exists: ${e.message}');
      return false;
    } catch (e) {
      // For unexpected errors, log and return false
      debugPrint('Unexpected error checking if file exists: $e');
      return false;
    }
  }

  /// Safely gets a download URL for a file in Firebase Storage
  /// Returns null if the file doesn't exist or there's an error
  static Future<String?> safeGetDownloadURL(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);

      // Check if the file exists before trying to get the download URL
      if (!await fileExists(path)) {
        debugPrint('File does not exist at path: $path');
        return null;
      }

      // If we get here, the file exists, so we can get the download URL
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('File does not exist at path: $path');
      } else {
        debugPrint('Error getting download URL: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected error getting download URL: $e');
      return null;
    }
  }

  /// Gets a download URL with a fallback to a default URL if the file doesn't exist
  static Future<String> getDownloadURLWithFallback(
    String path,
    String defaultUrl,
  ) async {
    final url = await safeGetDownloadURL(path);
    return url ?? defaultUrl;
  }

  /// Ensures a directory exists in Firebase Storage by creating a placeholder file if needed
  /// Returns true if the directory exists or was created successfully
  static Future<bool> ensureDirectoryExists(String directoryPath) async {
    try {
      // Check if the directory already exists
      if (await fileExists(directoryPath)) {
        debugPrint('Directory already exists: $directoryPath');
        return true;
      }

      // Directory doesn't exist, create a placeholder file
      debugPrint('Creating directory: $directoryPath');
      final placeholderPath = '$directoryPath/.placeholder';
      final placeholderContent = Uint8List.fromList(
        utf8.encode('Directory placeholder'),
      );

      // Create the placeholder file
      try {
        final ref = FirebaseStorage.instance.ref().child(placeholderPath);
        await ref.putData(placeholderContent);
        debugPrint('Directory created successfully: $directoryPath');
        return true;
      } catch (e) {
        debugPrint('Error creating directory: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error ensuring directory exists: $e');
      return false;
    }
  }
}
