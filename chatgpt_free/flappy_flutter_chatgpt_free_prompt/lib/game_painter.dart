import 'package:flutter/material.dart';
import 'game_state.dart';
import 'pipe.dart';
import 'bird.dart';

class GamePainter extends CustomPainter {
  final GameState game;

  GamePainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPipes(canvas, size);
    _drawBird(canvas, size);
    _drawGround(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.lightBlueAccent;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawGround(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.95, size.width, size.height * 0.05),
      paint,
    );
  }

  void _drawBird(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow;

    final center = Offset(
      game.bird.x * size.width,
      game.bird.y * size.height,
    );

    canvas.drawCircle(
        center, Bird.size * size.width, paint);

    // Wing animation (simple oscillation)
    final wingPaint = Paint()..color = Colors.orange;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, Bird.size * size.height),
        width: Bird.size * size.width,
        height: Bird.size * size.height,
      ),
      wingPaint,
    );
  }

  void _drawPipes(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.green[800]!;

    for (final pipe in game.pipes) {
      final x = pipe.x * size.width;
      final gapTop =
          (pipe.gapY - Pipe.gapHeight / 2) * size.height;
      final gapBottom =
          (pipe.gapY + Pipe.gapHeight / 2) * size.height;

      // Top pipe
      canvas.drawRect(
        Rect.fromLTWH(x, 0, Pipe.width * size.width, gapTop),
        paint,
      );

      // Bottom pipe
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          gapBottom,
          Pipe.width * size.width,
          size.height - gapBottom,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

