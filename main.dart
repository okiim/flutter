import 'package:flutter/material.dart';
import 'dashboard_page.dart';

void main() {
  runApp(const JudgingSystemApp());
}

class JudgingSystemApp extends StatelessWidget {
  const JudgingSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Judging System',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1538),
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}