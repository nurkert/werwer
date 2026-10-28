import 'package:protocol/protocol.dart';

/// What the host's QR code says.
///
/// One code for everyone where possible: the relay server's page for this
/// app's [build], when the room is on a server that has it (the app opens
/// it or dials it from its scanner, a camera without the app opens the
/// page). Otherwise the host's own address when it serves the web app on
/// the Wi-Fi ([servesWebApp]), else the plain link for the app. With
/// [localOnly] the host asked for the Wi-Fi code: never the server's page.
String inviteCode(
  JoinLink link, {
  required bool serverHasBuild,
  required bool servesWebApp,
  bool localOnly = false,
  String? build,
}) {
  if (!localOnly && serverHasBuild && build != null) {
    final page = link.encodeOnServer(build);
    if (page != null) return page;
  }
  return (servesWebApp ? link.encodeLocal() : null) ?? link.encode();
}
