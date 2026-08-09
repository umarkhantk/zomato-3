import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/address.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order
  Future<Order?> createOrder({
    required String customerId,
    required String restaurantId,
    required String addressId,
    required double subtotal,
    required double deliveryFee,
    required double tax,
    required double total,
    required String paymentMethod,
    required List<CartItem> cartItems,
    String? notes,
  }) async {
    final orderData = await _supabase
        .from('orders')
        .insert({
          'customer_id': customerId,
          'restaurant_id': restaurantId,
          'address_id': addressId,
          'subtotal': subtotal,
          'delivery_fee': deliveryFee,
          'tax': tax,
          'total': total,
          'payment_method': paymentMethod,
          'notes': notes,
          'status': 'placed',
        })
        .select()
        .single();

    final order = Order.fromJson({...orderData, 'items': []});

    final orderItems = cartItems
        .map((ci) => {
              'order_id': order.id,
              'menu_item_id': ci.menuItem.id,
              'item_name': ci.menuItem.name,
              'item_price': ci.menuItem.price,
              'quantity': ci.quantity,
            })
        .toList();

    await _supabase.from('order_items').insert(orderItems);

    return order;
  }

  /// Fetch all orders for a user
  Future<List<Order>> fetchUserOrders(String userId) async {
    final data = await _supabase
        .from('orders')
        .select('*, restaurant:restaurants(name, image_url), items:order_items(*)')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);

    return data.map((e) => Order.fromJson(e)).toList();
  }

  /// Fetch single order by ID
  Future<Order?> fetchOrderById(String orderId) async {
    final data = await _supabase
        .from('orders')
        .select(
            '*, restaurant:restaurants(name, address, phone), items:order_items(*), address:addresses(*)')
        .eq('id', orderId)
        .maybeSingle();

    if (data == null) return null;
    return Order.fromJson(data);
  }

  /// Subscribe to real-time order status updates
  RealtimeChannel subscribeToOrder(
      String orderId, void Function(Map<String, dynamic>) onUpdate) {
    return _supabase
        .channel('order_$orderId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Fetch saved addresses for a user
  Future<List<Address>> fetchAddresses(String userId) async {
    final data = await _supabase
        .from('addresses')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((e) => Address.fromJson(e)).toList();
  }

  /// Add a new address
  Future<Address?> addAddress({
    required String userId,
    required String label,
    required String addressLine,
    required String city,
    required String pincode,
    required bool isDefault,
  }) async {
    final data = await _supabase
        .from('addresses')
        .insert({
          'user_id': userId,
          'label': label,
          'address_line': addressLine,
          'city': city,
          'pincode': pincode,
          'is_default': isDefault,
        })
        .select()
        .single();

    return Address.fromJson(data);
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    await _supabase.from('addresses').delete().eq('id', addressId);
  }
}
