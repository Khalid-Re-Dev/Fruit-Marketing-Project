import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/screens/splash_screen.dart';
import 'package:food_delivery_app/screens/home_screen.dart';
import 'package:food_delivery_app/screens/cart_screen.dart';
import 'package:food_delivery_app/screens/favorites_screen.dart';
import 'package:food_delivery_app/screens/history_screen.dart';
import 'package:food_delivery_app/screens/profile_screen.dart';
import 'package:food_delivery_app/services/auth_service.dart';
import 'package:food_delivery_app/services/cart_service.dart';
import 'package:food_delivery_app/services/favorites_service.dart';
import 'package:food_delivery_app/themes/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Stripe integration
  Stripe.publishableKey =
      'pk_test_51RS2HIGdcUwRkYEpEJZuUe5kMnj3pU32fluUuxUErOWJN86IV0JTtOdQPONh5Fx0Oy4dPiVbJnt97uvsF5Cy5Ela00v6elyQOL';
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
      ],
      child: MaterialApp(
        title: 'Yum Bites',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        // Define named routes for better navigation
        routes: {
          '/home': (context) => const HomeScreen(),
          '/cart': (context) => const CartScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/history': (context) => const HistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
