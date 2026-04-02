import 'dart:math' show min;

import 'package:flutter/material.dart';

import '../game/bird.dart';
import '../game/game_engine.dart';
import '../game/game_state.dart';
import '../game/pipe.dart';

/// Renders the complete Flappy Bird game onto a [Canvas] each frame.
///
/// Drawing order (back-to-front):
///   1. Sky gradient
///   2. Parallax clouds
///   3. Pipes (top + bottom)
///   4. Ground (covers pipe bottoms)
///   5. Bird (with rotation)
///   6. HUD — score, start screen, or game-over panel
class GamePainter extends CustomPainter {
  final GameEngine engine;

  /// Passing [engine] as the repaint [Listenable] means Flutter repaints
  /// exactly when the engine calls notifyListeners() — once per Ticker tick.
  GamePainter(this.engine) : super(repaint: engine);

  // ── Entry point ───────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawClouds(canvas, size);
    _drawPipes(canvas, size);
    _drawGround(canvas, size);
    _drawBird(canvas, size);
    _drawHUD(canvas, size);
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;

  // ── Sky ───────────────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF47C6D6), Color(0xFF9BE0EE)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // ── Clouds ────────────────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.80);

    // Three clouds at different heights scroll left at different speeds
    // (parallax: closer-looking clouds move a bit faster).
    _drawWrappedCloud(canvas, size, engine.groundOffset * 0.18,
        size.width * 0.15, size.height * 0.10, 20, paint);
    _drawWrappedCloud(canvas, size, engine.groundOffset * 0.13,
        size.width * 0.52, size.height * 0.18, 16, paint);
    _drawWrappedCloud(canvas, size, engine.groundOffset * 0.20,
        size.width * 0.80, size.height * 0.08, 22, paint);
  }

  /// Draws a cloud centred at the given [baseX] (after subtracting [scrollX])
  /// and wraps it when it scrolls off the left edge.
  void _drawWrappedCloud(Canvas canvas, Size size, double scrollX, double baseX,
      double y, double r, Paint paint) {
    // Use modulo to keep the cloud within screen width range
    final x = (baseX - scrollX % size.width + size.width) % size.width;
    _paintCloud(canvas, Offset(x, y), r, paint);
    // Also draw a wrapped copy if the cloud is near the edge
    if (x < r * 3.5) {
      _paintCloud(canvas, Offset(x + size.width, y), r, paint);
    }
    if (x > size.width - r * 3.5) {
      _paintCloud(canvas, Offset(x - size.width, y), r, paint);
    }
  }

  /// Draws a simple puffy cloud from four overlapping circles.
  void _paintCloud(Canvas canvas, Offset center, double r, Paint paint) {
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center + Offset(r * 1.05, r * 0.18), r * 0.82, paint);
    canvas.drawCircle(center + Offset(-r * 0.90, r * 0.22), r * 0.72, paint);
    canvas.drawCircle(center + Offset(r * 0.35, r * 0.52), r * 0.88, paint);
  }

  // ── Pipes ─────────────────────────────────────────────────────────────────

  void _drawPipes(Canvas canvas, Size size) {
    for (final pipe in engine.pipes) {
      _drawOnePipe(canvas, pipe, size);
    }
  }

  void _drawOnePipe(Canvas canvas, Pipe pipe, Size size) {
    // Colour palette — mimics the original Flappy Bird green pipes.
    const bodyColor = Color(0xFF74BF2E);
    const highlightColor = Color(0xFFA4D84E);
    const shadowColor = Color(0xFF4D8C1A);
    const capColor = Color(0xFF5FA620);

    final bodyPaint = Paint()..color = bodyColor;
    final hlPaint = Paint()..color = highlightColor;
    final shPaint = Paint()..color = shadowColor;
    final capPaint = Paint()..color = capColor;

    final w = Pipe.kWidth;
    final capH = Pipe.kCapHeight;
    final capX = pipe.x - Pipe.kCapOverhang;
    final capW = w + Pipe.kCapOverhang * 2;
    // Ground line hides anything drawn below it.
    final groundLine = size.height - GameEngine.kGroundHeight;

    // ── Top pipe ──────────────────────────────────────────────────────────
    final topBottom = pipe.topPipeBottom; // y of the gap's top edge
    if (topBottom > 0) {
      final bodyTop = -60.0;
      final bodyBottom = topBottom - capH;

      if (bodyBottom > bodyTop) {
        // Body
        canvas.drawRect(
            Rect.fromLTRB(pipe.x, bodyTop, pipe.x + w, bodyBottom), bodyPaint);
        // Left highlight stripe
        canvas.drawRect(
            Rect.fromLTRB(pipe.x, bodyTop, pipe.x + 8, bodyBottom), hlPaint);
        // Right shadow stripe
        canvas.drawRect(
            Rect.fromLTRB(pipe.x + w - 8, bodyTop, pipe.x + w, bodyBottom),
            shPaint);
      }

      // Cap (flared section at the open end of the pipe)
      canvas.drawRect(
          Rect.fromLTRB(capX, topBottom - capH, capX + capW, topBottom),
          capPaint);
      canvas.drawRect(
          Rect.fromLTRB(capX, topBottom - capH, capX + 8, topBottom), hlPaint);
      canvas.drawRect(
          Rect.fromLTRB(capX + capW - 8, topBottom - capH, capX + capW, topBottom),
          shPaint);
    }

    // ── Bottom pipe ───────────────────────────────────────────────────────
    final bottomTop = pipe.bottomPipeTop; // y of the gap's bottom edge
    if (bottomTop < groundLine) {
      // Cap
      canvas.drawRect(
          Rect.fromLTRB(capX, bottomTop, capX + capW, bottomTop + capH), capPaint);
      canvas.drawRect(
          Rect.fromLTRB(capX, bottomTop, capX + 8, bottomTop + capH), hlPaint);
      canvas.drawRect(
          Rect.fromLTRB(capX + capW - 8, bottomTop, capX + capW, bottomTop + capH),
          shPaint);

      // Body (ground will overlap the bottom edge naturally)
      canvas.drawRect(
          Rect.fromLTRB(pipe.x, bottomTop + capH, pipe.x + w, groundLine + 2),
          bodyPaint);
      canvas.drawRect(
          Rect.fromLTRB(pipe.x, bottomTop + capH, pipe.x + 8, groundLine + 2),
          hlPaint);
      canvas.drawRect(
          Rect.fromLTRB(pipe.x + w - 8, bottomTop + capH, pipe.x + w, groundLine + 2),
          shPaint);
    }
  }

  // ── Ground ────────────────────────────────────────────────────────────────

  void _drawGround(Canvas canvas, Size size) {
    final groundY = size.height - GameEngine.kGroundHeight;

    // Base fill (yellowish-tan, like the original)
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, size.height),
      Paint()..color = const Color(0xFFDFD897),
    );

    // Lighter top strip
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, groundY + 15),
      Paint()..color = const Color(0xFFEBE49E),
    );

    // Scrolling alternating darker stripes
    final stripePaint = Paint()
      ..color = const Color(0xFFC9BA6A).withOpacity(0.40);
    const stripeW = 24.0;
    // engine.groundOffset cycles 0–23 so stripes tile seamlessly
    final offsetX = engine.groundOffset % stripeW;
    for (double x = -stripeW + offsetX; x < size.width + stripeW; x += stripeW) {
      canvas.drawRect(
          Rect.fromLTRB(x, groundY + 15, x + stripeW / 2, size.height),
          stripePaint);
    }

    // Top border line (green rim, like original)
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = const Color(0xFF8AA820)
        ..strokeWidth = 3.0,
    );
  }

  // ── Bird ──────────────────────────────────────────────────────────────────

  void _drawBird(Canvas canvas, Size size) {
    final bird = engine.bird;
    canvas.save();
    canvas.translate(bird.x, bird.y);
    canvas.rotate(bird.rotation);
    _paintBird(canvas, bird.wingFrame);
    canvas.restore();
  }

  /// Draws the bird centred at the origin (rotate/translate applied by caller).
  ///
  /// Visual layers (back to front):
  ///   wing → shadow → body → belly → eye → pupil → shine → beak → outline
  void _paintBird(Canvas canvas, int wingFrame) {
    // ── Wing (drawn behind body) ─────────────────────────────────────────
    _paintWing(canvas, wingFrame);

    // ── Drop shadow ──────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(1, 2), width: 34, height: 26),
      Paint()..color = Colors.black.withOpacity(0.13),
    );

    // ── Main body ────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 26),
      Paint()..color = const Color(0xFFFFC835),
    );

    // ── Belly highlight ──────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(1, 3), width: 20, height: 14),
      Paint()..color = const Color(0xFFFFE28A),
    );

    // ── Eye white ────────────────────────────────────────────────────────
    canvas.drawCircle(const Offset(8, -6), 8, Paint()..color = Colors.white);

    // ── Pupil ─────────────────────────────────────────────────────────────
    canvas.drawCircle(const Offset(10, -5), 4, Paint()..color = Colors.black);

    // ── Specular shine ────────────────────────────────────────────────────
    canvas.drawCircle(
        const Offset(12, -7), 1.6, Paint()..color = Colors.white);

    // ── Beak ──────────────────────────────────────────────────────────────
    final beakPath = Path()
      ..moveTo(13, -3)
      ..lineTo(22, 0)
      ..lineTo(13, 4)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFFF8C00));

    // Beak upper highlight
    final beakTopPath = Path()
      ..moveTo(13, -3)
      ..lineTo(22, 0)
      ..lineTo(13, 0)
      ..close();
    canvas.drawPath(beakTopPath, Paint()..color = const Color(0xFFFFAA44));

    // ── Body outline ──────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 26),
      Paint()
        ..color = Colors.black.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  /// Draws the animated wing behind the body.
  /// [wingFrame]: 0 = mid, 1 = up, 2 = down.
  void _paintWing(Canvas canvas, int wingFrame) {
    final wingPaint = Paint()..color = const Color(0xFFE8A820);
    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Each wingPath is a quadratic bezier shaped like a small feathered wing.
    final Path wingPath;
    switch (wingFrame) {
      case 1: // Wing up
        wingPath = Path()
          ..moveTo(-3, -2)
          ..quadraticBezierTo(-17, -19, -5, -14)
          ..quadraticBezierTo(-1, -9, 4, -4)
          ..close();
      case 2: // Wing down
        wingPath = Path()
          ..moveTo(-3, 2)
          ..quadraticBezierTo(-17, 17, -5, 13)
          ..quadraticBezierTo(-1, 9, 4, 3)
          ..close();
      default: // Wing mid (frame 0)
        wingPath = Path()
          ..moveTo(-3, 0)
          ..quadraticBezierTo(-17, -3, -6, 2)
          ..quadraticBezierTo(-1, 5, 4, 0)
          ..close();
    }

    canvas.drawPath(wingPath, wingPaint);
    canvas.drawPath(wingPath, outlinePaint);
  }

  // ── HUD ───────────────────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    // Live / post-game score counter
    if (engine.state == GameState.playing ||
        engine.state == GameState.gameOver) {
      _drawLiveScore(canvas, size);
    }

    // State-specific overlays
    switch (engine.state) {
      case GameState.idle:
        _drawStartOverlay(canvas, size);
      case GameState.gameOver:
        _drawGameOverPanel(canvas, size);
      case GameState.playing:
        break; // nothing extra while playing
    }
  }

  // ── Score counter ─────────────────────────────────────────────────────────

  void _drawLiveScore(Canvas canvas, Size size) {
    _paintCenteredText(
      canvas: canvas,
      text: '${engine.score}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 58,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
              color: Color(0x99000000), offset: Offset(2, 2), blurRadius: 4),
          Shadow(
              color: Color(0x44000000), offset: Offset(3, 3), blurRadius: 8),
        ],
      ),
      center: Offset(size.width / 2, size.height * 0.09),
    );
  }

  // ── Start overlay ─────────────────────────────────────────────────────────

  void _drawStartOverlay(Canvas canvas, Size size) {
    // Title
    _paintCenteredText(
      canvas: canvas,
      text: 'FLAPPY BIRD',
      style: const TextStyle(
        color: Color(0xFFFFF299),
        fontSize: 44,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
        shadows: [
          Shadow(color: Color(0xFFCA7D10), offset: Offset(3, 3)),
          Shadow(
              color: Color(0x99000000), offset: Offset(4, 4), blurRadius: 7),
        ],
      ),
      center: Offset(size.width / 2, size.height * 0.30),
    );

    // Tap-to-start prompt
    _paintCenteredText(
      canvas: canvas,
      text: 'TAP TO START',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        shadows: [
          Shadow(color: Color(0x99000000), offset: Offset(2, 2)),
        ],
      ),
      center: Offset(size.width / 2, size.height * 0.67),
    );
  }

  // ── Game-over panel ───────────────────────────────────────────────────────

  void _drawGameOverPanel(Canvas canvas, Size size) {
    final panelW = min(size.width * 0.76, 320.0);
    const panelH = 210.0;
    final panelCenter = Offset(size.width / 2, size.height * 0.43);
    final panelRect =
        Rect.fromCenter(center: panelCenter, width: panelW, height: panelH);
    final panelRRect =
        RRect.fromRectAndRadius(panelRect, const Radius.circular(14));

    // Panel fill
    canvas.drawRRect(
        panelRRect, Paint()..color = const Color(0xF2DEB887));
    // Panel border
    canvas.drawRRect(
        panelRRect,
        Paint()
          ..color = const Color(0xFF8B6914)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // "GAME OVER" heading
    _paintCenteredText(
      canvas: canvas,
      text: 'GAME OVER',
      style: const TextStyle(
        color: Color(0xFFD42B1E),
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        shadows: [Shadow(color: Color(0x66000000), offset: Offset(2, 2))],
      ),
      center: Offset(size.width / 2, panelCenter.dy - 74),
    );

    // Divider line inside panel
    canvas.drawLine(
      Offset(panelRect.left + 18, panelCenter.dy - 42),
      Offset(panelRect.right - 18, panelCenter.dy - 42),
      Paint()
        ..color = const Color(0x668B6914)
        ..strokeWidth = 1.5,
    );

    // Score row
    _paintCenteredText(
      canvas: canvas,
      text: 'SCORE',
      style: const TextStyle(
        color: Color(0xFF6B4A1C),
        fontSize: 17,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      center: Offset(panelCenter.dx - 48, panelCenter.dy - 14),
    );
    _paintCenteredText(
      canvas: canvas,
      text: '${engine.score}',
      style: const TextStyle(
        color: Color(0xFF1A0D00),
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
      center: Offset(panelCenter.dx + 52, panelCenter.dy - 14),
    );

    // Best row
    _paintCenteredText(
      canvas: canvas,
      text: 'BEST',
      style: const TextStyle(
        color: Color(0xFF6B4A1C),
        fontSize: 17,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
      center: Offset(panelCenter.dx - 48, panelCenter.dy + 22),
    );
    _paintCenteredText(
      canvas: canvas,
      text: '${engine.highScore}',
      style: const TextStyle(
        color: Color(0xFFD4A000),
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
      center: Offset(panelCenter.dx + 52, panelCenter.dy + 22),
    );

    // ── Restart button ───────────────────────────────────────────────────
    final btnCenter = Offset(size.width / 2, size.height * 0.63);
    final btnRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: btnCenter, width: 196, height: 48),
      const Radius.circular(10),
    );

    // Button shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: btnCenter + const Offset(0, 3), width: 196, height: 48),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF376110),
    );
    // Button fill
    canvas.drawRRect(btnRRect, Paint()..color = const Color(0xFF73BF2E));
    // Button border
    canvas.drawRRect(
      btnRRect,
      Paint()
        ..color = const Color(0xFF4A8A1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    _paintCenteredText(
      canvas: canvas,
      text: 'TAP TO PLAY AGAIN',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        shadows: [Shadow(color: Color(0x55000000), offset: Offset(1, 1))],
      ),
      center: btnCenter,
    );
  }

  // ── Text helper ───────────────────────────────────────────────────────────

  /// Lays out and paints [text] centred at [center].
  void _paintCenteredText({
    required Canvas canvas,
    required String text,
    required TextStyle style,
    required Offset center,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
