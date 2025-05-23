import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/food_item_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/food_service.dart';
import '../widgets/category_card.dart';
import '../widgets/food_item_card.dart';
import '../widgets/app_drawer.dart';
import 'cart_screen.dart';
import 'error_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'food_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _logger = Logger();
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _foodItems = [];
  List<FoodItem> _filteredItems = [];
  bool _isLoading = true;
  String _error = '';
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.restaurant},
    {'name': 'Pizza', 'icon': Icons.local_pizza},
    {'name': 'Burger', 'icon': Icons.lunch_dining},
    {'name': 'Sushi', 'icon': Icons.set_meal},
    {'name': 'Dessert', 'icon': Icons.icecream},
    {'name': 'Drinks', 'icon': Icons.local_drink},
  ];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodItems() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final items = await _foodService.getFoodItems();
      setState(() {
        _foodItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Failed to load food items: $e');
      setState(() {
        _error = 'Failed to load food items: $e';
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredItems = _foodItems;
      } else {
        _filteredItems =
            _foodItems
                .where((item) => item.categories.contains(category))
                .toList();
      }
    });
  }

  void _searchItems(String query) {
    if (query.isEmpty) {
      _filterByCategory(_selectedCategory);
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredItems =
          _foodItems.where((item) {
            return item.name.toLowerCase().contains(lowercaseQuery) ||
                item.description.toLowerCase().contains(lowercaseQuery);
          }).toList();
    });
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return ErrorScreen(message: _error, onRetry: _loadFoodItems);
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Item not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Try searching the item with\na different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filterByCategory('All');
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CategoryCard(
                name: category['name'],
                icon: category['icon'],
                isSelected: _selectedCategory == category['name'],
                onTap: () => _filterByCategory(category['name']),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Popular items title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Popular Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),

        // Food items grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];

              // Use Consumer for FavoritesService to automatically rebuild when favorites change
              return Consumer<FavoritesService>(
                builder: (context, favoritesService, _) {
                  final isFavorite = favoritesService.isFavorite(item.id);

                  return FoodItemCard(
                    foodItem: item,
                    isFavorite: isFavorite,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FoodDetailScreen(foodItem: item),
                        ),
                      );
                    },
                    onAddToCart: () {
                      final cartService = Provider.of<CartService>(
                        context,
                        listen: false,
                      );
                      cartService.addItem(item);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} added to cart'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'View Cart',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    onToggleFavorite: () {
                      // Toggle favorite state - UI will update automatically via Consumer
                      favoritesService.toggleFavorite(item);

                      // Show feedback to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? '${item.name} removed from favorites'
                                : '${item.name} added to favorites',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
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

  // Handle back button press
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // If not on home tab, go to home tab instead of exiting
      setState(() {
        _currentIndex = 0;
      });
      return false;
    }

    // If on home tab, show exit confirmation or exit
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    // Using WillPopScope for simplicity and compatibility
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title:
              _currentIndex == 0
                  ? TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _searchItems,
                  )
                  : Text(
                    _currentIndex == 1
                        ? 'Cart'
                        : _currentIndex == 2
                        ? 'Favorites'
                        : 'History',
                  ),
          actions: [
            if (_currentIndex == 0)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Builder(
                    builder: (context) {
                      final authService = Provider.of<AuthService>(context);
                      final user = authService.userModel;

                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26), // 0.1 opacity
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              user?.profileImageUrl != null
                                  ? CachedNetworkImageProvider(
                                    user!.profileImageUrl!,
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
                            // We'll handle this with the child fallback
                          },
                          child:
                              user?.profileImageUrl == null ||
                                      _isFirebaseStorageError(
                                        user?.profileImageUrl,
                                      )
                                  ? Text(
                                    user != null && user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildBody(),
            const CartScreen(),
            const FavoritesScreen(),
            const HistoryScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon:
                  cartService.itemCount > 0
                      ? Badge.count(
                        count: cartService.itemCount,
                        child: const Icon(Icons.shopping_cart_outlined),
                      )
                      : const Icon(Icons.shopping_cart_outlined),
              activeIcon:
                  cartService.itemCount > 0
                      ? Badge.count(
                        count: cartService.itemCount,
                        child: const Icon(Icons.shopping_cart),
                      )
                      : const Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
