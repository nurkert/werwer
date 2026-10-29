import 'dart:convert';

/// The official relay, run by the app's publisher.
const officialRelayHost = 'play.whowolf.de';

/// Which legal links a page in the browser shows.
class PageLegal {
  /// The app publisher's own privacy notice applies: the page comes from the
  /// official server or from the host's phone at the table.
  const PageLegal.publisher()
    : operator = false,
      imprint = null,
      privacy = null;

  /// Another operator's server served the page: only its own pages, if it
  /// set any, and never the publisher's.
  const PageLegal.operator({this.imprint, this.privacy}) : operator = true;

  /// Whether someone other than the publisher runs the server.
  final bool operator;
  final Uri? imprint;
  final Uri? privacy;
}

/// Decides the links for [page], given what its server answered for
/// `/legal.json` ([legalJson], `null` if it has no such address: the host's
/// phone, or a server from before there was one).
PageLegal pageLegal({
  required Uri page,
  required String? legalJson,
  required bool german,
}) {
  if (page.host == officialRelayHost || legalJson == null) {
    return const PageLegal.publisher();
  }
  Object? json;
  try {
    json = jsonDecode(legalJson);
  } on FormatException {
    return const PageLegal.operator();
  }
  if (json is! Map<String, Object?>) return const PageLegal.operator();
  final pages = json;
  Uri? read(String key) {
    final text = pages[key];
    if (text is! String || text.length > 300) return null;
    final url = Uri.tryParse(text);
    return url != null &&
            url.scheme == 'https' &&
            url.host.isNotEmpty &&
            url.userInfo.isEmpty
        ? url
        : null;
  }

  final imprint = read('imprint');
  final privacy = read('privacy');
  final imprintEn = read('imprintEn');
  final privacyEn = read('privacyEn');
  return german
      ? PageLegal.operator(
          imprint: imprint ?? imprintEn,
          privacy: privacy ?? privacyEn,
        )
      : PageLegal.operator(
          imprint: imprintEn ?? imprint,
          privacy: privacyEn ?? privacy,
        );
}
