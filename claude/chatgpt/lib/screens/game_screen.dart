import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../game/game_engine.dart';
import '../painters/game_painter.dart';

/// The single fullscreen game widget.
///
/// Architecture:
///   • A [Ticker] drives [GameEngine.tick] at the display refresh rate.
///   • [AnimatedBuilder] listens to [GameEngine] (a [ChangeNotifier]) and
///     triggers a repaint via [GamePainter] on every engine notification.
///   • [GestureDetector] forwards taps / clicks to [GameEngine.tap].
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameEngine _engine;
  late final Ticker _ticker;

  /// Guards against initialising the engine more than once when
  /// [didChangeDependencies] is called on subsequent hot reloads etc.
  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    // Drive the simulation at the display refresh rate.
    _ticker = createTicker((_elapsed) => _engine.tick())..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_engineReady) {
      // Provide real screen dimensions now that MediaQuery is available.
      final size = MediaQuery.of(context).size;
      _engine.init(size.width, size.height);
      _engineReady = true;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Black background prevents any white flash during first paint.
      backgroundColor: Colors.black,
      body: GestureDetector(
        // HitTestBehavior.opaque ensures taps register even on transparent areas.
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _engine.tap(),
        child: AnimatedBuilder(
          animation: _engine,
          builder: (context, _) {
            return CustomPaint(
              painter: GamePainter(_engine),
              // SizedBox.expand ensures the canvas fills the entire screen.
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}
