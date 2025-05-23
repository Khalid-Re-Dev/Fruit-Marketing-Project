import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/food_item_model.dart';

/// A card widget that displays food item information with hover effects and favorite functionality.
///
/// This widget is optimized for performance and responsiveness, with hover detection
/// for desktop platforms and immediate UI feedback for user interactions.
class FoodItemCard extends StatefulWidget {
  final FoodItem foodItem;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const FoodItemCard({
    super.key,
    required this.foodItem,
    required this.onTap,
    required this.onAddToCart,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(onTap: widget.onTap, child: _buildCard()),
    );
  }

  /// Builds the main card with all its components
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26), // 0.1 opacity = 26/255
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildImageSection(), _buildDetailsSection()],
      ),
    );
  }

  /// Builds the image section with favorite button overlay
  Widget _buildImageSection() {
    return Stack(
      children: [
        // Food image with caching for better performance
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          child: CachedNetworkImage(
            imageUrl: widget.foodItem.imageUrl,
            height: 110,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder:
                (context, url) => Container(
                  height: 110,
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
                ),
            errorWidget:
                (context, url, error) => Container(
                  height: 110,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
          ),
        ),
        // Favorite button - always shown but with different opacity based on state
        if (widget.onToggleFavorite != null)
          Positioned(top: 5, right: 5, child: _buildFavoriteButton()),
      ],
    );
  }

  /// Builds the favorite button with animation
  Widget _buildFavoriteButton() {
    // Determine opacity based on hover state and favorite status
    final double opacity = widget.isFavorite ? 1.0 : (_isHovering ? 0.8 : 0.5);

    return GestureDetector(
      onTap: widget.onToggleFavorite,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(204), // 0.8 opacity
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey<bool>(widget.isFavorite),
            color:
                widget.isFavorite
                    ? Colors.red
                    : Colors.grey.withAlpha((opacity * 255).toInt()),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Builds the details section with name, price and add to cart button
  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.foodItem.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'view details',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs. ${widget.foodItem.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              _buildAddToCartButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the add to cart button with hover effect
  Widget _buildAddToCartButton() {
    return GestureDetector(
      onTap: widget.onAddToCart,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}
