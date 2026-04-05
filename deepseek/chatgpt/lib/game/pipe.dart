import 'dart:math';

class Pipe {
  double x;
  final double width = 60;
  double topHeight;
  double bottomY;
  double bottomHeight;
  bool isPassed = false;
  
  static const double gapSize = 150;
  static const double speed = 150; // pixels per second
  static const double minTopHeight = 60;
  static const double maxTopHeight = 300;
  
  Pipe(double screenWidth, double screenHeight) : x = screenWidth {
    final random = Random();
    final maxHeight = screenHeight - gapSize - 100; // Account for ground
    topHeight = minTopHeight + random.nextDouble() * (maxHeight - minTopHeight);
    bottomY = topHeight + gapSize;
    bottomHeight = screenHeight - bottomY - 80; // Leave space for ground
  }
  
  void update(double deltaTime) {
    x -= speed * deltaTime;
  }
  
  Rect getTopPipeRect() {
    return Rect.fromLTWH(x, 0, width, topHeight);
  }
  
  Rect getBottomPipeRect() {
    return Rect.fromLTWH(x, bottomY, width, bottomHeight);
  }
}