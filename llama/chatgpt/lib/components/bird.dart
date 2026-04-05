import 'package:flappy_bird_clone/utils/game_constants.dart';
import 'package:flutter/material.dart';

class Bird {
  Offset position;
  double _velocity = 0.0;
  final double _flapAnimationTime = 0.15;
  double _flapTimer = 0.0;

  Bird({required this.position});

  void update(double deltaTime) {
    // Apply gravity
    _velocity += GameConstants.gravity * deltaTime;
    _velocity = _velocity.clamp(-double.infinity, GameConstants.maxFallSpeed);

    // Update position
    position = position.translate(0, _velocity * deltaTime);

    // Update flap animation
    if (_flapTimer > 0) {
      _flapTimer -= deltaTime;
    }
  }

  void flap() {
    _velocity = GameConstants.flapStrength;
    _flapTimer = _flapAnimationTime;
  }
  
  Rect get rect => Rect.fromCenter(
    center: position,
    width: GameConstants.birdSize,
    height: GameConstants.birdSize,
  );

  bool get isFlapping => _flapTimer > 0;
}

class BirdPainter extends CustomPainter {
  final Bird bird;

  BirdPainter({required this.bird});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bodyPaint = Paint()..color = GameConstants.birdColor1;
    final Paint beakPaint = Paint()..color = GameConstants.birdColor2;

    canvas.save();
    canvas.translate(bird.position.dx, bird.position.dy);

    // Rotate bird based on velocity
    double angle = (_velocityToAngle(bird._velocity)).clamp(-0.5, 1.0);
    canvas.rotate(angle);

    // Body
    final Rect bodyRect = Rect.fromCenter(
      center: Offset.zero,
      width: GameConstants.birdSize,
      height: GameConstants.birdSize * 0.8,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(10)), bodyPaint);

    // Beak
    final Path beakPath = Path()
      ..moveTo(bodyRect.right - 5, bodyRect.top + 8)
      ..lineTo(bodyRect.right + 10, bodyRect.center.dy)
      ..lineTo(bodyRect.right - 5, bodyRect.bottom - 8)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    
    // Eye
    canvas.drawCircle(Offset(bodyRect.right - 12, bodyRect.top + 10), 3, Paint()..color = Colors.black);
    
    // Wing
    final Paint wingPaint = Paint()..color = GameConstants.birdColor2;
    final wingRect = Rect.fromCenter(
      center: Offset(0, bird.isFlapping ? -2 : 2), // Animate wing flap
      width: GameConstants.birdSize / 2,
      height: GameConstants.birdSize / 3,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(wingRect, const Radius.circular(5)), wingPaint);

    canvas.restore();
  }
  
  double _velocityToAngle(double velocity) {
    // A simple mapping from vertical velocity to rotation angle
    return (velocity / (GameConstants.maxFallSpeed * 2.0));
  }

  @override
  bool shouldRepaint(covariant BirdPainter oldDelegate) {
    return oldDelegate.bird != bird;
  }
}