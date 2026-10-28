import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/net/update_check.dart';

void main() {
  test('versions compare by number, not by text', () {
    expect(compareVersions('0.1.10', '0.1.9'), greaterThan(0));
    expect(compareVersions('v0.2.0', '0.1.99'), greaterThan(0));
    expect(compareVersions('0.1.6', 'v0.1.6'), 0);
    expect(compareVersions('dev', '0.1.6'), isNull);
  });

  test('the newest published release counts, drafts and odd tags do not', () {
    final json = [
      {'tag_name': 'v0.1.6', 'draft': false, 'prerelease': true},
      {'tag_name': 'v0.2.0', 'draft': true},
      {'tag_name': 'nightly', 'draft': false},
      {'tag_name': 'v0.1.10', 'draft': false, 'prerelease': true},
      'garbage',
    ];
    expect(newestIn(json), '0.1.10');
    expect(newestIn({'message': 'rate limited'}), isNull);
    expect(newestIn(<Object?>[]), isNull);
  });
}
