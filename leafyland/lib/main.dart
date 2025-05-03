import 'package:flutter/material.dart';
import 'package:leafyland/home_page.dart';
import 'package:leafyland/login_page.dart';
import 'splash_screen.dart'; // لاحقاً ممكن تستخدمه بدل HomePage اذا خلصت منه

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LeafyLand 🌿',

     
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: ThemeData.light().textTheme,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

     
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[900],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: ThemeData.dark().textTheme,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      
      themeMode: ThemeMode.system,

      home: const SplashScreen(),
    );
  }
}
