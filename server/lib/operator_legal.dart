import 'dart:convert';

/// The operator's own imprint and privacy pages, optional and off by
/// default: most people run a relay at home for their own table and need
/// none. Set them with `IMPRINT_URL` and `PRIVACY_URL` (and, if the pages
/// exist in English too, `IMPRINT_URL_EN` and `PRIVACY_URL_EN`). Never
/// someone else's pages by default: whoever runs the server answers for it.
class OperatorLegal {
  const OperatorLegal({
    this.imprint,
    this.privacy,
    this.imprintEn,
    this.privacyEn,
  });

  /// Reads the four variables from [env]; an unusable value is left out and
  /// named in [rejected] (the variable's name only, never its value).
  factory OperatorLegal.fromEnvironment(
    Map<String, String> env, {
    void Function(String name)? rejected,
  }) {
    Uri? read(String name) {
      final value = env[name]?.trim() ?? '';
      if (value.isEmpty) return null;
      final url = parseLegalUrl(value);
      if (url == null) rejected?.call(name);
      return url;
    }

    return OperatorLegal(
      imprint: read('IMPRINT_URL'),
      privacy: read('PRIVACY_URL'),
      imprintEn: read('IMPRINT_URL_EN'),
      privacyEn: read('PRIVACY_URL_EN'),
    );
  }

  final Uri? imprint;
  final Uri? privacy;
  final Uri? imprintEn;
  final Uri? privacyEn;

  /// Whether any page is set.
  bool get any =>
      imprint != null ||
      privacy != null ||
      imprintEn != null ||
      privacyEn != null;

  /// The pages for a German or another reader: the English ones where set,
  /// else the same ones.
  ({Uri? imprint, Uri? privacy}) pagesFor({required bool german}) => german
      ? (imprint: imprint ?? imprintEn, privacy: privacy ?? privacyEn)
      : (imprint: imprintEn ?? imprint, privacy: privacyEn ?? privacy);

  /// A footer line for the server's own pages, or nothing at all when no
  /// page is set.
  String footerHtml({required bool german}) {
    final pages = pagesFor(german: german);
    final links = [
      if (pages.imprint case final url?)
        '<a href="${_attribute(url)}">${german ? 'Impressum' : 'Imprint'}</a>',
      if (pages.privacy case final url?)
        '<a href="${_attribute(url)}">${german ? 'Datenschutz' : 'Privacy'}</a>',
    ];
    if (links.isEmpty) return '';
    return '<p class="legal">${links.join(' · ')}</p>';
  }

  /// What `/legal.json` answers: the four pages, `null` where not set.
  String toJson() => jsonEncode({
    'imprint': imprint?.toString(),
    'privacy': privacy?.toString(),
    'imprintEn': imprintEn?.toString(),
    'privacyEn': privacyEn?.toString(),
  });
}

/// An operator's page address: `https` with a host, no user info, at most
/// 300 characters; anything else is `null`.
Uri? parseLegalUrl(String value) {
  if (value.length > 300) return null;
  final url = Uri.tryParse(value);
  if (url == null ||
      url.scheme != 'https' ||
      url.host.isEmpty ||
      url.userInfo.isNotEmpty) {
    return null;
  }
  return url;
}

/// [url] safe inside a double-quoted HTML attribute.
String _attribute(Uri url) =>
    const HtmlEscape(HtmlEscapeMode.attribute).convert(url.toString());
