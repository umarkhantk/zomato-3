import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const ZomatoApp(),
    ),
  );
}

class ZomatoApp extends StatelessWidget {
  const ZomatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final router = createRouter(authProvider);

    return MaterialApp.router(
      title: 'Zomato Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12121F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE23744),
          secondary: Color(0xFFE23744),
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF12121F),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12121F),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE23744),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
