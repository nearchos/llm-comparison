import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/game_engine.dart';

class GamePainter extends CustomPainter {
  final GameEngine engine;
  final double animationValue;

  GamePainter(this.engine, this.animationValue) : super(repaint: Listenable.merge([]));

  @override
  void paint(Canvas canvas, Size size) {
    if (engine.screenWidth == 0) return;

    _drawBackground(canvas, size);
    _drawPipes(canvas);
    _drawGround(canvas, size);
    _drawBird(canvas);
    _drawUI(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF70C5CE); // Classic sky blue
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw simple clouds
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 30, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.22), 40, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.2), 30, cloudPaint);
  }

  void _drawPipes(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFF74BF2E);
    final borderPaint = Paint()
      ..color = const Color(0xFF538D22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var pipe in engine.pipes) {
      // Top Pipe
      Rect topRect = Rect.fromLTRB(pipe.x, 0, pipe.x + pipe.width, pipe.topHeight);
      canvas.drawRect(topRect, bodyPaint);
      canvas.drawRect(topRect, borderPaint);
      
      // Top Pipe Cap
      Rect topCap = Rect.fromLTRB(pipe.x - 4, pipe.topHeight - 20, pipe.x + pipe.width + 4, pipe.topHeight);
      canvas.drawRect(topCap, bodyPaint);
      canvas.drawRect(topCap, borderPaint);

      // Bottom Pipe
      Rect bottomRect = Rect.fromLTRB(pipe.x, pipe.bottomY, pipe.x + pipe.width, engine.groundY);
      canvas.drawRect(bottomRect, bodyPaint);
      canvas.drawRect(bottomRect, borderPaint);

      // Bottom Pipe Cap
      Rect bottomCap = Rect.fromLTRB(pipe.x - 4, pipe.bottomY, pipe.x + pipe.width + 4, pipe.bottomY + 20);
      canvas.drawRect(bottomCap, bodyPaint);
      canvas.drawRect(bottomCap, borderPaint);
    }
  }

  void _drawGround(Canvas canvas, Size size) {
    // Ground Dirt
    final dirtPaint = Paint()..color = const Color(0xFFDED895);
    canvas.drawRect(Rect.fromLTRB(0, engine.groundY, size.width, size.height), dirtPaint);

    // Ground Grass Top
    final grassPaint = Paint()..color = const Color(0xFF73BF2E);
    canvas.drawRect(Rect.fromLTRB(0, engine.groundY, size.width, engine.groundY + 10), grassPaint);

    // Scrolling effect
    final borderPaint = Paint()
      ..color = const Color(0xFF558D22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, engine.groundY), Offset(size.width, engine.groundY), borderPaint);
    
    // Stripes to show movement
    if (engine.state == GameState.playing) {
       double offset = (animationValue * 1000) % 20;
       for(double i = -offset; i < size.width; i += 20) {
          canvas.drawLine(Offset(i, engine.groundY), Offset(i-10, engine.groundY + 10), borderPaint);
       }
    }
  }

  void _drawBird(Canvas canvas) {
    if (engine.bird == null) return;
    var b = engine.bird!;

    // Rotate bird based on velocity
    canvas.save();
    canvas.translate(b.x + b.width / 2, b.y + b.height / 2);
    
    double angle = 0;
    if (engine.state == GameState.playing || engine.state == GameState.gameOver) {
      angle = (b.velocityY * 0.0015).clamp(-0.5, 1.5); 
    }
    canvas.rotate(angle);

    // Body
    final bodyPaint = Paint()..color = const Color(0xFFF6D024);
    final rect = Rect.fromCenter(center: Offset.zero, width: b.width, height: b.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), bodyPaint);

    // Eye
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(b.width * 0.25, -b.height * 0.25), 6, whitePaint);
    canvas.drawCircle(Offset(b.width * 0.35, -b.height * 0.25), 2, blackPaint);

    // Beak
    final beakPaint = Paint()..color = const Color(0xFFE86121);
    final beakRect = Rect.fromCenter(center: Offset(b.width * 0.4, 2), width: 14, height: 8);
    canvas.drawRRect(RRect.fromRectAndRadius(beakRect, const Radius.circular(4)), beakPaint);

    // Wing (Flapping animation)
    final wingPaint = Paint()..color = Colors.white.withOpacity(0.9);
    double wingY = -2;
    if (engine.state == GameState.playing && b.velocityY < 0) {
       wingY = 4; // Wing down when moving up
    }
    final wingRect = Rect.fromCenter(center: Offset(-b.width * 0.1, wingY), width: 14, height: 10);
    canvas.drawRRect(RRect.fromRectAndRadius(wingRect, const Radius.circular(5)), wingPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), borderPaint);

    canvas.restore();
  }

  void _drawUI(Canvas canvas, Size size) {
    if (engine.state == GameState.ready) {
      _drawText(canvas, "TAP TO START", size.width / 2, size.height * 0.3, 40, Colors.white);
    } else if (engine.state == GameState.gameOver) {
      _drawText(canvas, "GAME OVER", size.width / 2, size.height * 0.3, 48, Colors.white);
      _drawText(canvas, "SCORE: ${engine.score}", size.width / 2, size.height * 0.4, 32, Colors.white);
      _drawText(canvas, "TAP TO RESTART", size.width / 2, size.height * 0.5, 24, Colors.white);
    } else {
      _drawText(canvas, engine.score.toString(), size.width / 2, size.height * 0.15, 64, Colors.white);
    }
  }

  void _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 2, offset: Offset(2, 2)),
        Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-2, 2)),
        Shadow(color: Colors.black, blurRadius: 2, offset: Offset(2, -2)),
        Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-2, -2)),
      ],
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}