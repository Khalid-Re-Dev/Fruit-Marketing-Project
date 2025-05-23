import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';

import '../models/food_item_model.dart';

class FoodService {
  final Logger _logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get food items from Firestore
  Future<List<FoodItem>> getFoodItems() async {
    try {
      // Try to get from Firestore first
      final snapshot = await _firestore.collection('food_items').get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => FoodItem.fromJson({'id': doc.id, ...doc.data()}))
            .toList();
      } else {
        // If Firestore is empty or unavailable, use local JSON
        return await getLocalFoodItems();
      }
    } catch (e) {
      _logger.e('Error fetching food items: $e');
      // Fallback to local data
      return await getLocalFoodItems();
    }
  }

  // Get food items from local JSON file
  Future<List<FoodItem>> getLocalFoodItems() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/json/food_items.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((item) => FoodItem.fromJson(item)).toList();
    } catch (e) {
      _logger.e('Error loading local food items: $e');
      return [];
    }
  }

  // Search food items
  Future<List<FoodItem>> searchFoodItems(String query) async {
    if (query.isEmpty) {
      return await getFoodItems();
    }

    try {
      final allItems = await getFoodItems();
      final lowercaseQuery = query.toLowerCase();

      return allItems.where((item) {
        return item.name.toLowerCase().contains(lowercaseQuery) ||
            item.description.toLowerCase().contains(lowercaseQuery) ||
            item.categories.any(
              (category) => category.toLowerCase().contains(lowercaseQuery),
            );
      }).toList();
    } catch (e) {
      _logger.e('Error searching food items: $e');
      return [];
    }
  }

  // Get food items by category
  Future<List<FoodItem>> getFoodItemsByCategory(String category) async {
    try {
      final allItems = await getFoodItems();

      return allItems.where((item) {
        return item.categories.contains(category);
      }).toList();
    } catch (e) {
      _logger.e('Error getting food items by category: $e');
      return [];
    }
  }
}
