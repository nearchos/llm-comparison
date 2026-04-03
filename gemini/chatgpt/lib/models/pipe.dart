class Pipe {
  double x;
  final double width;
  final double topHeight;
  final double gap;
  bool passed = false;

  Pipe({
    required this.x,
    required this.width,
    required this.topHeight,
    required this.gap,
  });

  double get bottomY => topHeight + gap;

  void update(double dt, double speed) {
    x -= speed * dt;
  }
}