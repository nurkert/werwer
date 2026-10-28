import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// "My role", the same button for everyone once the roles are dealt: the
/// role shows only while a finger (or the mouse) holds it, so a glance
/// from the side catches nothing. A tap only says how it works.
class RolePeek extends StatefulWidget {
  const RolePeek({required this.view, super.key});

  final PlayerView view;

  @override
  State<RolePeek> createState() => _RolePeekState();
}

class _RolePeekState extends State<RolePeek> {
  OverlayEntry? _card;

  void _show() {
    if (_card != null) return;
    final role = widget.view.yourRole;
    if (role == null) return;
    final entry = OverlayEntry(
      builder: (context) =>
          _RoleCard(role: role, persona: widget.view.yourSeat.persona),
    );
    Overlay.of(context).insert(entry);
    _card = entry;
  }

  void _hide() {
    _card?.remove();
    _card = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.rolePeek,
      child: Tooltip(
        message: l10n.rolePeekHint,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) => _show(),
          onLongPressEnd: (_) => _hide(),
          onLongPressCancel: _hide,
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.rolePeekHint))),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.badge_outlined),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.persona});

  final Role role;
  final Persona persona;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height;
    return IgnorePointer(
      child: ColoredBox(
        color: const Color(0xCC07090F),
        child: Center(
          child: Panel(
            paper: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  personaRoleAsset(persona, role),
                  height: (height * 0.36).clamp(140, 320),
                ),
                const SizedBox(height: 8),
                Headline(l10n.role(role), size: 30, color: Palette.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
