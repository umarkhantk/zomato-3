import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class RestaurantService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active restaurants with optional filters
  Future<List<Restaurant>> fetchRestaurants({
    String? cuisine,
    bool? isVeg,
    String? search,
    String? sort,
    double? minRating,
  }) async {
    var query = _supabase
        .from('restaurants')
        .select('*')
        .eq('is_active', true);

    if (cuisine != null) {
      query = query.contains('cuisine_tags', [cuisine]);
    }

    if (isVeg != null) {
      query = query.eq('is_veg', isVeg);
    }

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final data = await query;
    List<Restaurant> restaurants =
        data.map((e) => Restaurant.fromJson(e)).toList();

    // Client-side filtering and sorting
    if (minRating != null) {
      restaurants =
          restaurants.where((r) => r.rating >= minRating).toList();
    }

    switch (sort) {
      case 'time':
        restaurants.sort((a, b) => a.deliveryTimeMin - b.deliveryTimeMin);
        break;
      case 'cost_asc':
        restaurants.sort((a, b) => a.priceRange - b.priceRange);
        break;
      default:
        // Default: sort by rating descending
        restaurants.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return restaurants;
  }

  /// Fetch single restaurant with menu categories and items
  Future<Map<String, dynamic>?> fetchRestaurantBySlug(String slug) async {
    final restaurantData = await _supabase
        .from('restaurants')
        .select('*')
        .eq('slug', slug)
        .maybeSingle();

    if (restaurantData == null) return null;

    final restaurant = Restaurant.fromJson(restaurantData);

    final categoriesData = await _supabase
        .from('menu_categories')
        .select('*')
        .eq('restaurant_id', restaurant.id)
        .order('sort_order', ascending: true);

    final itemsData = await _supabase
        .from('menu_items')
        .select('*')
        .eq('restaurant_id', restaurant.id)
        .order('sort_order', ascending: true);

    final categories =
        categoriesData.map((e) => MenuCategory.fromJson(e)).toList();
    final menuItems = itemsData.map((e) => MenuItem.fromJson(e)).toList();

    return {
      'restaurant': restaurant,
      'categories': categories,
      'menuItems': menuItems,
    };
  }

  /// Fetch reviews for a restaurant
  Future<List<Map<String, dynamic>>> fetchReviews(
      String restaurantId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, profile:profiles(full_name, avatar_url)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
