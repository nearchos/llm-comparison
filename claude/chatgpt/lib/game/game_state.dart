/// The three distinct phases of the Flappy Bird game loop.
enum GameState {
  /// Start screen — bird hovers and waits for the first tap.
  idle,

  /// Active gameplay — physics, pipes, scrolling, and scoring are running.
  playing,

  /// The bird has collided — score panel is shown, awaiting restart.
  gameOver,
}
