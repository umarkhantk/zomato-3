import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get role => _profile?['role'] as String?;
  bool get isRestaurantOwner => role == 'restaurant_owner';

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _user = currentUser;
      await _loadProfile(currentUser.id);
    }
    _loading = false;
    notifyListeners();

    // Listen for auth state changes
    _authService.authStateChanges.listen((data) async {
      final user = data.session?.user;
      _user = user;
      if (user != null) {
        await _loadProfile(user.id);
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String userId) async {
    _profile = await _authService.fetchProfile(userId);
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final res = await _authService.signIn(email, password);
      if (res.user != null) {
        _user = res.user;
        await _loadProfile(res.user!.id);
        return null; // success
      }
      return 'Login failed';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(
    String email,
    String password,
    String fullName, {
    String role = 'customer',
  }) async {
    try {
      final res = await _authService.signUp(
        email,
        password,
        fullName,
        role: role,
      );
      if (res.user != null) {
        _user = res.user;
        await _loadProfile(res.user!.id);
        return null; // success
      }
      return 'Signup failed';
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadProfile(_user!.id);
    }
  }
}
