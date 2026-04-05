import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Game constants
  final double gravity = 0.6;
  final double jumpStrength = -10;
  final double pipeSpeed = 3;
  final double pipeWidth = 70;
  final double gapHeight = 180;

  // Bird
  double birdY = 0;
  double velocity = 0;
  final double birdSize = 50;

  // Game state
  bool isPlaying = false;
  bool isGameOver = false;

  // Pipes
  List<Map<String, double>> pipes = [];

  // Score
  int score = 0;

  Timer? gameLoop;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void startGame() {
    isPlaying = true;
    isGameOver = false;

    gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void resetGame() {
    birdY = 0;
    velocity = 0;
    score = 0;
    pipes.clear();
    generatePipe(initial: true);
    isPlaying = false;
    isGameOver = false;
    gameLoop?.cancel();
  }

  void jump() {
    if (!isPlaying) {
      startGame();
    }
    velocity = jumpStrength;
  }

  void updateGame() {
    setState(() {
      // Bird physics
      velocity += gravity;
      birdY += velocity;

      // Move pipes
      for (var pipe in pipes) {
        pipe['x'] = pipe['x']! - pipeSpeed;
      }

      // Remove offscreen pipes
      pipes.removeWhere((pipe) => pipe['x']! < -pipeWidth);

      // Generate new pipe
      if (pipes.isEmpty || pipes.last['x']! < 250) {
        generatePipe();
      }

      // Collision detection
      checkCollision();

      // Score update
      for (var pipe in pipes) {
        if (!pipe.containsKey('scored') &&
            pipe['x']! + pipeWidth < MediaQuery.of(context).size.width / 2) {
          pipe['scored'] = 1;
          score++;
        }
      }
    });
  }

  void generatePipe({bool initial = false}) {
    double screenHeight = MediaQuery.of(context).size.height;
    double safeArea = 100;

    double topHeight = random.nextDouble() *
        (screenHeight - gapHeight - safeArea * 2) +
        safeArea;

    pipes.add({
      'x': initial
          ? MediaQuery.of(context).size.width
          : MediaQuery.of(context).size.width + 100,
      'topHeight': topHeight,
    });
  }

  void checkCollision() {
    double screenHeight = MediaQuery.of(context).size.height;
    double birdTop = birdY + screenHeight / 2 - birdSize / 2;
    double birdBottom = birdTop + birdSize;
    double birdLeft = MediaQuery.of(context).size.width / 2 - birdSize / 2;
    double birdRight = birdLeft + birdSize;

    // Ground / ceiling
    if (birdTop <= 0 || birdBottom >= screenHeight) {
      gameOver();
      return;
    }

    // Pipes
    for (var pipe in pipes) {
      double pipeX = pipe['x']!;
      double topHeight = pipe['topHeight']!;
      double bottomY = topHeight + gapHeight;

      bool collisionX =
          birdRight > pipeX && birdLeft < pipeX + pipeWidth;

      bool collisionTop = birdTop < topHeight;
      bool collisionBottom = birdBottom > bottomY;

      if (collisionX && (collisionTop || collisionBottom)) {
        gameOver();
        return;
      }
    }
  }

  void gameOver() {
    isPlaying = false;
    isGameOver = true;
    gameLoop?.cancel();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isGameOver) {
          resetGame();
        } else {
          jump();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(color: Colors.lightBlue),

            // Pipes
            ...pipes.map((pipe) {
              double x = pipe['x']!;
              double topHeight = pipe['topHeight']!;
              double bottomHeight =
                  MediaQuery.of(context).size.height -
                      topHeight -
                      gapHeight;

              return Stack(
                children: [
                  // Top pipe
                  Positioned(
                    left: x,
                    top: 0,
                    child: Container(
                      width: pipeWidth,
                      height: topHeight,
                      color: Colors.green,
                    ),
                  ),
                  // Bottom pipe
                  Positioned(
                    left: x,
                    bottom: 0,
                    child: Container(
                      width: pipeWidth,
                      height: bottomHeight,
                      color: Colors.green,
                    ),
                  ),
                ],
              );
            }).toList(),

            // Bird
            Align(
              alignment: Alignment(0, birdY / (MediaQuery.of(context).size.height / 2)),
              child: Container(
                width: birdSize,
                height: birdSize,
                decoration: const BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Score
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Start / Game Over UI
            if (!isPlaying)
              Center(
                child: Text(
                  isGameOver ? 'Game Over\nTap to Restart' : 'Tap to Play',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}