import 'package:game_host/game_host.dart';

/// Joining from a browser page: only on the web.
Future<Connection> dialPageHost() =>
    Future.error(UnsupportedError('only in the browser'));

/// Removes the join link (with the room's key) from the address bar.
void forgetPageLink() {}
