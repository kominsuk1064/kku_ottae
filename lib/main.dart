import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/favorites/presentation/favorites_builder.dart';

import 'screens/initial_screen.dart';
import 'screens/login_screen.dart';
import 'screens/join_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bus_category_screen.dart';
import 'screens/exbus_info_screen.dart';
import 'screens/inbus_info_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/favorite_page_linked_screen.dart';
import 'screens/facility_category_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // ✅ Firebase 초기화
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '건대 어때',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      builder: (context, child) =>
          FavoritesErrorListener(child: child ?? const SizedBox.shrink()),
      initialRoute: '/',
      routes: {
        '/': (context) => const InitialScreen(),
        '/login': (context) => const LoginScreen(),
        '/join': (context) => const JoinScreen(),
        '/home': (context) => const HomeScreen(),
        '/bus': (context) => FavoritesBuilder(
          builder: (context, favorites, toggleFavorite) => BusCategoryScreen(
            favorites: favorites,
            toggleFavorite: toggleFavorite,
          ),
        ),
        '/exbus': (context) => FavoritesBuilder(
          builder: (context, favorites, toggleFavorite) => ExBusInfoScreen(
            favorites: favorites,
            toggleFavorite: toggleFavorite,
          ),
        ),
        '/inbus': (context) => const InBusInfoScreen(),
        '/mypage': (context) => FavoritesBuilder(
          builder: (context, favorites, toggleFavorite) =>
              MyPageScreen(myFavorites: favorites),
        ),
        '/favorites': (context) => FavoritesBuilder(
          builder: (context, favorites, toggleFavorite) =>
              FavoritePageScreen(favorites: favorites),
        ),
        '/facility': (context) => const FacilityCategoryScreen(),
      },
    );
  }
}
