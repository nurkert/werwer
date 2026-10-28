import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// Plain-language help for the usual network traps (iOS permission, desktop
/// firewall, guest Wi-Fi with client isolation), this device's first.
Future<void> showNetworkHelp(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final mine = [
    if (Platform.isIOS) l10n.helpIos,
    if (Platform.isAndroid) l10n.helpAndroid,
    if (Platform.isMacOS) l10n.helpMac,
    if (Platform.isWindows) l10n.helpWindows,
  ];
  final tips = [
    l10n.helpSameWifi,
    ...mine,
    l10n.helpGuest,
    for (final t in [l10n.helpIos, l10n.helpMac, l10n.helpWindows])
      if (!mine.contains(t)) t,
    l10n.helpVpn,
    l10n.helpQr,
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Headline(l10n.helpTitle)),
            const SizedBox(height: 12),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Palette.lantern400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: Palette.moon100,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A small text button that opens [showNetworkHelp].
class HelpLink extends StatelessWidget {
  const HelpLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => showNetworkHelp(context),
    icon: const Icon(Icons.help_outline, size: 18),
    label: Text(AppLocalizations.of(context).helpLink),
    style: TextButton.styleFrom(foregroundColor: Palette.moon200),
  );
}

/// The game in eight steps, as the rules on paper (task 012): every step
/// a little scene of the village's figures doing what it says, so a first
/// timer understands a round from the pictures alone. On the start
/// screen's left page (it scrolls) and in [showHowItWorks].
class HowSteps extends StatelessWidget {
  const HowSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String pose(String name) => 'assets/figures/poses/$name.webp';
    String role(Persona p, Role r) => personaRoleAsset(p, r);
    const wolf = 'assets/figures/werwolf.webp';
    final steps = <(String, String, String, _Tableau)>[
      (
        l10n.howPhaseSetup,
        l10n.how1Title,
        l10n.how1Text,
        _Tableau('village', const Alignment(0, 0.3), [
          _Actor(pose('buergermeister_3'), 0.3, 0.86, cue: _Cue.qr),
          _Actor(
            pose('dorfbewohner_3'),
            0.6,
            0.8,
            mirror: true,
            cue: _Cue.phone,
          ),
          _Actor(
            pose('gaensehirtin_2'),
            0.84,
            0.8,
            mirror: true,
            cue: _Cue.phone,
          ),
        ]),
      ),
      (
        l10n.howPhaseSetup,
        l10n.how2Title,
        l10n.how2Text,
        _Tableau('theatre', const Alignment(0, 0.6), [
          _Actor(personaAsset(Persona.maid), 0.23, 0.78, cue: _Cue.secret),
          _Actor(
            personaAsset(Persona.baker),
            0.5,
            0.82,
            cue: _Cue.figure,
            cueAsset: wolf,
          ),
          _Actor(
            personaAsset(Persona.smith),
            0.8,
            0.84,
            mirror: true,
            cue: _Cue.secret,
          ),
        ]),
      ),
      (
        l10n.howPhaseNight,
        l10n.how3Title,
        l10n.how3Text,
        _Tableau('nightlake', const Alignment(0, 0.2), night: true, [
          _Actor(
            personaAsset(Persona.spinner),
            0.19,
            0.74,
            asleep: true,
            cue: _Cue.sleep,
          ),
          _Actor(
            role(Persona.miller, Role.werewolf),
            0.42,
            0.86,
            cue: _Cue.paw,
          ),
          _Actor(
            role(Persona.innkeeper, Role.werewolf),
            0.64,
            0.82,
            mirror: true,
            cue: _Cue.paw,
          ),
          _Actor(
            personaAsset(Persona.grandfather),
            0.88,
            0.76,
            asleep: true,
            mirror: true,
            cue: _Cue.sleep,
          ),
        ]),
      ),
      (
        l10n.howPhaseNight,
        l10n.how4Title,
        l10n.how4Text,
        _Tableau('nightlake', const Alignment(0, 0.2), night: true, [
          _Actor(
            role(Persona.fisher, Role.seer),
            0.2,
            0.86,
            cue: _Cue.figure,
            cueAsset: wolf,
          ),
          _Actor(
            personaAsset(Persona.smith),
            0.5,
            0.8,
            asleep: true,
            cue: _Cue.sleep,
          ),
          _Actor(
            role(Persona.grandmother, Role.witch),
            0.8,
            0.82,
            mirror: true,
            cue: _Cue.potion,
          ),
        ]),
      ),
      (
        l10n.howPhaseMorning,
        l10n.how5Title,
        l10n.how5Text,
        _Tableau('morning', const Alignment(0, 0.6), [
          _Actor(pose('grossmutter_3'), 0.2, 0.8, cue: _Cue.alarm),
          _Actor(personaAsset(Persona.spinner), 0.5, 0.8, ghost: true),
          _Actor(pose('magd_3'), 0.8, 0.8, mirror: true, cue: _Cue.alarm),
        ]),
      ),
      (
        l10n.howPhaseDay,
        l10n.how6Title,
        l10n.how6Text,
        _Tableau('dusk', const Alignment(0, 0.6), [
          _Actor(pose('buergermeister_3'), 0.2, 0.86, cue: _Cue.accuse),
          _Actor(
            pose('spielmann_3'),
            0.5,
            0.84,
            mirror: true,
            cue: _Cue.innocent,
          ),
          _Actor(pose('wirtin_2'), 0.8, 0.82, mirror: true, cue: _Cue.doubt),
        ]),
      ),
      (
        l10n.howPhaseDay,
        l10n.how7Title,
        l10n.how7Text,
        _Tableau('finale', const Alignment(0, 0.6), [
          _Actor(pose('schmied_2'), 0.19, 0.8, cue: _Cue.vote),
          _Actor(pose('spielmann_2'), 0.42, 0.78, cue: _Cue.votes),
          _Actor(pose('fischerin_3'), 0.66, 0.8, mirror: true, cue: _Cue.vote),
          _Actor(
            pose('dorfbewohner_1'),
            0.88,
            0.82,
            mirror: true,
            cue: _Cue.vote,
          ),
        ]),
      ),
      (
        l10n.howPhaseEnd,
        l10n.how8Title,
        l10n.how8Text,
        _Tableau('village', const Alignment(0, 0.3), [
          _Actor(pose('spielmann_1'), 0.21, 0.82, cue: _Cue.win),
          _Actor(pose('wirtin_1'), 0.44, 0.8, cue: _Cue.win),
          _Actor(pose('blumenmaedchen_2'), 0.66, 0.8, mirror: true),
          const _Actor(wolf, 0.88, 0.7, ghost: true, mirror: true),
        ]),
      ),
    ];
    return Panel(
      paper: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (phase, title, text, tableau)) in steps.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Palette.gold500.withValues(alpha: 0.5),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.nightlight_round,
                        size: 14,
                        color: Palette.gold500,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Palette.gold500.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            _ActPicture(tableau: tableau, number: i + 1),
            const SizedBox(height: 12),
            Text(
              phase.toUpperCase(),
              style: const TextStyle(
                fontFamily: displayFont,
                fontSize: 12.5,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: Palette.curtain600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontFamily: displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.15,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.45,
                color: Palette.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What a figure in a step's scene thinks or holds, in a paper bubble
/// above its head.
enum _Cue {
  /// Shows the room's code.
  qr,

  /// Scans it with the phone.
  phone,

  /// A role nobody else may see.
  secret,

  /// A small figure: the role it sees (its own, or the seer's look).
  figure,

  /// Eyes closed.
  sleep,

  /// A werewolf choosing.
  paw,

  /// The witch's potions.
  potion,

  /// Shocked at the morning's news.
  alarm,

  /// Points at someone.
  accuse,

  /// Plays innocent.
  innocent,

  /// Not convinced.
  doubt,

  /// Votes on the phone.
  vote,

  /// Gets the most votes.
  votes,

  /// Cheers.
  win,
}

/// One figure in a step's scene: where it stands (its centre, as a part of
/// the width), how tall (as a part of the height), and what it does.
class _Actor {
  const _Actor(
    this.asset,
    this.x,
    this.height, {
    this.mirror = false,
    this.asleep = false,
    this.ghost = false,
    this.cue,
    this.cueAsset,
  });

  final String asset;
  final double x;
  final double height;
  final bool mirror;

  /// Dimmed in the dark: eyes closed while others act.
  final bool asleep;

  /// Out of the game: pale and see-through.
  final bool ghost;
  final _Cue? cue;
  final String? cueAsset;
}

/// A step's scene: a corner of a stage set and its figures.
class _Tableau {
  const _Tableau(this.scene, this.focus, this.actors, {this.night = false});

  final String scene;
  final Alignment focus;
  final List<_Actor> actors;

  /// Deep night: the set darkens, the sleepers with it.
  final bool night;
}

/// A step's picture: its scene framed in brass, with the step's number.
class _ActPicture extends StatelessWidget {
  const _ActPicture({required this.tableau, required this.number});

  final _Tableau tableau;
  final int number;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.stageBrass, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final h = box.maxHeight;
              final bubble = h * 0.2;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/stage/${tableau.scene}.webp',
                    fit: BoxFit.cover,
                    alignment: tableau.focus,
                    cacheWidth: (w * 2).round(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: tableau.night
                            ? const [Color(0x88050A18), Color(0xAA050A18)]
                            : const [Color(0x00000000), Color(0x66000000)],
                        stops: tableau.night ? null : const [0.5, 1],
                      ),
                    ),
                  ),
                  for (final a in tableau.actors) ...[
                    Positioned(
                      left: a.x * w - h * a.height * 0.45,
                      width: h * a.height * 0.9,
                      bottom: h * 0.03,
                      height: h * a.height,
                      child: _Figure(actor: a, night: tableau.night),
                    ),
                    if (a.cue != null)
                      Positioned(
                        left: a.x * w - bubble / 2 + bubble * 0.3,
                        bottom: h * 0.03 + h * a.height * 0.86,
                        width: bubble,
                        height: bubble,
                        child: _Bubble(cue: a.cue!, asset: a.cueAsset),
                      ),
                  ],
                  Positioned(
                    left: 10,
                    top: 8,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Palette.paper,
                        border: Border.all(
                          color: Palette.stageBrass,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          fontFamily: displayFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1,
                          color: Palette.curtain600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

/// A figure of a step's scene, dimmed when asleep, pale when out.
class _Figure extends StatelessWidget {
  const _Figure({required this.actor, required this.night});

  final _Actor actor;
  final bool night;

  @override
  Widget build(BuildContext context) {
    Widget figure = Image.asset(
      actor.asset,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
    if (actor.mirror) {
      figure = Transform.flip(flipX: true, child: figure);
    }
    if (actor.ghost) {
      return Opacity(
        opacity: 0.42,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.3, 0.5, 0.2, 0, 30, //
            0.3, 0.5, 0.2, 0, 40,
            0.3, 0.5, 0.2, 0, 70,
            0, 0, 0, 1, 0,
          ]),
          child: figure,
        ),
      );
    }
    if (actor.asleep || night) {
      // Who acts at night stands in moonlight; the sleepers in the dark.
      final dim = actor.asleep ? 0.45 : 0.85;
      figure = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          dim, 0, 0, 0, 0, //
          0, dim, 0, 0, 0,
          0, 0, dim * 1.15, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: figure,
      );
    }
    return figure;
  }
}

/// A paper bubble with what a figure thinks or holds.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.cue, this.asset});

  final _Cue cue;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(1);
    Widget icon(IconData i, [Color c = Palette.ink]) =>
        FittedBox(child: Icon(i, color: c));
    Widget glyph(String t, [Color c = Palette.ink]) => FittedBox(
      child: Text(
        t,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: displayFont,
          fontWeight: FontWeight.w700,
          fontSize: 40 / size,
          height: 1,
          color: c,
        ),
      ),
    );
    final content = switch (cue) {
      _Cue.qr => icon(Icons.qr_code_2_rounded),
      _Cue.phone => icon(Icons.smartphone_rounded),
      _Cue.secret => glyph('?', Palette.curtain600),
      _Cue.figure => Image.asset(asset!, fit: BoxFit.contain),
      _Cue.sleep => glyph('z z', Palette.night500),
      _Cue.paw => icon(Icons.pets_rounded, Palette.curtain600),
      _Cue.potion => icon(Icons.science_rounded, Palette.forest700),
      _Cue.alarm => glyph('!', Palette.curtain600),
      _Cue.accuse => glyph('!', Palette.curtain600),
      _Cue.innocent => icon(Icons.favorite_rounded, Palette.curtain600),
      _Cue.doubt => glyph('?'),
      _Cue.vote => icon(Icons.how_to_vote_rounded),
      _Cue.votes => glyph('3', Palette.curtain600),
      _Cue.win => icon(Icons.celebration_rounded, Palette.gold500),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Palette.paper,
        border: Border.all(color: Palette.stageBrass, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cue == _Cue.figure ? 3 : 7),
        child: ClipOval(child: Center(child: content)),
      ),
    );
  }
}

/// [HowSteps] in a sheet, for whoever plays for the first time.
Future<void> showHowItWorks(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          children: [
            Headline(l10n.howTitle, eyebrow: l10n.howEyebrow),
            const SizedBox(height: 16),
            const HowSteps(),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.howDone,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
