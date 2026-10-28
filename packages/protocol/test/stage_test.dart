import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test("the narrator's stage travels; without it the voice walks as it "
      'did, and an unknown one is refused', () {
    for (final stage in NarratorStage.values) {
      final settings = GameSettings(narratorStage: stage);
      final back = ClientMessage.parse(SettingsIntent(settings).encode());
      expect((back as SettingsIntent).settings, settings);
    }
    SettingsIntent parse(Map<String, Object?> settings) =>
        ClientMessage.parse(
              jsonEncode({
                'v': protocolVersion,
                'type': 'settings',
                'settings': settings,
              }),
            )
            as SettingsIntent;
    final old = encodeSettings(const GameSettings())..remove('stage');
    expect(parse(old).settings.narratorStage, NarratorStage.lively);
    expect(
      () => parse({...encodeSettings(const GameSettings()), 'stage': 'opera'}),
      throwsA(isA<ProtocolError>()),
    );
  });
}
