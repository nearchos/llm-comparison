// ─────────────────────────────────────────────────────────────────────────────
// main.dart
// Application entry point.
//   • Locks the device to portrait orientation.
//   • Hides status / navigation bars for a full-screen experience.
//   • Mounts GameScreen as the sole route.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'immersive/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only – matches the classic Flappy Bird feel.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full-screen immersive mode: hide status bar and navigation bar.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // We render everything on a CustomPainter canvas; the Material theme
        // is effectively invisible, but we still set a neutral scaffold colour.
        scaffoldBackgroundColor: const Color(0xFF4EC0CA),
      ),
      home: const Scaffold(
        body: GameScreen(),
      ),
    );
  }
}