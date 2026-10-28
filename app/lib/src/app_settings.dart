import 'dart:async';

import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/privacy_screen.dart';
import 'package:whowolf/src/stage/motion.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/theme.dart';

/// The app's own settings, laid out on the start screen's right page
/// (task 012): every choice takes effect at once, no dialog to open and
/// save. Only the server address waits until it is complete and valid.
/// The language is the flag at the top of the start screen
/// ([LanguageFlag]).
class AppSettings extends StatefulWidget {
  const AppSettings({required this.version, super.key});

  final String version;

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  static const _store = Store();
  final _server = TextEditingController();
  String _savedServer = '';
  RelayMode _mode = RelayMode.onDemand;
  bool _serveWebApp = true;
  bool _updateCheck = true;
  bool _loaded = false;

  bool get _relayOff => _mode == RelayMode.never;
  String? _error;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final server = await _store.customServer() ?? '';
    final mode = await _store.relayMode();
    final serve = await _store.serveWebApp();
    final updates = await _store.updateCheck();
    if (!mounted) return;
    setState(() {
      _updateCheck = updates;
      _server.text = _savedServer = server;
      _mode = mode;
      _serveWebApp = serve;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _setMode(RelayMode? mode) async {
    if (mode == null) return;
    setState(() => _mode = mode);
    await _store.setRelayMode(mode);
  }

  Future<void> _setServeWebApp(bool on) async {
    setState(() => _serveWebApp = on);
    await _store.setServeWebApp(on: on);
  }

  /// Stores the address once it parses (empty: the official server).
  Future<void> _saveServer() async {
    final l10n = AppLocalizations.of(context);
    final text = _server.text.trim();
    if (text.isNotEmpty && parseRelayServer(text) == null) {
      setState(() => _error = l10n.invalidServer);
      return;
    }
    await _store.setCustomServer(text);
    if (!mounted) return;
    setState(() {
      _savedServer = text;
      _error = null;
      _justSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final changed = _server.text.trim() != _savedServer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          title: l10n.settingsOnline,
          child: !_loaded
              ? const SizedBox(height: 48)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioGroup<RelayMode>(
                      groupValue: _mode,
                      onChanged: _setMode,
                      child: Column(
                        children: [
                          for (final (mode, title, hint) in [
                            (
                              RelayMode.onDemand,
                              l10n.relayOnDemand,
                              l10n.relayOnDemandHint,
                            ),
                            (
                              RelayMode.always,
                              l10n.relayAlways,
                              l10n.relayAlwaysHint,
                            ),
                            (RelayMode.never, l10n.relayOff, l10n.relayOffHint),
                          ])
                            RadioListTile<RelayMode>(
                              value: mode,
                              contentPadding: EdgeInsets.zero,
                              activeColor: Palette.lantern400,
                              title: Text(
                                title,
                                style: const TextStyle(color: Palette.moon100),
                              ),
                              subtitle: _mode == mode
                                  ? Text(
                                      hint,
                                      style: const TextStyle(
                                        color: Palette.moon200,
                                      ),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _updateCheck,
                      onChanged: (on) {
                        setState(() => _updateCheck = on);
                        unawaited(_store.setUpdateCheck(on: on));
                      },
                      activeThumbColor: Palette.lantern400,
                      title: Text(
                        l10n.updateCheck,
                        style: const TextStyle(color: Palette.moon100),
                      ),
                      subtitle: Text(
                        l10n.updateCheckHint,
                        style: const TextStyle(color: Palette.moon200),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _serveWebApp,
                      onChanged: _setServeWebApp,
                      activeThumbColor: Palette.lantern400,
                      title: Text(
                        l10n.serveWebApp,
                        style: const TextStyle(color: Palette.moon100),
                      ),
                      subtitle: Text(
                        l10n.serveWebAppHint,
                        style: const TextStyle(color: Palette.moon200),
                      ),
                    ),
                    if (!_relayOff) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: _server,
                        autocorrect: false,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {
                          _error = null;
                          _justSaved = false;
                        }),
                        onSubmitted: (_) => _saveServer(),
                        decoration: InputDecoration(
                          labelText: l10n.relayServer,
                          hintText: 'wss://relay.example.org',
                          errorText: _error,
                          helperText: _justSaved ? l10n.settingsSaved : null,
                          suffixIcon: changed
                              ? IconButton(
                                  tooltip: l10n.save,
                                  icon: const Icon(Icons.check_rounded),
                                  onPressed: _saveServer,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Body(
                        _server.text.trim().isEmpty
                            ? l10n.relayServerHelp
                            : l10n.relayCustomHint,
                        muted: true,
                      ),
                    ],
                  ],
                ),
        ),
        _Group(
          title: l10n.settingsStage,
          child: const StageMotionPicker(),
        ),
        _Group(
          title: l10n.settingsAbout,
          child: Column(
            children: [
              Stamp(l10n.devStamp(widget.version), size: 18),
              const SizedBox(height: 12),
              Body(l10n.testNote),
              const SizedBox(height: 14),
              SecondaryButton(
                label: l10n.privacyRead,
                icon: Icons.shield_outlined,
                onPressed: () => showPrivacy(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The three ways the stage may move ([StageMotion]), with their names
/// and what each costs.
List<(StageMotion, String, String)> stageMotionChoices(
  AppLocalizations l10n,
) => [
  (StageMotion.full, l10n.motionFull, l10n.motionFullHint),
  (StageMotion.calm, l10n.motionCalm, l10n.motionCalmHint),
  (StageMotion.still, l10n.motionStill, l10n.motionStillHint),
];

/// Picks how much the stage moves on this device; it changes at once
/// and is kept for the next start.
void pickStageMotion(StageMotion motion) {
  stageMotion.value = motion;
  unawaited(const Store().setStageMotion(motion));
}

/// How much the stage moves, as a choice of three with the picked one
/// explained.
class StageMotionPicker extends StatelessWidget {
  const StageMotionPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: stageMotion,
      builder: (context, picked, _) => RadioGroup<StageMotion>(
        groupValue: picked,
        onChanged: (motion) {
          if (motion != null) pickStageMotion(motion);
        },
        child: Column(
          children: [
            for (final (motion, title, hint) in stageMotionChoices(l10n))
              RadioListTile<StageMotion>(
                value: motion,
                contentPadding: EdgeInsets.zero,
                activeColor: Palette.lantern400,
                title: Text(
                  title,
                  style: const TextStyle(color: Palette.moon100),
                ),
                subtitle: picked == motion
                    ? Text(hint, style: const TextStyle(color: Palette.moon200))
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

/// One group of settings on a plaque, its name above it.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: StageBacking(child: Eyebrow(title))),
        const SizedBox(height: 8),
        Container(
          decoration: const PlaqueDecoration(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: child,
        ),
      ],
    ),
  );
}

/// The app's language as a small flag in the corner of the start screen:
/// tap it to pick German, English or the system's language.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key});

  static const _store = Store();

  void _pick(String code) {
    final picked = code.isEmpty ? null : code;
    appLanguage.value = picked == null ? null : Locale(picked);
    unawaited(_store.setLanguage(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = Localizations.localeOf(context).languageCode;
    final chosen = appLanguage.value?.languageCode ?? '';
    PopupMenuItem<String> item(String code, String label, String? flag) =>
        PopupMenuItem(
          value: code,
          child: Row(
            children: [
              if (flag == null)
                const Icon(Icons.phone_iphone_rounded, size: 22)
              else
                _Flag(flag, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              if (chosen == code)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: Palette.lantern400,
                ),
            ],
          ),
        );
    return PopupMenuButton<String>(
      tooltip: l10n.language,
      onSelected: _pick,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        item('de', 'Deutsch', 'de'),
        item('en', 'English', 'en'),
        item('', l10n.languageSystem, null),
      ],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: _Flag(shown == 'de' ? 'de' : 'en', size: 28),
      ),
    );
  }
}

/// A round flag, painted (no emoji: they look different everywhere).
class _Flag extends StatelessWidget {
  const _Flag(this.language, {required this.size});

  final String language;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Palette.lantern300, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: ClipOval(
      child: CustomPaint(painter: _FlagPainter(language)),
    ),
  );
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.language);

  final String language;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();
    if (language == 'de') {
      for (final (i, color) in const [
        Color(0xFF000000),
        Color(0xFFDD0000),
        Color(0xFFFFCE00),
      ].indexed) {
        canvas.drawRect(
          Rect.fromLTWH(0, h * i / 3, w, h / 3 + 0.5),
          paint..color = color,
        );
      }
      return;
    }
    // The Union flag, simplified to what reads at this size.
    canvas.drawRect(Offset.zero & size, paint..color = const Color(0xFF012169));
    final diagonal = Paint()..strokeWidth = h * 0.2;
    for (final (color, width) in const [
      (Color(0xFFFFFFFF), 0.2),
      (Color(0xFFC8102E), 0.08),
    ]) {
      diagonal
        ..color = color
        ..strokeWidth = h * width;
      canvas
        ..drawLine(Offset.zero, Offset(w, h), diagonal)
        ..drawLine(Offset(w, 0), Offset(0, h), diagonal);
    }
    for (final (color, width) in const [
      (Color(0xFFFFFFFF), 0.34),
      (Color(0xFFC8102E), 0.2),
    ]) {
      paint.color = color;
      canvas
        ..drawRect(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: w,
            height: h * width,
          ),
          paint,
        )
        ..drawRect(
          Rect.fromCenter(
            center: size.center(Offset.zero),
            width: h * width,
            height: h,
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.language != language;
}
