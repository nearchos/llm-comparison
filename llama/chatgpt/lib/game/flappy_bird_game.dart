import 'dart:math';

import 'package:flappy_bird_clone/components/bird.dart';
import 'package:flappy_bird_clone/components/ground.dart';
import 'package:flappy_bird_clone/components/pipe.dart';
import 'package:flappy_bird_clone/game/game_state.dart';
import 'package:flappy_bird_clone/utils/game_constants.dart';
import 'package:flutter/material.dart';

class FlappyBirdGame extends StatefulWidget {
  const FlappyBirdGame({super.key});

  @override
  State<FlappyBirdGame> createState() => _FlappyBirdGameState();
}

class _FlappyBirdGameState extends State<FlappyBirdGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  GameState _gameState = GameState.waiting;
  
  // Game objects
  late Bird _bird;
  final List<Pipe> _pipes = [];
  late Ground _ground1, _ground2;
  
  int _score = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000 ~/ GameConstants.frameRate),
    )..addListener(_gameLoop);
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _gameState = GameState.waiting;
      _score = 0;
      
      // Initialize bird
      final gameSize = MediaQuery.of(context).size;
      _bird = Bird(
        position: Offset(
          GameConstants.birdInitialPositionX,
          gameSize.height / 2,
        ),
      );

      // Initialize pipes
      _pipes.clear();
      _generatePipes(gameSize.width, gameSize.height);

      // Initialize ground
      _ground1 = Ground(position: Offset(0, gameSize.height - GameConstants.groundHeight));
      _ground2 = Ground(position: Offset(gameSize.width, gameSize.height - GameConstants.groundHeight));
    });
  }

  void _generatePipes(double screenWidth, double screenHeight) {
    double currentX = screenWidth * 1.5;
    for (int i = 0; i < 3; i++) {
      double gapTop = _random.nextDouble() * (screenHeight - GameConstants.groundHeight - GameConstants.pipeGap - 100) + 50;
      _pipes.add(Pipe(
        x: currentX,
        height: screenHeight,
        gapTop: gapTop,
      ));
      currentX += GameConstants.pipeSpacing + GameConstants.pipeWidth;
    }
  }

  void _startGame() {
    if (_gameState == GameState.waiting) {
      setState(() {
        _gameState = GameState.playing;
        _bird.flap();
      });
      _controller.forward();
    }
  }

  void _gameLoop() {
    if (_gameState != GameState.playing) {
      _controller.stop();
      return;
    }

    final double elapsed = _controller.lastElapsedDuration!.inMilliseconds / 1000.0;
    _controller.forward();

    setState(() {
      // Update Bird
      _bird.update(elapsed);

      // Update Pipes and check for score
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      for (var pipe in _pipes) {
        pipe.update(elapsed);

        // Check for score
        if (!pipe.isScored && pipe.x + GameConstants.pipeWidth < _bird.position.dx) {
          pipe.isScored = true;
          _score++;
        }

        // Reset pipe when it goes off-screen
        if (pipe.x < -GameConstants.pipeWidth) {
          pipe.x += (3 * (GameConstants.pipeWidth + GameConstants.pipeSpacing));
          pipe.gapTop = _random.nextDouble() * (screenHeight - GameConstants.groundHeight - GameConstants.pipeGap - 100) + 50;
          pipe.isScored = false;
        }
      }

      // Update Ground
      _ground1.update(elapsed, screenWidth);
      _ground2.update(elapsed, screenWidth);

      // Check for collisions
      if (_checkCollisions(screenHeight)) {
        _endGame();
      }
    });
  }
  
  bool _checkCollisions(double screenHeight) {
    // Ground collision
    if (_bird.position.dy + GameConstants.birdSize / 2 > screenHeight - GameConstants.groundHeight) {
      return true;
    }

    // Sky collision
    if (_bird.position.dy - GameConstants.birdSize / 2 < 0) {
      return true;
    }

    // Pipe collision
    final birdRect = _bird.rect;
    for (var pipe in _pipes) {
      if (birdRect.overlaps(pipe.topPipeRect) || birdRect.overlaps(pipe.bottomPipeRect)) {
        return true;
      }
    }
    
    return false;
  }

  void _endGame() {
    setState(() {
      _gameState = GameState.gameOver;
    });
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width == 0) {
      // Wait for layout
      return const Scaffold(backgroundColor: GameConstants.backgroundColor);
    }

    // Re-initialize game objects on first build with context
    if (_pipes.isEmpty) _resetGame();

    return GestureDetector(
      onTap: () {
        switch (_gameState) {
          case GameState.waiting:
            _startGame();
            break;
          case GameState.playing:
            _bird.flap();
            break;
          case GameState.gameOver:
            _resetGame();
            break;
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(color: GameConstants.backgroundColor),
            
            // Game elements
            ..._pipes.map((pipe) => CustomPaint(painter: PipePainter(pipe: pipe))),
            CustomPaint(painter: GroundPainter(ground: _ground1)),
            CustomPaint(painter: GroundPainter(ground: _ground2)),
            CustomPaint(painter: BirdPainter(bird: _bird)),
            
            // UI elements
            _buildUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildUI() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score display
          if (_gameState == GameState.playing || _gameState == GameState.gameOver)
            Text(
              '$_score',
              style: const TextStyle(
                fontSize: 60,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black45,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // "Game Over" and "Tap to play" messages
          if (_gameState == GameState.waiting || _gameState == GameState.gameOver)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _gameState == GameState.waiting ? "TAP TO PLAY" : "GAME OVER\nTAP TO RESTART",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}