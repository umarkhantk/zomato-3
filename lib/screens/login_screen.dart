import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final String redirectTo;

  const LoginScreen({super.key, this.redirectTo = '/'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _testCustomerLoading = false;
  bool _testOwnerLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final error = await auth.signIn(email, password);
    setState(() => _loading = false);

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack('Logged in successfully!');
      context.go(widget.redirectTo);
    }
  }

  Future<void> _handleTestLogin(String role) async {
    final isCustomer = role == 'customer';
    final testEmail =
        isCustomer ? 'customer@zomato.com' : 'owner@zomato.com';
    const testPassword = 'password123';
    final testName = isCustomer ? 'Test Customer' : 'Test Owner';

    setState(() {
      if (isCustomer) {
        _testCustomerLoading = true;
      } else {
        _testOwnerLoading = true;
      }
    });

    final auth = context.read<AuthProvider>();
    var error = await auth.signIn(testEmail, testPassword);

    if (error != null) {
      // Try signup
      error = await auth.signUp(testEmail, testPassword, testName,
          role: role);
      if (error == null) {
        error = await auth.signIn(testEmail, testPassword);
      }
    }

    setState(() {
      if (isCustomer) {
        _testCustomerLoading = false;
      } else {
        _testOwnerLoading = false;
      }
    });

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack('Logged in as $testName');
      context.go(widget.redirectTo);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFE23744) : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo
            const Icon(Icons.delivery_dining,
                size: 56, color: Color(0xFFE23744)),
            const SizedBox(height: 12),
            const Text(
              'Welcome Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to your Zomato account',
              style: TextStyle(color: Color(0xFF8A8A9A), fontSize: 14),
            ),

            const SizedBox(height: 40),

            // Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2D2D3E)),
              ),
              child: Column(
                children: [
                  // Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF8A8A9A),
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE23744),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.1))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or demo fast-track',
                            style: TextStyle(
                                color: Color(0xFF8A8A9A), fontSize: 12)),
                      ),
                      Expanded(
                          child: Divider(color: Colors.white.withOpacity(0.1))),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Test Customer
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _testCustomerLoading
                          ? null
                          : () => _handleTestLogin('customer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2D2D3E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _testCustomerLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Login as Test Customer',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Test Owner
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _testOwnerLoading
                          ? null
                          : () => _handleTestLogin('restaurant_owner'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2D2D3E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _testOwnerLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Login as Restaurant Owner',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("New to Zomato? ",
                    style: TextStyle(color: Color(0xFF8A8A9A))),
                GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: const Text(
                    'Create an account',
                    style: TextStyle(
                      color: Color(0xFFE23744),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF8A8A9A),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF5A5A6A)),
            prefixIcon: Icon(icon, color: const Color(0xFF8A8A9A), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF12121F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2D2D3E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2D2D3E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE23744)),
            ),
          ),
        ),
      ],
    );
  }
}
