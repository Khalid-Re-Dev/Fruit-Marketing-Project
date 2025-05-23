import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/auth_service.dart';
import '../themes/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/history_screen.dart';
import '../screens/profile_screen.dart';

/// A custom drawer widget for the application that displays user information
/// and navigation options.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, _) {
            final user = authService.userModel;
            final isLoading = authService.isLoading;

            return Column(
              children: [
                // User profile header
                _buildUserHeader(context, user, isLoading),

                // Divider with gradient
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withAlpha(50),
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withAlpha(50),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Navigation items - wrapped in Expanded with SingleChildScrollView
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          _buildNavigationItem(
                            context,
                            icon: Icons.home,
                            title: 'Home',
                            onTap:
                                () => _navigateTo(context, const HomeScreen()),
                          ),
                          _buildNavigationItem(
                            context,
                            icon: Icons.favorite,
                            title: 'Favorites',
                            onTap:
                                () => _navigateTo(
                                  context,
                                  const FavoritesScreen(),
                                ),
                          ),
                          _buildNavigationItem(
                            context,
                            icon: Icons.shopping_cart,
                            title: 'Cart',
                            onTap:
                                () => _navigateTo(context, const CartScreen()),
                          ),
                          _buildNavigationItem(
                            context,
                            icon: Icons.history,
                            title: 'Order History',
                            onTap:
                                () =>
                                    _navigateTo(context, const HistoryScreen()),
                          ),
                          _buildNavigationItem(
                            context,
                            icon: Icons.person,
                            title: 'Profile',
                            onTap:
                                () =>
                                    _navigateTo(context, const ProfileScreen()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // App version
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white60 : Colors.black38,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Logout button
                _buildLogoutButton(context, authService),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the user profile header section of the drawer
  Widget _buildUserHeader(BuildContext context, user, bool isLoading) {
    return Container(
      padding: const EdgeInsets.only(top: 30, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(230),
            AppTheme.primaryColor.withAlpha(200),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // User avatar with enhanced shadow and border
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer decorative circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                ),
              ),

              // User avatar with shadow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(70),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      user?.profileImageUrl != null
                          ? CachedNetworkImageProvider(
                            user.profileImageUrl,
                            errorListener: (error) {
                              // Log the specific error for debugging
                              debugPrint('CachedNetworkImage error: $error');
                            },
                          )
                          : null,
                  onBackgroundImageError: (exception, stackTrace) {
                    debugPrint('Error loading profile image: $exception');
                    // The CircleAvatar will automatically fall back to the child widget
                    // when the backgroundImage fails to load
                  },
                  child:
                      user?.profileImageUrl == null ||
                              _isFirebaseStorageError(user.profileImageUrl)
                          ? Text(
                            user?.name?.isNotEmpty == true
                                ? user.name[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                          : null,
                ),
              ),

              // Status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // User name with animation if loading
          isLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Text(
                user?.name ?? 'Guest User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),

          const SizedBox(height: 5),

          // User email with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // User status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'Premium Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a navigation item for the drawer
  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isSelected = currentRoute.contains(title.toLowerCase());
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color:
            isSelected
                ? AppTheme.primaryColor.withAlpha(30)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          splashColor: AppTheme.primaryColor.withAlpha(50),
          highlightColor: AppTheme.primaryColor.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border:
                  isSelected
                      ? Border.all(
                        color: AppTheme.primaryColor.withAlpha(50),
                        width: 1,
                      )
                      : null,
            ),
            child: Row(
              children: [
                // Icon with animated container if selected
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryColor
                            : isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Title with custom style
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color:
                        isSelected
                            ? AppTheme.primaryColor
                            : isDarkMode
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the logout button at the bottom of the drawer
  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(isDarkMode ? 40 : 80),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Close drawer
              Navigator.pop(context);

              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('LOGOUT'),
                        ),
                      ],
                    ),
              );

              // Proceed with logout if confirmed
              if (shouldLogout == true && context.mounted) {
                await authService.signOut();

                // Show snackbar confirmation
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have been logged out'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withAlpha(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to check if a URL error is related to Firebase Storage
  bool _isFirebaseStorageError(String? url) {
    if (url == null) return false;

    // Check if the URL is a Firebase Storage URL
    final isFirebaseStorageUrl =
        url.contains('firebasestorage.googleapis.com') ||
        url.contains('firebasestorage.app');

    // If it's not a Firebase Storage URL, we don't need to check further
    if (!isFirebaseStorageUrl) return false;

    // For Firebase Storage URLs, we can check if the URL is valid
    // This is a simple check - in a real app, you might want to do more validation
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty; // This should never be true for valid URLs
    } catch (e) {
      // If parsing fails, it's definitely an error
      debugPrint('Error parsing URL: $e');
      return true;
    }

    // Note: We can't actually check if the file exists without making a network request,
    // but this method helps identify obviously malformed URLs
  }

  /// Helper method to navigate to a screen and close the drawer
  void _navigateTo(BuildContext context, Widget screen) {
    // Get the route name based on the screen type
    String routeName = '/';
    if (screen is HomeScreen) {
      routeName = '/home';
    } else if (screen is CartScreen) {
      routeName = '/cart';
    } else if (screen is FavoritesScreen) {
      routeName = '/favorites';
    } else if (screen is HistoryScreen) {
      routeName = '/history';
    } else if (screen is ProfileScreen) {
      routeName = '/profile';
    }

    Navigator.pop(context); // Close drawer

    // Use named route if available, otherwise fallback to pushReplacement
    if (routeName != '/') {
      Navigator.pushReplacementNamed(context, routeName);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }
}
