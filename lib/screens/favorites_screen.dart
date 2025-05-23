import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../models/food_item_model.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/food_item_card.dart';
import '../widgets/app_drawer.dart';
import 'food_detail_screen.dart'; // Import the food detail screen

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesService = Provider.of<FavoritesService>(context);
    final cartService = Provider.of<CartService>(context, listen: false);

    if (favoritesService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favoritesService.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 100, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'No favorites yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add items to your favorites\nto see them here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Start browsing',
              onPressed: () {
                // Navigate to home tab
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap on an item to view details, or tap the + button to add to cart',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: favoritesService.favorites.length,
              itemBuilder: (context, index) {
                final item = favoritesService.favorites[index];
                return FoodItemCard(
                  foodItem: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodDetailScreen(foodItem: item),
                      ),
                    );
                  },
                  onAddToCart: () {
                    cartService.addItem(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to cart'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'View Cart',
                          onPressed: () {
                            // Switch to cart tab
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                              // This would be handled by the parent widget to switch to cart tab
                            }
                          },
                        ),
                      ),
                    );
                  },
                  isFavorite: true,
                  onToggleFavorite: () {
                    // Use toggleFavorite instead of removeFromFavorites for consistency
                    favoritesService.toggleFavorite(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} removed from favorites'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
