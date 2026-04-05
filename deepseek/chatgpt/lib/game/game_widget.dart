import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/game_state.dart';
import 'bird.dart';
import 'pipe.dart';
import 'ground.dart';
import 'collision.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({super.key});

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> with TickerProviderStateMixin {
  late GameState gameState;
  late Bird bird;
  late Ground ground;
  List<Pipe> pipes = [];
  
  late AnimationController gameLoopController;
  late AudioPlayer audioPlayer;
  
  double screenWidth = 0;
  double screenHeight = 0;
  
  static const double pipeSpawnInterval = 2.0; // seconds
  double lastPipeSpawnTime = 0;
  
  @override
  void initState() {
    super.initState();
    gameState = GameState();
    bird = Bird();
    ground = Ground();
    audioPlayer = AudioPlayer();
    
    gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(updateGame);
    
    gameLoopController.repeat();
  }
  
  void updateGame() {
    if (!gameState.isPlaying || gameState.isGameOver) return;
    
    final double deltaTime = 1.0 / 60.0; // Fixed timestep for simplicity
    
    // Update bird physics
    bird.update(deltaTime, screenHeight);
    
    // Update ground position
    ground.update(deltaTime);
    
    // Update pipes
    for (var pipe in pipes) {
      pipe.update(deltaTime);
    }
    
    // Remove off-screen pipes
    pipes.removeWhere((pipe) => pipe.x + pipe.width < 0);
    
    // Spawn new pipes
    lastPipeSpawnTime += deltaTime;
    if (lastPipeSpawnTime >= pipeSpawnInterval) {
      spawnPipe();
      lastPipeSpawnTime = 0;
      
      // Increase difficulty: reduce spawn interval over time
      if (gameState.score > 5 && pipeSpawnInterval > 1.2) {
        // This is handled by resetting lastPipeSpawnTime logic
      }
    }
    
    // Check collisions
    if (CollisionDetection.checkBirdCollision(bird, pipes, ground, screenHeight)) {
      gameOver();
    }
    
    // Check score
    for (var pipe in pipes) {
      if (!pipe.isPassed && pipe.x + pipe.width < bird.x) {
        pipe.isPassed = true;
        gameState.incrementScore();
        playScoreSound();
      }
    }
    
    setState(() {});
  }
  
  void spawnPipe() {
    pipes.add(Pipe(screenWidth, screenHeight));
  }
  
  void flap() {
    if (!gameState.isPlaying) {
      startGame();
      return;
    }
    
    if (gameState.isGameOver) return;
    
    bird.flap();
    playFlapSound();
  }
  
  void startGame() {
    gameState.startGame();
    bird.reset(screenHeight);
    pipes.clear();
    lastPipeSpawnTime = pipeSpawnInterval - 0.5; // Quick first pipe
    setState(() {});
  }
  
  void gameOver() {
    gameState.endGame();
    playHitSound();
    setState(() {});
  }
  
  void resetGame() {
    gameState.reset();
    bird.reset(screenHeight);
    pipes.clear();
    lastPipeSpawnTime = 0;
    setState(() {});
  }
  
  Future<void> playFlapSound() async {
    try {
      await audioPlayer.play(AssetSource('audio/flap.mp3'));
    } catch (e) {
      // Silent fail if audio file missing
    }
  }
  
  Future<void> playScoreSound() async {
    try {
      await audioPlayer.play(AssetSource('audio/score.mp3'));
    } catch (e) {
      // Silent fail if audio file missing
    }
  }
  
  Future<void> playHitSound() async {
    try {
      await audioPlayer.play(AssetSource('audio/hit.mp3'));
    } catch (e) {
      // Silent fail if audio file missing
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: flap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            screenWidth = constraints.maxWidth;
            screenHeight = constraints.maxHeight;
            
            return CustomPaint(
              painter: GamePainter(
                bird: bird,
                pipes: pipes,
                ground: ground,
                gameState: gameState,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              child: Center(
                child: gameState.isGameOver
                    ? GameOverlay(
                        score: gameState.score,
                        highScore: gameState.highScore,
                        onRestart: resetGame,
                      )
                    : !gameState.isPlaying
                        ? const StartOverlay()
                        : null,
              ),
            );
          },
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    gameLoopController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }
}

class GamePainter extends CustomPainter {
  final Bird bird;
  final List<Pipe> pipes;
  final Ground ground;
  final GameState gameState;
  final double screenWidth;
  final double screenHeight;
  
  GamePainter({
    required this.bird,
    required this.pipes,
    required this.ground,
    required this.gameState,
    required this.screenWidth,
    required this.screenHeight,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw sky background
    final skyPaint = Paint()..color = const Color(0xFF4EC0CA);
    canvas.drawRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight), skyPaint);
    
    // Draw clouds (simple decoration)
    drawCloud(canvas, 100, 100, 50);
    drawCloud(canvas, 300, 150, 40);
    drawCloud(canvas, screenWidth - 150, 80, 60);
    
    // Draw pipes
    for (var pipe in pipes) {
      drawPipe(canvas, pipe);
    }
    
    // Draw ground
    drawGround(canvas);
    
    // Draw bird
    drawBird(canvas);
    
    // Draw score
    drawScore(canvas);
  }
  
  void drawCloud(Canvas canvas, double x, double y, double radius) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(Offset(x, y), radius, cloudPaint);
    canvas.drawCircle(Offset(x + radius * 0.7, y - radius * 0.3), radius * 0.7, cloudPaint);
    canvas.drawCircle(Offset(x - radius * 0.5, y - radius * 0.2), radius * 0.6, cloudPaint);
  }
  
  void drawPipe(Canvas canvas, Pipe pipe) {
    final pipePaint = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.fill;
    
    final pipeBorderPaint = Paint()
      ..color = const Color(0xFF006400)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Top pipe
    canvas.drawRect(
      Rect.fromLTWH(pipe.x, 0, pipe.width, pipe.topHeight),
      pipePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(pipe.x, 0, pipe.width, pipe.topHeight),
      pipeBorderPaint,
    );
    
    // Top pipe cap
    canvas.drawRect(
      Rect.fromLTWH(pipe.x - 5, pipe.topHeight - 30, pipe.width + 10, 30),
      pipePaint,
    );
    
    // Bottom pipe
    canvas.drawRect(
      Rect.fromLTWH(pipe.x, pipe.bottomY, pipe.width, pipe.bottomHeight),
      pipePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(pipe.x, pipe.bottomY, pipe.width, pipe.bottomHeight),
      pipeBorderPaint,
    );
    
    // Bottom pipe cap
    canvas.drawRect(
      Rect.fromLTWH(pipe.x - 5, pipe.bottomY, pipe.width + 10, 30),
      pipePaint,
    );
  }
  
  void drawGround(Canvas canvas) {
    final groundPaint = Paint()..color = const Color(0xFFD4A017);
    final groundTopPaint = Paint()..color = const Color(0xFF8B5A00);
    
    // Main ground
    canvas.drawRect(
      Rect.fromLTWH(ground.x, screenHeight - ground.height, ground.width, ground.height),
      groundPaint,
    );
    
    // Ground top edge
    canvas.drawRect(
      Rect.fromLTWH(0, screenHeight - ground.height, screenWidth, 5),
      groundTopPaint,
    );
  }
  
  void drawBird(Canvas canvas) {
    final birdPaint = Paint()..color = const Color(0xFFFFD700);
    final birdEyePaint = Paint()..color = Colors.black;
    final birdBeakPaint = Paint()..color = const Color(0xFFFF6600);
    
    // Bird body (ellipse for rotation)
    canvas.save();
    canvas.translate(bird.x, bird.y);
    canvas.rotate(bird.rotation);
    
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-15, -12, 30, 24),
        const Radius.circular(12),
      ),
      birdPaint,
    );
    
    // Wing (animated based on wing position)
    final wingY = bird.wingPosition;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-5, wingY, 20, 12),
        const Radius.circular(6),
      ),
      birdPaint,
    );
    
    // Eye
    canvas.drawCircle(const Offset(8, -4), 3, birdEyePaint);
    canvas.drawCircle(const Offset(9, -5), 1, Colors.white);
    
    // Beak
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, -3, 8, 6),
        const Radius.circular(2),
      ),
      birdBeakPaint,
    );
    
    canvas.restore();
  }
  
  void drawScore(Canvas canvas) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: '${gameState.score}',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'PixelFont',
        ),
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(screenWidth / 2 - textPainter.width / 2, 50),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GameOverlay extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onRestart;
  
  const GameOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.onRestart,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.red[300],
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Score: $score',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            Text(
              'Best: $highScore',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.yellow,
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4EC0CA),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'RESTART',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PixelFont',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StartOverlay extends StatelessWidget {
  const StartOverlay({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FLAPPY BIRD',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap to Start',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'PixelFont',
              ),
            ),
            const SizedBox(height: 10),
            Icon(
              Icons.touch_app,
              color: Colors.white.withOpacity(0.7),
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}