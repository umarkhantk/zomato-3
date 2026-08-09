import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import '../widgets/restaurant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _restaurantService = RestaurantService();
  final _searchController = TextEditingController();

  List<Restaurant> _restaurants = [];
  bool _loading = false;
  String? _selectedCuisine;
  String? _sort;
  double? _minRating;

  static const _cuisines = [
    'All',
    'North Indian',
    'South Indian',
    'Chinese',
    'Pizza',
    'Biryani',
    'Burger',
    'Desserts',
    'Healthy',
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _loading = true);
    final data = await _restaurantService.fetchRestaurants(
      cuisine: _selectedCuisine,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      sort: _sort,
      minRating: _minRating,
    );
    setState(() {
      _restaurants = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF12121F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0A0C), Color(0xFF12121F)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Color(0xFFE23744), size: 20),
                            const SizedBox(width: 6),
                            const Text('Hyderabad',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white),
                            const Spacer(),
                            if (auth.isLoggedIn)
                              GestureDetector(
                                onTap: () => context.push('/profile'),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFE23744),
                                  child: Text(
                                    (auth.profile?['full_name'] as String? ??
                                            'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () => context.push('/login'),
                                child: const Text('Login',
                                    style: TextStyle(
                                        color: Color(0xFFE23744),
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Hungry? 🍔',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Order from your favourite restaurant',
                          style: TextStyle(
                              color: Color(0xFF8A8A9A), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _loadRestaurants(),
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF5A5A6A)),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF8A8A9A)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Color(0xFF8A8A9A)),
                            onPressed: () {
                              _searchController.clear();
                              _loadRestaurants();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E1E2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // Cuisine chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cuisines.length,
                itemBuilder: (context, index) {
                  final cuisine = _cuisines[index];
                  final isSelected = cuisine == 'All'
                      ? _selectedCuisine == null
                      : _selectedCuisine == cuisine;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCuisine =
                            cuisine == 'All' ? null : cuisine;
                      });
                      _loadRestaurants();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE23744)
                            : const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE23744)
                              : const Color(0xFF2D2D3E),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cuisine,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF8A8A9A),
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Sort/Filter bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _filterChip(
                    label: 'Rating 4.0+',
                    active: _minRating != null,
                    onTap: () {
                      setState(() =>
                          _minRating = _minRating == null ? 4.0 : null);
                      _loadRestaurants();
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Delivery Time',
                    active: _sort == 'time',
                    onTap: () {
                      setState(
                          () => _sort = _sort == 'time' ? null : 'time');
                      _loadRestaurants();
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Cost: Low to High',
                    active: _sort == 'cost_asc',
                    onTap: () {
                      setState(() =>
                          _sort = _sort == 'cost_asc' ? null : 'cost_asc');
                      _loadRestaurants();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'Search results for "${_searchController.text}"'
                    : 'Delivery Restaurants in Hyderabad',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Restaurant list
          _loading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE23744)),
                  ),
                )
              : _restaurants.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant,
                                size: 64, color: Colors.white24),
                            SizedBox(height: 16),
                            Text('No restaurants found',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: RestaurantCard(
                                restaurant: _restaurants[index]),
                          ),
                          childCount: _restaurants.length,
                        ),
                      ),
                    ),
        ],
      ),

      // Cart FAB
      floatingActionButton: cart.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/checkout'),
                backgroundColor: const Color(0xFFE23744),
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: Text(
                  '${cart.itemCount} items • ₹${cart.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE23744).withOpacity(0.15)
              : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFFE23744)
                : const Color(0xFF2D2D3E),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFE23744) : const Color(0xFF8A8A9A),
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
