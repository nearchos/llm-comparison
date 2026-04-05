import 'package:flappy_bird_clone/utils/game_constants.dart';
import 'package:flutter/material.dart';

class Pipe {
  double x;
  final double height;
  double gapTop;
  bool isScored = false;

  Pipe({required this.x, required this.height, required this.gapTop});

  void update(double deltaTime) {
    x -= GameConstants.worldSpeed * deltaTime;
  }

  Rect get topPipeRect => Rect.fromLTWH(
    x,
    0,
    GameConstants.pipeWidth,
    gapTop,
  );

  Rect get bottomPipeRect => Rect.fromLTWH(
    x,
    gapTop + GameConstants.pipeGap,
    GameConstants.pipeWidth,
    height - gapTop - GameConstants.pipeGap - GameConstants.groundHeight,
  );
}

class PipePainter extends CustomPainter {
  final Pipe pipe;

  PipePainter({required this.pipe});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()..color = GameConstants.pipeColor;
    final Paint borderPaint = Paint()
      ..color = GameConstants.pipeBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = GameConstants.pipeBorderWidth;

    // Draw top pipe body
    final topPipeBody = pipe.topPipeRect;
    canvas.drawRect(topPipeBody, fillPaint);
    canvas.drawRect(topPipeBody, borderPaint);

    // Draw top pipe cap
    final topPipeCap = Rect.fromLTWH(
      pipe.x - 5,
      pipe.gapTop - 25,
      GameConstants.pipeWidth + 10,
      25,
    );
    canvas.drawRect(topPipeCap, fillPaint);
    canvas.drawRect(topPipeCap, borderPaint);

    // Draw bottom pipe body
    final bottomPipeBody = pipe.bottomPipeRect;
    canvas.drawRect(bottomPipeBody, fillPaint);
    canvas.drawRect(bottomPipeBody, borderPaint);

    // Draw bottom pipe cap
    final bottomPipeCap = Rect.fromLTWH(
      pipe.x - 5,
      pipe.gapTop + GameConstants.pipeGap,
      GameConstants.pipeWidth + 10,
      25,
    );
    canvas.drawRect(bottomPipeCap, fillPaint);
    canvas.drawRect(bottomPipeCap, borderPaint);
  }

  @override
  bool shouldRepaint(covariant PipePainter oldDelegate) {
    return oldDelegate.pipe != pipe;
  }
}