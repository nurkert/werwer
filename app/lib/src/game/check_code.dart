import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// The 16 symbols of a check code (see `secure_channel`: 4 of 16), also
/// used for the door signs at night.
const List<IconData> checkSymbols = [
  Icons.nightlight_round,
  Icons.star_rounded,
  Icons.local_fire_department_rounded,
  Icons.eco_rounded,
  Icons.pets_rounded,
  Icons.cloud_rounded,
  Icons.favorite_rounded,
  Icons.key_rounded,
  Icons.lightbulb_rounded,
  Icons.anchor_rounded,
  Icons.music_note_rounded,
  Icons.wb_sunny_rounded,
  Icons.forest_rounded,
  Icons.diamond_rounded,
  Icons.bolt_rounded,
  Icons.water_drop_rounded,
];

/// A check code as big symbols, easy to compare across the table.
class CheckCode extends StatelessWidget {
  const CheckCode({required this.code, super.key, this.size = 44});

  final List<int> code;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final c in code)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.stagePlaque,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Palette.stageBrassLight, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                checkSymbols[c % checkSymbols.length],
                size: size,
                color: Palette.stageIvory,
              ),
            ),
          ),
        ),
    ],
  );
}
