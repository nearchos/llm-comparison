import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// Game constants for easy tuning
const double gravity = 0.5;
const double jumpVelocity = -10.0;
const double birdSize = 36.0;
const double pipeWidth = 80.0;
const double pipeGap = 200.0;
const double pipeSpeed = 4.0;
const double groundHeight = 110.0;
const double birdXPosition = 100.0;

void main() {
  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Flappy Bird',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FlappyBirdGame(),
    );
  }
}

// Enum to manage the current state of the game
enum GameState { ready, playing, gameOver }

class FlappyBirdGame extends StatefulWidget {
  const FlappyBirdGame({Key? key}) : super(key: key);

  @override
  _FlappyBirdGameState createState() => _FlappyBirdGameState();
}

class _FlappyBirdGameState extends State<FlappyBirdGame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Game state variables
  GameState _gameState = GameState.ready;
  double _birdY = 0;
  double _birdVelocity = 0;
  double _birdRotation = 0;
  int _score = 0;
  
  // Pipe management
  final List<Offset> _pipes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Initialize the game loop controller
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16));
    _controller.addListener(_gameLoop);
    _resetGame();
  }

  // Resets the game to its initial state
  void _resetGame() {
    setState(() {
      _gameState = GameState.ready;
      _birdY = 0;
      _birdVelocity = 0;
      _birdRotation = 0;
      _score = 0;
      _pipes.clear();
      // Generate initial pipes off-screen
      for (int i = 0; i < 2; i++) {
        _pipes.add(Offset(
          MediaQuery.of(context).size.width + i * (MediaQuery.of(context).size.width / 2 + pipeWidth / 2),
          _random.nextDouble() * (MediaQuery.of(context).size.height - pipeGap - groundHeight * 2) + groundHeight,
        ));
      }
    });
  }

  // The main game loop, called on every frame
  void _gameLoop() {
    if (_gameState != GameState.playing) {
      if (_controller.isAnimating) _controller.stop();
      return;
    }

    setState(() {
      // Apply gravity to the bird
      _birdVelocity += gravity;
      _birdY += _birdVelocity;

      // Update bird rotation based on its velocity for a tilting effect
      _birdRotation = min(max(-0.8, _birdVelocity / 15), 0.8);

      // Move pipes to the left
      for (int i = 0; i < _pipes.length; i++) {
        _pipes[i] = _pipes[i].translate(-pipeSpeed, 0);

        // Check if the pipe has gone off-screen
        if (_pipes[i].dx < -pipeWidth) {
          // Reset the pipe to the right with a new random height
          _pipes[i] = Offset(
            MediaQuery.of(context).size.width,
            _random.nextDouble() * (MediaQuery.of(context).size.height - pipeGap - groundHeight * 2) + groundHeight,
          );
          // Increment score when a pipe is passed
          _score++;
        }
      }

      _checkCollisions();
    });
  }

  // Checks for collisions with the ground, ceiling, and pipes
  void _checkCollisions() {
    final birdRect = Rect.fromCenter(center: Offset(birdXPosition, _birdY), width: birdSize, height: birdSize);
    final screenHeight = MediaQuery.of(context).size.height;

    // Ground and ceiling collision
    if (birdRect.bottom > screenHeight - groundHeight || birdRect.top < 0) {
      _endGame();
      return;
    }

    // Pipe collision
    for (final pipe in _pipes) {
      final topPipeRect = Rect.fromLTWH(pipe.dx, 0, pipeWidth, pipe.dy);
      final bottomPipeRect = Rect.fromLTWH(pipe.dx, pipe.dy + pipeGap, pipeWidth, screenHeight - (pipe.dy + pipeGap));

      if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
        _endGame();
        return;
      }
    }
  }

  // Bird flap action
  void _flap() {
    if (_gameState == GameState.playing) {
      setState(() {
        _birdVelocity = jumpVelocity;
      });
    } else if (_gameState == GameState.ready) {
      _startGame();
    }
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
    });
    _controller.repeat();
    _flap(); // Initial flap to start
  }

  void _endGame() {
    _controller.stop();
    setState(() {
      _gameState = GameState.gameOver;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_gameState == GameState.gameOver) {
            _resetGame();
          } else {
            _flap();
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: GamePainter(
            birdY: _birdY,
            birdRotation: _birdRotation,
            pipes: _pipes,
            gameState: _gameState,
            score: _score,
          ),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final double birdY;
  final double birdRotation;
  final List<Offset> pipes;
  final GameState gameState;
  final int score;

  GamePainter({
    required this.birdY,
    required this.birdRotation,
    required this.pipes,
    required this.gameState,
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all game elements
    _drawBackground(canvas, size);
    _drawPipes(canvas, size);
    _drawGround(canvas, size);
    _drawBird(canvas, size);
    _drawScore(canvas, size);

    // Show game over overlay if the state is gameOver
    if (gameState == GameState.gameOver) {
      _drawGameOver(canvas, size);
    }
    // Show ready message if the state is ready
    if (gameState == GameState.ready) {
      _drawReady(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF81D4FA); // Light blue sky
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundPaint = Paint()..color = const Color(0xFF5D4037); // Brown dirt
    final grassPaint = Paint()..color = const Color(0xFF66BB6A); // Green grass
    
    // Draw dirt layer
    canvas.drawRect(Rect.fromLTWH(0, size.height - groundHeight, size.width, groundHeight), groundPaint);
    // Draw grass on top of dirt
    canvas.drawRect(Rect.fromLTWH(0, size.height - groundHeight, size.width, 20), grassPaint);
  }

  void _drawBird(Canvas canvas, Size size) {
    final birdPaint = Paint()..color = Colors.yellow; // Yellow bird body
    final wingPaint = Paint()..color = Colors.amber; // Darker yellow for wing
    
    canvas.save();
    // Translate and rotate the canvas to draw the bird
    canvas.translate(birdXPosition, birdY);
    canvas.rotate(birdRotation);

    // Bird body (oval)
    final birdRect = Rect.fromCenter(center: Offset.zero, width: birdSize, height: birdSize * 0.8);
    canvas.drawOval(birdRect, birdPaint);
    
    // Bird eye
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(const Offset(birdSize * 0.2, -birdSize * 0.1), 3, eyePaint);
    
    // Bird wing (a simple path)
    final wingPath = Path()
      ..moveTo(-birdSize * 0.1, 0)
      ..quadraticBezierTo(0, birdSize * 0.3, birdSize * 0.1, 0)
      ..quadraticBezierTo(0, -birdSize * 0.3, -birdSize * 0.1, 0)
      ..close();
    canvas.drawPath(wingPath, wingPaint);
    
    canvas.restore();
  }

  void _drawPipes(Canvas canvas, Size size) {
    final pipePaint = Paint()..color = const Color(0xFF4CAF50); // Green pipes
    final pipeBorderPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final pipe in pipes) {
      // Top pipe
      final topPipeRect = Rect.fromLTWH(pipe.dx, 0, pipeWidth, pipe.dy);
      final topPipeCapRect = Rect.fromLTWH(pipe.dx - 5, pipe.dy - 30, pipeWidth + 10, 30);
      
      canvas.drawRect(topPipeRect, pipePaint);
      canvas.drawRect(topPipeRect, pipeBorderPaint);
      canvas.drawRect(topPipeCapRect, pipePaint);
      canvas.drawRect(topPipeCapRect, pipeBorderPaint);
      
      // Bottom pipe
      final bottomPipeY = pipe.dy + pipeGap;
      final bottomPipeRect = Rect.fromLTWH(pipe.dx, bottomPipeY, pipeWidth, size.height - bottomPipeY);
      final bottomPipeCapRect = Rect.fromLTWH(pipe.dx - 5, bottomPipeY, pipeWidth + 10, 30);

      canvas.drawRect(bottomPipeRect, pipePaint);
      canvas.drawRect(bottomPipeRect, pipeBorderPaint);
      canvas.drawRect(bottomPipeCapRect, pipePaint);
      canvas.drawRect(bottomPipeCapRect, pipeBorderPaint);
    }
  }

  void _drawScore(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 60,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 3.0,
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(2.0, 2.0),
        ),
      ],
    );
    final textSpan = TextSpan(
      text: score.toString(),
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset((size.width - textPainter.width) / 2, 50);
    textPainter.paint(canvas, offset);
  }

  void _drawGameOver(Canvas canvas, Size size) {
    // Semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // "Game Over" text
    _drawText(canvas, size, "Game Over", 60, size.height / 2 - 100);
    // Final score text
    _drawText(canvas, size, "Score: $score", 40, size.height / 2);
    // Restart instruction text
    _drawText(canvas, size, "Tap to Restart", 24, size.height / 2 + 60);
  }

  void _drawReady(Canvas canvas, Size size) {
    // "Tap to Play" instruction text
    _drawText(canvas, size, "Tap to Play", 40, size.height / 2);
  }

  // Helper function to draw centered text
  void _drawText(Canvas canvas, Size size, String text, double fontSize, double yOffset) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 3.0,
          color: Colors.black.withOpacity(0.7),
          offset: const Offset(3.0, 3.0),
        ),
      ],
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offset = Offset((size.width - textPainter.width) / 2, yOffset);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint on every frame to animate the game
    return true;
  }
}
