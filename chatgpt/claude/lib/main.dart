import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

/// Root App
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

/// Game States
enum GameState { playing, gameOver }

/// Main Game Page
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// GAME CONSTANTS
  static const double gravity = 900;
  static const double jumpVelocity = -300;
  static const double pipeSpeed = 200;
  static const double pipeGap = 180;
  static const double pipeWidth = 60;
  static const double groundHeight = 100;

  /// GAME STATE
  GameState gameState = GameState.playing;

  double birdY = 0;
  double birdVelocity = 0;

  List<Pipe> pipes = [];

  int score = 0;

  final Random random = Random();

  @override
  void initState() {
    super.initState();
    resetGame();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(gameLoop);

    _controller.repeat();
  }

  void resetGame() {
    birdY = 300;
    birdVelocity = 0;
    score = 0;
    gameState = GameState.playing;

    pipes = List.generate(3, (i) {
      return Pipe(
        x: 400 + i * 250,
        gapY: 200 + random.nextDouble() * 200,
      );
    });
  }

  void gameLoop() {
    if (gameState != GameState.playing) return;

    final dt = 1 / 60;

    // Apply gravity
    birdVelocity += gravity * dt;
    birdY += birdVelocity * dt;

    // Move pipes
    for (var pipe in pipes) {
      pipe.x -= pipeSpeed * dt;

      // Score
      if (!pipe.passed && pipe.x + pipeWidth < 100) {
        pipe.passed = true;
        score++;
      }
    }

    // Recycle pipes
    if (pipes.first.x < -pipeWidth) {
      pipes.removeAt(0);
      pipes.add(Pipe(
        x: pipes.last.x + 250,
        gapY: 150 + random.nextDouble() * 250,
      ));
    }

    checkCollisions();

    setState(() {});
  }

  void checkCollisions() {
    const birdSize = 30.0;

    // Ground / ceiling
    if (birdY < 0 || birdY > MediaQuery.of(context).size.height - groundHeight - birdSize) {
      gameOver();
    }

    // Pipes
    for (var pipe in pipes) {
      if (100 + birdSize > pipe.x &&
          100 < pipe.x + pipeWidth) {
        if (birdY < pipe.gapY - pipeGap / 2 ||
            birdY + birdSize > pipe.gapY + pipeGap / 2) {
          gameOver();
        }
      }
    }
  }

  void gameOver() {
    gameState = GameState.gameOver;
  }

  void onTap() {
    if (gameState == GameState.playing) {
      birdVelocity = jumpVelocity;
    } else {
      resetGame();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get birdRotation {
    return (birdVelocity / 400).clamp(-1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Scaffold(
        body: Stack(
          children: [
            CustomPaint(
              size: Size.infinite,
              painter: GamePainter(
                birdY: birdY,
                birdRotation: birdRotation,
                pipes: pipes,
                score: score,
              ),
            ),

            if (gameState == GameState.gameOver)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "GAME OVER",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Score: $score",
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Tap to Restart",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pipe Model
class Pipe {
  double x;
  double gapY;
  bool passed = false;

  Pipe({required this.x, required this.gapY});
}

/// Custom Painter
class GamePainter extends CustomPainter {
  final double birdY;
  final double birdRotation;
  final List<Pipe> pipes;
  final int score;

  GamePainter({
    required this.birdY,
    required this.birdRotation,
    required this.pipes,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    /// SKY
    paint.color = Colors.lightBlue;
    canvas.drawRect(Offset.zero & size, paint);

    /// PIPES
    paint.color = Colors.green;
    for (var pipe in pipes) {
      // Top pipe
      canvas.drawRect(
        Rect.fromLTWH(
          pipe.x,
          0,
          60,
          pipe.gapY - 90,
        ),
        paint,
      );

      // Bottom pipe
      canvas.drawRect(
        Rect.fromLTWH(
          pipe.x,
          pipe.gapY + 90,
          60,
          size.height,
        ),
        paint,
      );
    }

    /// GROUND
    paint.color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 100, size.width, 100),
      paint,
    );

    /// BIRD
    canvas.save();
    canvas.translate(100, birdY + 15);
    canvas.rotate(birdRotation);

    paint.color = Colors.yellow;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 30),
      paint,
    );

    /// Wing
    paint.color = Colors.orange;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, 5), width: 15, height: 10),
      paint,
    );

    canvas.restore();

    /// SCORE
    final textPainter = TextPainter(
      text: TextSpan(
        text: "$score",
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, 50),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}