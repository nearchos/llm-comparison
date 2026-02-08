import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const FlappyBirdApp());
}

// ============================================================================
// GAME CONSTANTS - Tune these values to adjust gameplay feel
// ============================================================================
class GameConstants {
  static const double gravity = 0.5;           // Downward acceleration
  static const double jumpVelocity = -10.0;   // Upward velocity when tapping
  static const double pipeSpeed = 3.0;         // Horizontal pipe movement speed
  static const double pipeGap = 150.0;         // Vertical gap between pipes
  static const double pipeWidth = 60.0;        // Width of each pipe
  static const double pipeSpacing = 250.0;     // Horizontal spacing between pipes
  static const double birdSize = 30.0;         // Bird diameter
  static const double groundHeight = 100.0;    // Height of ground/floor
}

// ============================================================================
// MAIN APP
// ============================================================================
class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flappy Bird',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

// ============================================================================
// GAME SCREEN - Main game widget with state management
// ============================================================================
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Bird state
  double birdY = 0;              // Vertical position relative to center
  double birdVelocity = 0;       // Current vertical velocity
  double birdRotation = 0;       // Bird rotation angle
  
  // Pipes
  List<Pipe> pipes = [];
  
  // Game state
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller for 60 FPS game loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // Essentially infinite
    );
    
    _controller.addListener(_gameLoop);
    _initializeGame();
  }
  
  // Initialize/reset game state
  void _initializeGame() {
    setState(() {
      birdY = 0;
      birdVelocity = 0;
      birdRotation = 0;
      pipes.clear();
      score = 0;
      isPlaying = false;
      isGameOver = false;
      
      // Create initial set of pipes
      for (int i = 0; i < 4; i++) {
        pipes.add(Pipe(
          x: 400.0 + i * GameConstants.pipeSpacing,
          gapY: _randomGapPosition(),
        ));
      }
    });
  }
  
  // Generate random gap position (normalized 0-1)
  double _randomGapPosition() {
    final random = Random();
    // Keep gap between 20% and 65% of playable height
    return 0.2 + random.nextDouble() * 0.45;
  }
  
  // Main game loop - called every frame
  void _gameLoop() {
    if (!isPlaying || isGameOver) return;
    
    setState(() {
      // Apply gravity to bird
      birdVelocity += GameConstants.gravity;
      birdY += birdVelocity;
      
      // Update bird rotation based on velocity
      birdRotation = (birdVelocity / 15).clamp(-1.5, 1.5);
      
      // Move all pipes to the left
      for (var pipe in pipes) {
        pipe.x -= GameConstants.pipeSpeed;
      }
      
      // Recycle pipes: remove off-screen pipes and add new ones
      if (pipes.isNotEmpty && pipes.first.x < -GameConstants.pipeWidth) {
        pipes.removeAt(0);
        pipes.add(Pipe(
          x: pipes.last.x + GameConstants.pipeSpacing,
          gapY: _randomGapPosition(),
        ));
      }
      
      // Update score when bird passes pipe center
      for (var pipe in pipes) {
        if (!pipe.passed && pipe.x + GameConstants.pipeWidth / 2 < MediaQuery.of(context).size.width * 0.2) {
          pipe.passed = true;
          score++;
        }
      }
      
      // Check for collisions
      _checkCollisions();
    });
  }
  
  // Collision detection
  void _checkCollisions() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Bird position in screen coordinates
    final birdScreenY = screenHeight / 2 + birdY;
    final birdCenterX = screenWidth * 0.2;
    final birdRadius = GameConstants.birdSize / 2;
    
    // Check collision with ground and ceiling
    if (birdScreenY + birdRadius > screenHeight - GameConstants.groundHeight ||
        birdScreenY - birdRadius < 0) {
      _triggerGameOver();
      return;
    }
    
    // Check collision with pipes
    for (var pipe in pipes) {
      final pipeLeft = pipe.x;
      final pipeRight = pipe.x + GameConstants.pipeWidth;
      
      // Check if bird overlaps horizontally with pipe
      if (birdCenterX + birdRadius > pipeLeft && 
          birdCenterX - birdRadius < pipeRight) {
        
        final gapTop = (screenHeight - GameConstants.groundHeight) * pipe.gapY;
        final gapBottom = gapTop + GameConstants.pipeGap;
        
        // Check if bird is outside the gap vertically
        if (birdScreenY - birdRadius < gapTop || 
            birdScreenY + birdRadius > gapBottom) {
          _triggerGameOver();
          return;
        }
      }
    }
  }
  
  void _triggerGameOver() {
    setState(() {
      isGameOver = true;
      isPlaying = false;
    });
  }
  
  // Handle tap input
  void _onTap() {
    if (isGameOver) {
      // Restart game
      _initializeGame();
    } else if (!isPlaying) {
      // Start game
      setState(() {
        isPlaying = true;
      });
      _controller.forward(from: 0);
    }
    
    // Make bird jump (flap)
    if (isPlaying && !isGameOver) {
      setState(() {
        birdVelocity = GameConstants.jumpVelocity;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Main game canvas
            CustomPaint(
              painter: GamePainter(
                birdY: birdY,
                birdRotation: birdRotation,
                pipes: pipes,
              ),
              size: Size.infinite,
            ),
            
            // Score display
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Game over overlay
            if (isGameOver)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Game Over',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Tap to Restart',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Start screen overlay
            if (!isPlaying && !isGameOver)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: Text(
                    'Tap to Start',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================================================
// PIPE DATA CLASS
// ============================================================================
class Pipe {
  double x;              // Horizontal position
  double gapY;           // Gap position (0-1 normalized)
  bool passed;           // Whether bird has passed this pipe
  
  Pipe({
    required this.x,
    required this.gapY,
    this.passed = false,
  });
}

// ============================================================================
// GAME PAINTER - Renders all game graphics
// ============================================================================
class GamePainter extends CustomPainter {
  final double birdY;
  final double birdRotation;
  final List<Pipe> pipes;
  
  GamePainter({
    required this.birdY,
    required this.birdRotation,
    required this.pipes,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw sky background
    _drawBackground(canvas, size);
    
    // Draw all pipes
    for (var pipe in pipes) {
      _drawPipe(canvas, size, pipe);
    }
    
    // Draw ground
    _drawGround(canvas, size);
    
    // Draw bird (drawn last so it appears on top)
    _drawBird(canvas, size);
  }
  
  void _drawBackground(Canvas canvas, Size size) {
    // Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4EC0CA),
          const Color(0xFF87CEEB),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      skyPaint,
    );
  }
  
  void _drawGround(Canvas canvas, Size size) {
    // Ground base
    final groundPaint = Paint()..color = const Color(0xFFDEB887);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - GameConstants.groundHeight,
        size.width,
        GameConstants.groundHeight,
      ),
      groundPaint,
    );
    
    // Ground grass pattern
    final grassPaint = Paint()..color = const Color(0xFF8B7355);
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawRect(
        Rect.fromLTWH(
          i,
          size.height - GameConstants.groundHeight,
          15,
          15,
        ),
        grassPaint,
      );
    }
    
    // Ground outline
    final groundOutlinePaint = Paint()
      ..color = const Color(0xFF654321)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, size.height - GameConstants.groundHeight),
      Offset(size.width, size.height - GameConstants.groundHeight),
      groundOutlinePaint,
    );
  }
  
  void _drawPipe(Canvas canvas, Size size, Pipe pipe) {
    final playableHeight = size.height - GameConstants.groundHeight;
    final gapTop = playableHeight * pipe.gapY;
    final gapBottom = gapTop + GameConstants.pipeGap;
    
    // Pipe colors
    final pipePaint = Paint()..color = const Color(0xFF6BBF59);
    final pipeHighlightPaint = Paint()..color = const Color(0xFF7DD968);
    final pipeOutlinePaint = Paint()
      ..color = const Color(0xFF4A8F3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final pipeCapPaint = Paint()..color = const Color(0xFF5FA84E);
    
    // Top pipe body
    final topPipeRect = Rect.fromLTWH(
      pipe.x,
      0,
      GameConstants.pipeWidth,
      gapTop - 30,
    );
    canvas.drawRect(topPipeRect, pipePaint);
    
    // Top pipe highlight
    canvas.drawRect(
      Rect.fromLTWH(pipe.x + 5, 0, 15, gapTop - 30),
      pipeHighlightPaint,
    );
    
    canvas.drawRect(topPipeRect, pipeOutlinePaint);
    
    // Top pipe cap
    final topCapRect = Rect.fromLTWH(
      pipe.x - 5,
      gapTop - 30,
      GameConstants.pipeWidth + 10,
      30,
    );
    canvas.drawRect(topCapRect, pipeCapPaint);
    canvas.drawRect(topCapRect, pipeOutlinePaint);
    
    // Bottom pipe body
    final bottomPipeRect = Rect.fromLTWH(
      pipe.x,
      gapBottom + 30,
      GameConstants.pipeWidth,
      playableHeight - gapBottom - 30,
    );
    canvas.drawRect(bottomPipeRect, pipePaint);
    
    // Bottom pipe highlight
    canvas.drawRect(
      Rect.fromLTWH(
        pipe.x + 5,
        gapBottom + 30,
        15,
        playableHeight - gapBottom - 30,
      ),
      pipeHighlightPaint,
    );
    
    canvas.drawRect(bottomPipeRect, pipeOutlinePaint);
    
    // Bottom pipe cap
    final bottomCapRect = Rect.fromLTWH(
      pipe.x - 5,
      gapBottom,
      GameConstants.pipeWidth + 10,
      30,
    );
    canvas.drawRect(bottomCapRect, pipeCapPaint);
    canvas.drawRect(bottomCapRect, pipeOutlinePaint);
  }
  
  void _drawBird(Canvas canvas, Size size) {
    final birdCenterX = size.width * 0.2;
    final birdCenterY = size.height / 2 + birdY;
    
    canvas.save();
    canvas.translate(birdCenterX, birdCenterY);
    canvas.rotate(birdRotation * 0.3); // Rotation in radians
    
    // Bird body (main circle)
    final bodyPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(
      Offset.zero,
      GameConstants.birdSize / 2,
      bodyPaint,
    );
    
    // Body highlight
    final highlightPaint = Paint()..color = const Color(0xFFFFE55C);
    canvas.drawCircle(
      const Offset(-3, -3),
      GameConstants.birdSize / 3,
      highlightPaint,
    );
    
    // Body outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFDAA520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      Offset.zero,
      GameConstants.birdSize / 2,
      outlinePaint,
    );
    
    // Wing
    final wingPaint = Paint()..color = const Color(0xFFFFA500);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-2, 5),
        width: 16,
        height: 12,
      ),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-2, 5),
        width: 16,
        height: 12,
      ),
      Paint()
        ..color = const Color(0xFFFF8C00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    
    // Eye white
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(10, -5), 6, eyeWhitePaint);
    
    // Eye outline
    canvas.drawCircle(
      const Offset(10, -5),
      6,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    
    // Pupil
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(const Offset(11, -4), 3, pupilPaint);
    
    // Beak
    final beakPaint = Paint()..color = const Color(0xFFFF8C00);
    final beakPath = Path()
      ..moveTo(14, 0)
      ..lineTo(25, -2)
      ..lineTo(25, 4)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    
    // Beak outline
    canvas.drawPath(
      beakPath,
      Paint()
        ..color = const Color(0xFFFF6600)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    
    canvas.restore();
  }
  
  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}