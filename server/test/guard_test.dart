import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:game_host/socket_guard.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:whowolf_server/relay_server.dart';

Future<T> eventually<T>(T? Function() probe) async {
  for (var i = 0; i < 250; i++) {
    final value = probe();
    if (value != null) return value;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw TimeoutException('condition not met');
}

/// One masked client frame (RFC 6455, 5.2) with [opcode] and [payload].
Uint8List frame(int opcode, List<int> payload, {required bool fin}) {
  final header = BytesBuilder()..addByte((fin ? 0x80 : 0) | opcode);
  final n = payload.length;
  if (n < 126) {
    header.addByte(0x80 | n);
  } else if (n < 65536) {
    header
      ..addByte(0x80 | 126)
      ..add([n >> 8, n & 0xFF]);
  } else {
    header.addByte(0x80 | 127);
    for (var k = 7; k >= 0; k--) {
      header.addByte((n >> (8 * k)) & 0xFF);
    }
  }
  const mask = [1, 2, 3, 4];
  header.add(mask);
  return (header..add([for (var i = 0; i < n; i++) payload[i] ^ mask[i % 4]]))
      .takeBytes();
}

/// A raw WebSocket client: the upgrade by hand, then bytes as they are.
/// `null` if the server did not switch protocols.
Future<Socket?> rawUpgrade(
  int port,
  String path, {
  bool reads = true,
}) async {
  final socket = await Socket.connect('127.0.0.1', port);
  socket.write(
    'GET $path HTTP/1.1\r\n'
    'Host: 127.0.0.1:$port\r\n'
    'Connection: Upgrade\r\n'
    'Upgrade: websocket\r\n'
    'Sec-WebSocket-Version: 13\r\n'
    'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n',
  );
  final answer = StringBuffer();
  final head = Completer<bool>();
  // Ends with the socket.
  // ignore: cancel_subscriptions
  late final StreamSubscription<Uint8List> subscription;
  subscription = socket.listen(
    (bytes) {
      if (head.isCompleted) return;
      answer.write(latin1.decode(bytes));
      if (answer.toString().contains('\r\n\r\n')) {
        head.complete(answer.toString().startsWith('HTTP/1.1 101'));
        // A client that stops reading: the OS buffers fill, then nothing.
        if (!reads) subscription.pause();
      }
    },
    onDone: () {
      if (!head.isCompleted) head.complete(false);
    },
    onError: (Object _) {},
  );
  return await head.future ? socket : null;
}

void main() {
  late RelayServer relay;

  setUp(() async {
    relay = await RelayServer.start(address: '127.0.0.1', port: 0);
  });
  tearDown(() => relay.close());

  Future<int> health() async {
    final client = HttpClient();
    addTearDown(client.close);
    final request = await client.get('127.0.0.1', relay.port, '/health');
    return (await request.close()).statusCode;
  }

  test(
    'a request with a repeated header does not take the server down',
    () async {
      final socket = await Socket.connect('127.0.0.1', relay.port);
      socket.write(
        'GET /host HTTP/1.1\r\n'
        'Host: x\r\n'
        'Origin: https://a.example\r\n'
        'Origin: https://b.example\r\n'
        'Connection: Upgrade\r\n'
        'Upgrade: websocket\r\n'
        'Sec-WebSocket-Version: 13\r\n'
        'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n',
      );
      final reply = await socket
          .cast<List<int>>()
          .transform(latin1.decoder)
          .first
          .timeout(const Duration(seconds: 5));
      expect(reply, isNot(startsWith('HTTP/1.1 101')));
      socket.destroy();
      expect(await health(), HttpStatus.ok);
    },
  );

  test('a message sent in endless fragments is cut off', () async {
    final host = (await rawUpgrade(relay.port, '/host'))!;
    addTearDown(host.destroy);
    await eventually(() => relay.connectionCount == 1 ? true : null);
    host.add(frame(1, utf8.encode('{"t":"x"'), fin: false));
    // Small continuation frames, well within the byte rate, but the
    // message never ends: past its size limit the relay hangs up.
    final chunk = List.filled(16 * 1024, 0x20);
    for (var i = 0; i < 20 && relay.connectionCount == 1; i++) {
      try {
        host.add(frame(0, chunk, fin: false));
        await host.flush();
      } on Object {
        break;
      }
    }
    await eventually(() => relay.connectionCount == 0 ? true : null);
    expect(await health(), HttpStatus.ok);
  });

  test('a message left unfinished is cut off after its deadline', () async {
    relay.hostLimits = const SocketLimits(
      burst: 1 << 20,
      rate: 1 << 20,
      maxMessage: 1 << 20,
      maxBacklog: 1 << 20,
      messageDeadline: Duration(milliseconds: 300),
    );
    final host = (await rawUpgrade(relay.port, '/host'))!
      ..add(frame(1, utf8.encode('{"t"'), fin: false));
    await host.flush();
    await eventually(() => relay.connectionCount == 1 ? true : null);
    await eventually(() => relay.connectionCount == 0 ? true : null);
  });

  test('a player who stops reading is dropped, not buffered', () async {
    relay
      ..playerLimits = const SocketLimits(
        burst: 1 << 20,
        rate: 1 << 20,
        maxMessage: 8 * 1024,
        maxBacklog: 64 * 1024,
        drainDeadline: Duration(seconds: 1),
      )
      // The host may send as fast as it likes here.
      ..hostLimits = const SocketLimits(
        burst: 64 << 20,
        rate: 64 << 20,
        maxMessage: 1 << 20,
        maxBacklog: 1 << 20,
      );
    final host = await WebSocket.connect('ws://127.0.0.1:${relay.port}/host');
    final opened = Completer<String>();
    final joined = Completer<int>();
    host.listen((data) {
      final frame = RelayFrame.parse(data as String);
      if (frame is RoomOpened) opened.complete(frame.roomId);
      if (frame is PeerJoined && !joined.isCompleted) {
        joined.complete(frame.peer);
      }
    });
    final room = await opened.future;
    // Joins, then never reads a byte.
    final lazy = (await rawUpgrade(relay.port, '/join/$room', reads: false))!;
    addTearDown(lazy.destroy);
    final peer = await joined.future;
    expect(relay.connectionCount, 2);
    final view = 'v' * 60000;
    for (var i = 0; i < 300 && relay.connectionCount == 2; i++) {
      host.add(PeerData(peer, view).encode());
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await eventually(() => relay.connectionCount == 1 ? true : null);
    expect(relay.roomCount, 1, reason: 'the host keeps its room');
    await host.close();
  });
}
