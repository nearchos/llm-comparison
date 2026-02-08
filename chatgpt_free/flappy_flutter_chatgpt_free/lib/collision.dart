import 'bird.dart';
import 'pipe.dart';

class Collision {
  static bool hitGround(Bird bird) {
    return bird.y > 1.0 || bird.y < 0.0;
  }

  static bool hitPipe(Bird bird, List<Pipe> pipes) {
    for (final pipe in pipes) {
      if ((bird.x + Bird.size > pipe.x) &&
          (bird.x - Bird.size < pipe.x + Pipe.width)) {
        final gapTop = pipe.gapY - Pipe.gapHeight / 2;
        final gapBottom = pipe.gapY + Pipe.gapHeight / 2;

        if (bird.y - Bird.size < gapTop ||
            bird.y + Bird.size > gapBottom) {
          return true;
        }
      }
    }
    return false;
  }
}

