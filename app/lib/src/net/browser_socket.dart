import 'dart:convert';
import 'dart:js_interop';

import 'package:game_host/browser.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:web/web.dart' as web;

/// The browser's connection to the game, back to the origin that served this
/// page: the host's phone on the local network, or a relay server (see
/// `pageSocket`).
Future<Connection> dialPage(JoinLink link) {
  final url = pageSocket(Uri.base, link);
  if (url == null) return Future.error(StateError('no way to the host'));
  return dialBrowser(url);
}

/// A small text file from this page's own server ([path] on the same
/// origin), or `null` if it has none.
Future<String?> fetchPageText(String path) async {
  try {
    final response = await web.window.fetch(path.toJS).toDart;
    if (!response.ok) return null;
    final text = (await response.text().toDart).toDart;
    return text.length > 4096 ? null : text;
  } on Object {
    return null;
  }
}

/// Removes the join link (with the room's key) from the address bar and
/// the history, so it does not linger where others can see it. The page's
/// own path stays, so a reload still finds the page.
void forgetPageLink() {
  final history = web.window.history;
  // Keep the router's own state; only the address changes.
  history.replaceState(history.state, '', Uri.base.path);
}

/// A game kept for this browser: how to get back in and as whom.
typedef KeptGame = ({JoinLink link, String? token, String? name});

const _gamesKey = 'whowolf.games';
const _tabKey = 'whowolf.tab';

/// How long a game is kept after it was last seen.
const _keep = Duration(hours: 12);

/// Most games kept at once.
const _most = 8;

/// The key a game is kept under: the room and its host, so two rooms with
/// the same code never mix.
String _id(JoinLink link) =>
    '${link.room}.${base64Url.encode(link.hostKey ?? const [])}';

Map<String, Object?> _games() {
  try {
    final raw = web.window.localStorage.getItem(_gamesKey);
    final games = raw == null
        ? <String, Object?>{}
        : jsonDecode(raw) as Map<String, Object?>;
    final now = DateTime.now().millisecondsSinceEpoch;
    games.removeWhere(
      (_, g) => g is! Map<String, Object?> || (g['until'] as int? ?? 0) < now,
    );
    return games;
  } on Object {
    return {};
  }
}

void _save(Map<String, Object?> games) {
  try {
    web.window.localStorage.setItem(_gamesKey, jsonEncode(games));
  } on Object {
    // No storage: a reload means scanning again.
  }
}

/// Keeps the way back into [link]'s game (the link with the room's key,
/// the session token) on this device for a few hours: a phone that throws
/// away a background tab, a reload or a second scan brings the player back
/// to their seat instead of a new one. Each room has its own entry; this
/// tab remembers which one is its own.
void rememberGame(JoinLink link, {String? token, String? name}) {
  final id = _id(link);
  final games = _games()
    ..remove(id)
    ..[id] = {
      'link': link.encode(),
      'token': ?token,
      'name': ?name,
      'until': DateTime.now().add(_keep).millisecondsSinceEpoch,
    };
  while (games.length > _most) {
    games.remove(games.keys.first);
  }
  _save(games);
  try {
    web.window.sessionStorage.setItem(_tabKey, id);
  } on Object {
    // This tab will not find its way back after a reload.
  }
}

/// The game kept for [link], or without a link the one of this tab (after
/// a reload the address no longer carries the link).
KeptGame? recallGame([JoinLink? link]) {
  String? id;
  try {
    id = link == null ? web.window.sessionStorage.getItem(_tabKey) : _id(link);
  } on Object {
    return null;
  }
  final game = _games()[id];
  if (game is! Map<String, Object?>) return null;
  final kept = JoinLink.tryParse(game['link'] as String? ?? '');
  if (kept == null || (link != null && _id(kept) != id)) return null;
  return (
    link: link ?? kept,
    token: game['token'] as String?,
    name: game['name'] as String?,
  );
}

/// Forgets [link]'s game (it ended, or the player left).
void forgetGame(JoinLink link) {
  _save(_games()..remove(_id(link)));
}
