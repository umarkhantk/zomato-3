class Restaurant {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? description;
  final double rating;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final int priceRange;
  final List<String> cuisineTags;
  final bool isVeg;
  final bool isActive;
  final String address;
  final String city;
  final String? phone;
  final String openingTime;
  final String closingTime;

  const Restaurant({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.description,
    required this.rating,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.priceRange,
    required this.cuisineTags,
    required this.isVeg,
    required this.isActive,
    required this.address,
    required this.city,
    this.phone,
    required this.openingTime,
    required this.closingTime,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      deliveryTimeMin: json['delivery_time_min'] as int? ?? 30,
      deliveryTimeMax: json['delivery_time_max'] as int? ?? 45,
      priceRange: json['price_range'] as int? ?? 2,
      cuisineTags: List<String>.from(json['cuisine_tags'] ?? []),
      isVeg: json['is_veg'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String?,
      openingTime: json['opening_time'] as String? ?? '09:00',
      closingTime: json['closing_time'] as String? ?? '23:00',
    );
  }
}

class MenuCategory {
  final String id;
  final String restaurantId;
  final String name;
  final int sortOrder;

  const MenuCategory({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.sortOrder,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: json['name'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
