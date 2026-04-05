import 'package:flutter/material.dart';

class GameConstants {
  // --- Game Loop ---
  static const int frameRate = 60;

  // --- World ---
  static const double gravity = 800.0;
  static const double worldSpeed = 200.0;
  static const Color backgroundColor = Color(0xFF70c5ce);

  // --- Bird ---
  static const double birdInitialPositionX = 50.0;
  static const double birdSize = 34.0;
  static const double flapStrength = -350.0; // Negative because y-axis is inverted
  static const double maxFallSpeed = 400.0;
  static const Color birdColor1 = Color(0xFFfddb69);
  static const Color birdColor2 = Color(0xFFf9a029);
  
  // --- Pipes ---
  static const double pipeWidth = 80.0;
  static const double pipeGap = 180.0;
  static const double pipeSpacing = 220.0;
  static const Color pipeColor = Color(0xFF74bf2e);
  static const Color pipeBorderColor = Color(0xFF558822);
  static const double pipeBorderWidth = 4.0;

  // --- Ground ---
  static const double groundHeight = 110.0;
  static const Color groundColor1 = Color(0xFFded895);
  static const Color groundColor2 = Color(0xFFe0c85e);
}