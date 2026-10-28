@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:game_host/relay.dart';
import 'package:test/test.dart';
import 'package:whowolf_server/relay_server.dart';
import 'package:whowolf_server/web_apps.dart';

/// The relay serving the web app: only the builds it loaded, only reading,
/// with the page's headers, and within limits.
void main() {
  late Directory root;
  late RelayServer relay;
  late HttpClient client;

  Future<Directory> fixture() async {
    final dir = await Directory.systemTemp.createTemp('webapps');
    Future<void> put(String path, List<int> bytes) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }

    await put('7/0.2.0/index.html', utf8.encode('<!DOCTYPE html>page'));
    await put('7/0.2.0/main.dart.js.gz', gzip.encode(utf8.encode('code();')));
    await put('7/0.2.0/assets/figure.png', [1, 2, 3]);
    // Not part of any web app: no known media type.
    await put('7/0.2.0/run.sh', utf8.encode('rm -rf /'));
    await put('7/0.2.0/.secret.json', utf8.encode('{}'));
    // A build without its page is no build.
    await put('7/broken/main.dart.js', utf8.encode('x'));
    return dir;
  }

  Future<HttpClientResponse> get(
    String path, {
    String method = 'GET',
    Map<String, String> headers = const {},
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:${relay.port}$path'),
    );
    headers.forEach(request.headers.set);
    return request.close();
  }

  Future<String> body(HttpClientResponse r) => r.transform(utf8.decoder).join();

  setUp(() async {
    root = await fixture();
    relay = await RelayServer.start(
      address: '127.0.0.1',
      port: 0,
      webApps: await WebApps.load(root),
      config: const RelayConfig(
        maxRequestsPerMinute: 40,
        publicHost: 'play.example.org',
      ),
    );
    client = HttpClient()..autoUncompress = false;
  });

  tearDown(() async {
    client.close(force: true);
    await relay.close();
    await root.delete(recursive: true);
  });

  test('loads only complete builds and only known files', () async {
    final apps = await WebApps.load(root);
    expect(apps.builds, ['7/0.2.0']);
  });

  test('serves the page and its files with the page headers', () async {
    final page = await get('/v/7/0.2.0/join');
    expect(page.statusCode, 200);
    expect(await body(page), '<!DOCTYPE html>page');
    expect(page.headers.contentType?.mimeType, 'text/html');
    expect(page.headers.value('cache-control'), 'no-cache');
    final csp = page.headers.value('content-security-policy')!;
    expect(csp, contains("connect-src 'self' wss://play.example.org;"));
    expect(csp, contains("frame-ancestors 'none'"));
    expect(csp, contains("base-uri 'none'"));
    expect(csp, contains("object-src 'none'"));
    expect(page.headers.value('x-content-type-options'), 'nosniff');
    expect(page.headers.value('referrer-policy'), 'no-referrer');

    final code = await get(
      '/v/7/0.2.0/main.dart.js',
      headers: {'accept-encoding': 'gzip'},
    );
    expect(code.headers.value('content-encoding'), 'gzip');
    expect(
      utf8.decode(gzip.decode(await code.expand((b) => b).toList())),
      'code();',
    );
    expect(
      code.headers.value('cache-control'),
      'public, max-age=31536000, immutable',
    );
    expect(code.headers.value('content-security-policy'), isNotNull);

    // Without gzip support the same file comes plain.
    final plain = await get(
      '/v/7/0.2.0/main.dart.js',
      headers: {'accept-encoding': 'identity'},
    );
    expect(plain.headers.value('content-encoding'), isNull);
    expect(await body(plain), 'code();');

    // A browser that has it already gets 304.
    final again = await get(
      '/v/7/0.2.0/assets/figure.png',
      headers: {
        'if-none-match': (await get(
          '/v/7/0.2.0/assets/figure.png',
        )).headers.value('etag')!,
      },
    );
    expect(again.statusCode, 304);
  });

  test('nothing but the loaded files, and only reading', () async {
    for (final path in [
      '/v/7/0.2.0/run.sh',
      '/v/7/0.2.0/.secret.json',
      '/v/7/0.2.0/%2e%2e/index.html',
      '/v/7/0.2.0//index.html',
      '/v/7/0.2.0/index.html%00.png',
      '/v/7/0.2.0/nothing.js',
      '/v/7/broken/join',
      '/v/8/0.2.0/join',
      '/v/7/../../etc/passwd',
      '/v/',
    ]) {
      final r = await get(path);
      expect(r.statusCode, 404, reason: path);
      await r.drain<void>();
    }
    // Dot segments sent raw, past any client that would clean them up:
    // they never leave the loaded files.
    for (final path in [
      '/v/7/0.2.0/../../../etc/passwd',
      '/v/7/../x',
      r'/v/7/0.2.0/..\..\..\etc\passwd',
    ]) {
      final socket = await Socket.connect('127.0.0.1', relay.port);
      socket.write('GET $path HTTP/1.1\r\nHost: x\r\n\r\n');
      final head = await utf8.decoder.bind(socket).first;
      expect(head, startsWith('HTTP/1.1 404'), reason: path);
      socket.destroy();
    }
    // An unknown build gets a readable page, not a blank screen.
    final missing = await get('/v/7/9.9.9/join');
    expect(await body(missing), contains('Whowolf-App'));
    for (final method in ['POST', 'PUT', 'DELETE']) {
      final r = await get('/v/7/0.2.0/join', method: method);
      expect(r.statusCode, 405, reason: method);
      await r.drain<void>();
    }
    final head = await get('/v/7/0.2.0/join', method: 'HEAD');
    expect(head.statusCode, 200);
    await head.drain<void>();
  });

  test('no page can install a service worker', () async {
    final r = await get(
      '/v/7/0.2.0/main.dart.js',
      headers: {'service-worker': 'script'},
    );
    expect(r.statusCode, 403);
    await r.drain<void>();
  });

  test('one address cannot flood the files', () async {
    var limited = false;
    for (var i = 0; i < 45 && !limited; i++) {
      final r = await get('/v/7/0.2.0/assets/figure.png');
      limited = r.statusCode == 429;
      await r.drain<void>();
    }
    expect(limited, isTrue);
  });

  test('without a web app nothing is served, not even to HEAD', () async {
    final bare = await RelayServer.start(address: '127.0.0.1', port: 0);
    for (final method in ['GET', 'HEAD']) {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:${bare.port}/v/7/0.2.0/join'),
      );
      final r = await request.close();
      expect(r.statusCode, 404, reason: method);
      await r.drain<void>();
    }
    await bare.close();
  });

  test('a browser cannot open a room, the app can', () async {
    final server = 'ws://127.0.0.1:${relay.port}';
    await expectLater(
      WebSocket.connect(
        '$server/host',
        headers: {'origin': 'https://evil.example.org'},
      ),
      throwsA(isA<WebSocketException>()),
    );
    await expectLater(
      WebSocket.connect('$server/host', headers: {'origin': 'null'}),
      throwsA(isA<WebSocketException>()),
    );
    final host = await RelayTransport.open(Uri.parse(server));
    expect(relay.roomCount, 1);
    await host.close();
  });

  test('app links only from the server configuration', () async {
    final r = await get('/.well-known/apple-app-site-association');
    expect(r.statusCode, 404);
    await r.drain<void>();
    final linked = await RelayServer.start(
      address: '127.0.0.1',
      port: 0,
      config: const RelayConfig(
        appleAppId: 'ABCDE12345.de.whowolf.app',
        androidCertSha256: ['AA:BB'],
      ),
    );
    Future<Object?> json(String path) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${linked.port}$path?x=<script>'),
      );
      final r = await request.close();
      expect(r.headers.contentType?.mimeType, 'application/json');
      return jsonDecode(await body(r));
    }

    final apple = await json('/.well-known/apple-app-site-association');
    expect(jsonEncode(apple), contains('ABCDE12345.de.whowolf.app'));
    expect(jsonEncode(apple), isNot(contains('script')));
    final android = await json('/.well-known/assetlinks.json');
    expect(jsonEncode(android), contains('de.whowolf.app'));
    await linked.close();
  });

  test('the relay never writes paths or contents anywhere', () async {
    for (final file in Directory('lib').listSync().whereType<File>()) {
      final source = await file.readAsString();
      expect(
        RegExp(r'\b(print|stdout|stderr|log)\s*\(').hasMatch(source),
        isFalse,
        reason: file.path,
      );
    }
  });
}
