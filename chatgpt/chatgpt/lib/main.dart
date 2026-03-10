import 'package:flutter/material.dart';
import 'game_page.dart';

void main() {
  runApp(const FlappyApp());
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flappy Flutter',
      theme: ThemeData.dark(),
      home: const GamePage(),
    );
  }
}

