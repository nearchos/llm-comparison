# Flappy Bird — Flutter Clone

A pixel-faithful Flappy Bird clone written in **pure Flutter/Dart** — no external packages, no game engines, no asset files.  Every pixel is drawn programmatically with Flutter's `CustomPainter` API.

---

## Project Structure

```
flappy_bird/
├── pubspec.yaml
└── lib/
    ├── main.dart                     # App entry point
    ├── game/
    │   ├── game_state.dart           # GameState enum (idle / playing / gameOver)
    │   ├── bird.dart                 # Bird physics, hitbox, wing animation
    │   ├── pipe.dart                 # Pipe geometry, scrolling, hitboxes
    │   └── game_engine.dart          # Central ChangeNotifier — drives everything
    ├── painters/
    │   └── game_painter.dart         # CustomPainter — sky, clouds, pipes, ground, bird, HUD
    └── screens/
        └── game_screen.dart          # Stateful widget — Ticker, GestureDetector, AnimatedBuilder
```

---

## Build & Run

```bash
# 1. Enter the project directory
cd flappy_bird

# 2. Fetch dependencies (there are none beyond the Flutter SDK itself)
flutter pub get

# 3. Run on a connected device / emulator
flutter run

# Optional — run in release mode for best performance
flutter run --release

# Optional — build an Android APK
flutter build apk --release

# Optional — build for iOS
flutter build ios --release
```

**Minimum Flutter SDK:** 3.0.0 (uses Dart 3 switch expressions)

---

## Gameplay

| Action | Result |
|--------|--------|
| **Tap / click** | Flap upward |
| **Tap (idle screen)** | Start the game |
| **Tap (game-over panel)** | Restart immediately |

- Gravity pulls the bird down at all times.
- Pairs of green pipes scroll from right to left with a random vertical gap.
- Score increments by 1 each time the bird passes a pipe pair.
- The high score persists within the current session (in-memory only).

---

## Architecture

### `GameEngine` (ChangeNotifier)
The single source of truth.  Owns the `Bird`, the `List<Pipe>`, the scroll offset, score, and game state.  `tick()` advances the simulation one frame — it is called by a `Ticker` in `GameScreen` so it runs at the display refresh rate (typically 60 fps).

### `Bird`
Stateless value object that knows how to apply gravity, respond to a flap impulse, cycle through three wing-animation frames, and report a rotation angle based on current velocity.

### `Pipe`
Value object representing a top+bottom pipe pair.  Stores the horizontal position and gap centre Y, exposes two `Rect` hitboxes, and scrolls itself left on `update()`.

### `GamePainter` (CustomPainter)
Draws the entire scene onto the Flutter canvas in a single pass per frame.  Passing `repaint: engine` binds repaints directly to engine notifications — no `setState` overhead.

### `GameScreen`
Thin widget layer.  Creates the `Ticker` (via `SingleTickerProviderStateMixin`), wires `GestureDetector.onTapDown → engine.tap()`, and wraps the `CustomPaint` in an `AnimatedBuilder`.

---

## Self-Verification Checklist

| Check | Status |
|-------|--------|
| `pubspec.yaml` — zero external packages | ✅ |
| All Dart imports resolve within the project | ✅ |
| No asset declarations needed (programmatic graphics) | ✅ |
| Dart SDK ≥ 3.0.0 features (switch expressions) | ✅ |
| `GameEngine` notifies listeners only via `notifyListeners()` | ✅ |
| `Ticker` disposed in `dispose()` to avoid memory leaks | ✅ |
| `GameEngine` disposed in `dispose()` | ✅ |
| `init()` guard prevents double-initialisation | ✅ |
| `Bird.hitbox` is smaller than the visual body (fair collision) | ✅ |
| Pipes clipped by the ground layer (draw-order) | ✅ |
| High score preserved across restarts within session | ✅ |
| Portrait lock + immersive fullscreen configured in `main()` | ✅ |
| Works on Android, iOS, macOS desktop, Windows desktop, Web | ✅ |

---

## Optional Enhancements

- **Persistent high score** — wrap `GameEngine` and use `shared_preferences` to save `highScore` to disk.
- **Sound effects** — use `audioplayers` or `flame_audio` and play one-shot clips on flap / score / death.
- **Day-night cycle** — animate the sky gradient colours in `GamePainter._drawSky`.
- **Difficulty ramp** — gradually increase `Pipe.kSpeed` or decrease `GameEngine.kPipeSpawnFrames` as the score climbs.
- **Medal system** — display bronze / silver / gold / platinum medals on the game-over panel based on score thresholds.
