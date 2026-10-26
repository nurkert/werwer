import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';

/// One player at a terminal: prints what the host sends and turns typed
/// commands into intents. Works on any [Connection]; input and output are
/// injected so tests can drive it.
class CliPlayer {
  CliPlayer({
    required this.name,
    required this.room,
    required this.connection,
    required this._out,
    String? token,
    this.checkCode = const [],
  }) : _token = token {
    connection.messages.listen(
      _receive,
      onDone: () => _say('Connection closed.'),
    );
    connection.send(Hello(name: name, room: room, token: token).encode());
  }

  final String name;
  final String room;
  final Connection connection;
  final List<int> checkCode;
  final StringSink _out;
  String? _token;
  PlayerView? view;
  List<PendingJoin> pending = const [];
  bool isOwner = false;
  bool ended = false;

  String? get token => _token;

  void _say(String line) => _out.writeln(line);

  String _nameOf(PlayerId id) =>
      view?.seats.where((s) => s.id == id).map((s) => s.name).firstOrNull ??
      id.value;

  void _receive(String raw) {
    final HostMessage message;
    try {
      message = HostMessage.parse(raw);
    } on ProtocolError {
      return;
    }
    switch (message) {
      case Welcome(:final token):
        _token = token;
        _say('Joined room $room as $name.');
      case Ack() || Pong():
        break;
      case Waiting():
        _say(
          'Waiting for the host. Show them this check code: '
          '${checkCode.join('-')}',
        );
      case StateMessage():
        final before = view;
        view = message.view;
        isOwner = message.isOwner;
        if (message.pending.length != pending.length) {
          for (final p in message.pending) {
            _say(
              '${p.name} wants to join (code ${p.checkCode.join('-')}): '
              'type "admit ${p.id}" or "refuse ${p.id}".',
            );
          }
        }
        pending = message.pending;
        if (before?.phase != view!.phase ||
            before?.round != view!.round ||
            before?.seats.length != view!.seats.length) {
          _describe();
        }
      case Refused(:final reason):
        _say('Not possible: ${reason.name}');
      case Bye(:final reason):
        ended = true;
        _say('The host ended the connection: ${reason.name}');
    }
  }

  void _describe() {
    final v = view!;
    final seats = v.seats
        .map(
          (s) => [
            s.name,
            if (s.id == v.you) '(you)',
            if (s.role != null) '[${s.role!.name}]',
            if (!s.isAlive) '†',
          ].join(' '),
        )
        .join(', ');
    _say('--- ${v.phase.name} ${v.round > 0 ? v.round : ''}'.trimRight());
    _say('Table: $seats');
    switch (v.phase) {
      case Phase.lobby:
        _say(isOwner ? 'Type "start" when everyone is here.' : 'Waiting…');
      case Phase.roleReveal:
        _say('Your role: ${v.yourRole?.name}. Type "confirm".');
      case Phase.night:
        if (v.yourSeat.isAlive) {
          final action = switch (v.yourRole?.nightAbility) {
            NightAbility.hunt => 'whom the pack takes',
            NightAbility.inspect => 'whose role you see',
            _ => 'anyone (it has no effect)',
          };
          _say('Night: type "pick <name>" for $action.');
        }
      case Phase.day:
        final died = v.deaths.where(
          (d) => d.round == v.round && d.cause == DeathCause.night,
        );
        _say(
          died.isEmpty
              ? 'Nobody died tonight.'
              : '${_nameOf(died.first.player)} did not wake up.',
        );
        if (isOwner) _say('Type "vote" to start the vote.');
      case Phase.vote:
        _say('Type "vote <name>" or "vote none".');
      case Phase.ended:
        _say('Game over: ${v.winner?.name} win.');
    }
    for (final r in v.seerResults.where((r) => r.round == v.round)) {
      _say(
        'You saw: ${_nameOf(r.target)} is ${r.role?.name ?? r.faction.name}.',
      );
    }
  }

  PlayerId? _find(String who) {
    final v = view;
    if (v == null) return null;
    final lower = who.toLowerCase();
    return v.seats
        .where((s) => s.name.toLowerCase() == lower)
        .map((s) => s.id)
        .firstOrNull;
  }

  /// Handles one typed line.
  void command(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return;
    final arg = parts.skip(1).join(' ');
    ClientMessage? intent;
    switch (parts.first.toLowerCase()) {
      case 'start':
        intent = const StartGameIntent();
      case 'confirm':
        intent = const ConfirmRoleIntent();
      case 'pick':
        final id = _find(arg);
        intent = id == null ? null : NightIntent(id);
      case 'vote' when arg.isEmpty:
        intent = const EndDiscussionIntent();
      case 'vote':
        final id = arg.toLowerCase() == 'none' ? null : _find(arg);
        intent = id == null && arg.toLowerCase() != 'none'
            ? null
            : VoteIntent(id);
      case 'admit' || 'refuse':
        final id = int.tryParse(arg);
        intent = id == null
            ? null
            : AdmitIntent(id, admit: parts.first.toLowerCase() == 'admit');
      case 'again':
        intent = const RematchIntent();
      case 'table':
        if (view != null) _describe();
        return;
      default:
        _say(
          'Commands: start, confirm, pick <name>, vote, vote <name|none>, '
          'admit <id>, refuse <id>, again, table',
        );
        return;
    }
    if (intent == null) {
      _say('Unknown player "$arg".');
      return;
    }
    connection.send(intent.encode());
  }
}
