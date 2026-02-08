import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

void main() {
  runApp(const FlappyBirdGame());
}

class FlappyBirdGame extends StatelessWidget {
  const FlappyBirdGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF64B5F6), // Sky blue background
        body: SafeArea(
          child: GameWidget(),
        ),
      ),
    );
  }
}

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

enum GameState { ready, playing, gameOver }

class _GameWidgetState extends State<GameWidget>
    with SingleTickerProviderStateMixin {
  // Game constants
  static const double gravity = 0.3;
  static const double jumpVelocity = -8.0;
  static const double pipeWidth = 80.0;
  static const double pipeGap = 180.0;
  static const double pipeSpeed = 3.0;
  static const double groundHeight = 80.0;
  static const double birdRadius = 15.0;
  static const double birdX = 100.0;
  static const double minPipeHeight = 60.0;
  static const double maxPipeHeight = 300.0;

  // Game state
  late AnimationController _animationController;
  GameState _gameState = GameState.ready;
  double _birdY = 300.0;
  double _birdVelocity = 0.0;
  int _score = 0;
  List<Pipe> _pipes = [];
  double _scrollOffset = 0.0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    );

    _animationController.addListener(() {
      if (_gameState == GameState.playing) {
        _updateGame();
      }
    });

    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _gameState = GameState.ready;
      _birdY = 300.0;
      _birdVelocity = 0.0;
      _score = 0;
      _pipes = [];
      _scrollOffset = 0.0;
    });
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _birdVelocity = 0.0;
    });
    _animationController.repeat();
  }

  void _gameOver() {
    setState(() {
      _gameState = GameState.gameOver;
    });
    _animationController.stop();
  }

  void _jump() {
    if (_gameState == GameState.playing) {
      setState(() {
        _birdVelocity = jumpVelocity;
      });
    } else if (_gameState == GameState.ready) {
      _startGame();
    } else if (_gameState == GameState.gameOver) {
      _resetGame();
      _startGame();
    }
  }

  void _updateGame() {
    if (_gameState != GameState.playing) return;

    // Update bird physics
    setState(() {
      _birdVelocity += gravity;
      _birdY += _birdVelocity;

      // Update pipe positions
      _scrollOffset -= pipeSpeed;
      
      // Remove pipes that are off screen
      _pipes.removeWhere((pipe) => pipe.x + pipeWidth < 0);
      
      // Update existing pipes
      for (var pipe in _pipes) {
        pipe.x += -pipeSpeed;
      }

      // Add new pipe when needed
      if (_pipes.isEmpty || _pipes.last.x < MediaQuery.of(context).size.width - 300) {
        final double pipeHeight = minPipeHeight +
            _random.nextDouble() * (maxPipeHeight - minPipeHeight);
        _pipes.add(Pipe(
          x: MediaQuery.of(context).size.width,
          topHeight: pipeHeight,
        ));
      }

      // Check for score
      for (var pipe in _pipes) {
        if (!pipe.passed && pipe.x + pipeWidth < birdX) {
          pipe.passed = true;
          _score++;
        }
      }

      // Check collisions
      if (_checkCollisions()) {
        _gameOver();
      }
    });
  }

  bool _checkCollisions() {
    // Check ground and ceiling
    if (_birdY - birdRadius <= 0 ||
        _birdY + birdRadius >= MediaQuery.of(context).size.height - groundHeight) {
      return true;
    }

    // Check pipe collisions
    final birdRect = Rect.fromCircle(
      center: Offset(birdX, _birdY),
      radius: birdRadius - 2, // Slightly smaller for better gameplay
    );

    for (var pipe in _pipes) {
      // Top pipe
      final topPipeRect = Rect.fromLTWH(
        pipe.x,
        0,
        pipeWidth,
        pipe.topHeight,
      );

      // Bottom pipe
      final bottomPipeRect = Rect.fromLTWH(
        pipe.x,
        pipe.topHeight + pipeGap,
        pipeWidth,
        MediaQuery.of(context).size.height - (pipe.topHeight + pipeGap),
      );

      if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
        return true;
      }
    }

    return false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _jump,
      child: Stack(
        children: [
          // Background
          CustomPaint(
            painter: BackgroundPainter(),
            size: Size.infinite,
          ),

          // Pipes
          for (var pipe in _pipes)
            Positioned(
              left: pipe.x,
              child: CustomPaint(
                painter: PipePainter(
                  topHeight: pipe.topHeight,
                  gap: pipeGap,
                ),
                size: Size(pipeWidth, MediaQuery.of(context).size.height),
              ),
            ),

          // Bird
          Positioned(
            left: birdX - birdRadius,
            top: _birdY - birdRadius,
            child: CustomPaint(
              painter: BirdPainter(),
              size: Size(birdRadius * 2, birdRadius * 2),
            ),
          ),

          // Ground
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: GroundPainter(scrollOffset: _scrollOffset),
              size: Size(MediaQuery.of(context).size.width, groundHeight),
            ),
          ),

          // Score display
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Arial',
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Game state messages
          if (_gameState == GameState.ready)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FLAPPY BIRD',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Tap to start!',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_gameState == GameState.gameOver)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score: $_score',
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tap to restart',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Instructions
          if (_gameState == GameState.playing)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Pipe {
  double x;
  double topHeight;
  bool passed;

  Pipe({
    required this.x,
    required this.topHeight,
    this.passed = false,
  });
}

class BirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFF00) // Yellow
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final beakPaint = Paint()
      ..color = const Color(0xFFFFA500) // Orange
      ..style = PaintingStyle.fill;

    // Draw bird body (circle)
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, paint);

    // Draw eye
    canvas.drawCircle(
      Offset(center.dx + 5, center.dy - 5),
      4,
      eyePaint,
    );

    // Draw beak (triangle)
    final beakPath = Path()
      ..moveTo(center.dx + 15, center.dy)
      ..lineTo(center.dx + 30, center.dy - 5)
      ..lineTo(center.dx + 30, center.dy + 5)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Draw wing
    final wingPaint = Paint()
      ..color = const Color(0xFFFFD700) // Gold - slightly darker yellow
      ..style = PaintingStyle.fill;

    final wingPath = Path()
      ..moveTo(center.dx - 5, center.dy + 5)
      ..quadraticBezierTo(
        center.dx - 15,
        center.dy + 10,
        center.dx - 5,
        center.dy + 20,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + 15,
        center.dx - 5,
        center.dy + 5,
      )
      ..close();
    canvas.drawPath(wingPath, wingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PipePainter extends CustomPainter {
  final double topHeight;
  final double gap;

  PipePainter({required this.topHeight, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = const Color(0xFF4CAF50) // Green
      ..style = PaintingStyle.fill;

    final pipeEdgePaint = Paint()
      ..color = const Color(0xFF388E3C) // Darker green for edges
      ..style = PaintingStyle.fill;

    // Draw top pipe
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, topHeight),
      pipePaint,
    );

    // Draw top pipe edge
    canvas.drawRect(
      Rect.fromLTWH(-5, topHeight - 20, size.width + 10, 20),
      pipeEdgePaint,
    );

    // Draw bottom pipe
    final bottomPipeY = topHeight + gap;
    canvas.drawRect(
      Rect.fromLTWH(0, bottomPipeY, size.width, size.height - bottomPipeY),
      pipePaint,
    );

    // Draw bottom pipe edge
    canvas.drawRect(
      Rect.fromLTWH(-5, bottomPipeY, size.width + 10, 20),
      pipeEdgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GroundPainter extends CustomPainter {
  final double scrollOffset;

  GroundPainter({required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final groundPaint = Paint()
      ..color = const Color(0xFF8BC34A) // Light green ground
      ..style = PaintingStyle.fill;

    final darkGroundPaint = Paint()
      ..color = const Color(0xFF7CB342) // Slightly darker green
      ..style = PaintingStyle.fill;

    // Draw main ground
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      groundPaint,
    );

    // Draw ground pattern (stripes)
    for (double i = 0; i < size.width; i += 40) {
      final x = (i - scrollOffset) % size.width;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 20, size.height),
        darkGroundPaint,
      );
    }

    // Draw ground top border
    final borderPaint = Paint()
      ..color = const Color(0xFF5D4037) // Brown border
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 5),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sky background
    final skyPaint = Paint()
      ..color = const Color(0xFF64B5F6) // Sky blue
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      skyPaint,
    );

    // Draw clouds
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Cloud positions (static)
    _drawCloud(canvas, 100, 100, cloudPaint);
    _drawCloud(canvas, 300, 200, cloudPaint);
    _drawCloud(canvas, 500, 150, cloudPaint);
  }

  void _drawCloud(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawCircle(Offset(x, y), 20, paint);
    canvas.drawCircle(Offset(x + 15, y - 10), 25, paint);
    canvas.drawCircle(Offset(x + 35, y), 20, paint);
    canvas.drawCircle(Offset(x + 20, y + 10), 22, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}