import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(const FlappyBirdGame());
}

class FlappyBirdGame extends StatelessWidget {
  const FlappyBirdGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const GameScreen(),
    );
  }
}

/// Main game screen that manages game state and rendering
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late GameEngine _gameEngine;
  Timer? _gameTimer;
  
  // Game state flags
  bool _isGameRunning = false;
  bool _isGameOver = false;
  int _currentScore = 0;
  
  // Game constants - tuning for classic Flappy Bird feel
  static const double _gravity = 1200.0;          // pixels per second squared
  static const double _jumpVelocity = -320.0;      // upward velocity on tap (pixels per second)
  static const double _pipeSpeed = 180.0;          // pixels per second moving left
  static const double _pipeSpawnInterval = 2.0;    // seconds between pipe spawns
  static const double _pipeGapSize = 160.0;        // gap height between pipes
  static const double _pipeWidth = 70.0;            // pipe width
  static const double _birdSize = 32.0;             // bird width/height
  
  @override
  void initState() {
    super.initState();
    // Create animation controller for smooth game loop
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onGameLoopUpdate);
    
    _gameEngine = GameEngine(
      gravity: _gravity,
      jumpVelocity: _jumpVelocity,
      pipeSpeed: _pipeSpeed,
      pipeGapSize: _pipeGapSize,
      pipeWidth: _pipeWidth,
      birdSize: _birdSize,
    );
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  /// Called every frame to update physics and collision
  void _onGameLoopUpdate() {
    if (!_isGameRunning) return;
    
    final double deltaTime = _animationController.value; // seconds since last frame
    if (deltaTime > 0.033) return; // Cap large deltas
    
    _gameEngine.update(deltaTime);
    
    // Check for collisions
    if (_gameEngine.checkCollisions()) {
      _endGame();
    }
    
    // Check for scoring (passing pipes)
    final int newScore = _gameEngine.updateScore();
    if (newScore != _currentScore) {
      setState(() {
        _currentScore = newScore;
      });
    }
    
    setState(() {}); // Trigger repaint
  }
  
  void _startGame() {
    setState(() {
      _isGameRunning = true;
      _isGameOver = false;
      _currentScore = 0;
      _gameEngine.reset();
    });
    
    // Start the animation loop
    _animationController.repeat(min: 0.016, max: 0.033); // Target 30-60 FPS
    
    // Spawn pipes at regular intervals
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(milliseconds: (_pipeSpawnInterval * 1000).round()), (timer) {
      if (_isGameRunning) {
        _gameEngine.spawnPipe();
      }
    });
  }
  
  void _endGame() {
    setState(() {
      _isGameRunning = false;
      _isGameOver = true;
    });
    _animationController.stop();
    _gameTimer?.cancel();
  }
  
  void _restartGame() {
    _startGame();
  }
  
  void _handleTap() {
    if (_isGameRunning) {
      _gameEngine.flap();
    } else if (_isGameOver) {
      _restartGame();
    } else {
      _startGame();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        child: Container(
          color: const Color(0xFF87CEEB), // Sky blue background
          child: Stack(
            children: [
              // Main game canvas
              CustomPaint(
                size: Size.infinite,
                painter: GamePainter(
                  gameEngine: _gameEngine,
                  screenSize: MediaQuery.of(context).size,
                  isGameOver: _isGameOver,
                ),
              ),
              
              // Score display
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_currentScore',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Game over overlay
              if (_isGameOver)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Score: $_currentScore',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tap to Restart',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Start instruction overlay (when not playing and not game over)
              if (!_isGameRunning && !_isGameOver)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 48, color: Colors.white70),
                        SizedBox(height: 15),
                        Text(
                          'Tap to Start',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap screen to flap bird',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          'Avoid pipes and ground',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Core game logic: physics, pipes, collision detection
class GameEngine {
  final double gravity;
  final double jumpVelocity;
  final double pipeSpeed;
  final double pipeGapSize;
  final double pipeWidth;
  final double birdSize;
  
  // Bird physics
  double birdY = 0;
  double birdVelocity = 0;
  
  // Pipes list: each pipe is defined by its x position and gap Y center
  final List<Pipe> pipes = [];
  
  // Scoring
  int score = 0;
  int _lastScoredPipeIndex = -1;
  
  // Screen dimensions (updated each frame)
  double screenHeight = 800;
  double screenWidth = 400;
  
  // Ground level (pixels from top)
  double groundY = 700;
  
  // Random generator for pipe gaps
  final Random _random = Random();
  
  GameEngine({
    required this.gravity,
    required this.jumpVelocity,
    required this.pipeSpeed,
    required this.pipeGapSize,
    required this.pipeWidth,
    required this.birdSize,
  });
  
  /// Reset game to initial state
  void reset() {
    birdY = screenHeight / 2;
    birdVelocity = 0;
    pipes.clear();
    score = 0;
    _lastScoredPipeIndex = -1;
  }
  
  /// Apply flap impulse
  void flap() {
    birdVelocity = jumpVelocity;
  }
  
  /// Update physics for one frame
  void update(double deltaTime) {
    // Apply gravity
    birdVelocity += gravity * deltaTime;
    birdY += birdVelocity * deltaTime;
    
    // Update pipe positions
    for (final pipe in pipes) {
      pipe.x -= pipeSpeed * deltaTime;
    }
    
    // Remove offscreen pipes
    pipes.removeWhere((pipe) => pipe.x + pipeWidth < 0);
  }
  
  /// Spawn a new pipe at the right edge
  void spawnPipe() {
    // Ensure gap stays within bounds (not too high or too low)
    final double minGapY = pipeGapSize / 2 + 80;
    final double maxGapY = screenHeight - groundY - pipeGapSize / 2 - 80;
    double gapCenterY = minGapY + _random.nextDouble() * (maxGapY - minGapY);
    gapCenterY = gapCenterY.clamp(minGapY, maxGapY);
    
    pipes.add(Pipe(
      x: screenWidth,
      gapCenterY: gapCenterY,
      gapSize: pipeGapSize,
      width: pipeWidth,
    ));
  }
  
  /// Check collision with pipes, ground, or ceiling
  bool checkCollisions() {
    // Ceiling collision (top of screen)
    if (birdY <= 0) return true;
    
    // Ground collision
    if (birdY + birdSize >= groundY) return true;
    
    // Bird rectangle for collision
    final Rect birdRect = Rect.fromLTWH(
      screenWidth * 0.25, // Fixed horizontal position
      birdY,
      birdSize,
      birdSize,
    );
    
    // Check each pipe
    for (final pipe in pipes) {
      // Top pipe rectangle
      final Rect topPipeRect = Rect.fromLTWH(
        pipe.x,
        0,
        pipe.width,
        pipe.gapCenterY - pipe.gapSize / 2,
      );
      
      // Bottom pipe rectangle
      final Rect bottomPipeRect = Rect.fromLTWH(
        pipe.x,
        pipe.gapCenterY + pipe.gapSize / 2,
        pipe.width,
        screenHeight - (pipe.gapCenterY + pipe.gapSize / 2),
      );
      
      if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Update score by checking if bird has passed pipes
  int updateScore() {
    final double birdCenterX = screenWidth * 0.25 + birdSize / 2;
    
    for (int i = 0; i < pipes.length; i++) {
      final pipe = pipes[i];
      final double pipeRightEdge = pipe.x + pipe.width;
      
      // If bird passed this pipe and hasn't scored it yet
      if (birdCenterX > pipeRightEdge && i > _lastScoredPipeIndex) {
        _lastScoredPipeIndex = i;
        score++;
        break;
      }
    }
    
    return score;
  }
  
  /// Update screen dimensions (called from painter)
  void updateScreenSize(Size size) {
    screenWidth = size.width;
    screenHeight = size.height;
    groundY = screenHeight - 80; // Ground at bottom
  }
  
  /// Get bird angle in radians based on velocity (for visual tilt)
  double getBirdRotation() {
    // Clamp velocity to reasonable range
    final double clampedVel = birdVelocity.clamp(-400, 400);
    // Map velocity to angle between -0.5 and 0.8 rad
    return (clampedVel / 600).clamp(-0.6, 0.8);
  }
}

/// Data class for a pipe obstacle
class Pipe {
  double x;
  final double gapCenterY;
  final double gapSize;
  final double width;
  
  Pipe({
    required this.x,
    required this.gapCenterY,
    required this.gapSize,
    required this.width,
  });
}

/// Custom painter that draws all game elements
class GamePainter extends CustomPainter {
  final GameEngine gameEngine;
  final Size screenSize;
  final bool isGameOver;
  
  GamePainter({
    required this.gameEngine,
    required this.screenSize,
    required this.isGameOver,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Update engine with current dimensions
    gameEngine.updateScreenSize(size);
    
    // Draw sky gradient (light blue to slightly darker)
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [Color(0xFF87CEEB), Color(0xFF6BB5D9)],
    );
    final skyPaint = Paint()
      ..shader = skyGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
    
    // Draw clouds (simple decorative)
    _drawCloud(canvas, 50, 80, 60);
    _drawCloud(canvas, size.width - 120, 120, 80);
    _drawCloud(canvas, size.width * 0.3, 180, 50);
    
    // Draw pipes
    for (final pipe in gameEngine.pipes) {
      _drawPipe(canvas, pipe, size);
    }
    
    // Draw ground
    final groundPaint = Paint()
      ..color = const Color(0xFF8B5A2B)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, gameEngine.groundY, size.width, size.height - gameEngine.groundY), groundPaint);
    
    // Draw grass strip on ground
    final grassPaint = Paint()
      ..color = const Color(0xFF6B8E23)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, gameEngine.groundY - 8, size.width, 8), grassPaint);
    
    // Draw bird
    _drawBird(canvas, gameEngine);
    
    // Draw game over overlay tint (semi-transparent)
    if (isGameOver) {
      final overlayPaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
    }
  }
  
  void _drawCloud(Canvas canvas, double x, double y, double size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), size * 0.5, paint);
    canvas.drawCircle(Offset(x + size * 0.4, y - size * 0.2), size * 0.4, paint);
    canvas.drawCircle(Offset(x - size * 0.3, y - size * 0.1), size * 0.45, paint);
    canvas.drawCircle(Offset(x + size * 0.2, y + size * 0.1), size * 0.4, paint);
  }
  
  void _drawPipe(Canvas canvas, Pipe pipe, Size size) {
    // Pipe green color with shading
    final pipePaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.fill;
    
    final pipeBorderPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Top pipe
    final topHeight = pipe.gapCenterY - pipe.gapSize / 2;
    final topRect = Rect.fromLTWH(pipe.x, 0, pipe.width, topHeight);
    canvas.drawRect(topRect, pipePaint);
    canvas.drawRect(topRect, pipeBorderPaint);
    
    // Pipe rim (top pipe)
    final rimPaint = Paint()
      ..color = const Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTWH(pipe.x - 5, topHeight - 25, pipe.width + 10, 25), rimPaint);
    
    // Bottom pipe
    final bottomY = pipe.gapCenterY + pipe.gapSize / 2;
    final bottomHeight = size.height - bottomY;
    final bottomRect = Rect.fromLTWH(pipe.x, bottomY, pipe.width, bottomHeight);
    canvas.drawRect(bottomRect, pipePaint);
    canvas.drawRect(bottomRect, pipeBorderPaint);
    
    // Pipe rim (bottom pipe)
    canvas.drawRect(Rect.fromLTWH(pipe.x - 5, bottomY, pipe.width + 10, 25), rimPaint);
  }
  
  void _drawBird(Canvas canvas, GameEngine engine) {
    final double birdX = engine.screenWidth * 0.25;
    final double birdY = engine.birdY;
    final double birdSize = engine.birdSize;
    
    canvas.save();
    // Translate to bird center and rotate
    canvas.translate(birdX + birdSize / 2, birdY + birdSize / 2);
    canvas.rotate(engine.getBirdRotation());
    canvas.translate(-(birdX + birdSize / 2), -(birdY + birdSize / 2));
    
    // Bird body (yellow)
    final bodyPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(birdX, birdY, birdSize, birdSize),
        const Radius.circular(12),
      ),
      bodyPaint,
    );
    
    // Bird wing (darker yellow/orange)
    final wingPaint = Paint()
      ..color = const Color(0xFFFFA500)
      ..style = PaintingStyle.fill;
    final wingPath = Path();
    wingPath.moveTo(birdX + birdSize * 0.15, birdY + birdSize * 0.5);
    wingPath.quadraticBezierTo(
      birdX + birdSize * 0.5, birdY + birdSize * 0.3,
      birdX + birdSize * 0.85, birdY + birdSize * 0.5,
    );
    wingPath.quadraticBezierTo(
      birdX + birdSize * 0.5, birdY + birdSize * 0.7,
      birdX + birdSize * 0.15, birdY + birdSize * 0.5,
    );
    canvas.drawPath(wingPath, wingPaint);
    
    // Bird eye (white)
    final eyeWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(birdX + birdSize * 0.7, birdY + birdSize * 0.35),
      birdSize * 0.12,
      eyeWhitePaint,
    );
    
    // Bird pupil (black)
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(birdX + birdSize * 0.73, birdY + birdSize * 0.35),
      birdSize * 0.06,
      pupilPaint,
    );
    
    // Bird beak (orange)
    final beakPaint = Paint()
      ..color = const Color(0xFFFF6347)
      ..style = PaintingStyle.fill;
    final beakPath = Path();
    beakPath.moveTo(birdX + birdSize * 0.85, birdY + birdSize * 0.4);
    beakPath.lineTo(birdX + birdSize * 0.95, birdY + birdSize * 0.45);
    beakPath.lineTo(birdX + birdSize * 0.85, birdY + birdSize * 0.5);
    beakPath.close();
    canvas.drawPath(beakPath, beakPaint);
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.gameEngine != gameEngine || 
           oldDelegate.screenSize != screenSize ||
           oldDelegate.isGameOver != isGameOver;
  }
}