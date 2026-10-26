import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/figures.dart';

void main() {
  test('every persona has a figure in every role', () {
    final missing = [
      for (final persona in Persona.values)
        for (final role in Role.values)
          if (!File(personaRoleAsset(persona, role)).existsSync())
            personaRoleAsset(persona, role),
    ];
    expect(missing, isEmpty);
  });

  test('every role has its own figure for the rules and settings', () {
    for (final role in Role.values) {
      expect(File(figureAsset(role)).existsSync(), isTrue, reason: '$role');
    }
  });
}
