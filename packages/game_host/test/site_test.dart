import 'dart:convert';
import 'dart:io';

import 'package:game_host/lan.dart';
import 'package:test/test.dart';

void main() {
  late LanTransport lan;
  late HttpClient client;
  final files = {
    '': const SiteFile([60, 104, 49, 62], 'text/html; charset=utf-8'),
    'main.dart.js': SiteFile(
      gzip.encode(utf8.encode('main()')),
      'text/javascript',
      gzip: true,
    ),
  };

  setUp(() async {
    lan = await LanTransport.bind(port: 0, site: (path) async => files[path]);
    lan.connections.listen((_) {});
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await lan.close();
  });

  Future<HttpClientResponse> get(String path, {String method = 'GET'}) async {
    final request = await client.open(method, '127.0.0.1', lan.port, path);
    return request.close();
  }

  test('serves the web app with headers that keep it to itself', () async {
    for (final path in ['/', '/join']) {
      final response = await get(path);
      expect(response.statusCode, 200);
      expect(await utf8.decodeStream(response), '<h1>');
      final csp = response.headers.value('content-security-policy')!;
      expect(csp, contains("default-src 'self'"));
      expect(csp, contains('ws://127.0.0.1:${lan.port}'));
      expect(response.headers.value('x-content-type-options'), 'nosniff');
      expect(response.headers.value('x-frame-options'), 'DENY');
    }
    final js = await get('/main.dart.js');
    // HttpClient asks for gzip and unpacks it.
    expect(await utf8.decodeStream(js), 'main()');
    expect(js.headers.contentType!.mimeType, 'text/javascript');
  });

  test('nothing outside the site, and only reading', () async {
    for (final path in [
      '/missing.js',
      '/../secret',
      '/%2e%2e/secret',
      '/.hidden',
      '/a//b',
      '/a/../b',
      '/${'x' * 300}',
    ]) {
      final response = await get(path);
      await response.drain<void>();
      expect(response.statusCode, anyOf(400, 404), reason: path);
    }
    final post = await get('/', method: 'POST');
    await post.drain<void>();
    expect(post.statusCode, 400);
  });

  test('the game socket still answers next to the site', () async {
    final socket = await dialHost('127.0.0.1', lan.port);
    await socket.close();
  });
}
