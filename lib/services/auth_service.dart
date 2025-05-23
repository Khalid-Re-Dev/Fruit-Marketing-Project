import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';

import '../models/user_model.dart';
import '../utils/firebase_storage_helper.dart';

class AuthService with ChangeNotifier {
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  final bool _isWindows = defaultTargetPlatform == TargetPlatform.windows;
  final Connectivity _connectivity = Connectivity();
  final Logger _logger = Logger();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  User? _firebaseUser;
  bool _isOffline = false;

  // Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result != ConnectivityResult.none;

      if (!hasConnection) {
        debugPrint('=== NO INTERNET CONNECTION ===');
        _isOffline = true;
      } else {
        _isOffline = false;
      }

      return hasConnection;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return true; // Assume online if we can't check
    }
  }

  // Demo user for Windows platform
  final UserModel _demoUser = UserModel(
    id: 'demo-user-id',
    name: 'Demo User',
    email: 'demo@example.com',
    address: '123 Demo Street',
    phoneNumber: '555-1234',
    profileImageUrl:
        'https://ui-avatars.com/api/?name=Demo+User&background=random&size=200',
  );

  UserModel? get userModel => _isWindows ? _demoUser : _user;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isWindows ? true : _user != null;

  AuthService() {
    debugPrint('=== INITIALIZING AUTH SERVICE ===');
    debugPrint('Platform: ${_isWindows ? "Windows" : "Mobile/Web"}');

    if (!_isWindows) {
      debugPrint('Initializing Firebase Auth and Firestore instances...');
      try {
        _auth = FirebaseAuth.instance;
        debugPrint('Firebase Auth initialized successfully');

        _firestore = FirebaseFirestore.instance;
        debugPrint('Firestore initialized successfully');

        _storage = FirebaseStorage.instance;
        debugPrint('Firebase Storage initialized successfully');

        _init();
      } catch (e) {
        debugPrint('=== ERROR INITIALIZING FIREBASE SERVICES ===');
        debugPrint('Error: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
      }
    } else {
      debugPrint('Running on Windows - using demo user');
      // No need to initialize Firebase on Windows
    }
    debugPrint('=== AUTH SERVICE INITIALIZATION COMPLETED ===');
  }

  Future<void> _init() async {
    debugPrint('=== SETTING UP AUTH STATE LISTENER ===');
    if (_isWindows) {
      debugPrint('Skipping auth state listener on Windows');
      return;
    }

    try {
      debugPrint('Subscribing to Firebase auth state changes...');
      _auth.authStateChanges().listen((User? firebaseUser) async {
        debugPrint('=== AUTH STATE CHANGED ===');
        debugPrint(
          'Firebase user: ${firebaseUser != null ? "EXISTS" : "NULL"}',
        );

        _firebaseUser = firebaseUser;

        if (firebaseUser != null) {
          debugPrint('User is signed in with ID: ${firebaseUser.uid}');
          debugPrint('User email: ${firebaseUser.email}');
          debugPrint('Fetching user data from Firestore...');
          await _fetchUserData(firebaseUser.uid);
        } else {
          debugPrint('User is signed out');
          _user = null;
          notifyListeners();
        }
      });
      debugPrint('Auth state listener set up successfully');
    } catch (e) {
      debugPrint('=== ERROR SETTING UP AUTH STATE LISTENER ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _fetchUserData(String uid) async {
    debugPrint('=== FETCHING USER DATA STARTED ===');
    debugPrint('Attempting to fetch user data for UID: $uid');

    if (_isWindows) {
      // On Windows, we use the demo user
      debugPrint('Using demo user on Windows platform');
      return;
    }

    // Check internet connectivity
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      debugPrint('No internet connection while fetching user data');
      _error =
          'No internet connection. Please check your network and try again.';
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Sending Firestore request to fetch user document...');

      // Add timeout to Firestore request
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Firestore request timed out');
            },
          );

      debugPrint('Firestore response received!');
      debugPrint('Document exists: ${doc.exists}');

      if (doc.exists) {
        // تأكد من أن البيانات المستردة هي Map وليست List
        final data = doc.data();
        debugPrint('Document data retrieved: ${data != null ? "YES" : "NO"}');

        if (data != null) {
          // طباعة البيانات للتصحيح
          debugPrint('User data from Firestore: $data');
          debugPrint('Data type: ${data.runtimeType}');
          debugPrint('Data fields: ${data.keys.join(', ')}');

          // تحويل البيانات بشكل آمن
          try {
            debugPrint('Attempting to create UserModel from data...');
            _user = UserModel.fromJson({'id': uid, ...data});
            debugPrint('User model created successfully');
            debugPrint('User model details: ${_user?.toJson()}');
          } catch (e) {
            debugPrint('=== ERROR PARSING USER DATA ===');
            debugPrint('Error parsing user data: $e');
            debugPrint('Stack trace: ${StackTrace.current}');
            _error = 'Error parsing user data: $e';

            // Create a basic user model even if parsing fails
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              _user = UserModel(
                id: uid,
                name:
                    currentUser.displayName ??
                    data['name'] as String? ??
                    'User',
                email: currentUser.email ?? data['email'] as String? ?? '',
                address: data['address'] as String? ?? '',
                phoneNumber: data['phoneNumber'] as String?,
                profileImageUrl: data['profileImageUrl'] as String?,
              );
              debugPrint('Created fallback user model from partial data');
            }
          }
        } else {
          _error = 'User data is null';
          debugPrint('=== ERROR: USER DATA IS NULL ===');

          // If document exists but data is null, create a basic user model
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            _user = UserModel(
              id: uid,
              name: currentUser.displayName ?? 'User',
              email: currentUser.email ?? '',
              address: '',
            );
            debugPrint('Created basic user model from Firebase Auth data');
          }
        }
      } else {
        debugPrint('=== USER DOCUMENT DOES NOT EXIST ===');
        debugPrint('Collection: users, Document ID: $uid');

        // If document doesn't exist, create a basic user model and the document
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          _user = UserModel(
            id: uid,
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            address: '',
          );

          // Optionally create the user document in Firestore
          try {
            await _firestore
                .collection('users')
                .doc(uid)
                .set(_user!.toJson()..remove('id'));
            debugPrint('Created new user document in Firestore');
          } catch (e) {
            debugPrint('Could not create user document: $e');
          }
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('=== ERROR FETCHING USER DATA ===');
      debugPrint('Error fetching user data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Create a basic user model even if Firestore fails
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _user = UserModel(
          id: uid,
          name: currentUser.displayName ?? 'User',
          email: currentUser.email ?? '',
          address: '',
        );
        debugPrint('Created basic user model from Firebase Auth data');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('=== FETCHING USER DATA COMPLETED ===');
    }
  }

  Future<bool> signIn(String email, String password) async {
    debugPrint('=== SIGN IN PROCESS STARTED ===');
    debugPrint('Attempting to sign in with email: $email');
    debugPrint(
      'Password provided: ${password.isNotEmpty ? "YES (${password.length} characters)" : "NO"}',
    );

    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_isWindows) {
      // On Windows, we simulate successful login with demo user
      debugPrint(
        'Windows platform: simulating successful login with demo user',
      );
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _isLoading = false;
      notifyListeners();
      debugPrint('=== SIGN IN SUCCESSFUL (WINDOWS SIMULATION) ===');
      return true;
    }

    // Check internet connectivity
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _error =
          'No internet connection. Please check your network and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      debugPrint('Sending authentication request to Firebase...');

      // Use try-catch specifically for the signInWithEmailAndPassword call
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        debugPrint('Firebase response received!');
        if (credential.user != null) {
          debugPrint(
            'User authenticated successfully with ID: ${credential.user!.uid}',
          );
          _firebaseUser = credential.user;

          // Try to fetch user data, but don't fail login if this fails
          try {
            await _fetchUserData(credential.user!.uid);
          } catch (dataError) {
            debugPrint('Warning: Could not fetch user data: $dataError');
            // Create a basic user model with available information
            _user = UserModel(
              id: credential.user!.uid,
              name: credential.user!.displayName ?? 'User',
              email: credential.user!.email ?? email,
              address: '',
            );
          }

          debugPrint('=== SIGN IN SUCCESSFUL ===');
          return true;
        } else {
          debugPrint(
            'Firebase returned null user despite successful authentication',
          );
          _error = 'Authentication successful but user data is null';
          return false;
        }
      } catch (authError) {
        // Handle the specific type casting error
        if (authError.toString().contains('type \'List<Object?>\'') ||
            authError.toString().contains('PigeonUserDetails')) {
          debugPrint(
            'Caught type casting error, attempting alternative authentication approach',
          );

          // The user is actually authenticated, but there's an error in the response handling
          // Get the current user as a workaround
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            debugPrint('Current user found: ${currentUser.uid}');
            _firebaseUser = currentUser;

            // Create a basic user model with available information
            _user = UserModel(
              id: currentUser.uid,
              name: currentUser.displayName ?? 'User',
              email: currentUser.email ?? email,
              address: '',
            );

            debugPrint('=== SIGN IN SUCCESSFUL (WORKAROUND) ===');
            return true;
          }
        }

        // Re-throw if the workaround didn't help
        rethrow;
      }
    } catch (e) {
      debugPrint('=== SIGN IN FAILED ===');
      debugPrint('Error during authentication: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign in process completed (success or failure)');
    }
  }

  Future<bool> signUp(UserModel user, String password) async {
    debugPrint('=== SIGN UP PROCESS STARTED ===');
    debugPrint('User data: ${user.toJson()}');
    debugPrint('Password length: ${password.length} characters');

    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_isWindows) {
      // On Windows, we simulate successful registration with demo user
      debugPrint('Windows platform: simulating successful registration');
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _isLoading = false;
      notifyListeners();
      debugPrint('=== SIGN UP SUCCESSFUL (WINDOWS SIMULATION) ===');
      return true;
    }

    // Check internet connectivity
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      _error =
          'No internet connection. Please check your network and try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      debugPrint('Creating Firebase Auth user account...');

      // Use try-catch specifically for the createUserWithEmailAndPassword call
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: user.email,
          password: password,
        );

        debugPrint('Firebase Auth response received!');
        if (credential.user != null) {
          debugPrint(
            'User created successfully with ID: ${credential.user!.uid}',
          );
          _firebaseUser = credential.user;

          // Create user document in Firestore
          try {
            debugPrint('Creating user document in Firestore...');
            final userWithId = user.copyWith(id: credential.user!.uid);
            final userData = userWithId.toJson()..remove('id');

            debugPrint('User data to save: $userData');
            await _firestore
                .collection('users')
                .doc(credential.user!.uid)
                .set(userData)
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException('Firestore request timed out');
                  },
                );

            debugPrint('User document created successfully');
          } catch (firestoreError) {
            // If Firestore fails, we still have a valid user in Firebase Auth
            debugPrint(
              'Warning: Could not create Firestore document: $firestoreError',
            );
            // We'll continue with the registration process
          }

          // Set the user model even if Firestore fails
          _user = user.copyWith(id: credential.user!.uid);

          // Try to fetch user data to confirm, but don't fail if this fails
          try {
            debugPrint('Fetching user data to confirm creation...');
            await _fetchUserData(credential.user!.uid);
          } catch (fetchError) {
            debugPrint('Warning: Could not fetch user data: $fetchError');
            // We already have a user model, so we can continue
          }

          debugPrint('=== SIGN UP SUCCESSFUL ===');
          return true;
        } else {
          debugPrint('=== SIGN UP FAILED: NULL USER RETURNED ===');
          _error = 'Registration successful but user data is null';
          return false;
        }
      } catch (authError) {
        // Handle specific Firebase Auth errors
        if (authError is FirebaseAuthException) {
          switch (authError.code) {
            case 'email-already-in-use':
              _error =
                  'The email address is already in use by another account.';
              break;
            case 'weak-password':
              _error = 'The password is too weak.';
              break;
            case 'invalid-email':
              _error = 'The email address is not valid.';
              break;
            default:
              _error =
                  authError.message ?? 'An error occurred during registration.';
          }
        } else {
          // Re-throw other errors
          rethrow;
        }
        return false;
      }
    } catch (e) {
      debugPrint('=== SIGN UP FAILED ===');
      debugPrint('Error during registration: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('Sign up process completed (success or failure)');
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    if (_isWindows) {
      // On Windows, we simulate sign out
      debugPrint('Windows platform: simulating sign out');
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await _auth.signOut();
      _user = null;
      _firebaseUser = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_isWindows) {
      // On Windows, we simulate profile update
      debugPrint('Windows platform: simulating profile update');
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.toJson()..remove('id'));
      _user = updatedUser;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optimized profile image upload with compression and immediate UI update
  Future<bool> uploadProfileImage(
    File imageFile,
    String userId, {
    String? localImagePath,
  }) async {
    // Don't set global loading state to true - we'll handle loading UI in the widget
    _error = null;

    // Update the user model immediately with local image path for instant UI feedback
    if (localImagePath != null && _user != null) {
      // Create a temporary URL for the local image that will be shown immediately
      final tempUrl = 'file://$localImagePath';
      final tempUpdatedUser = _user!.copyWith(
        profileImageUrl: tempUrl,
        hasLocalImage: true, // Flag to indicate this is a local image
      );

      // Update local user model immediately for responsive UI
      _user = tempUpdatedUser;
      notifyListeners();
    }

    if (_isWindows) {
      // On Windows, we simulate image upload but make it faster
      debugPrint('Windows platform: simulating profile image upload');
      await Future.delayed(
        const Duration(milliseconds: 500), // Reduced delay for better UX
      );

      // Generate a unique avatar URL for Windows users
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userName = _demoUser.name.replaceAll(' ', '+');
      final avatarUrl =
          'https://ui-avatars.com/api/?name=$userName&background=random&size=400&cache=$timestamp';

      // Update the demo user with the avatar URL
      final updatedUser = _demoUser.copyWith(
        profileImageUrl: avatarUrl,
        hasLocalImage: false,
      );
      _user = updatedUser;
      notifyListeners();
      return true;
    }

    try {
      // Check internet connectivity in background
      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        _error =
            'No internet connection. Please check your network and try again.';
        notifyListeners();
        return false;
      }

      // Create a reference to the file location in Firebase Storage
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Ensure the profile_images directory exists
      final storageRef = _storage.ref().child('profile_images').child(fileName);

      // Upload the file with metadata for caching
      debugPrint('Uploading image to Firebase Storage...');
      final metadata = SettableMetadata(
        contentType:
            'image/${path.extension(imageFile.path).replaceFirst('.', '')}',
        customMetadata: {'userId': userId},
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      try {
        // First, check if the directory exists
        try {
          // Try to get metadata for the directory to check if it exists
          await _storage.ref().child('profile_images').getMetadata();
          debugPrint('profile_images directory exists');
        } catch (dirError) {
          // If directory doesn't exist, we'll handle it by using the root path
          if (dirError is FirebaseException &&
              dirError.code == 'object-not-found') {
            debugPrint(
              'profile_images directory does not exist, will use root path',
            );
            // We'll continue with the upload, but we'll use a different path later
          } else {
            // For other errors, log and continue
            debugPrint('Error checking directory: $dirError');
          }
        }

        // Start upload in background
        final uploadTask = storageRef.putFile(imageFile, metadata);

        // Set up a listener for upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint(
            'Upload progress: ${(progress * 100).toStringAsFixed(2)}%',
          );
        });

        // Wait for the upload to complete
        final snapshot = await uploadTask;

        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('Image uploaded successfully. URL: $downloadUrl');

        // Update the user profile with the new image URL
        if (_user != null) {
          final updatedUser = _user!.copyWith(
            profileImageUrl: downloadUrl,
            hasLocalImage: false, // Reset the local image flag
          );

          // Update Firestore in background - make sure to use the correct collection name
          try {
            debugPrint('Updating user document in Firestore...');
            await _firestore.collection('users').doc(userId).update({
              'profileImageUrl': downloadUrl,
              'hasLocalImage': false,
            });
            debugPrint('Firestore update successful');
          } catch (firestoreError) {
            // If update fails, try to set the document instead (it might not exist yet)
            debugPrint(
              'Firestore update failed, trying to set document instead: $firestoreError',
            );
            await _firestore.collection('users').doc(userId).set({
              'id': userId,
              'profileImageUrl': downloadUrl,
              'hasLocalImage': false,
              'name': _user!.name,
              'email': _user!.email,
              'address': _user!.address,
              'phoneNumber': _user!.phoneNumber,
            }, SetOptions(merge: true));
            debugPrint('Firestore set with merge successful');
          }

          // Update local user model
          _user = updatedUser;
          notifyListeners();
          debugPrint('User profile updated with new image URL');
        } else {
          throw Exception('User not authenticated');
        }

        return true;
      } catch (storageError) {
        // Handle specific Firebase Storage errors
        if (storageError is FirebaseException &&
            storageError.code == 'object-not-found') {
          debugPrint(
            'Storage error: object-not-found. Using root reference instead...',
          );

          // Try a different approach - use root reference
          final rootRef = _storage.ref();
          final newFileName =
              'user_profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
          final newStorageRef = rootRef.child(newFileName);

          try {
            // Try upload again with the root reference
            final uploadTask = newStorageRef.putFile(imageFile, metadata);

            // Set up a listener for upload progress
            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              final progress = snapshot.bytesTransferred / snapshot.totalBytes;
              debugPrint(
                'Upload progress (retry): ${(progress * 100).toStringAsFixed(2)}%',
              );
            });

            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();
            debugPrint(
              'Image uploaded successfully with root reference. URL: $downloadUrl',
            );

            // Update user with the new URL
            if (_user != null) {
              final updatedUser = _user!.copyWith(
                profileImageUrl: downloadUrl,
                hasLocalImage: false,
              );

              // Update Firestore
              await _firestore.collection('users').doc(userId).update({
                'profileImageUrl': downloadUrl,
                'hasLocalImage': false,
              });

              // Update local model
              _user = updatedUser;
              notifyListeners();
              return true;
            }
          } catch (retryError) {
            debugPrint('Error during retry upload: $retryError');
            rethrow; // Re-throw to be caught by the outer catch
          }
        }

        // If we get here, rethrow the error
        rethrow;
      }
    } catch (e) {
      _logger.e('Error uploading profile image: $e');
      debugPrint('Error uploading profile image: $e');

      // Provide a more user-friendly error message
      if (e is FirebaseException) {
        switch (e.code) {
          case 'object-not-found':
            _error =
                'Storage location not found. The system will create it automatically on retry.';
            debugPrint(
              'Firebase Storage object-not-found error. Code: ${e.code}',
            );
            break;
          case 'unauthorized':
            _error = 'You don\'t have permission to upload images.';
            break;
          case 'canceled':
            _error = 'Image upload was canceled.';
            break;
          default:
            _error = 'Firebase error: ${e.message ?? e.code}';
        }
      } else if (e.toString().contains('object-not-found')) {
        // Fallback for cases where the exception isn't properly typed
        _error = 'Storage location not found. Please try again.';
      } else if (e.toString().contains('unauthorized')) {
        _error = 'You don\'t have permission to upload images.';
      } else if (e.toString().contains('canceled')) {
        _error = 'Image upload was canceled.';
      } else {
        _error = 'Failed to upload image: ${e.toString()}';
      }

      notifyListeners();
      return false;
    }
  }

  Future<bool> checkAuthentication() async {
    debugPrint('=== CHECKING AUTHENTICATION STATUS ===');

    if (_isWindows) {
      // On Windows, we simulate authentication check
      debugPrint('Windows platform: simulating authentication check');
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Simulate network delay
      debugPrint('=== AUTHENTICATION CHECK COMPLETED (WINDOWS SIMULATION) ===');
      return true; // Always return true on Windows for demo purposes
    }

    // Check internet connectivity - but don't fail if offline
    // We can still check local auth state
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      debugPrint('No internet connection during authentication check');
      // We'll continue with local checks
    }

    try {
      // Check if user is already authenticated
      debugPrint('Checking if user model already exists in memory...');
      if (_user != null) {
        debugPrint('User is already authenticated in memory');
        debugPrint('User ID: ${_user!.id}');
        debugPrint(
          '=== AUTHENTICATION CHECK COMPLETED: ALREADY AUTHENTICATED ===',
        );
        return true;
      }

      // Check if there's a current Firebase user
      debugPrint('Checking Firebase authentication state...');
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        debugPrint('Firebase user found in current session');
        debugPrint('Firebase User ID: ${currentUser.uid}');
        debugPrint('Firebase User Email: ${currentUser.email}');
        debugPrint(
          'Firebase User Email Verified: ${currentUser.emailVerified}',
        );

        _firebaseUser = currentUser;

        // If we're offline, create a basic user model
        if (!hasConnection) {
          debugPrint(
            'Offline mode: creating basic user model from Firebase Auth',
          );
          _user = UserModel(
            id: currentUser.uid,
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            address: '',
          );
          debugPrint(
            '=== AUTHENTICATION CHECK COMPLETED: AUTHENTICATED (OFFLINE) ===',
          );
          return true;
        }

        // Fetch user data if we have a Firebase user but no user model
        debugPrint(
          'Firebase user exists but no user model - fetching user data...',
        );

        try {
          await _fetchUserData(currentUser.uid);

          final result = _user != null;
          debugPrint(
            'User data fetch result: ${result ? "SUCCESS" : "FAILED"}',
          );

          if (!result) {
            // If fetching data failed but we have a Firebase user, create a basic user model
            _user = UserModel(
              id: currentUser.uid,
              name: currentUser.displayName ?? 'User',
              email: currentUser.email ?? '',
              address: '',
            );
            debugPrint('Created basic user model from Firebase Auth data');
            debugPrint(
              '=== AUTHENTICATION CHECK COMPLETED: AUTHENTICATED (FALLBACK) ===',
            );
            return true;
          }

          debugPrint('=== AUTHENTICATION CHECK COMPLETED: AUTHENTICATED ===');
          return true;
        } catch (fetchError) {
          debugPrint('Error fetching user data: $fetchError');
          // If fetching data failed but we have a Firebase user, create a basic user model
          _user = UserModel(
            id: currentUser.uid,
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            address: '',
          );
          debugPrint('Created basic user model from Firebase Auth data');
          debugPrint(
            '=== AUTHENTICATION CHECK COMPLETED: AUTHENTICATED (FALLBACK) ===',
          );
          return true;
        }
      }

      debugPrint('No Firebase user found in current session');
      debugPrint('=== AUTHENTICATION CHECK COMPLETED: NOT AUTHENTICATED ===');
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('=== ERROR CHECKING AUTHENTICATION ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Even if there's an error, check if we have a Firebase user
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          // We have a Firebase user, so create a basic user model
          _user = UserModel(
            id: currentUser.uid,
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            address: '',
          );
          debugPrint(
            'Created basic user model from Firebase Auth data despite error',
          );
          debugPrint(
            '=== AUTHENTICATION CHECK COMPLETED: AUTHENTICATED (ERROR RECOVERY) ===',
          );
          return true;
        }
      } catch (_) {
        // Ignore errors in the error handler
      }

      return false;
    }
  }
}
