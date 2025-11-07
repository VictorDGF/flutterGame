// test/game_controller_test.dart
import 'dart:math';
import 'package:flutter_game/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('GameController basic behavior', () {
    test('spawnObstacle adds an obstacle with negative y when not provided', () {
      final controller = GameController(random: const _FixedRandom());
      controller.reset();
      controller.spawnObstacle(size: 0.1);
      expect(controller.obstacles.length, 1);
      expect(controller.obstacles.first.y < 0, true);
    });

    test('update moves obstacles by obstacleSpeed * dt', () {
      final controller = GameController(random: const _FixedRandom());
      controller.reset();
      controller.spawnObstacle(size: 0.1, x: 0.5, y: 0.0);
      final beforeY = controller.obstacles.first.y;
      controller.update(0.5); // dt = 0.5s
      final afterY = controller.obstacles.first.y;
      // expected increment approximately obstacleSpeed * dt
      expect(afterY, closeTo(beforeY + controller.obstacleSpeed * 0.5, 1e-6));
    });

    test('obstacle removed off-screen increments score', () {
      final controller = GameController(random: const _FixedRandom());
      controller.reset();
      // put an obstacle already beyond threshold
      controller.spawnObstacle(size: 0.05, x: 0.5, y: 1.3);
      // call update; it should remove it and increment score
      controller.update(0.016);
      expect(controller.obstacles.isEmpty, true);
      expect(controller.score, greaterThanOrEqualTo(1));
    });

    test('collision detection sets gameOver', () {
      final controller = GameController(random: const _FixedRandom());
      controller.reset();
      // place obstacle exactly where player is vertically and horizontally
      final double playerHalfW = controller.playerWidthRatio / 2;
      final double playerTopY = 1.0 - controller.playerVerticalOffset - (controller.playerHeightRatio / 2);
      // place obstacle to overlap player's rect (set o.y slightly less than player's bottom)
      final double obsSize = controller.playerHeightRatio; // same height => overlap
      controller.spawnObstacle(size: obsSize, x: controller.playerX, y: playerTopY - obsSize / 2);
      controller.update(0.016);
      expect(controller.gameOver, true);
      expect(controller.running, false);
    });

    test('movePlayerBy clamps to bounds', () {
      final controller = GameController(random: const _FixedRandom());
      controller.reset();
      controller.movePlayerBy(-1.0); // try to move far left
      expect(controller.playerX, controller.playerWidthRatio / 2);
      controller.movePlayerBy(2.0); // far right
      expect(controller.playerX, 1 - controller.playerWidthRatio / 2);
    });

    test('difficulty scales spawn interval and speed over time', () {
      final controller = GameController(random: const _FixedRandom());
      controller.reset();
      final initialSpawn = controller.spawnIntervalSeconds;
      final initialSpeed = controller.obstacleSpeed;
      // simulate many updates to increase elapsed > 12s
      for (int i = 0; i < 1200; i++) {
        controller.update(0.01); // total ~12s
      }
      expect(controller.spawnIntervalSeconds <= initialSpawn, true);
      expect(controller.obstacleSpeed >= initialSpeed, true);
    });
  });
}

/// Deterministic Random: returns always 0.5 for nextDouble (makes tests predictable)
class _FixedRandom implements Random {
  const _FixedRandom();
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0.5;
  @override
  int nextInt(int max) => (max / 2).floor();
  @override
  int nextUint32() => 0;
  @override
  int nextUint64() => 0;
}
