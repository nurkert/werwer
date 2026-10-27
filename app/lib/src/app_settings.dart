import 'dart:async';

import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/privacy_screen.dart';
import 'package:whowolf/src/stage/stage_kit.dart';
import 'package:whowolf/src/theme.dart';

/// The app's own settings, laid out on the start screen's right page
/// (task 012): every choice takes effect at once, no dialog to open and
/// save. Only the server address waits until it is complete and valid.
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
  bool _relayOff = false;
  bool _loaded = false;
  String? _error;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final server = await _store.customServer() ?? '';
    final off = await _store.relayOff();
    if (!mounted) return;
    setState(() {
      _server.text = _savedServer = server;
      _relayOff = off;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  void _language(String code) {
    final picked = code.isEmpty ? null : code;
    appLanguage.value = picked == null ? null : Locale(picked);
    unawaited(_store.setLanguage(picked));
    setState(() {});
  }

  Future<void> _setRelayOff(bool off) async {
    setState(() => _relayOff = off);
    await _store.setRelayOff(off: off);
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
    final language = appLanguage.value?.languageCode ?? '';
    final changed = _server.text.trim() != _savedServer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Group(
          title: l10n.language,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: '',
                label: const Text('System'),
                tooltip: l10n.languageSystem,
              ),
              const ButtonSegment(value: 'de', label: Text('Deutsch')),
              const ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {language},
            onSelectionChanged: (v) => _language(v.first),
          ),
        ),
        _Group(
          title: l10n.settingsOnline,
          child: !_loaded
              ? const SizedBox(height: 48)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _relayOff,
                      onChanged: _setRelayOff,
                      activeThumbColor: Palette.lantern400,
                      title: Text(
                        l10n.relayOff,
                        style: const TextStyle(color: Palette.moon100),
                      ),
                      subtitle: _relayOff
                          ? Text(
                              l10n.relayOffHint,
                              style: const TextStyle(color: Palette.moon200),
                            )
                          : null,
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
        Center(child: Eyebrow(title)),
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
