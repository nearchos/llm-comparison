import 'package:flutter/painting.dart' show Offset, Rect;

/// A single pipe obstacle consisting of a top pipe and a bottom pipe
/// with a randomly-positioned vertical gap in between.
///
/// Pipes scroll from right to left at a constant speed.
class Pipe {
  // ── Geometry constants ───────────────────────────────────────────────────

  /// Width of the pipe body in logical pixels.
  static const double kWidth = 70.0;

  /// Vertical size of the gap the bird must fly through.
  static const double kGapHeight = 148.0;

  /// Horizontal scroll speed (pixels per frame).
  static const double kSpeed = 2.8;

  /// Height of the flared cap at each pipe opening.
  static const double kCapHeight = 26.0;

  /// Extra width added to each side of the cap beyond the body width.
  static const double kCapOverhang = 5.0;

  // ── State ────────────────────────────────────────────────────────────────

  /// Left edge of this pipe in screen coordinates.
  double x;

  /// Y coordinate of the vertical centre of the gap.
  final double gapCenterY;

  /// True once the bird has passed this pipe (prevents double-counting score).
  bool scored = false;

  // ── Constructor ──────────────────────────────────────────────────────────

  Pipe({required this.x, required this.gapCenterY});

  // ── Update ───────────────────────────────────────────────────────────────

  /// Scroll the pipe one frame to the left.
  void update() => x -= kSpeed;

  /// Returns true when the pipe has fully left the visible area.
  bool isOffScreen() => x + kWidth + kCapOverhang < 0;

  // ── Gap geometry ─────────────────────────────────────────────────────────

  /// Y coordinate of the bottom edge of the top pipe (= top of the gap).
  double get topPipeBottom => gapCenterY - kGapHeight / 2;

  /// Y coordinate of the top edge of the bottom pipe (= bottom of the gap).
  double get bottomPipeTop => gapCenterY + kGapHeight / 2;

  // ── Hitboxes ─────────────────────────────────────────────────────────────
  // Both hitboxes are inset by 3 px on each side for a slightly more forgiving
  // collision feel.

  /// Hitbox for the top pipe (extends infinitely upward).
  Rect get topHitbox =>
      Rect.fromLTRB(x + 3, -2000, x + kWidth - 3, topPipeBottom);

  /// Hitbox for the bottom pipe (extends infinitely downward).
  Rect get bottomHitbox =>
      Rect.fromLTRB(x + 3, bottomPipeTop, x + kWidth - 3, 20000);
}
