import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Game Settings
  static double birdYaxis = 0;
  double time = 0;
  double height = 0;
  double initialHeight = birdYaxis;
  bool gameHasStarted = false;
  int score = 0;
  int highScore = 0;

  // Physics
  double velocity = 2.8; // Strength of the jump
  double gravity = -4.9; // Strength of gravity

  // Barriers (Pipes)
  static List<double> barrierX = [2, 2 + 1.5];
  static double barrierWidth = 0.5; // out of 2
  List<List<double>> barrierHeight = [
    // [topHeight, bottomHeight] - must add up to less than 2 to leave a gap
    [0.6, 0.4],
    [0.4, 0.6],
  ];

  late Timer _timer;

  void startGame() {
    gameHasStarted = true;
    initialHeight = birdYaxis;
    score = 0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      // 1. Update Physics (Gravity)
      // Equation: y = -1/2 * g * t^2 + v * t
      time += 0.04; // time step
      height = gravity * time * time + velocity * time;
      
      setState(() {
        birdYaxis = initialHeight - height;
      });

      // 2. Move Barriers
      setState(() {
        for (int i = 0; i < barrierX.length; i++) {
          barrierX[i] -= 0.04; // Speed of scroll
          
          // If barrier goes off screen, reset it to the right
          if (barrierX[i] < -2) {
            barrierX[i] += 3;
            // Randomize gap
            // Keeping it simple for this snippet, just toggling existing presets could work,
            // or simple random logic:
             // barrierHeight[i] = ... (Random logic could go here)
          }
        }
      });

      // 3. Check Collision
      if (birdIsDead()) {
        timer.cancel();
        _showDialog();
      }

      // 4. Update Score
      // If a barrier passes the center (0), increment score
      // We use a small range to avoid double counting or need a flag. 
      // Ideally, use a flag, but for simple clone:
      for (int i = 0; i < barrierX.length; i++) {
         if (barrierX[i] < -0.02 && barrierX[i] > -0.06) {
           score++;
         }
      }
    });
  }

  void jump() {
    setState(() {
      time = 0;
      initialHeight = birdYaxis;
    });
  }

  bool birdIsDead() {
    // Check if bird hits top or bottom
    if (birdYaxis > 1.1 || birdYaxis < -1.1) {
      return true;
    }

    // Check if bird hits barriers
    for (int i = 0; i < barrierX.length; i++) {
      if (barrierX[i] <= 0.2 &&
          barrierX[i] + barrierWidth >= -0.2 &&
          (birdYaxis <= -1 + barrierHeight[i][0] ||
           birdYaxis >= 1 - barrierHeight[i][1])) {
        return true;
      }
    }
    return false;
  }

  void resetGame() {
    Navigator.pop(context); // Dismiss dialog
    setState(() {
      birdYaxis = 0;
      gameHasStarted = false;
      time = 0;
      initialHeight = birdYaxis;
      barrierX = [2, 2 + 1.5];
      score = 0;
    });
  }

  void _showDialog() {
    if (score > highScore) {
      highScore = score;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.brown,
          title: const Text(
            "G A M E  O V E R",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Score: $score\nBest: $highScore",
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: resetGame,
              child: const Text("PLAY AGAIN", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (gameHasStarted) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Background
                  Container(color: Colors.blue[300]),
                  
                  // Bird
                  AnimatedContainer(
                    alignment: Alignment(0, birdYaxis),
                    duration: const Duration(milliseconds: 0),
                    child: const MyBird(),
                  ),
                  
                  // Barriers
                  // First barrier
                  AnimatedContainer(
                    alignment: Alignment(barrierX[0], 1.1),
                    duration: const Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: barrierHeight[0][1] * 350, // Approximation for height
                    ),
                  ),
                  AnimatedContainer(
                    alignment: Alignment(barrierX[0], -1.1),
                    duration: const Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: barrierHeight[0][0] * 350,
                    ),
                  ),
                  // Second barrier
                  AnimatedContainer(
                    alignment: Alignment(barrierX[1], 1.1),
                    duration: const Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: barrierHeight[1][1] * 350,
                    ),
                  ),
                  AnimatedContainer(
                    alignment: Alignment(barrierX[1], -1.1),
                    duration: const Duration(milliseconds: 0),
                    child: MyBarrier(
                      size: barrierHeight[1][0] * 350,
                    ),
                  ),

                  // Tap to Play Overlay
                  Container(
                    alignment: const Alignment(0, -0.3),
                    child: gameHasStarted
                        ? const SizedBox()
                        : const Text(
                            "T A P  T O  P L A Y",
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  )
                ],
              ),
            ),
            Container(
              height: 15,
              color: Colors.green, // The Ground
            ),
            Expanded(
              child: Container(
                color: Colors.brown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("SCORE", style: TextStyle(color: Colors.white, fontSize: 20)),
                        const SizedBox(height: 20),
                        Text(score.toString(), style: const TextStyle(color: Colors.white, fontSize: 35)),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("BEST", style: TextStyle(color: Colors.white, fontSize: 20)),
                        const SizedBox(height: 20),
                        Text(highScore.toString(), style: const TextStyle(color: Colors.white, fontSize: 35)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- CUSTOM WIDGETS (Defined in Code as requested) ----

class MyBird extends StatelessWidget {
  const MyBird({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: Colors.black) 
      ),
      // Adding a simple eye and wing to make it look like a bird
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            ),
          ),
           Positioned(
            right: -5,
            top: 20,
            child: Container(
              width: 20,
              height: 10,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.rectangle),
            ),
          ),
        ],
      ),
    );
  }
}

class MyBarrier extends StatelessWidget {
  final double size;

  const MyBarrier({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green,
        border: Border.all(width: 5, color: Colors.green[800]!),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}