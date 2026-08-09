import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../models/address.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _orderService = OrderService();

  List<Address> _addresses = [];
  bool _loadingAddresses = true;
  bool _showAddForm = false;
  bool _submittingAddress = false;

  String _newLabel = 'Home';
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Hyderabad');
  final _pincodeController = TextEditingController();

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
    await _orderService.addAddress(
      userId: auth.user!.id,
      label: _newLabel,
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      isDefault: _addresses.isEmpty,
    );
    _addressController.clear();
    _pincodeController.clear();
    setState(() {
      _submittingAddress = false;
      _showAddForm = false;
    });
    _showSnack('Address added');
    _loadAddresses();
  }

  Future<void> _handleDeleteAddress(String id) async {
    await _orderService.deleteAddress(id);
    _showSnack('Address deleted');
    _loadAddresses();
  }

  Future<void> _handleSignOut() async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (mounted) context.go('/');
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
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE23744))),
      );
    }

    final fullName = profile['full_name'] as String? ?? 'User';
    final email = auth.user?.email ?? '';
    final role = profile['role'] as String? ?? 'customer';
    final initial = fullName[0].toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2D2D3E)),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE23744), Color(0xFFFF6B7A)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE23744).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFE23744),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  // Email
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          color: Color(0xFF8A8A9A), size: 18),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email',
                              style: TextStyle(
                                  color: Color(0xFF8A8A9A), fontSize: 11)),
                          Text(email,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  if (role == 'customer') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/orders'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF2D2D3E)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined,
                            color: Colors.white, size: 18),
                        label: const Text('My Orders',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleSignOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout,
                          color: Colors.red, size: 18),
                      label: const Text('Sign Out',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),

            // Addresses section (only for customers)
            if (role == 'customer') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2D2D3E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saved Addresses',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        if (!_showAddForm)
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showAddForm = true),
                            icon: const Icon(Icons.add,
                                size: 16, color: Color(0xFFE23744)),
                            label: const Text('Add New',
                                style:
                                    TextStyle(color: Color(0xFFE23744))),
                          ),
                      ],
                    ),

                    // Add form
                    if (_showAddForm) ...[
                      const SizedBox(height: 12),
                      _buildAddressForm(),
                    ],

                    const SizedBox(height: 12),

                    // Address list
                    if (_loadingAddresses)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE23744)))
                    else if (_addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.location_off,
                                  size: 40, color: Colors.white12),
                              SizedBox(height: 8),
                              Text('No saved addresses yet',
                                  style: TextStyle(color: Colors.white38)),
                              Text('Add an address to start ordering',
                                  style: TextStyle(
                                      color: Colors.white24, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...(_addresses.map((addr) => _addressTile(addr))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Address',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: ['Home', 'Work', 'Other'].map((lbl) {
              final sel = _newLabel == lbl;
              return GestureDetector(
                onTap: () => setState(() => _newLabel = lbl),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
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
                        color:
                            sel ? Colors.white : const Color(0xFF8A8A9A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _formField(_addressController, 'Address Line',
              'Flat/House No, Building, Street'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _formField(_cityController, 'City', 'City')),
              const SizedBox(width: 8),
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
                    : const Text('Save Address'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addressTile(Address addr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2D2D3E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFFE23744), size: 22),
          const SizedBox(width: 12),
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
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFF8A8A9A), size: 20),
            onPressed: () => _handleDeleteAddress(addr.id),
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
            style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 12)),
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
}
