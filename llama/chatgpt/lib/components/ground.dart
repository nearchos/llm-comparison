import 'package:flappy_bird_clone/utils/game_constants.dart';
import 'package:flutter/material.dart';

class Ground {
  Offset position;
  
  Ground({required this.position});

  void update(double deltaTime, double screenWidth) {
    position = position.translate(-GameConstants.worldSpeed * deltaTime, 0);
    if (position.dx <= -screenWidth) {
      position = Offset(screenWidth, position.dy);
    }
  }

  Rect get rect => Rect.fromLTWH(
    position.dx,
    position.dy,
    GameConstants.groundHeight,
    GameConstants.groundHeight
  );
}

class GroundPainter extends CustomPainter {
  final Ground ground;

  GroundPainter({required this.ground});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint groundPaint1 = Paint()..color = GameConstants.groundColor1;
    final Paint groundPaint2 = Paint()..color = GameConstants.groundColor2;

    // Main ground area
    final groundRect = Rect.fromLTWH(ground.position.dx, ground.position.dy, size.width + 2, GameConstants.groundHeight);
    canvas.drawRect(groundRect, groundPaint1);

    // Draw checker pattern for scrolling illusion
    for (double i = 0; i < size.width + 50; i += 30) {
      final grassRect = Rect.fromLTWH(
        ground.position.dx + i,
        ground.position.dy,
        15,
        15
      );
      canvas.drawRect(grassRect, groundPaint2);
    }
  }

  @override
  bool shouldRepaint(covariant GroundPainter oldDelegate) {
    return oldDelegate.ground != ground;
  }
}