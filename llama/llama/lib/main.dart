import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Bird Clone',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  double _birdY = 0;
  double _birdVelocity = 0;
  double _gravity = 0.5;
  List<double> _pipeX = [];
  List<double> _pipeGap = [];
  int _score = 0;
  bool _gameOver = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _birdY = 0;
    _birdVelocity = 0;
    _pipeX = [300, 600, 900];
    _pipeGap = [100, 200, 300];
    _score = 0;
    _gameOver = false;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_gameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        _updateGame();
      });
    });
  }

  void _updateGame() {
    _birdVelocity += _gravity;
    _birdY += _birdVelocity;

    for (int i = 0; i < _pipeX.length; i++) {
      _pipeX[i] -= 2;
      if (_pipeX[i] < -50) {
        _pipeX[i] = 300;
        _pipeGap[i] = Random().nextInt(200) + 100;
      }
      if (_pipeX[i] < 50 && _pipeX[i] > -50) {
        if (_birdY < _pipeGap[i] || _birdY > _pipeGap[i] + 100) {
          _gameOver = true;
        }
      }
      if (_pipeX[i] == 0) {
        _score++;
      }
    }

    if (_birdY > 1 || _birdY < -1) {
      _gameOver = true;
    }
  }

  void _flap() {
    _birdVelocity = -8;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _flap,
        child: Container(
          color: Colors.blue[200],
          child: Stack(
            children: [
              Positioned(
                top: _birdY * 200 + 200,
                left: 50,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              for (int i = 0; i < _pipeX.length; i++)
                Positioned(
                  top: 0,
                  left: _pipeX[i],
                  child: Container(
                    width: 50,
                    height: _pipeGap[i],
                    color: Colors.green,
                  ),
                ),
              for (int i = 0; i < _pipeX.length; i++)
                Positioned(
                  top: _pipeGap[i] + 100,
                  left: _pipeX[i],
                  child: Container(
                    width: 50,
                    height: 500,
                    color: Colors.green,
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  color: Colors.green[700],
                ),
              ),
              Positioned(
                top: 50,
                right: 50,
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              if (_gameOver)
                Center(
                  child: Text(
                    'Game Over!',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}