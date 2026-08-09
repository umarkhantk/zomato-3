import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config['bg'] as Color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config['border'] as Color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'] as IconData,
              size: 13, color: config['color'] as Color),
          const SizedBox(width: 5),
          Text(
            status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: config['color'] as Color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getConfig(String status) {
    switch (status) {
      case 'placed':
        return {
          'color': Colors.blue,
          'bg': Colors.blue.withOpacity(0.1),
          'border': Colors.blue.withOpacity(0.3),
          'icon': Icons.receipt_long,
        };
      case 'confirmed':
        return {
          'color': Colors.orange,
          'bg': Colors.orange.withOpacity(0.1),
          'border': Colors.orange.withOpacity(0.3),
          'icon': Icons.check_circle_outline,
        };
      case 'preparing':
        return {
          'color': Colors.orange,
          'bg': Colors.orange.withOpacity(0.1),
          'border': Colors.orange.withOpacity(0.3),
          'icon': Icons.soup_kitchen,
        };
      case 'out_for_delivery':
        return {
          'color': const Color(0xFFE23744),
          'bg': const Color(0xFFE23744).withOpacity(0.1),
          'border': const Color(0xFFE23744).withOpacity(0.3),
          'icon': Icons.delivery_dining,
        };
      case 'delivered':
        return {
          'color': Colors.green,
          'bg': Colors.green.withOpacity(0.1),
          'border': Colors.green.withOpacity(0.3),
          'icon': Icons.check_circle,
        };
      case 'cancelled':
        return {
          'color': Colors.red,
          'bg': Colors.red.withOpacity(0.1),
          'border': Colors.red.withOpacity(0.3),
          'icon': Icons.cancel,
        };
      default:
        return {
          'color': Colors.grey,
          'bg': Colors.grey.withOpacity(0.1),
          'border': Colors.grey.withOpacity(0.3),
          'icon': Icons.info_outline,
        };
    }
  }
}
