import 'dart:async';
import 'dart:io';

import 'package:whowolf_server/relay_server.dart';

/// Configuration comes from the environment (see docker-compose.yml):
/// `PORT` (8080), `MAX_ROOMS` (200), `MAX_PEERS` (24).
///
/// `server healthcheck` asks the running server for `/health` and exits with
/// 0 or 1 (the container image has no shell or curl).
Future<void> main(List<String> args) async {
  int env(String name, int fallback) =>
      int.tryParse(Platform.environment[name] ?? '') ?? fallback;

  if (args.firstOrNull == 'healthcheck') {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final request = await client.get(
        '127.0.0.1',
        env('PORT', 8080),
        '/health',
      );
      final response = await request.close();
      exit(response.statusCode == HttpStatus.ok ? 0 : 1);
    } on Object {
      exit(1);
    }
  }

  final relay = await RelayServer.start(
    port: env('PORT', 8080),
    config: RelayConfig(
      maxRooms: env('MAX_ROOMS', 200),
      maxPeersPerRoom: env('MAX_PEERS', 24),
    ),
  );
  stdout.writeln('Whowolf relay listening on port ${relay.port}');

  Future<void> stop(ProcessSignal signal) async {
    stdout.writeln('Stopping (${signal.name})');
    await relay.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);
}
