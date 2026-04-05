import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const FlappyBirdApp());

// ─────────────────────────────────────────────────────────────
//  App
// ─────────────────────────────────────────────────────────────

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Flappy Bird',
        debugShowCheckedModeBanner: false,
        home: GameScreen(),
      );
}

// ─────────────────────────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────────────────────────

enum GameState { ready, playing, gameOver }

class PipePair {
  double x;
  final double gapTop;
  final double gapBottom;
  bool scored;

  PipePair({
    required this.x,
    required this.gapTop,
    required this.gapBottom,
  }) : scored = false;
}

// ─────────────────────────────────────────────────────────────
//  Game widget
// ─────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // Ticker for the game loop
  late Ticker _ticker;
  Duration? _prevElapsed;

  // Game state
  GameState _state   = GameState.ready;
  double    _birdY   = 0.0; // offset from screen centre (px)
  double    _birdVel = 0.0; // vertical velocity px/s  (+ve = downward)
  final     List<PipePair> _pipes = [];
  int       _score = 0;
  int       _best  = 0;

  // Screen dimensions set by LayoutBuilder
  double _sw = 400.0;
  double _sh = 800.0;

  // ── Physics / geometry ──────────────────────────────────────
  static const double _kGravity = 1800.0; // px / s²
  static const double _kJump    = -560.0; // px / s  (upward)
  static const double _kTermV   =  900.0; // terminal velocity
  static const double _kPipeSpd =  175.0; // pipe scroll speed px / s
  static const double _kPipeW   =   70.0; // pipe body width px
  static const double _kGapH    =  165.0; // gap between top & bottom pipe px
  static const double _kSpacing =  265.0; // horizontal gap between pipe pairs px
  static const double _kBirdR   =   22.0; // bird radius px
  static const double _kGndH    =   80.0; // ground height px

  double get _birdAbsY => _sh / 2 + _birdY;

  // ── Lifecycle ───────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Game loop ───────────────────────────────────────────────
  void _tick(Duration elapsed) {
    if (_state != GameState.playing) {
      _prevElapsed = null;
      return;
    }
    if (_prevElapsed == null) {
      _prevElapsed = elapsed;
      return;
    }

    // Delta time, clamped to avoid large jumps after pauses
    final dt =
        ((elapsed - _prevElapsed!).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _prevElapsed = elapsed;

    setState(() {
      // ── Bird physics ────────────────────────────────────────
      _birdVel = (_birdVel + _kGravity * dt).clamp(-_kTermV, _kTermV);
      _birdY  += _birdVel * dt;

      // ── Pipe movement & scoring ─────────────────────────────
      for (final p in _pipes) {
        p.x -= _kPipeSpd * dt;
        if (!p.scored && p.x + _kPipeW < _sw / 2 - _kBirdR) {
          p.scored = true;
          _score++;
        }
      }
      _pipes.removeWhere((p) => p.x + _kPipeW < 0);
      if (_pipes.isEmpty || _pipes.last.x < _sw - _kSpacing) _addPipe();

      // ── Collision ───────────────────────────────────────────
      _checkCollisions();
    });
  }

  void _addPipe() {
    const minGapTop = 90.0;
    final maxGapTop =
        (_sh - _kGndH - _kGapH - 80.0).clamp(minGapTop + 20, double.maxFinite);
    final gapTop =
        minGapTop + Random().nextDouble() * (maxGapTop - minGapTop);
    _pipes.add(PipePair(
      x: _sw + _kPipeW,
      gapTop: gapTop,
      gapBottom: gapTop + _kGapH,
    ));
  }

  void _checkCollisions() {
    final bx = _sw / 2;
    final by = _birdAbsY;

    // Ground / ceiling
    if (by + _kBirdR >= _sh - _kGndH || by - _kBirdR <= 0) {
      _die();
      return;
    }

    // Pipes (AABB vs circle approximation)
    for (final p in _pipes) {
      if (bx + _kBirdR > p.x && bx - _kBirdR < p.x + _kPipeW) {
        if (by - _kBirdR < p.gapTop || by + _kBirdR > p.gapBottom) {
          _die();
          return;
        }
      }
    }
  }

  void _die() {
    _state = GameState.gameOver;
    if (_score > _best) _best = _score;
    _prevElapsed = null;
  }

  // ── Input ───────────────────────────────────────────────────
  void _onTap() {
    if (_state == GameState.playing) {
      setState(() => _birdVel = _kJump);
    } else {
      _restart();
    }
  }

  void _restart() {
    setState(() {
      _state       = GameState.playing;
      _birdY       = 0;
      _birdVel     = 0;
      _pipes.clear();
      _score       = 0;
      _prevElapsed = null;
    });
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      _sw = c.maxWidth;
      _sh = c.maxHeight;
      return GestureDetector(
        onTap: _onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _Painter(
            birdAbsY: _birdAbsY,
            birdVel:  _birdVel,
            pipes:    _pipes,
            score:    _score,
            best:     _best,
            state:    _state,
            sw:       _sw,
            sh:       _sh,
          ),
          size: Size(_sw, _sh),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────

class _Painter extends CustomPainter {
  final double birdAbsY, birdVel, sw, sh;
  final List<PipePair> pipes;
  final int score, best;
  final GameState state;

  // Mirror constants (must stay in sync with _GameScreenState)
  static const double _pipeW = 70.0;
  static const double _birdR = 22.0;
  static const double _gndH  = 80.0;
  static const double _capH  = 26.0; // pipe cap height
  static const double _capX  = 11.0; // pipe cap side extension

  _Painter({
    required this.birdAbsY,
    required this.birdVel,
    required this.pipes,
    required this.score,
    required this.best,
    required this.state,
    required this.sw,
    required this.sh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _sky(canvas);
    _clouds(canvas);
    _allPipes(canvas);
    _ground(canvas);
    _bird(canvas);
    _hud(canvas);
    if (state == GameState.ready)    _screenReady(canvas);
    if (state == GameState.gameOver) _screenGameOver(canvas);
  }

  // ── Sky ─────────────────────────────────────────────────────
  void _sky(Canvas canvas) {
    final r = Rect.fromLTWH(0, 0, sw, sh - _gndH);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: const [Color(0xFF4EC0CA), Color(0xFF87CEEB)],
        ).createShader(r),
    );
  }

  // ── Clouds ──────────────────────────────────────────────────
  void _clouds(Canvas canvas) {
    void puff(double cx, double cy, double r) {
      final p = Paint()..color = Colors.white.withOpacity(0.82);
      canvas.drawCircle(Offset(cx,              cy),            r,         p);
      canvas.drawCircle(Offset(cx + r * 0.90,   cy - r * 0.15), r * 0.75, p);
      canvas.drawCircle(Offset(cx - r * 0.80,   cy - r * 0.10), r * 0.65, p);
      canvas.drawCircle(Offset(cx + r * 0.30,   cy + r * 0.40), r * 0.60, p);
    }
    puff(sw * 0.12, sh * 0.09, 22);
    puff(sw * 0.52, sh * 0.06, 27);
    puff(sw * 0.82, sh * 0.12, 19);
  }

  // ── Pipes ───────────────────────────────────────────────────
  void _allPipes(Canvas canvas) {
    for (final p in pipes) _pipe(canvas, p);
  }

  void _pipe(Canvas canvas, PipePair p) {
    final groundY = sh - _gndH;

    // Gradient factory (horizontal highlight → mid → dark)
    Paint grPaint(Rect r) => Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF74D44E), Color(0xFF5EBD3E), Color(0xFF3A9020)],
        stops:  const [0.0, 0.35, 1.0],
      ).createShader(r);

    final border = Paint()
      ..color       = const Color(0xFF2A6E12)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    void seg(Rect r) {
      if (r.height <= 0 || r.width <= 0) return;
      canvas.drawRect(r, grPaint(r));
      canvas.drawRect(r, border);
    }

    // ── Top pipe ──────────────────────────────────────────────
    seg(Rect.fromLTWH(
        p.x, 0, _pipeW, (p.gapTop - _capH).clamp(0.0, sh)));
    seg(Rect.fromLTWH(
        p.x - _capX, p.gapTop - _capH, _pipeW + _capX * 2, _capH));

    // ── Bottom pipe ───────────────────────────────────────────
    seg(Rect.fromLTWH(
        p.x - _capX, p.gapBottom, _pipeW + _capX * 2, _capH));
    seg(Rect.fromLTWH(
        p.x,
        p.gapBottom + _capH,
        _pipeW,
        (groundY - p.gapBottom - _capH).clamp(0.0, sh)));
  }

  // ── Ground ──────────────────────────────────────────────────
  void _ground(Canvas canvas) {
    final y = sh - _gndH;
    canvas.drawRect(Rect.fromLTWH(0, y,      sw, _gndH),
        Paint()..color = const Color(0xFFDEB887));
    canvas.drawRect(Rect.fromLTWH(0, y,      sw, 22),
        Paint()..color = const Color(0xFF8BC34A));
    canvas.drawRect(Rect.fromLTWH(0, y + 22, sw, 5),
        Paint()..color = const Color(0xFF558B2F));
  }

  // ── Bird ────────────────────────────────────────────────────
  void _bird(Canvas canvas) {
    final bx    = sw / 2;
    final by    = birdAbsY;
    final angle = (birdVel / 650).clamp(-0.45, pi / 2.1);

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(angle);

    // Drop shadow
    canvas.drawCircle(const Offset(2, 3), _birdR,
        Paint()..color = Colors.black26);

    // Body
    canvas.drawCircle(Offset.zero, _birdR,
        Paint()..color = const Color(0xFFFFD600));

    // Belly highlight
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(4, 7), width: 24, height: 16),
      Paint()..color = const Color(0xFFFFF9C4),
    );

    // Wing
    final wing = Path()
      ..moveTo(-5, -2)
      ..quadraticBezierTo(-18, 5, -12, 14)
      ..quadraticBezierTo(-4,  8,   0,  4)
      ..close();
    canvas.drawPath(wing, Paint()..color = const Color(0xFFFFB300));

    // Eye
    canvas.drawCircle(const Offset(9,  -7),  8.0, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(11, -7),  4.5, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(13, -9),  1.5, Paint()..color = Colors.white);

    // Beak
    final beak = Path()
      ..moveTo(_birdR - 2, -3)
      ..lineTo(_birdR + 12, 1)
      ..lineTo(_birdR - 2,  7)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF8F00));
    canvas.drawLine(
      Offset(_birdR - 2, 2),
      Offset(_birdR + 11, 2),
      Paint()
        ..color       = const Color(0xFFE65100)
        ..strokeWidth = 1.5,
    );

    canvas.restore();
  }

  // ── HUD (score during play) ──────────────────────────────────
  void _hud(Canvas canvas) {
    if (state != GameState.playing) return;
    _text(canvas, '$score', Offset(sw / 2, 58),
        size: 46, color: Colors.white, bold: true, shadow: true);
  }

  // ── Ready screen ─────────────────────────────────────────────
  void _screenReady(Canvas canvas) {
    _text(
      canvas,
      'FLAPPY\nBIRD',
      Offset(sw / 2, sh * 0.27),
      size:   44,
      color:  const Color(0xFFFFD600),
      bold:   true,
      shadow: true,
    );
    _pillButton(canvas, 'TAP  TO  START', Offset(sw / 2, sh * 0.62));
  }

  // ── Game-over screen ─────────────────────────────────────────
  void _screenGameOver(Canvas canvas) {
    // Dim overlay
    canvas.drawRect(
        Rect.fromLTWH(0, 0, sw, sh), Paint()..color = Colors.black45);

    const panW = 290.0;
    const panH = 232.0;
    final px = (sw - panW) / 2;
    final py = sh / 2 - panH / 2 - 20;

    // Panel
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(px, py, panW, panH), const Radius.circular(18));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFFF5E6C8));
    canvas.drawRRect(
        rr,
        Paint()
          ..color       = const Color(0xFF7C5C3A)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 3.0);

    // Title
    _text(canvas, 'GAME OVER', Offset(sw / 2, py + 42),
        size: 30, color: const Color(0xFFD32F2F), bold: true, shadow: true);

    // Divider
    canvas.drawLine(
        Offset(px + 18, py + 75), Offset(px + panW - 18, py + 75),
        Paint()..color = const Color(0xFFBCAAA4)..strokeWidth = 1.5);

    // Score row
    _text(canvas, 'SCORE', Offset(px + 50, py + 110),
        size: 15, color: const Color(0xFF795548),
        bold: true, align: TextAlign.left);
    _text(canvas, '$score', Offset(px + panW - 50, py + 110),
        size: 22, color: Colors.black87,
        bold: true, align: TextAlign.right);

    // Best row
    _text(canvas, 'BEST', Offset(px + 50, py + 150),
        size: 15, color: const Color(0xFF795548),
        bold: true, align: TextAlign.left);
    _text(canvas, '$best', Offset(px + panW - 50, py + 150),
        size: 22, color: const Color(0xFFFFB300),
        bold: true, align: TextAlign.right);

    // Medal circle (colour reflects score bracket)
    if (score > 0) {
      final mc = score >= 40
          ? const Color(0xFFFFD700) // gold
          : score >= 20
              ? const Color(0xFFB0BEC5) // silver
              : score >= 10
                  ? const Color(0xFFCD7F32) // bronze
                  : const Color(0xFF4CAF50); // green
      canvas.drawCircle(Offset(sw / 2, py + 130), 18, Paint()..color = mc);
      canvas.drawCircle(
          Offset(sw / 2, py + 130),
          18,
          Paint()
            ..color       = Colors.white30
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }

    _pillButton(canvas, 'TAP TO RESTART', Offset(sw / 2, py + panH + 38));
  }

  // ── Helpers ──────────────────────────────────────────────────
  void _pillButton(Canvas canvas, String label, Offset center) {
    final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 210, height: 46),
        const Radius.circular(23));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawRRect(
        rr,
        Paint()
          ..color       = const Color(0xFF2E7D32)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    _text(canvas, label, center, size: 15, color: Colors.white, bold: true);
  }

  void _text(
    Canvas canvas,
    String text,
    Offset pos, {
    required double size,
    required Color  color,
    bool      bold   = false,
    bool      shadow = false,
    TextAlign align  = TextAlign.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color:      color,
          fontSize:   size,
          fontWeight: bold ? FontWeight.w900 : FontWeight.normal,
          height:     1.2,
          shadows: shadow
              ? [
                  Shadow(
                    color:      Colors.black.withOpacity(0.55),
                    offset:     const Offset(2, 3),
                    blurRadius: 5,
                  )
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign:     align,
    );
    tp.layout();

    final double dx;
    if (align == TextAlign.right) {
      dx = pos.dx - tp.width;
    } else if (align == TextAlign.left) {
      dx = pos.dx;
    } else {
      dx = pos.dx - tp.width / 2;
    }
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_Painter old) => true;
}