import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/favorites/data/favorite_repository_impl.dart';
import 'features/favorites/data/shared_preferences_favorite_local_storage.dart';
import 'features/favorites/domain/favorite_repository.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Set<String> favorites = {};
  final FavoriteRepository _favoriteRepository = FavoriteRepositoryImpl(
    SharedPreferencesFavoriteLocalStorage(),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadFavorites());
  }

  Future<void> _loadFavorites() async {
    try {
      final restoredFavorites = await _favoriteRepository.loadFavorites();
      if (!mounted) {
        return;
      }
      setState(() => favorites.addAll(restoredFavorites));
    } catch (error, stackTrace) {
      developer.log(
        '즐겨찾기 복원 실패',
        name: 'kku_ottae.favorites',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _saveFavorites(Set<String> snapshot) async {
    try {
      await _favoriteRepository.saveFavorites(snapshot);
    } catch (error, stackTrace) {
      developer.log(
        '즐겨찾기 저장 실패',
        name: 'kku_ottae.favorites',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _toggleFavorite(String key) {
    setState(() {
      if (favorites.contains(key)) {
        favorites.remove(key);
      } else {
        favorites.add(key);
      }
    });
    unawaited(_saveFavorites(Set<String>.unmodifiable(favorites)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '건대 어때',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (context) => const InitialScreen(),
        '/login': (context) => const LoginScreen(),
        '/join': (context) => const JoinScreen(),
        '/home': (context) => const HomeScreen(),
        '/bus': (context) => BusCategoryScreen(
          favorites: favorites,
          toggleFavorite: _toggleFavorite,
        ),
        '/exbus': (context) => ExBusInfoScreen(favorites: favorites),
        '/inbus': (context) => const InBusInfoScreen(),
        '/mypage': (context) => MyPageScreen(myFavorites: favorites),
        '/favorites': (context) => FavoritePageScreen(favorites: favorites),
        '/facility': (context) => FacilityCategoryScreen(
          favorites: favorites,
          toggleFavorite: _toggleFavorite,
        ),
      },
    );
  }
}
