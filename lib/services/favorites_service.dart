import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

import '../models/food_item_model.dart';

class FavoritesService extends ChangeNotifier {
  final Logger _logger = Logger();
  List<FoodItem> _favorites = [];
  bool _isLoading = false;
  final bool _isWindows = defaultTargetPlatform == TargetPlatform.windows;

  List<FoodItem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isEmpty => _favorites.isEmpty;
  int get itemCount => _favorites.length;

  FavoritesService() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isWindows) {
        // On Windows, we use demo data
        debugPrint('Windows platform: using demo favorites data');
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Simulate loading

        // Add some demo items to favorites
        _favorites = [
          FoodItem(
            id: 'demo-1',
            name: 'Burger',
            description: 'Delicious burger with cheese',
            price: 8.99,
            imageUrl:
                'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
            categories: ['Fast Food', 'Burgers'],
            rating: 4.5,
            reviewCount: 120,
          ),
          FoodItem(
            id: 'demo-3',
            name: 'Sushi',
            description: 'Fresh sushi with wasabi',
            price: 15.99,
            imageUrl:
                'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
            categories: ['Japanese', 'Seafood'],
            rating: 4.9,
            reviewCount: 95,
          ),
        ];
      } else {
        final prefs = await SharedPreferences.getInstance();
        final favoritesJson = prefs.getString('favorites');

        if (favoritesJson != null) {
          final List<dynamic> decodedData = jsonDecode(favoritesJson);
          _favorites =
              decodedData.map((item) => FoodItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      _logger.e('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    if (_isWindows) {
      // On Windows, we just log the action
      debugPrint('Windows platform: simulating favorites save');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(
        _favorites.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('favorites', favoritesJson);
    } catch (e) {
      _logger.e('Error saving favorites: $e');
    }
  }

  void addToFavorites(FoodItem foodItem) {
    if (!isFavorite(foodItem.id)) {
      _favorites.add(foodItem);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFromFavorites(String foodItemId) {
    _favorites.removeWhere((item) => item.id == foodItemId);
    _saveFavorites();
    notifyListeners();
  }

  // Optimized toggle favorite with immediate UI update
  void toggleFavorite(FoodItem foodItem) {
    final bool wasAlreadyFavorite = isFavorite(foodItem.id);

    // Update state immediately for responsive UI
    if (wasAlreadyFavorite) {
      _favorites.removeWhere((item) => item.id == foodItem.id);
    } else {
      _favorites.add(foodItem);
    }

    // Notify listeners immediately to update UI
    notifyListeners();

    // Save changes in background
    _saveFavorites();
  }

  bool isFavorite(String foodItemId) {
    return _favorites.any((item) => item.id == foodItemId);
  }

  void clearFavorites() {
    _favorites = [];
    _saveFavorites();
    notifyListeners();
  }
}
