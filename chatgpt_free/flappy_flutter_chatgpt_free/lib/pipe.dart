class Pipe {
  static const width = 0.15;
  static const gapHeight = 0.25;
  static const speed = 0.5;

  double x = 1.2;
  final double gapY;
  bool passed = false;

  Pipe(this.gapY);

  void update(double dt) {
    x -= speed * dt;
  }
}

