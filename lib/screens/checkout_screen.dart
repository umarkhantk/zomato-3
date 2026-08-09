import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../models/address.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderService = OrderService();

  List<Address> _addresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;
  bool _placingOrder = false;
  String _paymentMethod = 'cod';
  String _notes = '';
  bool _showAddForm = false;

  // Add address form
  String _newLabel = 'Home';
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Hyderabad');
  final _pincodeController = TextEditingController();
  bool _submittingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _loadingAddresses = true);
    final addresses = await _orderService.fetchAddresses(auth.user!.id);
    setState(() {
      _addresses = addresses;
      _loadingAddresses = false;
      if (addresses.isNotEmpty) {
        final defaultAddr =
            addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        _selectedAddressId = defaultAddr.id;
      }
    });
  }

  Future<void> _handleAddAddress() async {
    if (_addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      _showSnack('Please fill all fields', isError: true);
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _submittingAddress = true);

    final newAddr = await _orderService.addAddress(
      userId: auth.user!.id,
      label: _newLabel,
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _addresses.isEmpty,
    );

    setState(() => _submittingAddress = false);

    if (newAddr != null) {
      _addressController.clear();
      _pincodeController.clear();
      setState(() => _showAddForm = false);
      await _loadAddresses();
      setState(() => _selectedAddressId = newAddr.id);
      _showSnack('Address added successfully');
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (_selectedAddressId == null) {
      _showSnack('Please select a delivery address', isError: true);
      return;
    }

    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    setState(() => _placingOrder = true);

    try {
      final order = await _orderService.createOrder(
        customerId: auth.user!.id,
        restaurantId: cart.restaurant!.id,
        addressId: _selectedAddressId!,
        subtotal: cart.subtotal,
        deliveryFee: cart.deliveryFee,
        tax: cart.tax,
        total: cart.total,
        paymentMethod: _paymentMethod,
        cartItems: cart.items,
        notes: _notes.isEmpty ? null : _notes,
      );

      if (!mounted) return;

      if (order != null) {
        cart.clearCart();
        _showSnack('Order placed successfully! 🎉');
        context.go('/orders/${order.id}');
      } else {
        _showSnack('Failed to place order. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      setState(() => _placingOrder = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFE23744) : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(backgroundColor: Color(0xFF12121F));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('Secure Checkout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Delivery Address
            _sectionCard(
              title: '1. Delivery Address',
              trailing: !_showAddForm
                  ? TextButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      icon: const Icon(Icons.add,
                          size: 16, color: Color(0xFFE23744)),
                      label: const Text('Add Address',
                          style: TextStyle(color: Color(0xFFE23744))),
                    )
                  : null,
              child: Column(
                children: [
                  // Add form
                  if (_showAddForm) _buildAddressForm(),

                  // Address list
                  if (_loadingAddresses)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: Color(0xFFE23744)),
                    )
                  else if (_addresses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white12, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'No saved addresses.\nPlease add a delivery address.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    ...(_addresses.map((addr) => _addressTile(addr))),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Payment Mode
            _sectionCard(
              title: '2. Payment Mode',
              child: Column(
                children: [
                  _paymentOption(
                    value: 'cod',
                    icon: Icons.money,
                    title: 'Cash on Delivery (COD)',
                    subtitle: 'Pay cash or scan QR code when order arrives',
                  ),
                  const SizedBox(height: 10),
                  _paymentOption(
                    value: 'card',
                    icon: Icons.credit_card,
                    title: 'Credit/Debit Card (Mocked)',
                    subtitle: 'Fast instant transactions',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Delivery Instructions
            _sectionCard(
              title: '3. Delivery Instructions',
              child: TextField(
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => _notes = val,
                decoration: InputDecoration(
                  hintText:
                      "e.g. Leave at the gate, don't ring the bell...",
                  hintStyle: const TextStyle(color: Color(0xFF5A5A6A)),
                  filled: true,
                  fillColor: const Color(0xFF12121F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF2D2D3E)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF2D2D3E)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE23744)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bill Summary
            _sectionCard(
              title: 'Order Details',
              child: Column(
                children: [
                  Text('Ordering from ${cart.restaurant?.name ?? ''}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  ...cart.items.map(
                    (ci) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${ci.menuItem.name} x${ci.quantity}',
                              style: const TextStyle(
                                  color: Color(0xFF8A8A9A)),
                            ),
                          ),
                          Text(
                            '₹${ci.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _billRow('Subtotal', '₹${cart.subtotal.toStringAsFixed(0)}'),
                  _billRow('Delivery Fee', '₹${cart.deliveryFee.toStringAsFixed(0)}'),
                  _billRow('GST (5%)', '₹${cart.tax.toStringAsFixed(0)}'),
                  const Divider(color: Colors.white12, height: 16),
                  _billRow('Total', '₹${cart.total.toStringAsFixed(0)}',
                      bold: true),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placingOrder || _selectedAddressId == null
                    ? null
                    : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  disabledBackgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _placingOrder
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Place Order (₹${cart.total.toStringAsFixed(0)})',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Address',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Label chips
          Row(
            children: ['Home', 'Work', 'Other'].map((lbl) {
              final sel = _newLabel == lbl;
              return GestureDetector(
                onTap: () => setState(() => _newLabel = lbl),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFE23744)
                        : const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFFE23744)
                          : const Color(0xFF2D2D3E),
                    ),
                  ),
                  child: Text(lbl,
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF8A8A9A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          _formField(_addressController, 'Address Line',
              'Street name, House/Flat number'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _formField(_cityController, 'City', 'City')),
              const SizedBox(width: 10),
              Expanded(
                  child: _formField(
                      _pincodeController, 'Pincode', 'Pincode')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _showAddForm = false),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF8A8A9A))),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _submittingAddress ? null : _handleAddAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE23744),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _submittingAddress
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save & Select'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formField(
      TextEditingController ctrl, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8A8A9A), fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFF5A5A6A), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E1E2E),
            isDense: true,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D2D3E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2D2D3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE23744)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressTile(Address addr) {
    final isSelected = _selectedAddressId == addr.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressId = addr.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE23744).withOpacity(0.08)
              : const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE23744)
                : const Color(0xFF2D2D3E),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: addr.id,
              groupValue: _selectedAddressId,
              onChanged: (v) =>
                  setState(() => _selectedAddressId = v),
              activeColor: const Color(0xFFE23744),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(addr.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      if (addr.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('DEFAULT',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(addr.fullAddress,
                      style: const TextStyle(
                          color: Color(0xFF8A8A9A), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE23744).withOpacity(0.08)
              : const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE23744)
                : const Color(0xFF2D2D3E),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
              activeColor: const Color(0xFFE23744),
            ),
            Icon(icon,
                color: isSelected
                    ? const Color(0xFFE23744)
                    : const Color(0xFF8A8A9A)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8A8A9A), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
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
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              )),
          Text(value,
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              )),
        ],
      ),
    );
  }
}
