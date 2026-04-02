import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/game_screen.dart';

/// Entry point — locks the app to portrait and hides system UI bars.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait-only orientation for correct gameplay layout.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Hide status bar and navigation bar for a proper fullscreen experience.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flappy Bird',
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}
