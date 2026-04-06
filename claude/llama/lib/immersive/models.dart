// ─────────────────────────────────────────────────────────────────────────────
// models.dart
// Data models shared across the game: state machine, pipe pairs, cloud data.
// ─────────────────────────────────────────────────────────────────────────────

/// The three high-level states the game can be in.
enum GameState {
  /// Splash / waiting for first tap.
  start,

  /// Bird is flying, pipes are scrolling.
  playing,

  /// Bird hit something; show score and restart prompt.
  gameOver,
}

// ─────────────────────────────────────────────────────────────────────────────
// PipePair
// ─────────────────────────────────────────────────────────────────────────────

/// A single pair of upper + lower pipes with a gap between them.
class PipePair {
  /// Left edge of the pipe body in screen-pixel coordinates.
  double x;

  /// Y coordinate (pixels from top) of the *bottom* edge of the upper pipe.
  final double gapTop;

  /// Y coordinate (pixels from top) of the *top* edge of the lower pipe.
  final double gapBottom;

  /// Whether the player has already been awarded a point for clearing this pair.
  bool scored;

  PipePair({
    required this.x,
    required this.gapTop,
    required this.gapBottom,
    this.scored = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Cloud
// ─────────────────────────────────────────────────────────────────────────────

/// A decorative background cloud that scrolls at its own speed.
class Cloud {
  double x;
  final double y;

  /// Width in pixels (height is proportional).
  final double size;

  /// Fraction of pipe-speed at which this cloud scrolls (parallax).
  final double speedFactor;

  Cloud({
    required this.x,
    required this.y,
    required this.size,
    required this.speedFactor,
  });
}