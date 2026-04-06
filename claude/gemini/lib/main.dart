import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FlappyBirdApp());
}

// ─────────────────────────────────────────────
// App Root
// ─────────────────────────────────────────────
class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flappy Bird',
      home: GameScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────
enum GameState { idle, playing, dead }

class PipePair {
  double x;
  final double topHeight; // height of the top pipe from top of screen
  final double gap;       // vertical gap between pipes

  PipePair({required this.x, required this.topHeight, required this.gap});
}

// ─────────────────────────────────────────────
// Game Constants
// ─────────────────────────────────────────────
const double kBirdSize      = 44.0;
const double kPipeWidth     = 72.0;
const double kGapSize       = 190.0;
const double kPipeSpeed     = 3.2;
const double kGravity       = 0.38;
const double kJumpVelocity  = -8.2;
const double kPipeSpawnGap  = 310.0; // horizontal distance between pipe pairs
const int    kTickMs        = 16;    // ~60fps

// ─────────────────────────────────────────────
// Game Screen (StatefulWidget)
// ─────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ── Layout ──────────────────────────────────
  late double _screenW;
  late double _screenH;
  late double _groundH;

  // ── Bird ─────────────────────────────────────
  double _birdY       = 0.0;  // Y position (pixels from top)
  double _birdVelocity = 0.0;
  double _birdAngle   = 0.0;

  // ── Pipes ────────────────────────────────────
  final List<PipePair> _pipes = [];
  final Random _rng = Random();
  double _nextPipeX   = 0.0;

  // ── State & Score ────────────────────────────
  GameState _state    = GameState.idle;
  int _score          = 0;
  int _bestScore      = 0;

  // ── Timer ────────────────────────────────────
  Timer? _timer;

  // ── Ground scroll ────────────────────────────
  double _groundOffset = 0.0;

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Initialization / Reset
  // ─────────────────────────────────────────────
  void _initGame() {
    _birdY        = _screenH * 0.40;
    _birdVelocity = 0.0;
    _birdAngle    = 0.0;
    _pipes.clear();
    _score        = 0;
    _groundOffset = 0.0;
    _nextPipeX    = _screenW + 60.0;
    _spawnPipe();
  }

  void _startGame() {
    _initGame();
    _state = GameState.playing;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: kTickMs), (_) => _tick());
  }

  void _spawnPipe() {
    final minTop = _screenH * 0.12;
    final maxTop = _screenH - _groundH - kGapSize - _screenH * 0.12;
    final topH   = minTop + _rng.nextDouble() * (maxTop - minTop);
    _pipes.add(PipePair(x: _nextPipeX, topHeight: topH, gap: kGapSize));
    _nextPipeX += kPipeSpawnGap;
  }

  // ─────────────────────────────────────────────
  // Game Loop
  // ─────────────────────────────────────────────
  void _tick() {
    if (_state != GameState.playing) return;

    setState(() {
      // ── Physics ──────────────────────────────
      _birdVelocity += kGravity;
      _birdY        += _birdVelocity;

      // Bird tilt based on velocity
      _birdAngle = (_birdVelocity * 3.0).clamp(-45.0, 90.0);

      // ── Ground scroll ─────────────────────────
      _groundOffset = (_groundOffset + kPipeSpeed) % 40.0;

      // ── Pipes ────────────────────────────────
      for (final p in _pipes) {
        p.x -= kPipeSpeed;
      }

      // Spawn new pipes
      if (_pipes.isEmpty || _pipes.last.x < _screenW - kPipeSpawnGap + kPipeSpeed) {
        if (_nextPipeX <= _pipes.last.x + kPipeSpawnGap + kPipeSpeed) {
          _nextPipeX = _pipes.last.x + kPipeSpawnGap;
          _spawnPipe();
        }
      }

      // Remove off-screen pipes
      _pipes.removeWhere((p) => p.x + kPipeWidth < -20);

      // ── Scoring ──────────────────────────────
      for (final p in _pipes) {
        final birdCenterX = _screenW * 0.28 + kBirdSize / 2;
        final pipeCenterX = p.x + kPipeWidth / 2;
        // Score when bird center crosses pipe center going left→right
        if (!p._scored && pipeCenterX < birdCenterX) {
          p._scored = true;
          _score++;
        }
      }

      // ── Collision ────────────────────────────
      if (_checkCollision()) {
        _state = GameState.dead;
        if (_score > _bestScore) _bestScore = _score;
        _timer?.cancel();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Collision Detection
  // ─────────────────────────────────────────────
  bool _checkCollision() {
    const double margin = 6.0; // slight forgiveness
    final birdLeft   = _screenW * 0.28 + margin;
    final birdRight  = birdLeft + kBirdSize - margin * 2;
    final birdTop    = _birdY + margin;
    final birdBottom = _birdY + kBirdSize - margin;

    // Ground / ceiling
    if (birdBottom >= _screenH - _groundH || _birdY <= 0) return true;

    // Pipes
    for (final p in _pipes) {
      final pLeft  = p.x;
      final pRight = p.x + kPipeWidth;

      if (birdRight > pLeft && birdLeft < pRight) {
        // Top pipe bottom
        if (birdTop < p.topHeight) return true;
        // Bottom pipe top
        if (birdBottom > p.topHeight + p.gap) return true;
      }
    }
    return false;
  }

  // ─────────────────────────────────────────────
  // Input
  // ─────────────────────────────────────────────
  void _onTap() {
    switch (_state) {
      case GameState.idle:
        _startGame();
        break;
      case GameState.playing:
        _birdVelocity = kJumpVelocity;
        break;
      case GameState.dead:
        _startGame();
        break;
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _screenW = MediaQuery.of(context).size.width;
    _screenH = MediaQuery.of(context).size.height;
    _groundH = _screenH * 0.095;

    // Initialize bird position on first build (idle state)
    if (_state == GameState.idle && _birdY == 0.0) {
      _birdY = _screenH * 0.40;
    }

    return GestureDetector(
      onTap: _onTap,
      child: Scaffold(
        backgroundColor: const Color(0xFF4EC0CA),
        body: Stack(
          children: [
            // ── Sky gradient ───────────────────
            _buildSky(),

            // ── Clouds (decorative) ────────────
            _buildClouds(),

            // ── Pipes ─────────────────────────
            ..._buildPipes(),

            // ── Ground ────────────────────────
            _buildGround(),

            // ── Bird ──────────────────────────
            _buildBird(),

            // ── Score ─────────────────────────
            if (_state == GameState.playing || _state == GameState.dead)
              _buildScore(),

            // ── Overlay UI ────────────────────
            _buildOverlay(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Widget Builders
  // ─────────────────────────────────────────────
  Widget _buildSky() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF70D6F0), Color(0xFFB8EAF5)],
          ),
        ),
      ),
    );
  }

  Widget _buildClouds() {
    // Static decorative clouds – positions are percentages of screen
    const clouds = [
      (0.08, 0.08, 80.0, 30.0),
      (0.38, 0.05, 110.0, 36.0),
      (0.65, 0.12, 70.0, 25.0),
      (0.82, 0.06, 90.0, 32.0),
    ];
    return Stack(
      children: clouds.map((c) {
        return Positioned(
          left:  _screenW * c.$1,
          top:   _screenH * c.$2,
          child: _Cloud(width: c.$3, height: c.$4),
        );
      }).toList(),
    );
  }

  List<Widget> _buildPipes() {
    final widgets = <Widget>[];
    for (final p in _pipes) {
      final bottomPipeTop = p.topHeight + p.gap;
      final bottomPipeH   = _screenH - _groundH - bottomPipeTop;

      // Top pipe
      widgets.add(Positioned(
        left:   p.x,
        top:    0,
        width:  kPipeWidth,
        height: p.topHeight,
        child:  _Pipe(isTop: true),
      ));

      // Bottom pipe
      if (bottomPipeH > 0) {
        widgets.add(Positioned(
          left:   p.x,
          top:    bottomPipeTop,
          width:  kPipeWidth,
          height: bottomPipeH,
          child:  _Pipe(isTop: false),
        ));
      }
    }
    return widgets;
  }

  Widget _buildGround() {
    return Positioned(
      bottom: 0,
      left:   0,
      right:  0,
      height: _groundH,
      child: CustomPaint(painter: _GroundPainter(_groundOffset)),
    );
  }

  Widget _buildBird() {
    return Positioned(
      left: _screenW * 0.28,
      top:  _birdY,
      child: Transform.rotate(
        angle: _birdAngle * pi / 180,
        child: const _Bird(),
      ),
    );
  }

  Widget _buildScore() {
    return Positioned(
      top:   _screenH * 0.07,
      left:  0,
      right: 0,
      child: Center(
        child: Text(
          '$_score',
          style: const TextStyle(
            fontFamily:   'Courier',
            fontSize:     62,
            fontWeight:   FontWeight.w900,
            color:        Colors.white,
            shadows: [
              Shadow(offset: Offset(2, 3), blurRadius: 0, color: Color(0x88000000)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    if (_state == GameState.playing) return const SizedBox.shrink();

    if (_state == GameState.idle) {
      return Positioned.fill(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _gameTitle(),
            const SizedBox(height: 50),
            _pulsingTapHint('TAP TO START'),
          ],
        ),
      );
    }

    // Dead
    return Positioned.fill(
      child: Container(
        color: Colors.black26,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD97706), width: 3),
              boxShadow: const [
                BoxShadow(offset: Offset(0, 6), blurRadius: 20, color: Colors.black38),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GAME OVER',
                  style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309), letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBox('SCORE', '$_score'),
                    _statBox('BEST',  '$_bestScore'),
                  ],
                ),
                const SizedBox(height: 24),
                _pulsingTapHint('TAP TO RESTART'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameTitle() {
    return Column(
      children: [
        const Text('🐦', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        Text(
          'FLAPPY BIRD',
          style: TextStyle(
            fontSize:   40,
            fontWeight: FontWeight.w900,
            color:      Colors.white,
            letterSpacing: 3,
            shadows: [
              const Shadow(offset: Offset(2, 4), blurRadius: 0, color: Color(0x88000000)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
      ],
    );
  }

  Widget _pulsingTapHint(String text) {
    return _PulsingText(text: text);
  }
}

// ─────────────────────────────────────────────
// Pipe scored flag extension
// ─────────────────────────────────────────────
extension _PipeScoredFlag on PipePair {
  static final _flags = <PipePair, bool>{};
  bool get _scored => _flags[this] ?? false;
  set _scored(bool v) => _flags[this] = v;
}

// ─────────────────────────────────────────────
// Bird Widget (CustomPainter)
// ─────────────────────────────────────────────
class _Bird extends StatelessWidget {
  const _Bird();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(kBirdSize, kBirdSize),
      painter: _BirdPainter(),
    );
  }
}

class _BirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 2, cy + 3), width: w * 0.85, height: h * 0.7),
      Paint()..color = Colors.black26,
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: w * 0.88, height: h * 0.8),
      Paint()..color = const Color(0xFFFCD34D),
    );

    // Wing
    final wingPath = Path()
      ..moveTo(cx - 6, cy - 2)
      ..quadraticBezierTo(cx - 18, cy - 18, cx - 4, cy + 6)
      ..close();
    canvas.drawPath(wingPath, Paint()..color = const Color(0xFFF59E0B));

    // Eye white
    canvas.drawCircle(Offset(cx + 10, cy - 7), 8, Paint()..color = Colors.white);
    // Pupil
    canvas.drawCircle(Offset(cx + 12, cy - 6), 4, Paint()..color = const Color(0xFF1E293B));
    // Eye shine
    canvas.drawCircle(Offset(cx + 13, cy - 8), 1.5, Paint()..color = Colors.white);

    // Beak
    final beakPath = Path()
      ..moveTo(cx + 16, cy)
      ..lineTo(cx + 28, cy + 4)
      ..lineTo(cx + 16, cy + 8)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFF97316));

    // Head highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 4, cy - 8), width: 14, height: 9),
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..blendMode = BlendMode.overlay,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// Pipe Widget
// ─────────────────────────────────────────────
class _Pipe extends StatelessWidget {
  final bool isTop;
  const _Pipe({required this.isTop});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PipePainter(isTop: isTop),
      size: Size.infinite,
    );
  }
}

class _PipePainter extends CustomPainter {
  final bool isTop;
  const _PipePainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const capH = 28.0;
    const capExtra = 8.0; // cap wider than pipe body
    const bodyX = capExtra;
    final bodyW = w - capExtra * 2;

    final bodyGrad = LinearGradient(colors: const [
      Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF15803D),
    ]).createShader(Rect.fromLTWH(0, 0, w, h));

    final capGrad = LinearGradient(colors: const [
      Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D),
    ]).createShader(Rect.fromLTWH(0, 0, w, h));

    final bodyPaint = Paint()..shader = bodyGrad;
    final capPaint  = Paint()..shader = capGrad;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.18);

    if (isTop) {
      // Pipe body (top)
      canvas.drawRect(Rect.fromLTWH(bodyX, 0, bodyW, h - capH), bodyPaint);
      // Shadow on pipe body right edge
      canvas.drawRect(Rect.fromLTWH(bodyX + bodyW - 10, 0, 10, h - capH), shadowPaint);
      // Cap
      final capRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h - capH, w, capH),
        const Radius.circular(4),
      );
      canvas.drawRRect(capRect, capPaint);
      canvas.drawRect(Rect.fromLTWH(w - 12, h - capH, 12, capH), shadowPaint);
    } else {
      // Cap (bottom pipe shows cap at top)
      final capRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, capH),
        const Radius.circular(4),
      );
      canvas.drawRRect(capRect, capPaint);
      canvas.drawRect(Rect.fromLTWH(w - 12, 0, 12, capH), shadowPaint);
      // Pipe body
      canvas.drawRect(Rect.fromLTWH(bodyX, capH, bodyW, h - capH), bodyPaint);
      canvas.drawRect(Rect.fromLTWH(bodyX + bodyW - 10, capH, 10, h - capH), shadowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipePainter old) => false;
}

// ─────────────────────────────────────────────
// Ground Painter (scrolling striped ground)
// ─────────────────────────────────────────────
class _GroundPainter extends CustomPainter {
  final double offset;
  const _GroundPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    // Dirt
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFDEB887),
    );

    // Grass stripe at top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.30),
      Paint()..color = const Color(0xFF4CAF50),
    );

    // Scrolling dashes on grass
    final dashPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 2;
    for (double x = -offset; x < size.width + 40; x += 40) {
      canvas.drawLine(
        Offset(x, size.height * 0.12),
        Offset(x + 20, size.height * 0.12),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroundPainter old) => old.offset != offset;
}

// ─────────────────────────────────────────────
// Cloud Widget
// ─────────────────────────────────────────────
class _Cloud extends StatelessWidget {
  final double width;
  final double height;
  const _Cloud({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CloudPainter(),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.82);
    final w = size.width;
    final h = size.height;
    canvas.drawOval(Rect.fromLTWH(0, h * 0.3, w * 0.55, h * 0.7), paint);
    canvas.drawOval(Rect.fromLTWH(w * 0.2, 0, w * 0.5, h * 0.85), paint);
    canvas.drawOval(Rect.fromLTWH(w * 0.5, h * 0.25, w * 0.5, h * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// Pulsing Text Widget (for tap hints)
// ─────────────────────────────────────────────
class _PulsingText extends StatefulWidget {
  final String text;
  const _PulsingText({required this.text});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(offset: Offset(0, 4), blurRadius: 12, color: Colors.black26),
          ],
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            fontSize:   18,
            fontWeight: FontWeight.w900,
            color:      Color(0xFF065F46),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}