import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AvoidObstaclesApp());
}

class AvoidObstaclesApp extends StatelessWidget {
  const AvoidObstaclesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evita Obstáculos',
      theme: ThemeData.dark(),
      home: const GamePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class Obstacle {
  double x; // 0.0 .. 1.0 (ratio of screen width)
  double y; // 0.0 .. 1.0 (ratio of screen height)
  double size; // ratio of shorter side
  Obstacle({required this.x, required this.y, required this.size});
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final Random _rand = Random();
  Timer? _gameTimer;
  bool _running = false;
  double _playerX = 0.5; // player center position in ratio (0..1)
  double _playerWidthRatio = 0.16;
  double _playerHeightRatio = 0.04;
  List<Obstacle> _obstacles = [];
  Duration _tick = const Duration(milliseconds: 16); // ~60 FPS
  double _obstacleSpeed = 0.35; // ratio per second
  double _spawnIntervalSeconds = 0.9;
  double _timeSinceLastSpawn = 0;
  double _elapsed = 0; // seconds survived (score)
  int _score = 0;
  double _screenWidth = 1;
  double _screenHeight = 1;
  late double _aspectShorter;
  bool _gameOver = false;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    _obstacles.clear();
    _playerX = 0.5;
    _obstacleSpeed = 0.35;
    _spawnIntervalSeconds = 0.9;
    _timeSinceLastSpawn = 0;
    _elapsed = 0;
    _score = 0;
    _gameOver = false;
    _running = true;
    _startTimer();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_tick, _update);
  }

  void _stopTimer() {
    _gameTimer?.cancel();
  }

  void _endGame() {
    _running = false;
    _gameOver = true;
    _stopTimer();
    if (_score > _bestScore) _bestScore = _score;
    setState(() {});
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _spawnObstacle() {
    // spawn at random horizontal position, size variation
    double size = 0.06 + _rand.nextDouble() * 0.12; // ratio relative to shorter side
    double x = (size / 2) + _rand.nextDouble() * (1 - size);
    _obstacles.add(Obstacle(x: x, y: -size, size: size));
  }

  void _update(Timer timer) {
    final double dt = _tick.inMilliseconds / 1000.0;
    if (!_running) return;

    _elapsed += dt;
    _timeSinceLastSpawn += dt;

    // Increase difficulty gradually
    if (_elapsed > 10 && _spawnIntervalSeconds > 0.5) {
      _spawnIntervalSeconds = 0.9 - (_elapsed - 10) * 0.02;
      if (_spawnIntervalSeconds < 0.4) _spawnIntervalSeconds = 0.4;
    }
    if (_elapsed > 5) _obstacleSpeed = 0.35 + (_elapsed - 5) * 0.02;

    if (_timeSinceLastSpawn >= _spawnIntervalSeconds) {
      _timeSinceLastSpawn = 0;
      _spawnObstacle();
    }

    // Move obstacles
    for (var o in _obstacles) {
      o.y += _obstacleSpeed * dt; // y is ratio of screen height
    }

    // Remove off-screen obstacles and increment score
    _obstacles.removeWhere((o) {
      if (o.y - o.size > 1.2) {
        _score += 1;
        return true;
      }
      return false;
    });

    // Collision detection
    // Convert player rect and obstacle rect to same coordinate system (0..1)
    final double playerHalfW = _playerWidthRatio / 2;
    final double playerHalfH = _playerHeightRatio / 2;
    final Rect playerRect = Rect.fromLTWH(
      _playerX - playerHalfW,
      1.0 - 0.06 - playerHalfH, // player vertical position at bottom (y ratio)
      _playerWidthRatio,
      _playerHeightRatio,
    );

    for (var o in _obstacles) {
      final Rect obsRect = Rect.fromLTWH(
        o.x - o.size / 2,
        o.y,
        o.size,
        o.size,
      );
      if (_rectsOverlap(playerRect, obsRect)) {
        _endGame();
        break;
      }
    }

    // Request redraw
    setState(() {});
  }

  bool _rectsOverlap(Rect a, Rect b) {
    return a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
  }

  // Handle horizontal drag to move the player
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_running) return;
    // map local delta to ratio
    final dx = details.primaryDelta ?? 0;
    final ratioDx = dx / _screenWidth;
    _playerX += ratioDx;
    if (_playerX < _playerWidthRatio / 2) _playerX = _playerWidthRatio / 2;
    if (_playerX > 1 - _playerWidthRatio / 2) _playerX = 1 - _playerWidthRatio / 2;
    setState(() {});
  }

  // alternative: tap left/right buttons
  void _movePlayerBy(double deltaRatio) {
    if (!_running) return;
    _playerX += deltaRatio;
    if (_playerX < _playerWidthRatio / 2) _playerX = _playerWidthRatio / 2;
    if (_playerX > 1 - _playerWidthRatio / 2) _playerX = 1 - _playerWidthRatio / 2;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // capture real screen size and compute aspect
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _aspectShorter = min(_screenWidth, _screenHeight);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evita Obstáculos'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('Puntaje: $_score  •  Mejor: $_bestScore')),
          )
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _onDragUpdate,
        onTapDown: (details) {
          // quick tap: small nudge to where tapped
          if (!_running) return;
          final local = details.localPosition;
          final tappedRatio = local.dx / _screenWidth;
          // move a bit toward tap
          final delta = tappedRatio - _playerX;
          _playerX += delta.sign * 0.06;
          if (_playerX < _playerWidthRatio / 2) _playerX = _playerWidthRatio / 2;
          if (_playerX > 1 - _playerWidthRatio / 2) _playerX = 1 - _playerWidthRatio / 2;
          setState(() {});
        },
        child: Stack(
          children: [
            // Game canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _GamePainter(
                  playerX: _playerX,
                  playerWidthRatio: _playerWidthRatio,
                  playerHeightRatio: _playerHeightRatio,
                  obstacles: _obstacles,
                ),
              ),
            ),

            // HUD: center top score/time
            Positioned(
              top: 14,
              left: 8,
              right: 8,
              child: Center(
                child: Text(
                  _running ? 'Tiempo: ${_elapsed.toStringAsFixed(1)} s' : (_gameOver ? 'Game Over' : 'Pausa'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Controls: left / right buttons
            Positioned(
              bottom: 18,
              left: 18,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _movePlayerBy(-0.08),
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(14)),
                    child: const Icon(Icons.arrow_left),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _movePlayerBy(0.08),
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(14)),
                    child: const Icon(Icons.arrow_right),
                  ),
                ],
              ),
            ),

            // Center overlay when game over or paused
            if (_gameOver || !_running)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_gameOver) ...[
                          const Text('¡PERDISTE!', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Puntaje: $_score', style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 8),
                        ],
                        ElevatedButton(
                          onPressed: () {
                            _resetGame();
                            setState(() {});
                          },
                          child: Text(_gameOver ? 'Reintentar' : 'Continuar'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // pause/resume if not game over
                            if (!_gameOver) {
                              _running = !_running;
                              if (_running) _startTimer(); else _stopTimer();
                              setState(() {});
                            }
                          },
                          child: Text(_gameOver ? 'Volver al juego' : (_running ? 'Pausar' : 'Reanudar')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final double playerX;
  final double playerWidthRatio;
  final double playerHeightRatio;
  final List<Obstacle> obstacles;

  _GamePainter({
    required this.playerX,
    required this.playerWidthRatio,
    required this.playerHeightRatio,
    required this.obstacles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final w = size.width;
    final h = size.height;

    // draw background (simple)
    paint.color = Colors.black;
    canvas.drawRect(Offset.zero & size, paint);

    // draw player
    paint.color = Colors.blueAccent;
    final playerW = playerWidthRatio * w;
    final playerH = playerHeightRatio * h;
    final playerCenterX = playerX * w;
    final playerTop = h - (h * 0.06) - playerH / 2; // slightly above bottom
    final playerRect = Rect.fromCenter(center: Offset(playerCenterX, playerTop + playerH / 2), width: playerW, height: playerH);
    canvas.drawRRect(RRect.fromRectAndRadius(playerRect, const Radius.circular(6)), paint);

    // draw obstacles
    paint.color = Colors.redAccent;
    for (var o in obstacles) {
      final obsSizePx = o.size * min(w, h);
      final centerX = o.x * w;
      final top = o.y * h;
      final rect = Rect.fromCenter(center: Offset(centerX, top + obsSizePx / 2), width: obsSizePx, height: obsSizePx);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
    }

    // ground line
    paint.color = Colors.grey.shade900;
    canvas.drawRect(Rect.fromLTWH(0, h - 8, w, 8), paint);
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}
