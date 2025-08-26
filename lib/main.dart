import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ SharedPreferences 추가

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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
    loadFavorites(); // ✅ 앱 시작 시 즐겨찾기 로드
  }

  // ✅ SharedPreferences로부터 즐겨찾기 로드
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    setState(() {
      favorites.addAll(favList);
    });
  }

  // ✅ SharedPreferences에 즐겨찾기 저장
  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  // ✅ 즐겨찾기 추가/제거 + 저장
  void toggleFavorite(String key) {
    setState(() {
      if (favorites.contains(key)) {
        favorites.remove(key);
      } else {
        favorites.add(key);
      }
    });
    saveFavorites();
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
          toggleFavorite: toggleFavorite,
        ),
        '/exbus': (context) => ExBusInfoScreen(favorites: favorites),
        '/inbus': (context) => const InBusInfoScreen(),
        '/mypage': (context) => MyPageScreen(myFavorites: favorites),
        '/favorites': (context) => FavoritePageScreen(favorites: favorites),
        '/facility': (context) => FacilityCategoryScreen(
          favorites: favorites,
          toggleFavorite: toggleFavorite,
        ),
      },
    );
  }
}
