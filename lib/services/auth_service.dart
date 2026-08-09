import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email, password, full name, and role
  Future<AuthResponse> signUp(
    String email,
    String password,
    String fullName, {
    String role = 'customer',
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );

    // Update profile role explicitly (in case trigger didn't fire)
    if (response.user != null) {
      await _supabase
          .from('profiles')
          .update({'role': role})
          .eq('id', response.user!.id);
    }

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Fetch user profile from DB
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
    return data;
  }
}
