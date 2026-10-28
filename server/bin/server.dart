import 'dart:async';
import 'dart:io';

import 'package:whowolf_server/relay_server.dart';
import 'package:whowolf_server/web_apps.dart';

/// Configuration comes from the environment (see deploy/docker-compose.yml):
/// `PORT` (8080), `MAX_ROOMS` (200), `MAX_ROOMS_PER_ADDRESS` (4, 0 = off),
/// `MAX_PEERS` (24), `MAX_CONNECTIONS` (2000), `MAX_CONNECTIONS_PER_ADDRESS`
/// (32), `MAX_UPGRADES_PER_MINUTE` (60) and `TRUST_PROXY` (`1` only behind
/// a reverse proxy that is the sole way in; the client address then comes
/// from `X-Forwarded-For`).
///
/// The web app for players without the app is opt-in: `WEB_APP_DIR` (the
/// builds in the image are under `/webapps`), `PUBLIC_HOST` (the name
/// players reach the server under, else `RELAY_DOMAIN`), `WEB_APP_MAX_MB`
/// (160, held in memory), `MAX_REQUESTS_PER_MINUTE` (600). To let
/// QR codes open the installed app: `APPLE_APP_ID` (`TEAMID.de.whowolf.app`)
/// and `ANDROID_CERT_SHA256` (fingerprints, comma-separated).
///
/// `server healthcheck` asks the running server for `/health` and exits with
/// 0 or 1 (the container image has no shell or curl).
void main(List<String> args) {
  // The last line of defence: an error no handler caught (from any socket
  // or timer) is noted by its type only, never with addresses or contents,
  // and the server keeps serving everyone else.
  runZonedGuarded(
    () => unawaited(_serve(args)),
    (error, _) => stderr.writeln('Unhandled error: ${error.runtimeType}'),
  );
}

Future<void> _serve(List<String> args) async {
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

  String? text(String name, RegExp valid) {
    final value = Platform.environment[name]?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!valid.hasMatch(value)) {
      stderr.writeln('$name is not valid, ignored');
      return null;
    }
    return value;
  }

  final dir = Platform.environment['WEB_APP_DIR'] ?? '';
  final webApps = dir.isEmpty
      ? WebApps.none()
      : await WebApps.load(
          Directory(dir),
          maxBytes: env('WEB_APP_MAX_MB', 160) << 20,
        );
  if (dir.isNotEmpty) {
    stdout.writeln(
      'Web app: ${webApps.builds.join(', ')} '
      '(${webApps.bytes ~/ 1024} KiB in memory)',
    );
  }
  final fingerprints = text(
    'ANDROID_CERT_SHA256',
    RegExp(
      r'^([0-9A-F]{2}(:[0-9A-F]{2}){31})(,[0-9A-F]{2}(:[0-9A-F]{2}){31})*$',
    ),
  );
  final relay = await RelayServer.start(
    webApps: webApps,
    port: env('PORT', 8080),
    config: RelayConfig(
      maxRooms: env('MAX_ROOMS', 200),
      maxRoomsPerAddress: env('MAX_ROOMS_PER_ADDRESS', 4),
      maxPeersPerRoom: env('MAX_PEERS', 24),
      maxConnections: env('MAX_CONNECTIONS', 2000),
      maxConnectionsPerAddress: env('MAX_CONNECTIONS_PER_ADDRESS', 32),
      maxUpgradesPerMinute: env('MAX_UPGRADES_PER_MINUTE', 60),
      trustProxy: Platform.environment['TRUST_PROXY'] == '1',
      maxRequestsPerMinute: env('MAX_REQUESTS_PER_MINUTE', 600),
      publicHost: text(
        Platform.environment['PUBLIC_HOST'] == null
            ? 'RELAY_DOMAIN'
            : 'PUBLIC_HOST',
        RegExp(r'^[a-z0-9.-]{1,253}(:[0-9]{1,5})?$'),
      ),
      appleAppId: text(
        'APPLE_APP_ID',
        RegExp(r'^[A-Z0-9]{10}\.[a-z0-9.]{1,100}$'),
      ),
      androidCertSha256: fingerprints?.split(','),
    ),
  );
  stdout.writeln('Whowolf relay listening on port ${relay.port}');
  // Counts only, never addresses or contents: enough to see the load.
  Timer.periodic(const Duration(minutes: 15), (_) {
    stdout.writeln(
      'rooms=${relay.roomCount} connections=${relay.connectionCount}',
    );
  });

  Future<void> stop(ProcessSignal signal) async {
    stdout.writeln('Stopping (${signal.name})');
    await relay.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);
}
