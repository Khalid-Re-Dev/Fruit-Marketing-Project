import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

import '../models/cart_item_model.dart';
import '../models/food_item_model.dart';

class CartService extends ChangeNotifier {
  final Logger _logger = Logger();
  List<CartItem> _items = [];
  bool _isLoading = false;
  final bool _isWindows = defaultTargetPlatform == TargetPlatform.windows;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(
    0,
    (sum, item) => sum + (item.foodItem.price * item.quantity),
  );

  CartService() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isWindows) {
        // On Windows, we use demo data
        debugPrint('Windows platform: using demo cart data');
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Simulate loading

        // Add some demo items to the cart
        _items = [
          CartItem(
            foodItem: FoodItem(
              id: 'demo-1',
              name: 'Burger',
              description: 'Delicious burger with cheese',
              price: 8.99,
              imageUrl: 'assets/images/burger.jpg',
              categories: ['Fast Food', 'Burgers'],
              rating: 4.5,
              reviewCount: 120,
            ),
            quantity: 2,
          ),
          CartItem(
            foodItem: FoodItem(
              id: 'demo-2',
              name: 'Pizza',
              description: 'Pepperoni pizza with extra cheese',
              price: 12.99,
              imageUrl: 'assets/images/pizza.jpg',
              categories: ['Italian', 'Pizza'],
              rating: 4.8,
              reviewCount: 85,
            ),
            quantity: 1,
          ),
        ];
      } else {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString('cart');

        if (cartJson != null) {
          final List<dynamic> decodedData = jsonDecode(cartJson);
          _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
        }
      }
    } catch (e) {
      _logger.e('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    if (_isWindows) {
      // On Windows, we just log the action
      debugPrint('Windows platform: simulating cart save');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('cart', cartJson);
    } catch (e) {
      _logger.e('Error saving cart: $e');
    }
  }

  void addItem(FoodItem foodItem) {
    final existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItem.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(foodItem: foodItem));
    }

    _saveCart();
    notifyListeners();
  }

  void removeItem(String foodItemId) {
    _items.removeWhere((item) => item.foodItem.id == foodItemId);
    _saveCart();
    notifyListeners();
  }

  void decreaseQuantity(String foodItemId) {
    final existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItemId,
    );

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity -= 1;
      } else {
        _items.removeAt(existingIndex);
      }

      _saveCart();
      notifyListeners();
    }
  }

  void increaseQuantity(String foodItemId) {
    final existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItemId,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items = [];
    _saveCart();
    notifyListeners();
  }

  void toggleFavorite(String foodItemId) {
    // This would typically interact with a separate favorites service
    _logger.i('Toggle favorite for item: $foodItemId');
  }
}
