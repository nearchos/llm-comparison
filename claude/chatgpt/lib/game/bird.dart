import 'dart:math' show sin, min;

import 'package:flutter/painting.dart' show Offset, Rect;

/// Represents the player-controlled bird.
///
/// Responsibilities:
///   • Store and update position / velocity each frame.
///   • Provide an upward flap impulse.
///   • Animate wing frames (up / mid / down) for the flapping effect.
///   • Expose a hitbox slightly smaller than the visual body for fairness.
///   • Supply a rotation angle that tilts the bird realistically.
class Bird {
  // ── Physics constants ────────────────────────────────────────────────────

  /// Downward acceleration applied each frame (pixels per frame²).
  static const double kGravity = 0.45;

  /// Upward velocity impulse applied on flap.
  static const double kFlapVelocity = -9.2;

  /// Maximum downward velocity (terminal velocity).
  static const double kTerminalVelocity = 14.0;

  // ── Hitbox half-dimensions ───────────────────────────────────────────────

  /// Half-width of the forgiving collision hitbox.
  static const double kHitboxHalfW = 12.0;

  /// Half-height of the forgiving collision hitbox.
  static const double kHitboxHalfH = 9.0;

  // ── State ────────────────────────────────────────────────────────────────

  double x;
  double y;
  double velocity;

  /// 0 = wing mid, 1 = wing up, 2 = wing down.
  int wingFrame;

  int _wingCounter;

  /// Y position used as the centre of the idle hover bob animation.
  final double _idleBaseY;

  // ── Constructor ──────────────────────────────────────────────────────────

  Bird({required this.x, required this.y})
      : velocity = 0,
        wingFrame = 0,
        _wingCounter = 0,
        _idleBaseY = y;

  // ── Public API ───────────────────────────────────────────────────────────

  /// Apply an upward impulse (called on tap during gameplay).
  void flap() {
    velocity = kFlapVelocity;
    wingFrame = 1; // immediately show "wing up" frame
  }

  /// Advance physics and wing animation by one frame during active gameplay.
  void update() {
    velocity += kGravity;
    if (velocity > kTerminalVelocity) velocity = kTerminalVelocity;
    y += velocity;
    _stepWingAnimation();
  }

  /// Idle bobbing animation: sinusoidal vertical oscillation, no gravity.
  void hover(int frameCount) {
    y = _idleBaseY + 10 * sin(frameCount * 0.05);
    _stepWingAnimation();
  }

  // ── Computed properties ──────────────────────────────────────────────────

  /// Rotation angle in radians — positive = nose-down, negative = nose-up.
  double get rotation {
    if (velocity <= -6) return -0.38;
    if (velocity < 0) return -0.18;
    if (velocity < 5) return 0.15;
    return min(velocity / kTerminalVelocity * 1.35, 1.35);
  }

  /// Axis-aligned hitbox, intentionally smaller than the visual for fair play.
  Rect get hitbox => Rect.fromCenter(
        center: Offset(x, y),
        width: kHitboxHalfW * 2,
        height: kHitboxHalfH * 2,
      );

  // ── Private helpers ──────────────────────────────────────────────────────

  void _stepWingAnimation() {
    _wingCounter++;
    if (_wingCounter % 7 == 0) {
      wingFrame = (wingFrame + 1) % 3;
    }
  }
}
