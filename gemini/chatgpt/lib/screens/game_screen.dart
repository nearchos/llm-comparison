import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../engine/game_engine.dart';
import '../rendering/game_painter.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;
  final GameEngine _engine = GameEngine();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    
    // Calculate Delta Time (dt) in seconds
    double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;

    // Cap dt to prevent huge physics jumps on lag spikes
    if (dt > 0.05) dt = 0.05;

    setState(() {
      _engine.update(dt);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Initialize engine with screen dimensions on first frame
          if (_engine.screenWidth == 0) {
            _engine.init(constraints.maxWidth, constraints.maxHeight);
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _engine.onTap(),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: CustomPaint(
                painter: GamePainter(
                  _engine,
                  _lastTime.inMilliseconds / 1000.0, // Used for scrolling animations
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}