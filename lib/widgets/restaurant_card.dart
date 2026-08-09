import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/restaurant.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/restaurant/${restaurant.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D2D3E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: restaurant.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: restaurant.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF2D2D3E),
                          child: const Center(
                            child: Icon(Icons.restaurant,
                                color: Colors.white24, size: 40),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF2D2D3E),
                          child: const Center(
                            child: Icon(Icons.restaurant,
                                color: Colors.white24, size: 40),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF2D2D3E),
                        child: const Center(
                          child: Icon(Icons.restaurant,
                              color: Colors.white24, size: 40),
                        ),
                      ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Veg Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant.isVeg)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'VEG',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Cuisine tags
                  Text(
                    restaurant.cuisineTags.take(3).join(', '),
                    style: const TextStyle(
                        color: Color(0xFF8A8A9A), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Rating, Time, Price
                  Row(
                    children: [
                      _infoChip(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        label: restaurant.rating.toStringAsFixed(1),
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        icon: Icons.access_time_rounded,
                        iconColor: const Color(0xFFE23744),
                        label:
                            '${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax} min',
                      ),
                      const SizedBox(width: 8),
                      _infoChip(
                        icon: Icons.currency_rupee,
                        iconColor: const Color(0xFF8A8A9A),
                        label:
                            '₹${restaurant.priceRange * 200} for two',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB0B0C0), fontSize: 12),
        ),
      ],
    );
  }
}
