import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:whowolf_server/operator_legal.dart';
import 'package:whowolf_server/relay_server.dart';
import 'package:whowolf_server/web_apps.dart';

/// The operator's own imprint and privacy pages: off by default, only
/// what the operator set, escaped, never anyone else's (task 029).
void main() {
  group('reading the settings', () {
    test('nothing set means no pages at all', () {
      final legal = OperatorLegal.fromEnvironment(const {});
      expect(legal.any, isFalse);
      expect(legal.footerHtml(german: true), isEmpty);
      expect(jsonDecode(legal.toJson()), {
        'imprint': null,
        'privacy': null,
        'imprintEn': null,
        'privacyEn': null,
      });
    });

    test('only https pages are taken, the rest is named and left out', () {
      final rejected = <String>[];
      final legal = OperatorLegal.fromEnvironment(
        {
          'IMPRINT_URL': 'https://example.org/impressum',
          'PRIVACY_URL': 'http://example.org/privacy',
          'IMPRINT_URL_EN': 'javascript:alert(1)',
          'PRIVACY_URL_EN': 'https://user:pw@example.org/p',
        },
        rejected: rejected.add,
      );
      expect(legal.imprint, Uri.parse('https://example.org/impressum'));
      expect(legal.privacy, isNull);
      expect(legal.imprintEn, isNull);
      expect(legal.privacyEn, isNull);
      expect(rejected, ['PRIVACY_URL', 'IMPRINT_URL_EN', 'PRIVACY_URL_EN']);
      expect(parseLegalUrl('https://example.org/${'a' * 300}'), isNull);
    });

    test('English pages where set, else the same ones', () {
      final legal = OperatorLegal(
        imprint: Uri.parse('https://example.org/impressum'),
        privacy: Uri.parse('https://example.org/datenschutz'),
        privacyEn: Uri.parse('https://example.org/privacy'),
      );
      final en = legal.pagesFor(german: false);
      expect(en.imprint, Uri.parse('https://example.org/impressum'));
      expect(en.privacy, Uri.parse('https://example.org/privacy'));
      expect(
        legal.footerHtml(german: true),
        [
          '<p class="legal">',
          '<a href="https://example.org/impressum">Impressum</a> · ',
          '<a href="https://example.org/datenschutz">Datenschutz</a></p>',
        ].join(),
      );
    });

    test('a page address cannot break out of its link', () {
      final legal = OperatorLegal(
        imprint: parseLegalUrl('https://example.org/a"><script>x</script>'),
      );
      final html = legal.footerHtml(german: false);
      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('/a">')));
      expect(html, contains('%22'));
    });
  });

  group('on the server', () {
    late Directory root;
    late HttpClient client;
    final relays = <RelayServer>[];

    setUpAll(() async {
      root = await Directory.systemTemp.createTemp('legal');
      final page = File('${root.path}/12/0.3.0/index.html');
      await page.parent.create(recursive: true);
      await page.writeAsString('<!DOCTYPE html>page');
    });
    tearDownAll(() => root.delete(recursive: true));
    setUp(() => client = HttpClient());
    tearDown(() async {
      client.close(force: true);
      for (final relay in relays) {
        await relay.close();
      }
      relays.clear();
    });

    Future<RelayServer> start(OperatorLegal legal) async {
      final relay = await RelayServer.start(
        address: '127.0.0.1',
        port: 0,
        config: RelayConfig(legal: legal),
        webApps: await WebApps.load(root),
      );
      relays.add(relay);
      return relay;
    }

    Future<HttpClientResponse> get(RelayServer relay, String path) async {
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:${relay.port}$path'),
      );
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'de');
      return request.close();
    }

    Future<String> body(RelayServer relay, String path) async =>
        (await get(relay, path)).transform(utf8.decoder).join();

    test('without settings the pages link to no legal page', () async {
      final relay = await start(const OperatorLegal());
      for (final path in ['/', '/v/12/9.9.9/join']) {
        final page = await body(relay, path);
        expect(page, isNot(contains('Impressum')), reason: path);
        expect(page, isNot(contains('Datenschutz')), reason: path);
        expect(page, isNot(contains('class="legal"')), reason: path);
      }
      expect(jsonDecode(await body(relay, '/legal.json')), {
        'imprint': null,
        'privacy': null,
        'imprintEn': null,
        'privacyEn': null,
      });
    });

    test("with settings the pages show the operator's links", () async {
      final relay = await start(
        OperatorLegal(
          imprint: Uri.parse('https://example.org/impressum'),
          privacy: Uri.parse('https://example.org/datenschutz'),
        ),
      );
      for (final path in ['/', '/v/12/9.9.9/join']) {
        final page = await body(relay, path);
        expect(page, contains('https://example.org/impressum'), reason: path);
        expect(page, contains('https://example.org/datenschutz'), reason: path);
      }
      final response = await get(relay, '/legal.json');
      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'application/json');
      expect(response.headers.value('x-content-type-options'), 'nosniff');
      expect(
        response.headers.value('content-security-policy'),
        contains("default-src 'none'"),
      );
      final json =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, Object?>;
      expect(json['imprint'], 'https://example.org/impressum');
      expect(json['privacy'], 'https://example.org/datenschutz');
      expect(json['imprintEn'], isNull);
    });
  });
}
