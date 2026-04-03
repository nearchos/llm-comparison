class Bird {
  double x;
  double y;
  final double width;
  final double height;
  double velocityY = 0;
  
  // Physics constants
  final double flapStrength = -450.0;
  final double gravity = 1500.0;

  Bird({
    required this.x,
    required this.y,
    this.width = 36.0,
    this.height = 26.0,
  });

  void flap() {
    velocityY = flapStrength;
  }

  void update(double dt) {
    velocityY += gravity * dt;
    y += velocityY * dt;
  }
}