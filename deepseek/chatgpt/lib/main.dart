import 'package:flutter/material.dart';
import 'game/game_widget.dart';

void main() {
  runApp(const FlappyBirdGame());
}

class FlappyBirdGame extends StatelessWidget {
  const FlappyBirdGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird Clone',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'PixelFont',
      ),
      home: const GameWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}