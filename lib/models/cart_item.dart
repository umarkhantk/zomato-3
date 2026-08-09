import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toJson() => {
        'id': menuItem.id,
        'name': menuItem.name,
        'price': menuItem.price,
        'image_url': menuItem.imageUrl,
        'quantity': quantity,
        'restaurant_id': menuItem.restaurantId,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItem: MenuItem(
        id: json['id'] as String,
        restaurantId: json['restaurant_id'] as String,
        categoryId: '',
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'] as String?,
        isVeg: false,
        isAvailable: true,
        sortOrder: 0,
      ),
      quantity: json['quantity'] as int,
    );
  }
}
