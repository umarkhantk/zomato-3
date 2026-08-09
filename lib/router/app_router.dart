import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/restaurant_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isLoading = authProvider.loading;

      if (isLoading) return '/splash';

      final protectedRoutes = [
        '/checkout',
        '/orders',
        '/profile',
      ];

      final isProtected = protectedRoutes
          .any((r) => state.matchedLocation.startsWith(r));

      if (!isLoggedIn && isProtected) {
        return '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/restaurant/:slug',
        builder: (context, state) =>
            RestaurantScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectTo: state.uri.queryParameters['from'] ?? '/',
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
    ],
  );
}
