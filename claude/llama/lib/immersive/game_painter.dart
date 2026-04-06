// ─────────────────────────────────────────────────────────────────────────────
// game_painter.dart
// CustomPainter that handles ALL rendering:
//   sky gradient → clouds → pipes → ground → bird → HUD / overlay text
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

// Palette (keeping colours in one place makes tuning easy).
const Color _skyTop = Color(0xFF4EC0CA);
const Color _skyBottom = Color(0xFF87DCEB);
const Color _pipeBody = Color(0xFF73BF2E);
const Color _pipeCapBody = Color(0xFF5CA51F);
const Color _pipeHighlight = Color(0xFF96E04A);
const Color _groundTop = Color(0xFFDEB887);
const Color _groundBottom = Color(0xFFB8860B);
const Color _groundGrass = Color(0xFF5DBB3F);
const Color _birdYellow = Color(0xFFFDD835);
const Color _birdOrange = Color(0xFFFF8F00);
const Color _birdWhite = Color(0xFFFFF9C4);
const Color _birdEyeWhite = Color(0xFFFFFFFF);
const Color _birdPupil = Color(0xFF1A1A1A);
const Color _birdWing = Color(0xFFFFB300);
const Color _cloudColor = Color(0xFFFFFFFF);

/// The width of the pipe's end cap relative to the pipe body.
const double _capExtraW = 10.0;
const double _capHeight = 26.0;

class GamePainter extends CustomPainter {
  final GameState gameState;
  final double birdX;
  final double birdY;

  /// Radians – positive = nose-down.
  final double birdRotation;

  /// 0..1 cycle that drives the wing flap oscillation.
  final double flapProgress;

  final List<PipePair> pipes;
  final List<Cloud> clouds;
  final int score;
  final int bestScore;

  /// Horizontal scroll offset for the ground texture (pixels).
  final double groundScrollOffset;
  final double pipeWidth;
  final double groundHeight;

  /// Whether the "Get Ready" pulse should be shown on the start screen.
  final bool showTapPulse;

  const GamePainter({
    required this.gameState,
    required this.birdX,
    required this.birdY,
    required this.birdRotation,
    required this.flapProgress,
    required this.pipes,
    required this.clouds,
    required this.score,
    required this.bestScore,
    required this.groundScrollOffset,
    required this.pipeWidth,
    required this.groundHeight,
    required this.showTapPulse,
  });

  // ── Main paint entry ──────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawClouds(canvas, size);
    _drawPipes(canvas, size);
    _drawGround(canvas, size);
    _drawBird(canvas);
    _drawHUD(canvas, size);

    if (gameState == GameState.start) _drawStartOverlay(canvas, size);
    if (gameState == GameState.gameOver) _drawGameOverOverlay(canvas, size);
  }

  @override
  bool shouldRepaint(GamePainter old) => true;

  // ─────────────────────────────────────────────────────────────────────────
  // Background / sky
  // ─────────────────────────────────────────────────────────────────────────

  void _drawSky(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _skyBottom],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Clouds  (parallax)
  // ─────────────────────────────────────────────────────────────────────────

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = _cloudColor.withOpacity(0.88);
    for (final c in clouds) {
      _drawCloud(canvas, paint, c.x, c.y, c.size);
    }
  }

  /// A cloud made from three overlapping circles.
  void _drawCloud(Canvas canvas, Paint paint, double x, double y, double w) {
    final h = w * 0.5;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x - w * 0.25, y + h * 0.15), width: w * 0.6, height: h * 0.75), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + w * 0.25, y + h * 0.1), width: w * 0.55, height: h * 0.7), paint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pipes
  // ─────────────────────────────────────────────────────────────────────────

  void _drawPipes(Canvas canvas, Size size) {
    for (final pipe in pipes) {
      // Upper pipe – extends from the top of the screen down to gapTop.
      _drawSinglePipe(canvas, pipe.x, 0, pipe.gapTop, isTop: true);
      // Lower pipe – extends from gapBottom down to just above the ground.
      _drawSinglePipe(canvas, pipe.x, pipe.gapBottom, size.height - groundHeight, isTop: false);
    }
  }

  void _drawSinglePipe(Canvas canvas, double x, double top, double bottom, {required bool isTop}) {
    final bodyRect = Rect.fromLTRB(x, top, x + pipeWidth, bottom);

    // ── Body ──────────────────────────────────────────────────────────────
    final bodyPaint = Paint()..color = _pipeBody;
    canvas.drawRect(bodyRect, bodyPaint);

    // Highlight stripe on the left edge of the body.
    final hlPaint = Paint()..color = _pipeHighlight;
    canvas.drawRect(Rect.fromLTRB(x + 4, top, x + 14, bottom), hlPaint);

    // Dark right edge shadow.
    final shadowPaint = Paint()..color = Colors.black26;
    canvas.drawRect(Rect.fromLTRB(x + pipeWidth - 8, top, x + pipeWidth, bottom), shadowPaint);

    // ── End cap ───────────────────────────────────────────────────────────
    final capLeft = x - _capExtraW;
    final capRight = x + pipeWidth + _capExtraW;
    final double capTop;
    final double capBottom;

    if (isTop) {
      // Cap sits at the *bottom* of the upper pipe.
      capTop = bottom - _capHeight;
      capBottom = bottom;
    } else {
      // Cap sits at the *top* of the lower pipe.
      capTop = top;
      capBottom = top + _capHeight;
    }

    final capRect = Rect.fromLTRB(capLeft, capTop, capRight, capBottom);
    final capPaint = Paint()..color = _pipeCapBody;
    canvas.drawRect(capRect, capPaint);

    // Highlight on cap.
    canvas.drawRect(Rect.fromLTRB(capLeft + 4, capTop, capLeft + 14, capBottom), hlPaint);
    canvas.drawRect(Rect.fromLTRB(capRight - 8, capTop, capRight, capBottom), shadowPaint);

    // Thin outline around cap.
    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(capRect, outlinePaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Ground
  // ─────────────────────────────────────────────────────────────────────────

  void _drawGround(Canvas canvas, Size size) {
    final groundTop = size.height - groundHeight;

    // Grass strip.
    final grassPaint = Paint()..color = _groundGrass;
    canvas.drawRect(Rect.fromLTRB(0, groundTop, size.width, groundTop + 18), grassPaint);

    // Dirt body gradient.
    final dirtRect = Rect.fromLTRB(0, groundTop + 18, size.width, size.height);
    final dirtPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_groundTop, _groundBottom],
      ).createShader(dirtRect);
    canvas.drawRect(dirtRect, dirtPaint);

    // Scrolling vertical stripe texture on the dirt.
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 3;
    const stripeSpacing = 20.0;
    final startX = -(groundScrollOffset % stripeSpacing);
    for (double sx = startX; sx < size.width + stripeSpacing; sx += stripeSpacing) {
      canvas.drawLine(Offset(sx, groundTop + 18), Offset(sx, size.height), stripePaint);
    }

    // Top edge shadow.
    final edgePaint = Paint()..color = Colors.black.withOpacity(0.15);
    canvas.drawRect(Rect.fromLTRB(0, groundTop, size.width, groundTop + 5), edgePaint);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bird
  // ─────────────────────────────────────────────────────────────────────────

  /// Draw the bird centred at (birdX, birdY) with rotation applied.
  void _drawBird(Canvas canvas) {
    canvas.save();
    canvas.translate(birdX, birdY);
    canvas.rotate(birdRotation);

    const double bodyW = 44.0;
    const double bodyH = 32.0;

    // ── Shadow ────────────────────────────────────────────────────────────
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.12);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(2, 6), width: bodyW * 0.85, height: bodyH * 0.4),
      shadowPaint,
    );

    // ── Wing (drawn behind the body) ──────────────────────────────────────
    // Wing flaps up and down based on flapProgress (0..1 cycle).
    final wingAngle = math.sin(flapProgress * 2 * math.pi);
    final wingYOff = wingAngle * 8.0;
    final wingPaint = Paint()..color = _birdWing;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-4, -6 + wingYOff), width: 26, height: 14),
      wingPaint,
    );

    // ── Body ──────────────────────────────────────────────────────────────
    final bodyPaint = Paint()..color = _birdYellow;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: bodyW, height: bodyH),
      bodyPaint,
    );

    // Belly highlight (cream oval, offset slightly right + down).
    final bellyPaint = Paint()..color = _birdWhite;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4, 4), width: bodyW * 0.55, height: bodyH * 0.55),
      bellyPaint,
    );

    // Body outline.
    final outlinePaint = Paint()
      ..color = _birdOrange.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: bodyW, height: bodyH),
      outlinePaint,
    );

    // ── Eye ───────────────────────────────────────────────────────────────
    const eyeCx = 10.0;
    const eyeCy = -6.0;
    // White sclera.
    canvas.drawCircle(const Offset(eyeCx, eyeCy), 8, Paint()..color = _birdEyeWhite);
    // Pupil.
    canvas.drawCircle(const Offset(eyeCx + 1.5, eyeCy), 4.5, Paint()..color = _birdPupil);
    // Catchlight.
    canvas.drawCircle(const Offset(eyeCx + 3, eyeCy - 2.5), 1.8, Paint()..color = Colors.white);

    // ── Beak ──────────────────────────────────────────────────────────────
    final beakPaint = Paint()..color = _birdOrange;
    final beakPath = Path()
      ..moveTo(17, -2)
      ..lineTo(30, 2)
      ..lineTo(17, 7)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    // Beak outline.
    canvas.drawPath(
      beakPath,
      Paint()
        ..color = Colors.brown.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HUD – score during play
  // ─────────────────────────────────────────────────────────────────────────

  void _drawHUD(Canvas canvas, Size size) {
    if (gameState != GameState.playing) return;
    _paintText(
      canvas,
      text: '$score',
      center: Offset(size.width / 2, 60),
      fontSize: 52,
      bold: true,
      color: Colors.white,
      shadow: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Start overlay
  // ─────────────────────────────────────────────────────────────────────────

  void _drawStartOverlay(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Semi-transparent panel.
    _drawPanel(canvas, Rect.fromCenter(center: Offset(cx, size.height * 0.38), width: size.width * 0.78, height: 160));

    // Title.
    _paintText(canvas, text: 'FLAPPY BIRD', center: Offset(cx, size.height * 0.32), fontSize: 38, bold: true, color: Colors.white, shadow: true);

    // Tap prompt – uses showTapPulse to blink.
    if (showTapPulse) {
      _paintText(canvas, text: 'TAP TO START', center: Offset(cx, size.height * 0.44), fontSize: 20, bold: true, color: const Color(0xFFFFE082), shadow: true);
    }

    // Draw the bird icon on the start screen (static, always centred above).
    // Saved state so we don't interfere with transforms.
    canvas.save();
    canvas.translate(cx, size.height * 0.22);
    _drawBirdAt(canvas, 0, 0);
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Game-over overlay
  // ─────────────────────────────────────────────────────────────────────────

  void _drawGameOverOverlay(Canvas canvas, Size size) {
    // Dim background.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.38),
    );

    final cx = size.width / 2;
    final cy = size.height * 0.42;

    // Score panel.
    _drawPanel(canvas, Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.8, height: 220));

    _paintText(canvas, text: 'GAME OVER', center: Offset(cx, cy - 76), fontSize: 36, bold: true, color: const Color(0xFFFF5252), shadow: true);

    // Score row.
    _paintText(canvas, text: 'SCORE', center: Offset(cx - 50, cy - 18), fontSize: 15, bold: false, color: Colors.white70, shadow: false);
    _paintText(canvas, text: '$score', center: Offset(cx + 60, cy - 18), fontSize: 28, bold: true, color: Colors.white, shadow: true);

    // Best row.
    _paintText(canvas, text: 'BEST', center: Offset(cx - 50, cy + 26), fontSize: 15, bold: false, color: Colors.white70, shadow: false);
    _paintText(canvas, text: '$bestScore', center: Offset(cx + 60, cy + 26), fontSize: 28, bold: true, color: const Color(0xFFFFD700), shadow: true);

    // Divider.
    canvas.drawLine(
      Offset(cx - (size.width * 0.8 / 2) + 20, cy + 52),
      Offset(cx + (size.width * 0.8 / 2) - 20, cy + 52),
      Paint()
        ..color = Colors.white30
        ..strokeWidth = 1.0,
    );

    _paintText(canvas, text: 'TAP TO RESTART', center: Offset(cx, cy + 80), fontSize: 18, bold: true, color: const Color(0xFFFFE082), shadow: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Rounded rectangle panel with a translucent dark fill.
  void _drawPanel(Canvas canvas, Rect rect) {
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.drawRRect(rRect, Paint()..color = Colors.black.withOpacity(0.55));
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Paints centred text with an optional drop-shadow.
  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double fontSize,
    required bool bold,
    required Color color,
    required bool shadow,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
      color: color,
      letterSpacing: 1.2,
      shadows: shadow
          ? [Shadow(color: Colors.black54, offset: const Offset(2, 2), blurRadius: 4)]
          : null,
    );
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// Draws the bird shape around a local origin (used for the start-screen icon).
  void _drawBirdAt(Canvas canvas, double cx, double cy) {
    const double bodyW = 44.0;
    const double bodyH = 32.0;

    final bodyPaint = Paint()..color = _birdYellow;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: bodyW, height: bodyH), bodyPaint);

    final bellyPaint = Paint()..color = _birdWhite;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 4, cy + 4), width: bodyW * 0.55, height: bodyH * 0.55), bellyPaint);

    canvas.drawCircle(Offset(cx + 10, cy - 6), 8, Paint()..color = _birdEyeWhite);
    canvas.drawCircle(Offset(cx + 11.5, cy - 6), 4.5, Paint()..color = _birdPupil);

    final beakPaint = Paint()..color = _birdOrange;
    final beakPath = Path()
      ..moveTo(cx + 17, cy - 2)
      ..lineTo(cx + 30, cy + 2)
      ..lineTo(cx + 17, cy + 7)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
  }
}