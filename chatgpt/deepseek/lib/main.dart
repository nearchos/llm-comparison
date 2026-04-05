import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlappyApp());
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: FlappyGame(),
        ),
      ),
    );
  }
}

enum GameState { ready, playing, gameOver }

class FlappyGame extends StatefulWidget {
  const FlappyGame({super.key});

  @override
  State<FlappyGame> createState() => _FlappyGameState();
}

class _FlappyGameState extends State<FlappyGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;

  // Game state
  GameState gameState = GameState.ready;

  // Bird physics
  double birdY = 0;
  double velocity = 0;
  final double gravity = 900;
  final double jumpStrength = -300;

  // Pipes
  final List<Pipe> pipes = [];
  final double pipeWidth = 60;
  final double gapHeight = 150;
  final double pipeSpeed = 200;

  // Screen size
  Size screenSize = Size.zero;

  // Score
  int score = 0;

  final Random random = Random();

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(days: 1))
          ..addListener(_gameLoop)
          ..forward();

    _initializeGame();
  }

  void _initializeGame() {
    birdY = 0;
    velocity = 0;
    pipes.clear();
    score = 0;

    // Add initial pipes
    for (int i = 0; i < 3; i++) {
      pipes.add(_createPipe(300.0 + i * 200));
    }
  }

  Pipe _createPipe(double x) {
    double minHeight = -0.5;
    double maxHeight = 0.5;
    double gapY = minHeight + random.nextDouble() * (maxHeight - minHeight);

    return Pipe(
      x: x,
      gapY: gapY,
      passed: false,
    );
  }

  void _gameLoop() {
    if (gameState != GameState.playing) return;

    final dt = _controller.lastElapsedDuration!.inMilliseconds / 1000.0;

    _updateBird(dt);
    _updatePipes(dt);
    _checkCollisions();

    setState(() {});
  }

  void _updateBird(double dt) {
    velocity += gravity * dt;
    birdY += velocity * dt / screenSize.height;
  }

  void _updatePipes(double dt) {
    for (var pipe in pipes) {
      pipe.x -= pipeSpeed * dt;

      // Score
      if (!pipe.passed && pipe.x < 100) {
        pipe.passed = true;
        score++;
      }
    }

    // Remove offscreen pipes
    pipes.removeWhere((pipe) => pipe.x < -pipeWidth);

    // Add new pipe
    if (pipes.isNotEmpty && pipes.last.x < screenSize.width - 200) {
      pipes.add(_createPipe(screenSize.width));
    }
  }

  void _checkCollisions() {
    const birdRadius = 20.0;

    // Ground / ceiling
    if (birdY > 1 || birdY < -1) {
      _gameOver();
    }

    for (var pipe in pipes) {
      final birdX = 100.0;

      final pipeLeft = pipe.x;
      final pipeRight = pipe.x + pipeWidth;

      if (birdX + birdRadius > pipeLeft &&
          birdX - birdRadius < pipeRight) {
        final gapTop = pipe.gapY - gapHeight / screenSize.height / 2;
        final gapBottom = pipe.gapY + gapHeight / screenSize.height / 2;

        if (birdY - birdRadius / screenSize.height < gapTop ||
            birdY + birdRadius / screenSize.height > gapBottom) {
          _gameOver();
        }
      }
    }
  }

  void _gameOver() {
    gameState = GameState.gameOver;
  }

  void _onTap() {
    if (gameState == GameState.ready) {
      setState(() {
        gameState = GameState.playing;
        velocity = jumpStrength;
      });
    } else if (gameState == GameState.playing) {
      velocity = jumpStrength;
    } else if (gameState == GameState.gameOver) {
      setState(() {
        gameState = GameState.ready;
        _initializeGame();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: CustomPaint(
        painter: GamePainter(
          birdY: birdY,
          pipes: pipes,
          score: score,
          gameState: gameState,
          screenSize: screenSize,
          pipeWidth: pipeWidth,
          gapHeight: gapHeight,
        ),
        child: Container(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Pipe {
  double x;
  double gapY;
  bool passed;

  Pipe({
    required this.x,
    required this.gapY,
    this.passed = false,
  });
}

class GamePainter extends CustomPainter {
  final double birdY;
  final List<Pipe> pipes;
  final int score;
  final GameState gameState;
  final Size screenSize;
  final double pipeWidth;
  final double gapHeight;

  GamePainter({
    required this.birdY,
    required this.pipes,
    required this.score,
    required this.gameState,
    required this.screenSize,
    required this.pipeWidth,
    required this.gapHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPipes(canvas, size);
    _drawBird(canvas, size);
    _drawGround(canvas, size);
    _drawScore(canvas, size);
    _drawOverlay(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.lightBlueAccent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawBird(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow;

    final birdX = 100.0;
    final y = size.height / 2 + birdY * size.height / 2;

    canvas.drawCircle(Offset(birdX, y), 20, paint);

    // Eye
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(birdX + 5, y - 5), 5, eyePaint);

    final pupil = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(birdX + 6, y - 5), 2, pupil);
  }

  void _drawPipes(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green;

    for (var pipe in pipes) {
      final gapY = size.height / 2 + pipe.gapY * size.height / 2;
      final gapHalf = gapHeight / 2;

      // Top pipe
      canvas.drawRect(
        Rect.fromLTWH(
          pipe.x,
          0,
          pipeWidth,
          gapY - gapHalf,
        ),
        paint,
      );

      // Bottom pipe
      canvas.drawRect(
        Rect.fromLTWH(
          pipe.x,
          gapY + gapHalf,
          pipeWidth,
          size.height,
        ),
        paint,
      );
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.brown;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 50, size.width, 50),
      paint,
    );
  }

  void _drawScore(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
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

  void _drawOverlay(Canvas canvas, Size size) {
    if (gameState == GameState.ready) {
      _drawCenteredText(canvas, size, "TAP TO START");
    } else if (gameState == GameState.gameOver) {
      _drawCenteredText(canvas, size, "GAME OVER\nTAP TO RESTART");
    }
  }

  void _drawCenteredText(Canvas canvas, Size size, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width);

    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}