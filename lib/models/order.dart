class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String itemName;
  final double itemPrice;
  final int quantity;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.itemName,
    required this.itemPrice,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      itemName: json['item_name'] as String,
      itemPrice: (json['item_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  double get totalPrice => itemPrice * quantity;
}

class Order {
  final String id;
  final String customerId;
  final String restaurantId;
  final String addressId;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double total;
  final String paymentMethod;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItem> items;
  final Map<String, dynamic>? restaurant;
  final Map<String, dynamic>? address;

  const Order({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.addressId,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.items,
    this.restaurant,
    this.address,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      addressId: json['address_id'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      status: json['status'] as String? ?? 'placed',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      restaurant: json['restaurant'] as Map<String, dynamic>?,
      address: json['address'] as Map<String, dynamic>?,
    );
  }

  String get displayStatus => status.replaceAll('_', ' ');

  bool get isActive => !['delivered', 'cancelled'].contains(status);
}
