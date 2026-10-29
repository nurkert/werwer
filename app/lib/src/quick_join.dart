import 'package:flutter/material.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/store.dart';

/// Whether [resume] is a seat in [room]: same code and, where both know
/// it, the same host key.
bool holdsSeat(NearbyRoom room, ResumeInfo? resume) {
  if (resume == null || resume.room != room.room) return false;
  final key = resume.hostKey;
  final print = room.keyPrint;
  return key == null || print == null || keyPrint(key) == print;
}

/// The rooms for the start screen's quick buttons: the last one first, at
/// most two. A locked room takes nobody new, so it shows only to whoever
/// still holds a seat in it ([resume]); everyone else finds it, marked as
/// locked, in the join screen's list.
List<NearbyRoom> quickRooms(
  List<NearbyRoom> rooms, {
  String? lastRoom,
  ResumeInfo? resume,
}) {
  final shown =
      [
        for (final room in rooms)
          if (!room.locked || holdsSeat(room, resume)) room,
      ]..sort(
        (a, b) => (b.room == lastRoom ? 1 : 0) - (a.room == lastRoom ? 1 : 0),
      );
  return shown.take(2).toList();
}

/// One tap into a table nearby. Into a locked room only with the seat this
/// device still holds ([onResume]).
class QuickJoinButtons extends StatelessWidget {
  const QuickJoinButtons({
    required this.rooms,
    required this.onJoin,
    required this.onResume,
    super.key,
    this.lastRoom,
    this.resume,
  });

  final List<NearbyRoom> rooms;
  final String? lastRoom;
  final ResumeInfo? resume;
  final ValueChanged<NearbyRoom> onJoin;
  final ValueChanged<ResumeInfo> onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (final room in quickRooms(
          rooms,
          lastRoom: lastRoom,
          resume: resume,
        )) ...[
          SecondaryButton(
            label: room.hostName.isEmpty
                ? l10n.joinRoom
                : l10n.quickJoin(room.hostName),
            icon: room.locked
                ? Icons.lock_rounded
                : room.room == lastRoom
                ? Icons.history_rounded
                : Icons.wifi_rounded,
            selected: room.room == lastRoom,
            onPressed: () => switch (resume) {
              final seat? when room.locked => onResume(seat),
              _ => onJoin(room),
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
