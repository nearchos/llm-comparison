import 'dart:math';
import 'dart:ui';

class Bird {
  double x = 100;
  double y = 0;
  double velocity = 0;
  double rotation = 0;
  double wingPosition = 0;
  bool wingDirection = true;
  
  static const double gravity = 800.0; // pixels per second squared
  static const double jumpStrength = -300.0;
  static const double maxVelocity = 500.0;
  static const double size = 30.0;
  
  Bird() {
    reset(0);
  }
  
  void update(double deltaTime, double screenHeight) {
    // Apply gravity
    velocity += gravity * deltaTime;
    velocity = velocity.clamp(-maxVelocity, maxVelocity);
    y += velocity * deltaTime;
    
    // Update rotation based on velocity
    rotation = (velocity / maxVelocity) * (pi / 3);
    rotation = rotation.clamp(-pi / 3, pi / 3);
    
    // Animate wings
    wingPosition += (wingDirection ? 2.0 : -2.0);
    if (wingPosition > 5) {
      wingDirection = false;
    } else if (wingPosition < -5) {
      wingDirection = true;
    }
    
    // Ground and ceiling boundaries
    if (y < 0) {
      y = 0;
      velocity = 0;
    }
  }
  
  void flap() {
    velocity = jumpStrength;
    // Reset wing animation on flap
    wingPosition = -5;
    wingDirection = true;
  }
  
  void reset(double screenHeight) {
    y = screenHeight / 2;
    velocity = 0;
    rotation = 0;
    wingPosition = 0;
    wingDirection = true;
  }
  
  Rect getCollisionRect() {
    return Rect.fromLTWH(x - 15, y - 12, 30, 24);
  }
} 