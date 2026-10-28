import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// Quiet mode at the table (task 023 F1): no notifications from other apps
/// while the game runs, so no phone distracts or gives anything away.
/// Android switches "do not disturb" itself, once the player allowed it;
/// elsewhere apps may not, so the card explains how. Only this device, only
/// by choice, and back to how it was when the game ends.
abstract final class QuietMode {
  static const _channel = MethodChannel('whowolf/quiet');

  /// Whether this device can switch it itself.
  static bool get switches => !kIsWeb && Platform.isAndroid;

  /// Whether it is on for this game.
  static final on = ValueNotifier<bool>(false);

  static Future<bool> _call(String method, [Object? argument]) async {
    try {
      return await _channel.invokeMethod<bool>(method, argument) ?? false;
    } on Object {
      return false;
    }
  }

  /// Switches it on, or says it needs the player's permission first
  /// (and opens that setting): `false` then.
  static Future<bool> start() async {
    if (!await _call('allowed')) {
      await _call('ask');
      return false;
    }
    return on.value = await _call('set', true);
  }

  /// Back to how it was.
  static Future<void> stop() async {
    if (!on.value) return;
    on.value = false;
    await _call('set', false);
  }
}

/// The lobby's card for quiet mode.
class QuietModeCard extends StatelessWidget {
  const QuietModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.do_not_disturb_on_outlined,
                color: Palette.stageLanternTop,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.quietTitle,
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Palette.stageIvory,
                  ),
                ),
              ),
              if (QuietMode.switches)
                ValueListenableBuilder(
                  valueListenable: QuietMode.on,
                  builder: (context, on, _) => Switch(
                    value: on,
                    onChanged: (want) async {
                      if (!want) return QuietMode.stop();
                      if (!await QuietMode.start() && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.quietAllow)),
                        );
                      }
                    },
                  ),
                )
              else
                TextButton(
                  onPressed: () => _how(context),
                  child: Text(l10n.quietHow),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Body(l10n.quietText, muted: true),
        ],
      ),
    );
  }

  Future<void> _how(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final steps = [
      if (!kIsWeb && Platform.isIOS) ...[
        l10n.quietIos1,
        l10n.quietIos2,
        l10n.quietIos3,
      ] else if (apple)
        l10n.quietMac
      else
        l10n.quietOther,
    ];
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Headline(l10n.quietTitle, size: 26),
              const SizedBox(height: 12),
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Body(steps.length > 1 ? '${i + 1}. $step' : step),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
