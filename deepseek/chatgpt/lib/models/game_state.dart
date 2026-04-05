class GameState {
  int _score = 0;
  int _highScore = 0;
  bool _isPlaying = false;
  bool _isGameOver = false;
  
  int get score => _score;
  int get highScore => _highScore;
  bool get isPlaying => _isPlaying;
  bool get isGameOver => _isGameOver;
  
  void startGame() {
    _isPlaying = true;
    _isGameOver = false;
    _score = 0;
  }
  
  void endGame() {
    _isPlaying = false;
    _isGameOver = true;
    
    if (_score > _highScore) {
      _highScore = _score;
    }
  }
  
  void reset() {
    _score = 0;
    _isPlaying = false;
    _isGameOver = false;
  }
  
  void incrementScore() {
    _score++;
  }
}