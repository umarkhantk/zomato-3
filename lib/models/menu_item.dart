class MenuItem {
  final String id;
  final String restaurantId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isVeg;
  final bool isAvailable;
  final int sortOrder;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isVeg,
    required this.isAvailable,
    required this.sortOrder,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      isVeg: json['is_veg'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
