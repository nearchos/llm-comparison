import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'bird.dart';
import 'game_state.dart';
import 'pipe.dart';

/// Central game engine — owns all game state and steps the simulation
/// one frame at a time when [tick] is called.
///
/// Extends [ChangeNotifier] so the UI layer can rebuild cheaply through
/// [AnimatedBuilder] without needing setState.
class GameEngine extends ChangeNotifier {
  // ── Layout constants ─────────────────────────────────────────────────────

  /// Height of the ground strip at the bottom of the screen.
  static const double kGroundHeight = 82.0;

  /// Pixels the ground scrolls per frame (must match [Pipe.kSpeed]).
  static const double kGroundScrollSpeed = Pipe.kSpeed;

  /// Minimum frames between consecutive pipe spawns (~1.8 s at 60 fps).
  static const int kPipeSpawnFrames = 110;

  // ── Screen dimensions ────────────────────────────────────────────────────

  double screenWidth = 375;
  double screenHeight = 667;
  bool _initialized = false;

  // ── Public game state ────────────────────────────────────────────────────

  GameState state = GameState.idle;
  int score = 0;
  int highScore = 0;

  late Bird bird;
  final List<Pipe> pipes = [];

  /// Horizontal offset driving the ground stripe scroll (0–23 loop).
  double groundOffset = 0;

  // ── Private frame counters ────────────────────────────────────────────────

  int _frameCount = 0;

  /// Set to a negative value so the first pipe spawns after one interval.
  int _lastPipeFrame = -kPipeSpawnFrames;

  final _rng = Random();

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once (and only once) with the actual screen dimensions
  /// before the first [tick].  Safe to call again — subsequent calls are
  /// ignored.
  void init(double width, double height) {
    if (_initialized) return;
    screenWidth = width;
    screenHeight = height;
    _initialized = true;
    _reset();
  }

  // ── Per-frame update ──────────────────────────────────────────────────────

  /// Advance the simulation by one frame.  Should be driven by a [Ticker]
  /// in the widget layer so it runs at the display refresh rate.
  void tick() {
    if (!_initialized) return;

    switch (state) {
      case GameState.idle:
        _tickIdle();
      case GameState.playing:
        _tickPlaying();
      case GameState.gameOver:
        _tickGameOver();
    }

    notifyListeners();
  }

  // ── Idle state ────────────────────────────────────────────────────────────

  void _tickIdle() {
    groundOffset = (groundOffset + kGroundScrollSpeed) % 24;
    bird.hover(_frameCount);
    _frameCount++;
  }

  // ── Playing state ─────────────────────────────────────────────────────────

  void _tickPlaying() {
    _frameCount++;

    // 1. Bird physics
    bird.update();

    // 2. Ground scroll
    groundOffset = (groundOffset + kGroundScrollSpeed) % 24;

    // 3. Pipe spawning
    if (_frameCount - _lastPipeFrame >= kPipeSpawnFrames) {
      _spawnPipe();
      _lastPipeFrame = _frameCount;
    }

    // 4. Pipe movement & cleanup
    for (final p in pipes) {
      p.update();
    }
    pipes.removeWhere((p) => p.isOffScreen());

    // 5. Score: increment when the bird's left edge clears the pipe's right edge
    for (final p in pipes) {
      if (!p.scored && p.x + Pipe.kWidth < bird.x) {
        p.scored = true;
        score++;
      }
    }

    // 6. Collision detection
    _checkCollisions();
  }

  // ── Game-over state ───────────────────────────────────────────────────────

  /// After dying the bird continues to fall until it lands on the ground.
  void _tickGameOver() {
    bird.update();
    final groundY = screenHeight - kGroundHeight - Bird.kHitboxHalfH;
    if (bird.y >= groundY) {
      bird.y = groundY;
      bird.velocity = 0;
    }
  }

  // ── Pipe spawning ─────────────────────────────────────────────────────────

  void _spawnPipe() {
    // Keep the gap centre away from the very top / bottom edges.
    final minGap = screenHeight * 0.22;
    final maxGap = screenHeight - kGroundHeight - screenHeight * 0.22;
    final gapCenter = minGap + _rng.nextDouble() * (maxGap - minGap);

    pipes.add(Pipe(x: screenWidth + 12, gapCenterY: gapCenter));
  }

  // ── Collision detection ───────────────────────────────────────────────────

  void _checkCollisions() {
    // Ground collision
    if (bird.y + Bird.kHitboxHalfH >= screenHeight - kGroundHeight) {
      _triggerGameOver();
      return;
    }
    // Ceiling collision
    if (bird.y - Bird.kHitboxHalfH <= 0) {
      _triggerGameOver();
      return;
    }
    // Pipe collision
    for (final p in pipes) {
      if (bird.hitbox.overlaps(p.topHitbox) ||
          bird.hitbox.overlaps(p.bottomHitbox)) {
        _triggerGameOver();
        return;
      }
    }
  }

  void _triggerGameOver() {
    state = GameState.gameOver;
    if (score > highScore) highScore = score;
  }

  // ── Input ─────────────────────────────────────────────────────────────────

  /// Called on every player tap / click.
  void tap() {
    switch (state) {
      case GameState.idle:
        // First tap starts the game
        state = GameState.playing;
        bird.flap();
      case GameState.playing:
        bird.flap();
      case GameState.gameOver:
        // Restart
        _reset();
        state = GameState.playing;
        bird.flap();
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _reset() {
    bird = Bird(
      x: screenWidth * 0.25,
      y: screenHeight / 2 - 60,
    );
    pipes.clear();
    score = 0;
    _frameCount = 0;
    _lastPipeFrame = -kPipeSpawnFrames;
    groundOffset = 0;
  }
}
