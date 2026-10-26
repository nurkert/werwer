import 'package:game_host/game_host.dart';

/// Joining from a browser page: only on the web.
Future<Connection> dialPageHost() =>
    Future.error(UnsupportedError('only in the browser'));

/// Removes the join link (with the room's key) from the address bar.
void forgetPageLink() {}

/// Keeps the way back into this game for this browser tab (see the web
/// version).
void rememberGame(String link, {String? token, String? name}) {}

/// The way back into this tab's game, if any.
({String link, String? token, String? name})? recallGame() => null;

/// Forgets this tab's game.
void forgetGame() {}
