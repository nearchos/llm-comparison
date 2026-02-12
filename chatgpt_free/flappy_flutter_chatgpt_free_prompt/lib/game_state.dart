import 'dart:math';
import 'bird.dart';
import 'pipe.dart';
import 'collision.dart';

class GameState {
  final Bird bird = Bird();
  final List<Pipe> pipes = [];

  double timeSincePipe = 0;
  double pipeInterval = 2.0;

  bool isGameOver = false;
  int score = 0;

  final Random _random = Random();

  void reset() {
    bird.reset();
    pipes.clear();
    timeSincePipe = 0;
    score = 0;
    isGameOver = false;
  }

  void flap() {
    bird.flap();
  }

  void update(double dt) {
    if (isGameOver) return;

    bird.update(dt);

    timeSincePipe += dt;

    if (timeSincePipe > pipeInterval) {
      timeSincePipe = 0;
      _spawnPipe();
    }

    for (final pipe in pipes) {
      pipe.update(dt);

      if (!pipe.passed && pipe.x + Pipe.width < bird.x) {
        pipe.passed = true;
        score++;
      }
    }

    pipes.removeWhere((p) => p.x < -Pipe.width);

    if (Collision.hitPipe(bird, pipes) ||
        Collision.hitGround(bird)) {
      isGameOver = true;
    }
  }

  void _spawnPipe() {
    final gapY = 0.2 + _random.nextDouble() * 0.6;
    pipes.add(Pipe(gapY));
  }
}

