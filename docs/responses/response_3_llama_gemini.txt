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
      home: FlappyBirdGame(),
    );
  }
}

class FlappyBirdGame extends StatefulWidget {
  const FlappyBirdGame({super.key});

  @override
  State<FlappyBirdGame> createState() => _FlappyBirdGameState();
}

class _FlappyBirdGameState extends State<FlappyBirdGame> {
  // Game state
  static const double birdSize = 50;
  double birdY = 0;
  double velocityY = 0;
  bool isGameStarted = false;
  bool isGameOver = false;

  // Physics constants
  final double gravity = 0.6;
  final double jumpStrength = -8;
  
  // Pipe state
  final double pipeWidth = 80;
  final double pipeGap = 200;
  List<Offset> pipes = []; // Using Offset to store x position and height of the top of the bottom pipe
  int score = 0;
  
  // Game loop timer
  Timer? gameLoopTimer;
  final Duration frameRate = const Duration(milliseconds: 17); // ~60 FPS

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    setState(() {
      birdY = 0;
      velocityY = 0;
      isGameStarted = false;
      isGameOver = false;
      score = 0;
      pipes.clear();
      // Initialize pipes so they are off-screen to start
      final screenWidth = MediaQuery.of(context).size.width;
      pipes.add(generatePipe(screenWidth + 100));
      pipes.add(generatePipe(screenWidth + 100 + (screenWidth / 2)));
    });
  }

  Offset generatePipe(double x) {
    final screenHeight = MediaQuery.of(context).size.height;
    final random = Random();
    // The y-value is the top of the bottom pipe
    final double randomHeight = random.nextDouble() * (screenHeight - pipeGap - 300) + 150;
    return Offset(x, randomHeight);
  }

  void startGameLoop() {
    if (!mounted) return;
    
    isGameStarted = true;
    
    gameLoopTimer = Timer.periodic(frameRate, (timer) {
      if (!isGameStarted || isGameOver) {
        timer.cancel();
        return;
      }
      
      // Apply gravity
      velocityY += gravity;
      birdY += velocityY;

      // Update pipe positions
      bool passedPipe = false;
      setState(() {
        for (int i = 0; i < pipes.length; i++) {
          final pipe = pipes[i];
          final newX = pipe.dx - 5; // Pipe scroll speed

          // Check for passing a pipe
          if (!isGameOver && pipe.dx > (MediaQuery.of(context).size.width / 2 - pipeWidth) && newX <= (MediaQuery.of(context).size.width / 2 - pipeWidth)) {
             passedPipe = true;
          }

          pipes[i] = Offset(newX, pipe.dy);
        }

        // Remove off-screen pipes and add new ones
        if (pipes.isNotEmpty && pipes.first.dx < -pipeWidth) {
          pipes.removeAt(0);
          final screenWidth = MediaQuery.of(context).size.width;
          pipes.add(generatePipe(pipes.last.dx + screenWidth / 2 + (Random().nextDouble() * 80 - 40)));
        }
      });
      
      if (passedPipe) {
        setState(() {
          score++;
        });
      }

      // Check for collisions
      if (isCollision()) {
        endGame();
      }
    });
  }
  
  void jump() {
    if (isGameOver) {
      resetGame();
      return;
    }
    if (!isGameStarted) {
      startGameLoop();
    }
    setState(() {
      velocityY = jumpStrength;
    });
  }

  bool isCollision() {
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Define bird's bounding box
    final birdRect = Rect.fromLTWH(
      MediaQuery.of(context).size.width / 2 - birdSize / 2, // Bird is centered horizontally
      screenHeight / 2 + birdY - birdSize / 2, // Bird's vertical position
      birdSize,
      birdSize,
    );

    // Ground and ceiling collision
    if (birdRect.bottom > screenHeight || birdRect.top < 0) {
      return true;
    }
    
    // Pipe collision
    for (final pipe in pipes) {
      // Bottom pipe
      final bottomPipeRect = Rect.fromLTWH(pipe.dx, pipe.dy, pipeWidth, screenHeight - pipe.dy);
      // Top pipe
      final topPipeRect = Rect.fromLTWH(pipe.dx, 0, pipeWidth, pipe.dy - pipeGap);

      if (birdRect.overlaps(bottomPipeRect) || birdRect.overlaps(topPipeRect)) {
        return true;
      }
    }
    
    return false;
  }
  
  void endGame() {
    if (!mounted) return;
    gameLoopTimer?.cancel();
    setState(() {
      isGameOver = true;
    });
  }
  
  @override
  void dispose() {
    gameLoopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(color: Colors.lightBlue[300]),
            
            // Pipes
            ...pipes.map((pipe) => buildPipe(pipe)),
            
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
            
            // UI Layer
            if (!isGameStarted && !isGameOver)
              const Center(
                child: Text(
                  'TAP TO START',
                  style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            
            if (isGameOver)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'GAME OVER\nTap to Restart',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

             // Score
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 70, 
                    color: Colors.white, 
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPipe(Offset pipe) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // Bottom Pipe
        Positioned(
          left: pipe.dx,
          top: pipe.dy,
          child: Container(
            width: pipeWidth,
            height: screenHeight - pipe.dy,
            decoration: BoxDecoration(
              color: Colors.green[800],
              border: Border.all(color: Colors.green[900]!, width: 5)
            ),
          ),
        ),
        // Top Pipe
        Positioned(
          left: pipe.dx,
          top: 0,
          child: Container(
            width: pipeWidth,
            height: pipe.dy - pipeGap,
             decoration: BoxDecoration(
              color: Colors.green[800],
              border: Border.all(color: Colors.green[900]!, width: 5)
            ),
          ),
        ),
      ],
    );
  }
}