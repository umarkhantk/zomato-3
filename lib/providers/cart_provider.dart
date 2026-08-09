import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  Restaurant? _restaurant;

  static const double _deliveryFee = 40.0;
  static const double _taxRate = 0.05; // 5% GST

  List<CartItem> get items => _items;
  Restaurant? get restaurant => _restaurant;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get deliveryFee => _items.isEmpty ? 0.0 : _deliveryFee;
  double get tax => subtotal * _taxRate;
  double get total => subtotal + tax + deliveryFee;

  CartProvider() {
    _loadFromPrefs();
  }

  /// Add item to cart. Returns error string if from different restaurant.
  String? addItem(MenuItem item, Restaurant rest) {
    // Check if from a different restaurant
    if (_restaurant != null &&
        _restaurant!.id != rest.id &&
        _items.isNotEmpty) {
      return 'You can only order from one restaurant at a time. Clear cart to start a new order.';
    }

    _restaurant = rest;

    final existingIndex =
        _items.indexWhere((ci) => ci.menuItem.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(menuItem: item));
    }

    _saveToPrefs();
    notifyListeners();
    return null;
  }

  void removeItem(String itemId) {
    _items.removeWhere((ci) => ci.menuItem.id == itemId);
    if (_items.isEmpty) _restaurant = null;
    _saveToPrefs();
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final index = _items.indexWhere((ci) => ci.menuItem.id == itemId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void clearCart() {
    _items = [];
    _restaurant = null;
    _saveToPrefs();
    notifyListeners();
  }

  int getQuantity(String itemId) {
    final index = _items.indexWhere((ci) => ci.menuItem.id == itemId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  // Persist cart to SharedPreferences (like localStorage)
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = {
      'items': _items.map((ci) => ci.toJson()).toList(),
      'restaurant': _restaurant != null
          ? {
              'id': _restaurant!.id,
              'name': _restaurant!.name,
              'slug': _restaurant!.slug,
              'image_url': _restaurant!.imageUrl,
              'rating': _restaurant!.rating,
              'delivery_time_min': _restaurant!.deliveryTimeMin,
              'delivery_time_max': _restaurant!.deliveryTimeMax,
              'price_range': _restaurant!.priceRange,
              'cuisine_tags': _restaurant!.cuisineTags,
              'is_veg': _restaurant!.isVeg,
              'is_active': _restaurant!.isActive,
              'address': _restaurant!.address,
              'city': _restaurant!.city,
              'opening_time': _restaurant!.openingTime,
              'closing_time': _restaurant!.closingTime,
            }
          : null,
    };
    await prefs.setString('zomato_cart', jsonEncode(cartData));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('zomato_cart');
    if (cartJson != null) {
      try {
        final cartData = jsonDecode(cartJson) as Map<String, dynamic>;
        final itemsList = cartData['items'] as List<dynamic>? ?? [];
        _items = itemsList
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        if (cartData['restaurant'] != null) {
          _restaurant =
              Restaurant.fromJson(cartData['restaurant'] as Map<String, dynamic>);
        }
        notifyListeners();
      } catch (_) {
        // Ignore corrupt cart
      }
    }
  }
}
