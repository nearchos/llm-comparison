// ─────────────────────────────────────────────────────────────────────────────
// game_screen.dart
// The main game widget.  Owns:
//   • The AnimationController that drives the game loop tick.
//   • All mutable game state (bird position/velocity, pipes, score …).
//   • Input handling (GestureDetector tap → flap).
//   • Physics update, collision detection, and pipe spawning.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'game_painter.dart';

// ─── Physics / gameplay constants ─────────────────────────────────────────────

/// Downward acceleration in pixels per second squared.
const double _kGravity = 1600.0;

/// Upward velocity applied on each tap/flap (negative = upward).
const double _kFlapVelocity = -530.0;

/// Horizontal scroll speed of the pipes in pixels per second.
const double _kPipeSpeed = 185.0;

/// Visual width of each pipe body.
const double _kPipeWidth = 72.0;

/// Height of the gap between the upper and lower pipes.
const double _kGapSize = 162.0;

/// Minimum pixels from the top of the play area to the top of the gap.
const double _kGapMinTopMargin = 90.0;

/// Minimum pixels from the bottom of the gap to the top of the ground.
const double _kGapMinBottomMargin = 60.0;

/// Horizontal distance between the LEFT edges of successive pipe pairs.
const double _kPipeSpacing = 240.0;

/// Height of the ground strip at the bottom of the screen.
const double _kGroundHeight = 78.0;

/// Collision shrink factor – makes the hitbox slightly smaller than the sprite.
const double _kBirdHitboxRadius = 14.0;

// ─── Cloud setup ──────────────────────────────────────────────────────────────

const int _kCloudCount = 6;

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── Animation controller (drives the game loop) ───────────────────────────
  late AnimationController _loopController;

  // ── Screen geometry (set once layout is known) ────────────────────────────
  double _screenW = 0;
  double _screenH = 0;
  bool _dimensionsReady = false;

  // ── Game state ────────────────────────────────────────────────────────────
  GameState _state = GameState.start;

  // ── Bird ──────────────────────────────────────────────────────────────────
  double _birdX = 0;
  double _birdY = 0;
  double _birdVelocity = 0; // pixels / second, positive = downward
  double _birdRotation = 0; // radians

  /// 0..1 continuously advancing value that drives the wing flap cycle.
  double _flapProgress = 0;

  // ── Pipes ─────────────────────────────────────────────────────────────────
  final List<PipePair> _pipes = [];
  final math.Random _rng = math.Random();

  // ── Clouds (parallax background) ─────────────────────────────────────────
  final List<Cloud> _clouds = [];

  // ── Scoring ───────────────────────────────────────────────────────────────
  int _score = 0;
  int _bestScore = 0;

  // ── Ground scroll ─────────────────────────────────────────────────────────
  double _groundScrollOffset = 0;

  // ── Start-screen tap pulse ────────────────────────────────────────────────
  bool _tapPulse = true;
  late AnimationController _pulseController;

  // ── Precise timing for dt calculation ────────────────────────────────────
  int? _prevTimestampUs; // microseconds

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Main game-loop ticker.
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(days: 365), // effectively infinite
    );
    _loopController.addListener(_onTick);
    _loopController.repeat();

    // Blinking pulse for "TAP TO START".
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          setState(() => _tapPulse = !_tapPulse);
          _pulseController.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _loopController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Layout hook – grab screen size once Flutter has laid out the widget.
  // ─────────────────────────────────────────────────────────────────────────

  void _initDimensions(BoxConstraints constraints) {
    if (_dimensionsReady) return;
    _screenW = constraints.maxWidth;
    _screenH = constraints.maxHeight;
    _dimensionsReady = true;

    // Position bird in left quarter of screen, vertically centred.
    _birdX = _screenW * 0.25;
    _birdY = _screenH * 0.45;

    // Spawn a handful of decorative clouds.
    _spawnClouds();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Input
  // ─────────────────────────────────────────────────────────────────────────

  void _handleTap() {
    if (!_dimensionsReady) return;

    switch (_state) {
      case GameState.start:
        _startGame();
        _flap();
      case GameState.playing:
        _flap();
      case GameState.gameOver:
        _resetGame();
    }
  }

  void _flap() {
    _birdVelocity = _kFlapVelocity;
    // Kick the flap animation back to "wings going up" phase.
    _flapProgress = 0.0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Game state transitions
  // ─────────────────────────────────────────────────────────────────────────

  void _startGame() {
    _state = GameState.playing;
    _prevTimestampUs = null;
    _pipes.clear();
    _score = 0;
  }

  void _resetGame() {
    setState(() {
      _state = GameState.start;
      _birdY = _screenH * 0.45;
      _birdVelocity = 0;
      _birdRotation = 0;
      _flapProgress = 0;
      _pipes.clear();
      _groundScrollOffset = 0;
      _prevTimestampUs = null;
    });
  }

  void _triggerGameOver() {
    _state = GameState.gameOver;
    _prevTimestampUs = null;
    if (_score > _bestScore) _bestScore = _score;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Game loop tick
  // ─────────────────────────────────────────────────────────────────────────

  void _onTick() {
    if (!_dimensionsReady) return;

    // Compute dt from the AnimationController's elapsed duration.
    final nowUs = (_loopController.lastElapsedDuration?.inMicroseconds ?? 0);
    final double dt;
    if (_prevTimestampUs == null) {
      dt = 0;
    } else {
      dt = (nowUs - _prevTimestampUs!) / 1e6;
    }
    _prevTimestampUs = nowUs;

    // Clamp dt to avoid enormous jumps after the app is backgrounded etc.
    final safeDt = dt.clamp(0.0, 0.05);

    setState(() {
      _updateClouds(safeDt);

      if (_state == GameState.playing) {
        _updateBird(safeDt);
        _updatePipes(safeDt);
        _checkCollisions();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Physics update
  // ─────────────────────────────────────────────────────────────────────────

  void _updateBird(double dt) {
    // Apply gravity.
    _birdVelocity += _kGravity * dt;
    _birdY += _birdVelocity * dt;

    // Tilt nose up when flying, nose down when falling.
    // Map velocity range [-600, +1000] px/s → [-0.5, 1.4] rad.
    _birdRotation = (_birdVelocity / 700.0).clamp(-0.5, 1.4);

    // Advance the wing animation.  Full flap cycle in ~0.35 s.
    _flapProgress = (_flapProgress + dt * 2.85) % 1.0;
  }

  void _updatePipes(double dt) {
    // Scroll ground texture.
    _groundScrollOffset = (_groundScrollOffset + _kPipeSpeed * dt) % 60;

    // Move existing pipes left.
    for (final pipe in _pipes) {
      pipe.x -= _kPipeSpeed * dt;

      // Award a point when the bird's centre passes the pipe's right edge.
      if (!pipe.scored && pipe.x + _kPipeWidth < _birdX) {
        pipe.scored = true;
        _score++;
      }
    }

    // Remove pipes that have scrolled fully off screen.
    _pipes.removeWhere((p) => p.x + _kPipeWidth + 20 < 0);

    // Spawn a new pipe pair if none exist yet, or the last one has
    // scrolled far enough to the left.
    if (_pipes.isEmpty || _pipes.last.x < _screenW - _kPipeSpacing) {
      _spawnPipe();
    }
  }

  void _updateClouds(double dt) {
    for (final cloud in _clouds) {
      cloud.x -= _kPipeSpeed * cloud.speedFactor * dt;

      // Wrap clouds around when they exit the left edge.
      if (cloud.x + cloud.size / 2 < 0) {
        cloud.x = _screenW + cloud.size / 2;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Collision detection
  // ─────────────────────────────────────────────────────────────────────────

  void _checkCollisions() {
    final playAreaBottom = _screenH - _kGroundHeight;

    // Ground / ceiling collision.
    if (_birdY + _kBirdHitboxRadius >= playAreaBottom || _birdY - _kBirdHitboxRadius <= 0) {
      _triggerGameOver();
      return;
    }

    // Pipe collision – use a circular hitbox centred on the bird.
    for (final pipe in _pipes) {
      if (_birdCircleHitsPipe(pipe)) {
        _triggerGameOver();
        return;
      }
    }
  }

  /// Returns true if the circular bird hitbox overlaps the given pipe pair.
  bool _birdCircleHitsPipe(PipePair pipe) {
    final pipeLeft = pipe.x;
    final pipeRight = pipe.x + _kPipeWidth;

    // Quick horizontal broad-phase check.
    if (_birdX + _kBirdHitboxRadius < pipeLeft) return false;
    if (_birdX - _kBirdHitboxRadius > pipeRight) return false;

    // Vertical overlap with the gap: if the bird is fully inside the gap, no collision.
    final topClearance = _birdY - _kBirdHitboxRadius > pipe.gapTop;
    final botClearance = _birdY + _kBirdHitboxRadius < pipe.gapBottom;
    if (topClearance && botClearance) return false;

    // The bird's horizontal range overlaps the pipe, and it's not in the gap → hit.
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Spawn helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _spawnPipe() {
    final playH = _screenH - _kGroundHeight;
    final maxGapTop = playH - _kGapSize - _kGapMinBottomMargin;
    final gapTop = _kGapMinTopMargin + _rng.nextDouble() * (maxGapTop - _kGapMinTopMargin);
    _pipes.add(PipePair(
      x: _screenW,
      gapTop: gapTop,
      gapBottom: gapTop + _kGapSize,
    ));
  }

  void _spawnClouds() {
    // Three layers: slow/large background, medium, fast/small foreground.
    final layers = [
      (factor: 0.18, size: 110.0, count: 2),
      (factor: 0.30, size: 80.0, count: 2),
      (factor: 0.42, size: 55.0, count: 2),
    ];

    for (final layer in layers) {
      for (int i = 0; i < layer.count; i++) {
        _clouds.add(Cloud(
          x: _rng.nextDouble() * _screenW,
          y: _kGapMinTopMargin * 0.3 + _rng.nextDouble() * (_screenH * 0.30),
          size: layer.size * (0.85 + _rng.nextDouble() * 0.3),
          speedFactor: layer.factor,
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTap(),
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _initDimensions(constraints);

          return CustomPaint(
            painter: GamePainter(
              gameState: _state,
              birdX: _birdX,
              birdY: _birdY,
              birdRotation: _birdRotation,
              flapProgress: _flapProgress,
              pipes: _pipes,
              clouds: _clouds,
              score: _score,
              bestScore: _bestScore,
              groundScrollOffset: _groundScrollOffset,
              pipeWidth: _kPipeWidth,
              groundHeight: _kGroundHeight,
              showTapPulse: _tapPulse,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}