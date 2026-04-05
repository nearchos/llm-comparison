import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const FlappyBirdClone());
}

class FlappyBirdClone extends StatelessWidget {
  const FlappyBirdClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Courier',
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Game state
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  
  // Bird physics
  double birdY = 0;
  double birdVelocity = 0;
  static const double birdSize = 45.0;
  static const double gravity = 1000.0; // pixels per second squared
  static const double jumpVelocity = -320.0; // upward velocity when tapping
  
  // Pipe settings
  List<Pipe> pipes = [];
  static const double pipeWidth = 70.0;
  static const double pipeGap = 170.0;
  static const double pipeSpeed = 180.0; // pixels per second
  static const double pipeSpawnInterval = 2.0; // seconds
  double pipeSpawnTimer = 0;
  
  // Screen dimensions
  late double screenHeight;
  late double screenWidth;
  
  // Game loop
  Timer? gameTimer;
  DateTime? lastUpdateTime;
  
  // Random number generator for pipe heights
  final Random random = Random();
  
  // Ground ceiling constraints
  double get groundY => screenHeight - 60;
  double get ceilingY => 40;
  
  @override
  void initState() {
    super.initState();
    _resetGame();
  }
  
  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
  
  void _resetGame() {
    setState(() {
      isPlaying = false;
      isGameOver = false;
      score = 0;
      birdY = screenHeight / 2 - birdSize / 2;
      birdVelocity = 0;
      pipes.clear();
      pipeSpawnTimer = 0.5; // Start with a pipe soon
    });
  }
  
  void _startGame() {
    if (isGameOver) {
      _resetGame();
    }
    isPlaying = true;
    isGameOver = false;
    score = 0;
    birdY = screenHeight / 2 - birdSize / 2;
    birdVelocity = 0;
    pipes.clear();
    pipeSpawnTimer = 0.5;
    lastUpdateTime = DateTime.now();
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }
  
  void _jump() {
    if (!isPlaying && !isGameOver) {
      _startGame();
      return;
    }
    
    if (isPlaying && !isGameOver) {
      setState(() {
        birdVelocity = jumpVelocity;
      });
    }
  }
  
  void _updateGame() {
    if (!isPlaying || isGameOver) return;
    
    final now = DateTime.now();
    final delta = (now.difference(lastUpdateTime!).inMilliseconds / 1000).clamp(0.001, 0.05);
    lastUpdateTime = now;
    
    setState(() {
      // Update bird physics
      birdVelocity += gravity * delta;
      birdY += birdVelocity * delta;
      
      // Update pipes
      for (var i = 0; i < pipes.length; i++) {
        pipes[i].x -= pipeSpeed * delta;
      }
      // Remove pipes that are off screen
      pipes.removeWhere((pipe) => pipe.x + pipeWidth < 0);
      
      // Spawn new pipes
      pipeSpawnTimer -= delta;
      if (pipeSpawnTimer <= 0) {
        _spawnPipe();
        pipeSpawnTimer = pipeSpawnInterval;
      }
      
      // Check collision with ground or ceiling
      if (birdY + birdSize >= groundY || birdY <= ceilingY) {
        _gameOver();
        return;
      }
      
      // Check collision with pipes
      for (var pipe in pipes) {
        if (_checkCollision(pipe)) {
          _gameOver();
          return;
        }
        
        // Check for scoring (bird passes the pipe)
        if (!pipe.scored && pipe.x + pipeWidth < screenWidth / 2 - birdSize / 2) {
          pipe.scored = true;
          score++;
        }
      }
      
      // Keep bird within reasonable bounds (just for visual, collision already handled)
      birdY = birdY.clamp(ceilingY, groundY - birdSize);
    });
  }
  
  void _spawnPipe() {
    final minHeight = 80.0;
    final maxHeight = screenHeight - groundY - pipeGap - 80;
    final pipeHeight = minHeight + random.nextDouble() * (maxHeight - minHeight);
    
    pipes.add(Pipe(
      x: screenWidth,
      height: pipeHeight,
      scored: false,
    ));
  }
  
  bool _checkCollision(Pipe pipe) {
    final birdLeft = screenWidth / 2 - birdSize / 2;
    final birdRight = screenWidth / 2 + birdSize / 2;
    final birdTop = birdY;
    final birdBottom = birdY + birdSize;
    
    final pipeLeft = pipe.x;
    final pipeRight = pipe.x + pipeWidth;
    
    // Top pipe collision
    final topPipeBottom = pipe.height;
    if (birdRight > pipeLeft && birdLeft < pipeRight && birdTop < topPipeBottom) {
      return true;
    }
    
    // Bottom pipe collision
    final bottomPipeTop = pipe.height + pipeGap;
    if (birdRight > pipeLeft && birdLeft < pipeRight && birdBottom > bottomPipeTop) {
      return true;
    }
    
    return false;
  }
  
  void _gameOver() {
    if (!isGameOver) {
      setState(() {
        isPlaying = false;
        isGameOver = true;
      });
      gameTimer?.cancel();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    
    // Initialize bird position if not set
    if (birdY == 0 && !isGameOver) {
      birdY = screenHeight / 2 - birdSize / 2;
    }
    
    return GestureDetector(
      onTap: _jump,
      child: Scaffold(
        body: Container(
          color: const Color(0xFF87CEEB), // Sky blue background
          child: Stack(
            children: [
              // Pipes
              for (var pipe in pipes)
                ..._buildPipePair(pipe),
              
              // Ground
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  color: const Color(0xFF8B4513),
                  child: Container(
                    margin: const EdgeInsets.only(top: 3),
                    color: const Color(0xFF654321),
                  ),
                ),
              ),
              
              // Ceiling (invisible but visual marker)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  color: Colors.brown.withOpacity(0.3),
                ),
              ),
              
              // Bird
              Positioned(
                left: screenWidth / 2 - birdSize / 2,
                top: birdY,
                child: Transform.rotate(
                  angle: (birdVelocity / 300).clamp(-0.8, 0.8),
                  child: Container(
                    width: birdSize,
                    height: birdSize,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(birdSize / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Eye
                        Positioned(
                          top: 12,
                          right: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        // Beak
                        Positioned(
                          top: 20,
                          right: -5,
                          child: Container(
                            width: 12,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Score display
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Start/Game Over overlay
              if (!isPlaying && !isGameOver)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'FLAPPY BIRD',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Tap Screen to Start',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Tap to Jump',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (isGameOver)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Tap Screen to Restart',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<Widget> _buildPipePair(Pipe pipe) {
    return [
      // Top pipe (flipped)
      Positioned(
        left: pipe.x,
        top: 0,
        child: Column(
          children: [
            Container(
              width: pipeWidth,
              height: pipe.height,
              decoration: const BoxDecoration(
                color: Color(0xFF228B22),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  // Pipe rim
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: pipeWidth + 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom pipe
      Positioned(
        left: pipe.x,
        top: pipe.height + pipeGap,
        child: Column(
          children: [
            Container(
              width: pipeWidth + 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ),
            Container(
              width: pipeWidth,
              height: screenHeight - (pipe.height + pipeGap),
              decoration: const BoxDecoration(
                color: Color(0xFF228B22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  // Pipe rim
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 20,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class Pipe {
  double x;
  double height;
  bool scored;
  
  Pipe({
    required this.x,
    required this.height,
    required this.scored,
  });
}