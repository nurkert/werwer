import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// First screen of the walking skeleton: the wordmark, what Whowolf is and
/// an honest "in development" stamp with the build version.
class StartScreen extends StatelessWidget {
  const StartScreen({required this.version, super.key});

  final String version;

  @override
  Widget build(BuildContext context) {
    final german = Localizations.localeOf(context).languageCode == 'de';
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/brand/wordmark.png',
                    semanticLabel: 'Whowolf',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    german
                        ? 'Werwolf am Tisch. Jeder mit seinem Handy.'
                        : 'Werewolf at the table. Everyone on their own phone.',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    german
                        ? 'Whowolf ist ein Konzept in Entwicklung. '
                              'Noch gibt es nichts zu spielen.'
                        : 'Whowolf is a concept in development. '
                              'There is nothing to play yet.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  _Stamp(
                    label: german
                        ? 'In Entwicklung · $version'
                        : 'In development · $version',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Palette.lantern400, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: displayFont,
              fontSize: 18,
              color: Palette.lantern400,
            ),
          ),
        ),
      ),
    );
  }
}
