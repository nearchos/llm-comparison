class Bird {
  double x = 0.3;
  double y = 0.5;

  double velocity = 0;

  static const gravity = 1.6;
  static const flapStrength = -0.5;
  static const size = 0.05;

  void reset() {
    y = 0.5;
    velocity = 0;
  }

  void flap() {
    velocity = flapStrength;
  }

  void update(double dt) {
    velocity += gravity * dt;
    y += velocity;
  }
}

