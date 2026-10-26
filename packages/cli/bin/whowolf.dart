import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:game_host/game_host.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf_cli/whowolf_cli.dart';

const _usage = '''
Whowolf on the command line.

  whowolf host <your name>
      Opens a room on this computer and lets you play in it.

  whowolf join <your name>
      Joins with the link the host prints (encrypted and verified): paste it
      when asked, or set it in the environment as WHOWOLF_LINK. It holds the
      room's secret, so it stays out of the command line, where the process
      list and the shell history would show it.

  whowolf join <your name> <host address> <room code>
      Joins by address, e.g. 192.168.1.5 or 192.168.1.5:47470; the host has
      to let you in after comparing the check code.
''';

Future<void> main(List<String> args) async {
  if (args.length < 2 || !{'host', 'join'}.contains(args.first)) {
    stdout.write(_usage);
    exitCode = 64;
    return;
  }
  final name = args[1];
  final CliPlayer player;
  if (args.first == 'host') {
    player = await _host(name);
  } else {
    final CliPlayer? p;
    try {
      p = await _join(name, _joinArgs(args.skip(2).toList()));
    } on SecureChannelError {
      stderr.writeln(
        'That is not the host from the link (wrong key or room secret).',
      );
      exitCode = 1;
      return;
    } on Object {
      stderr.writeln(
        'Could not reach the host. Same Wi-Fi? On the host computer, allow '
        'incoming connections in the firewall.',
      );
      exitCode = 1;
      return;
    }
    if (p == null) {
      stdout.write(_usage);
      exitCode = 64;
      return;
    }
    player = p;
  }
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim() == 'quit') break;
    player.command(line);
  }
  exit(0);
}

/// The join arguments: a link from the environment or the terminal when
/// none is given, so the room secret never sits in the command line.
List<String> _joinArgs(List<String> rest) {
  if (rest.isNotEmpty) {
    if (rest.length == 1) {
      stderr.writeln(
        'Note: a link on the command line shows up in the process list and '
        'the shell history. Next time run "whowolf join <name>" and paste it.',
      );
    }
    return rest;
  }
  final fromEnv = Platform.environment['WHOWOLF_LINK'];
  if (fromEnv != null && fromEnv.trim().isNotEmpty) return [fromEnv.trim()];
  stdout.write('Join link: ');
  final line = stdin.readLineSync()?.trim() ?? '';
  return line.isEmpty ? const [] : [line];
}

Future<CliPlayer> _host(String name) async {
  final random = Random.secure();
  final code = List.generate(roomCodeLength, (_) => random.nextInt(10)).join();
  final keys = await HostKeys.generate();
  final lan = await LanTransport.bind();
  final host = GameHost(
    roomCode: code,
    random: random,
    roomSecret: keys.roomSecret,
  )..serve(SecureTransport(lan, keys));
  final addresses = await privateAddresses();
  final ip = addresses.isEmpty ? '127.0.0.1' : addresses.first.address;
  final link = JoinLink(
    room: code,
    lan: LanAddress.tryParse('$ip:${lan.port}') ?? LanAddress(ip, lan.port),
    hostKey: keys.publicKey,
    roomSecret: keys.roomSecret,
  );
  stdout
    ..writeln('Room $code is open on $ip:${lan.port}.')
    ..writeln('Others join with:')
    ..writeln('  whowolf join <name>')
    ..writeln('and paste this link when asked (it holds the room secret):')
    ..writeln('  ${link.encode()}');
  return CliPlayer(
    name: name,
    room: code,
    connection: host.connectOwner(),
    out: stdout,
  );
}

Future<CliPlayer?> _join(String name, List<String> rest) async {
  if (rest.length == 1) {
    final link = JoinLink.tryParse(rest.single);
    final lan = link?.lan;
    if (link == null || lan == null) return null;
    final connection = await connectSecure(
      await dialHost(lan.ip, lan.port),
      hostKey: link.hostKey,
      roomSecret: link.roomSecret,
    );
    return CliPlayer(
      name: name,
      room: link.room,
      connection: connection,
      out: stdout,
      checkCode: connection.checkCode,
    );
  }
  if (rest.length == 2) {
    final lan = LanAddress.tryParse(rest.first);
    if (lan == null) return null;
    final connection = await connectSecure(await dialHost(lan.ip, lan.port));
    return CliPlayer(
      name: name,
      room: rest.last,
      connection: connection,
      out: stdout,
      checkCode: connection.checkCode,
    );
  }
  return null;
}
