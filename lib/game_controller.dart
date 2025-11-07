// lib/game_controller.dart
import 'dart:math';
import 'dart:ui';

class Obstacle {
  double x; // 0..1 horizontal center
  double y; // 0..1 vertical top (normalized)
  double size; // normalized relative to min(screenWidth, screenHeight)
  Obstacle({required this.x, required this.y, required this.size});
}

class GameController {
  final Random _rand;

  // public state
  double playerX; // center 0..1
  double playerWidthRatio;
  double playerHeightRatio;

  List<Obstacle> obstacles = [];

  double obstacleSpeed; // units: ratio per second
  double spawnIntervalSeconds;
  double timeSinceLastSpawn;
  double elapsed; // seconds survived
  int score;
  int bestScore;

  bool running;
  bool gameOver;

  // thresholds (same logic as original)
  final double _removeThreshold = 1.2;
  final double playerVerticalOffset = 0.06; // distance from bottom (ratio)

  GameController({
    Random? random,
    this.playerX = 0.5,
    this.playerWidthRatio = 0.16,
    this.playerHeightRatio = 0.04,
    this.obstacleSpeed = 0.35,
    this.spawnIntervalSeconds = 0.9,
  })  : _rand = random ?? Random(),
        timeSinceLastSpawn = 0,
        elapsed = 0,
        score = 0,
        bestScore = 0,
        running = false,
        gameOver = false;

  void reset() {
    obstacles.clear();
    playerX = 0.5;
    obstacleSpeed = 0.35;
    spawnIntervalSeconds = 0.9;
    timeSinceLastSpawn = 0;
    elapsed = 0;
    score = 0;
    gameOver = false;
    running = true;
  }

  void spawnObstacle({double? size, double? x, double? y}) {
    final double s = size ?? (0.06 + _rand.nextDouble() * 0.12);
    final double posX = x ?? ((s / 2) + _rand.nextDouble() * (1 - s));
    final double posY = y ?? -s;
    obstacles.add(Obstacle(x: posX, y: posY, size: s));
  }

  void update(double dt) {
    if (!running) return;

    elapsed += dt;
    timeSinceLastSpawn += dt;

    // difficulty increase (same tweak as original)
    if (elapsed > 10 && spawnIntervalSeconds > 0.5) {
      spawnIntervalSeconds = 0.9 - (elapsed - 10) * 0.02;
      if (spawnIntervalSeconds < 0.4) spawnIntervalSeconds = 0.4;
    }
    if (elapsed > 5) {
      obstacleSpeed = 0.35 + (elapsed - 5) * 0.02;
    }

    if (timeSinceLastSpawn >= spawnIntervalSeconds) {
      timeSinceLastSpawn = 0;
      spawnObstacle();
    }

    // move obstacles
    for (var o in obstacles) {
      o.y += obstacleSpeed * dt;
    }

    // remove off-screen and increment score
    obstacles.removeWhere((o) {
      if (o.y - o.size > _removeThreshold) {
        score += 1;
        return true;
      }
      return false;
    });

    // collision check
    if (_checkCollision()) {
      running = false;
      gameOver = true;
      if (score > bestScore) bestScore = score;
    }
  }

  bool _checkCollision() {
    final double playerHalfW = playerWidthRatio / 2;
    final double playerHalfH = playerHeightRatio / 2;
    final Rect playerRect = Rect.fromLTWH(
      playerX - playerHalfW,
      1.0 - playerVerticalOffset - playerHalfH,
      playerWidthRatio,
      playerHeightRatio,
    );

    for (final o in obstacles) {
      final Rect obsRect = Rect.fromLTWH(o.x - o.size / 2, o.y, o.size, o.size);
      if (_rectsOverlap(playerRect, obsRect)) return true;
    }
    return false;
  }

  static bool _rectsOverlap(Rect a, Rect b) {
    return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
  }

  // player control
  void movePlayerBy(double deltaRatio) {
    if (!running) return;
    playerX += deltaRatio;
    final double half = playerWidthRatio / 2;
    if (playerX < half) playerX = half;
    if (playerX > 1 - half) playerX = 1 - half;
  }

  // For tests: allow injecting an obstacle list
  void setObstacles(List<Obstacle> list) {
    obstacles = list;
  }
}
