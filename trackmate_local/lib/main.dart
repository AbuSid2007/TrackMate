import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const TrackmateApp());
}

class TrackmateApp extends StatelessWidget {
  const TrackmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF427AFA)), // Trackmate Blue
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}