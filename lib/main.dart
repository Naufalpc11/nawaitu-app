import 'package:flutter/material.dart';

import 'screens/main_navigation.dart'; // Mengimpor file navigasi

void main() {
  runApp(const NawaituApp());
}

class NawaituApp extends StatelessWidget {
  const NawaituApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nawaitu',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(
          0xFFF7F7F7,
        ), // Warna background abu-abu terang desainmu
        fontFamily: 'Poppins', // Nanti kita bisa setup font ini
      ),
      home: const MainNavigation(), // Arahkan ke navigasi utama
    );
  }
}
