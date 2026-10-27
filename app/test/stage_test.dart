import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/stage/moon.dart';
import 'package:whowolf/src/stage/scene.dart';

void main() {
  PlayerView view(Phase phase, {Faction? winner}) => PlayerView(
    you: const PlayerId('p1'),
    phase: phase,
    round: 1,
    seats: const [SeatView(id: PlayerId('p1'), name: 'Ada', isAlive: true)],
    deaths: const [],
    waitingFor: 0,
    winner: winner,
  );

  test('the scene follows the phase only, never a role', () {
    expect(sceneFor(null), Scene.village);
    expect(sceneFor(view(Phase.lobby)), Scene.village);
    expect(sceneFor(view(Phase.roleReveal)), Scene.theatre);
    expect(sceneFor(view(Phase.night)), Scene.nightLake);
    expect(sceneFor(view(Phase.vote)), Scene.dusk);
    expect(sceneFor(view(Phase.hunterShot)), Scene.hunt);
    expect(
      sceneFor(view(Phase.ended, winner: Faction.werewolves)),
      Scene.finaleWolves,
    );
  });

  test('the night ring runs evenly from the phase start, the same for all', () {
    double at(int now) => nightRing(
      nowMs: now,
      phaseStartedAtMs: 1000,
      nightLength: const Duration(seconds: 90),
    );
    expect(at(1000), 0);
    expect(at(46000), closeTo(0.5, 0.001));
    expect(at(999999), 1);
    expect(
      nightRing(
        nowMs: 5000,
        phaseStartedAtMs: null,
        nightLength: const Duration(seconds: 90),
      ),
      0,
    );
  });

  test('every stage set and wing named exists in the assets', () {
    for (final scene in Scene.values) {
      final files = [
        ?plateOf(scene),
        if (wingsOf(scene) case (final l, final r)) ...[l, r],
      ];
      for (final file in files) {
        expect(File(file).existsSync(), isTrue, reason: '$scene: $file');
      }
    }
  });

  test('every figure has three villager poses, picked from public values', () {
    for (final persona in Persona.values) {
      expect(poseCount(persona), 3, reason: '$persona');
      for (var pose = 0; pose <= 3; pose++) {
        final (asset, _) = posed(persona, pose);
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
      expect(poseFor(persona, '2/day/p3'), poseFor(persona, '2/day/p3'));
    }
  });
}
