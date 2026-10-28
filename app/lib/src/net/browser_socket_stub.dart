import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';

/// Joining from a browser page: only on the web.
Future<Connection> dialPage(JoinLink link) =>
    Future.error(UnsupportedError('only in the browser'));

/// Removes the join link (with the room's key) from the address bar.
void forgetPageLink() {}

/// A game kept for this browser: how to get back in and as whom.
typedef KeptGame = ({JoinLink link, String? token, String? name});

/// Keeps the way back into [link]'s game (see the web version).
void rememberGame(JoinLink link, {String? token, String? name}) {}

/// The game kept for [link], or this tab's game.
KeptGame? recallGame([JoinLink? link]) => null;

/// Forgets [link]'s game.
void forgetGame(JoinLink link) {}
