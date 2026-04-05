import 'bird.dart';
import 'pipe.dart';
import 'ground.dart';

class CollisionDetection {
  static bool checkBirdCollision(Bird bird, List<Pipe> pipes, Ground ground, double screenHeight) {
    // Check ground collision
    if (bird.y + 12 >= screenHeight - ground.height) {
      return true;
    }
    
    // Check ceiling collision
    if (bird.y - 12 <= 0) {
      return true;
    }
    
    final birdRect = bird.getCollisionRect();
    
    // Check pipe collisions
    for (var pipe in pipes) {
      if (birdRect.overlaps(pipe.getTopPipeRect()) ||
          birdRect.overlaps(pipe.getBottomPipeRect())) {
        return true;
      }
    }
    
    return false;
  }
}