import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Restaurant restaurant;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final quantity = cart.getQuantity(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Veg/Non-veg indicator
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: item.isVeg ? Colors.green : Colors.red,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.isVeg ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8A9A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Image + Add button
          Column(
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),

              const SizedBox(height: 8),

              // Add / Quantity controls
              quantity == 0
                  ? _addButton(context, cart)
                  : _quantityControl(context, cart, quantity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addButton(BuildContext context, CartProvider cart) {
    return GestureDetector(
      onTap: () {
        final error = cart.addItem(item, restaurant);
        if (error != null) {
          _showRestaurantConflictDialog(context, cart, error);
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade700),
        ),
        child: const Text(
          'ADD',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _quantityControl(
      BuildContext context, CartProvider cart, int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => cart.updateQuantity(item.id, quantity - 1),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Icon(Icons.remove, color: Colors.green, size: 16),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () => cart.addItem(item, restaurant),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Icon(Icons.add, color: Colors.green, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFF2D2D3E),
      child: const Center(
        child: Icon(Icons.fastfood, color: Colors.white24, size: 30),
      ),
    );
  }

  void _showRestaurantConflictDialog(
      BuildContext context, CartProvider cart, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Start New Order?',
            style: TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Color(0xFF8A8A9A))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8A8A9A))),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              cart.addItem(item, restaurant);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE23744)),
            child: const Text('Clear & Add'),
          ),
        ],
      ),
    );
  }
}
