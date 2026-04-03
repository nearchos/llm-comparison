import 'dart:math';
import '../models/bird.dart';
import '../models/pipe.dart';
import 'collision_detector.dart';

enum GameState { ready, playing, gameOver }

class GameEngine {
  double screenWidth = 0;
  double screenHeight = 0;
  double groundY = 0;

  Bird? bird;
  List<Pipe> pipes = [];
  GameState state = GameState.ready;
  int score = 0;

  final double pipeSpeed = 220.0;
  final double pipeWidth = 65.0;
  final double pipeGap = 170.0;
  final double pipeSpawnDistance = 250.0;

  final Random _random = Random();

  void init(double width, double height) {
    screenWidth = width;
    screenHeight = height;
    groundY = height * 0.85; // Ground takes up bottom 15%
    reset();
  }

  void reset() {
    bird = Bird(
      x: screenWidth * 0.25,
      y: screenHeight * 0.4,
    );
    pipes.clear();
    score = 0;
    state = GameState.ready;
  }

  void start() {
    state = GameState.playing;
    bird?.flap();
    _spawnPipe(screenWidth * 1.5); // Spawn first pipe off-screen
  }

  void onTap() {
    if (state == GameState.ready) {
      start();
    } else if (state == GameState.playing) {
      bird?.flap();
    } else if (state == GameState.gameOver) {
      reset();
    }
  }

  void update(double dt) {
    if (state != GameState.playing || bird == null) return;

    // 1. Update Bird
    bird!.update(dt);

    // 2. Update Pipes & Score
    for (int i = 0; i < pipes.length; i++) {
      pipes[i].update(dt, pipeSpeed);

      // Scoring logic: if bird passes the right edge of the pipe
      if (!pipes[i].passed && bird!.x > pipes[i].x + pipes[i].width) {
        score++;
        pipes[i].passed = true;
      }
    }

    // 3. Remove off-screen pipes
    pipes.removeWhere((p) => p.x + p.width < 0);

    // 4. Spawn new pipes
    if (pipes.isEmpty || (screenWidth - pipes.last.x) >= pipeSpawnDistance) {
      _spawnPipe(screenWidth + pipeWidth);
    }

    // 5. Check Collisions
    if (CollisionDetector.checkCollision(bird!, pipes, groundY)) {
      state = GameState.gameOver;
    }
  }

  void _spawnPipe(double startX) {
    double minPipeHeight = 50.0;
    double maxPipeHeight = groundY - minPipeHeight - pipeGap;
    
    // Randomize the top pipe height
    double topHeight = minPipeHeight + _random.nextDouble() * (maxPipeHeight - minPipeHeight);

    pipes.add(Pipe(
      x: startX,
      width: pipeWidth,
      topHeight: topHeight,
      gap: pipeGap,
    ));
  }
}