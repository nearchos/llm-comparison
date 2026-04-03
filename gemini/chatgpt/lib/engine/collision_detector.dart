import 'dart:ui';
import '../models/bird.dart';
import '../models/pipe.dart';

class CollisionDetector {
  static bool checkCollision(Bird bird, List<Pipe> pipes, double groundY) {
    // 1. Check ground and sky collisions
    if (bird.y + bird.height >= groundY || bird.y <= 0) {
      return true;
    }

    // Bird hitbox
    Rect birdRect = Rect.fromLTWH(bird.x, bird.y, bird.width, bird.height);

    // 2. Check pipe collisions
    for (var pipe in pipes) {
      // Top pipe hitbox
      Rect topPipeRect = Rect.fromLTRB(pipe.x, 0, pipe.x + pipe.width, pipe.topHeight);
      
      // Bottom pipe hitbox
      Rect bottomPipeRect = Rect.fromLTRB(pipe.x, pipe.bottomY, pipe.x + pipe.width, groundY);

      if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
        return true;
      }
    }
    
    return false;
  }
}