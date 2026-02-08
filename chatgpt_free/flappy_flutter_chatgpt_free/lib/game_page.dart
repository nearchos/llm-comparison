import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'game_state.dart';
import 'game_painter.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final GameState _game = GameState();

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      setState(() {
        _game.update(1 / 60); // fixed timestep
      });
    });

    _ticker.start();
  }

  void _tap() {
    if (_game.isGameOver) {
      _game.reset();
    } else {
      _game.flap();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tap,
      child: Scaffold(
        body: Stack(
          children: [
            CustomPaint(
              painter: GamePainter(_game),
              child: Container(),
            ),
            if (_game.isGameOver)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "GAME OVER",
                      style:
                          TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    Text("Score: ${_game.score}"),
                    const SizedBox(height: 20),
                    const Text("Tap to restart"),
                  ],
                ),
              )
            else
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _game.score.toString(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

