class Ground {
  double x = 0;
  double y = 0;
  double height = 80;
  double width = 0;
  
  static const double speed = 100; // pixels per second
  
  void update(double deltaTime) {
    x -= speed * deltaTime;
    
    // Reset ground position for infinite scrolling effect
    if (x <= -width) {
      x = 0;
    }
  }
  
  void setScreenSize(double screenWidth) {
    width = screenWidth;
  }
  
  Rect getCollisionRect() {
    return Rect.fromLTWH(0, y, width, height);
  }
}