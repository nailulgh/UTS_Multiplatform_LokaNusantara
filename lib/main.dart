import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/home_page.dart';
import 'views/category_page.dart';
import 'views/detail_page.dart';
import 'views/saved_page.dart';
import 'views/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Mengatur tampilan status bar transparan untuk antarmuka modern
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const LokaNusantaraApp());
}

/// Root widget yang mengatur konfigurasi tema global dan peta routing aplikasi.
class LokaNusantaraApp extends StatelessWidget {
  const LokaNusantaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LokaNusantara - Wisata & Kuliner Lokal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0D9488), // Emerald Teal
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0D9488),
          secondary: const Color(0xFFF59E0B), // Warm Amber
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),
      initialRoute: HomePage.routeName,
      routes: {
        HomePage.routeName: (context) => const HomePage(),
        CategoryPage.routeName: (context) =>
            const CategoryPage(isStandalone: true),
        DetailPage.routeName: (context) => const DetailPage(),
        SavedPage.routeName: (context) => const SavedPage(isStandalone: true),
        ProfilePage.routeName: (context) =>
            const ProfilePage(isStandalone: true),
      },
    );
  }
}
