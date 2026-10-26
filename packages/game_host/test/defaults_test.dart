import 'dart:math';

import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:test/test.dart';

void main() {
  test('a new room plays werewolf as everyone knows it', () async {
    final host = GameHost(roomCode: '1234', random: Random(1));
    addTearDown(host.close);
    expect(host.state.settings.preset, Preset.classic);
    expect(host.state.settings.nightMode, NightMode.called);
    expect(host.state.settings.sheepInPlay, isFalse);
    expect(host.state.settings.narratorVoice, isTrue);
  });
}
