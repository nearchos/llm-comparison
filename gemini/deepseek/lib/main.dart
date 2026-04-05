import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

enum GameState { ready, playing, gameOver }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Game State
  GameState gameState = GameState.ready;
  late Ticker _ticker;
  
  // Bird Physics
  double birdY = 0; // 0 is center of screen
  double birdVelocity = 0;
  double birdRotation = 0;
  final double gravity = 0.8;
  final double jumpStrength = -10;
  final double birdRadius = 20;

  // Pipes
  List<Pipe> pipes = [];
  double pipeSpeed = 3.5;
  double pipeSpawnTimer = 0;
  final double pipeWidth = 60;
  final double pipeGap = 160;

  // Scoring
  int score = 0;
  int highscore = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    if (gameState != GameState.playing) return;

    setState(() {
      // Apply Gravity
      birdVelocity += gravity;
      birdY += birdVelocity;
      
      // Rotate bird based on velocity
      birdRotation = (birdVelocity * 0.05).clamp(-0.5, 0.5);

      // Move Pipes
      for (var pipe in pipes) {
        pipe.x -= pipeSpeed;
        
        // Score point when passing pipe
        if (!pipe.passed && pipe.x + pipeWidth < -MediaQuery.of(context).size.width / 2 + 100) {
          pipe.passed = true;
          score++;
        }
      }

      // Remove off-screen pipes
      pipes.removeWhere((pipe) => pipe.x < -MediaQuery.of(context).size.width);

      // Spawn Pipes
      pipeSpawnTimer++;
      if (pipeSpawnTimer > 80) {
        _spawnPipe();
        pipeSpawnTimer = 0;
      }

      _checkCollisions();
    });
  }

  void _spawnPipe() {
    final random = Random();
    // Random height for the gap (relative to center)
    double gapCenterY = (random.nextDouble() * 200) - 100;
    pipes.add(Pipe(x: MediaQuery.of(context).size.width / 2, gapY: gapCenterY));
  }

  void _checkCollisions() {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Ground/Ceiling collision
    if (birdY.abs() > screenHeight / 2) {
      _endGame();
    }

    // Pipe collision
    double birdX = -MediaQuery.of(context).size.width / 4; // Visual offset for bird
    for (var pipe in pipes) {
      // Horizontal check
      if (birdX + birdRadius > pipe.x && birdX - birdRadius < pipe.x + pipeWidth) {
        // Vertical check (Top pipe or Bottom pipe)
        if (birdY - birdRadius < pipe.gapY - pipeGap / 2 || 
            birdY + birdRadius > pipe.gapY + pipeGap / 2) {
          _endGame();
        }
      }
    }
  }

  void _startGame() {
    setState(() {
      gameState = GameState.playing;
      birdY = 0;
      birdVelocity = 0;
      pipes.clear();
      score = 0;
      _spawnPipe();
    });
    _ticker.start();
  }

  void _jump() {
    if (gameState == GameState.playing) {
      setState(() {
        birdVelocity = jumpStrength;
      });
    } else if (gameState == GameState.ready || gameState == GameState.gameOver) {
      _startGame();
    }
  }

  void _endGame() {
    _ticker.stop();
    setState(() {
      gameState = GameState.gameOver;
      if (score > highscore) highscore = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: Stack(
          children: [
            // Background & Game World
            CustomPaint(
              painter: GamePainter(
                birdY: birdY,
                birdRotation: birdRotation,
                pipes: pipes,
                gameState: gameState,
                pipeWidth: pipeWidth,
                pipeGap: pipeGap,
              ),
              child: Container(),
            ),
            
            // UI Overlay
            SafeArea(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      "$score",
                      style: const TextStyle(
                        fontSize: 80, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    if (gameState == GameState.ready) ...[
                      const Spacer(),
                      const Text("TAP TO START", style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                    ],
                    if (gameState == GameState.gameOver) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          children: [
                            const Text("GAME OVER", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red)),
                            Text("Highscore: $highscore", style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 10),
                            const Text("Tap to Try Again", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pipe {
  double x;
  double gapY;
  bool passed = false;
  Pipe({required this.x, required this.gapY});
}

class GamePainter extends CustomPainter {
  final double birdY;
  final double birdRotation;
  final List<Pipe> pipes;
  final GameState gameState;
  final double pipeWidth;
  final double pipeGap;

  GamePainter({
    required this.birdY,
    required this.birdRotation,
    required this.pipes,
    required this.gameState,
    required this.pipeWidth,
    required this.pipeGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 1. Draw Background (Sky)
    paint.color = Colors.lightBlue.shade300;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 2. Draw Ground
    paint.color = Colors.orange.shade200;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2), paint);
    paint.color = Colors.green.shade400;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.8, size.width, 20), paint);

    // Coordinate System Translation (Center middle-ish)
    canvas.save();
    canvas.translate(size.width / 4, size.height / 2);

    // 3. Draw Pipes
    for (var pipe in pipes) {
      paint.color = Colors.green.shade700;
      double relativeX = pipe.x - (size.width / 4); // Offset to match bird's logic

      // Top Pipe
      canvas.drawRect(
        Rect.fromLTRB(relativeX, -size.height, relativeX + pipeWidth, pipe.gapY - pipeGap / 2),
        paint,
      );
      // Top Pipe Cap
      canvas.drawRect(
        Rect.fromLTRB(relativeX - 5, pipe.gapY - pipeGap / 2 - 30, relativeX + pipeWidth + 5, pipe.gapY - pipeGap / 2),
        paint,
      );

      // Bottom Pipe
      canvas.drawRect(
        Rect.fromLTRB(relativeX, pipe.gapY + pipeGap / 2, relativeX + pipeWidth, size.height),
        paint,
      );
      // Bottom Pipe Cap
      canvas.drawRect(
        Rect.fromLTRB(relativeX - 5, pipe.gapY + pipeGap / 2, relativeX + pipeWidth + 5, pipe.gapY + pipeGap / 2 + 30),
        paint,
      );
    }

    // 4. Draw Bird
    canvas.save();
    canvas.translate(0, birdY);
    canvas.rotate(birdRotation);
    
    // Body (Yellow)
    paint.color = Colors.yellow;
    canvas.drawCircle(Offset.zero, 20, paint);
    
    // Eye
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(10, -8), 6, paint);
    paint.color = Colors.black;
    canvas.drawCircle(const Offset(12, -8), 2, paint);
    
    // Beak
    paint.color = Colors.orange;
    Path beak = Path()
      ..moveTo(15, 0)
      ..lineTo(25, 5)
      ..lineTo(15, 10)
      ..close();
    canvas.drawPath(beak, paint);
    
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}