import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_bottom_bar.dart';

class RestaurantScreen extends StatefulWidget {
  final String slug;

  const RestaurantScreen({super.key, required this.slug});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen>
    with SingleTickerProviderStateMixin {
  final _restaurantService = RestaurantService();

  Restaurant? _restaurant;
  List<MenuCategory> _categories = [];
  List<MenuItem> _menuItems = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRestaurant();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurant() async {
    final data =
        await _restaurantService.fetchRestaurantBySlug(widget.slug);
    if (data != null && mounted) {
      final reviews = await _restaurantService
          .fetchReviews((data['restaurant'] as Restaurant).id);
      setState(() {
        _restaurant = data['restaurant'] as Restaurant;
        _categories = data['categories'] as List<MenuCategory>;
        _menuItems = data['menuItems'] as List<MenuItem>;
        _reviews = reviews;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE23744)),
        ),
      );
    }

    if (_restaurant == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF12121F),
        appBar: AppBar(backgroundColor: const Color(0xFF12121F)),
        body: const Center(
          child: Text('Restaurant not found',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF12121F),
            flexibleSpace: FlexibleSpaceBar(
              background: _restaurant!.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _restaurant!.imageUrl!,
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    )
                  : Container(color: const Color(0xFF2D2D3E)),
            ),
          ),

          // Restaurant info
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _restaurant!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_restaurant!.isVeg)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text('PURE VEG',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _restaurant!.cuisineTags.join(', '),
                    style: const TextStyle(
                        color: Color(0xFF8A8A9A), fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statChip(Icons.star_rounded, Colors.amber,
                          _restaurant!.rating.toStringAsFixed(1)),
                      const SizedBox(width: 16),
                      _statChip(
                        Icons.access_time_rounded,
                        const Color(0xFFE23744),
                        '${_restaurant!.deliveryTimeMin}-${_restaurant!.deliveryTimeMax} min',
                      ),
                      const SizedBox(width: 16),
                      _statChip(
                        Icons.currency_rupee,
                        Colors.white60,
                        '₹${_restaurant!.priceRange * 200} for two',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFE23744),
                unselectedLabelColor: const Color(0xFF8A8A9A),
                indicatorColor: const Color(0xFFE23744),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Menu'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Info'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Menu Tab
            _buildMenuTab(),

            // Reviews Tab
            _buildReviewsTab(),

            // Info Tab
            _buildInfoTab(),
          ],
        ),
      ),
      bottomNavigationBar: const CartBottomBar(),
    );
  }

  Widget _buildMenuTab() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text('No menu items available',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, catIndex) {
        final category = _categories[catIndex];
        final items =
            _menuItems.where((i) => i.categoryId == category.id).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...items.map((item) => MenuItemCard(
                  item: item,
                  restaurant: _restaurant!,
                )),
          ],
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No reviews yet',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final profile = review['profile'] as Map<String, dynamic>?;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2D2D3E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE23744),
                    child: Text(
                      (profile?['full_name'] as String? ?? 'U')[0]
                          .toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?['full_name'] as String? ?? 'Anonymous',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            size: 14,
                            color: i < (review['rating'] as int? ?? 0)
                                ? Colors.amber
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (review['comment'] != null) ...[
                const SizedBox(height: 10),
                Text(
                  review['comment'] as String,
                  style: const TextStyle(
                      color: Color(0xFF8A8A9A), fontSize: 14),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About this place',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            if (_restaurant!.description != null) ...[
              _infoSection('Description', _restaurant!.description!),
              const SizedBox(height: 16),
            ],

            _infoSection(
                'Cuisines', _restaurant!.cuisineTags.join(', ')),
            const SizedBox(height: 16),
            _infoSection('Average Cost',
                '₹${_restaurant!.priceRange * 200} for two people (approx.)'),
            const SizedBox(height: 16),
            _infoSection('Timing',
                '${_restaurant!.openingTime.substring(0, 5)} - ${_restaurant!.closingTime.substring(0, 5)}'),
            const SizedBox(height: 16),
            _infoSection(
                'Address', '${_restaurant!.address}, ${_restaurant!.city}'),
            if (_restaurant!.phone != null) ...[
              const SizedBox(height: 16),
              _infoSection('Phone', _restaurant!.phone!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF8A8A9A),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }

  Widget _statChip(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF12121F),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
