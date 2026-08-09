import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();

  Order? _order;
  bool _loading = true;
  RealtimeChannel? _subscription;

  static const _statusSteps = [
    'placed',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    final order = await _orderService.fetchOrderById(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
      // Subscribe to real-time updates
      if (order != null && order.isActive) {
        _subscription = _orderService.subscribeToOrder(
          widget.orderId,
          (updatedData) {
            if (mounted) {
              setState(() {
                _order = Order.fromJson({
                  ...updatedData,
                  'items': _order?.items.map((i) => {
                    'id': i.id,
                    'order_id': i.orderId,
                    'menu_item_id': i.menuItemId,
                    'item_name': i.itemName,
                    'item_price': i.itemPrice,
                    'quantity': i.quantity,
                  }).toList() ?? [],
                  'restaurant': _order?.restaurant,
                  'address': _order?.address,
                });
              });
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: Text(
          'Order #${widget.orderId.substring(0, 8).toUpperCase()}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE23744)))
          : _order == null
              ? const Center(
                  child: Text('Order not found',
                      style: TextStyle(color: Colors.white)))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  color: const Color(0xFFE23744),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Status Card
                        _statusCard(),
                        const SizedBox(height: 16),

                        // Tracking Steps (if not cancelled)
                        if (_order!.status != 'cancelled')
                          _trackingSteps(),

                        const SizedBox(height: 16),

                        // Items
                        _itemsCard(),
                        const SizedBox(height: 16),

                        // Bill
                        _billCard(),
                        const SizedBox(height: 16),

                        // Address
                        if (_order!.address != null) _addressCard(),
                        const SizedBox(height: 16),

                        // Restaurant
                        if (_order!.restaurant != null) _restaurantCard(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Color(0xFFE23744), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Status',
                    style: TextStyle(
                        color: Color(0xFF8A8A9A), fontSize: 12)),
                const SizedBox(height: 4),
                OrderStatusBadge(status: _order!.status),
                if (_order!.isActive) ...[
                  const SizedBox(height: 4),
                  const Text('Live updates enabled 🔴',
                      style: TextStyle(
                          color: Color(0xFF8A8A9A), fontSize: 11)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total',
                  style: TextStyle(color: Color(0xFF8A8A9A), fontSize: 12)),
              Text(
                '₹${_order!.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackingSteps() {
    final currentIndex = _statusSteps.indexOf(_order!.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Tracking',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 16),
          ...List.generate(_statusSteps.length, (index) {
            final step = _statusSteps[index];
            final isDone = index <= currentIndex;
            final isActive = index == currentIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFFE23744)
                            : const Color(0xFF2D2D3E),
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFFE23744)
                              : const Color(0xFF3D3D4E),
                        ),
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        size: 14,
                        color: isDone ? Colors.white : Colors.transparent,
                      ),
                    ),
                    if (index < _statusSteps.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: isDone
                            ? const Color(0xFFE23744).withOpacity(0.4)
                            : const Color(0xFF2D2D3E),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Text(
                    _stepLabel(step),
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : isDone
                              ? const Color(0xFF8A8A9A)
                              : const Color(0xFF4A4A5A),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _itemsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items Ordered',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          ..._order!.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.itemName}  x${item.quantity}',
                      style: const TextStyle(color: Color(0xFF8A8A9A)),
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Details',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          _billRow('Subtotal', '₹${_order!.subtotal.toStringAsFixed(0)}'),
          _billRow('Delivery Fee', '₹${_order!.deliveryFee.toStringAsFixed(0)}'),
          _billRow('GST (5%)', '₹${_order!.tax.toStringAsFixed(0)}'),
          const Divider(color: Colors.white12, height: 16),
          _billRow('Total', '₹${_order!.total.toStringAsFixed(0)}', bold: true),
          const SizedBox(height: 8),
          _billRow('Payment', _order!.paymentMethod.toUpperCase()),
        ],
      ),
    );
  }

  Widget _addressCard() {
    final addr = _order!.address!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Delivery Address',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${addr['label'] ?? 'Home'}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${addr['address_line']}, ${addr['city']} - ${addr['pincode']}',
            style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _restaurantCard() {
    final rest = _order!.restaurant!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant, color: Color(0xFFE23744), size: 18),
              SizedBox(width: 8),
              Text('Restaurant',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${rest['name']}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (rest['address'] != null) ...[
            const SizedBox(height: 2),
            Text('${rest['address']}',
                style: const TextStyle(
                    color: Color(0xFF8A8A9A), fontSize: 13)),
          ],
          if (rest['phone'] != null) ...[
            const SizedBox(height: 2),
            Text('📞 ${rest['phone']}',
                style: const TextStyle(
                    color: Color(0xFF8A8A9A), fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: bold ? Colors.white : const Color(0xFF8A8A9A),
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 15 : 13,
              )),
          Text(value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 15 : 13,
              )),
        ],
      ),
    );
  }

  String _stepLabel(String step) {
    switch (step) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Your Food';
      case 'out_for_delivery':
        return 'Out for Delivery 🛵';
      case 'delivered':
        return 'Delivered ✅';
      default:
        return step;
    }
  }
}
