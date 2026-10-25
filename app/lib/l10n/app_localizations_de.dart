// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get tagline => 'Werwolf am Tisch. Jeder mit seinem Handy.';

  @override
  String devStamp(String version) {
    return 'Testversion · $version';
  }

  @override
  String get testNote =>
      'Frühe Testversion: Spielt im eigenen WLAN mit Leuten, denen ihr vertraut.';

  @override
  String get nameLabel => 'Dein Name';

  @override
  String get createRoom => 'Raum eröffnen';

  @override
  String get joinRoom => 'Raum beitreten';

  @override
  String get nameRequired => 'Gib zuerst deinen Namen ein.';

  @override
  String get joinTitle => 'Raum beitreten';

  @override
  String get hostAddress => 'Adresse des Gastgebers';

  @override
  String get roomCode => 'Raumcode';

  @override
  String get connect => 'Beitreten';

  @override
  String get joinHelp =>
      'Das Handy, das den Raum eröffnet hat, zeigt Adresse und Code. Alle müssen im selben WLAN sein.';

  @override
  String get connectFailed =>
      'Gastgeber nicht erreichbar. Selbes WLAN? Adresse richtig?';

  @override
  String get hostFailed => 'Auf diesem Gerät ließ sich kein Raum eröffnen.';

  @override
  String get byeWrongRoom => 'Der Raumcode stimmt nicht.';

  @override
  String get byeGameRunning => 'Dieses Spiel läuft schon.';

  @override
  String get byeUnknownSession => 'Der Gastgeber kennt dich nicht mehr.';

  @override
  String get byeRefused => 'Abgelehnt: Name vergeben oder Raum voll.';

  @override
  String get byeKicked => 'Der Gastgeber hat dich entfernt.';

  @override
  String get byeLeft => 'Du hast den Raum verlassen.';

  @override
  String get byeReplaced =>
      'Du bist von einem anderen Gerät erneut beigetreten.';

  @override
  String get byeClosed => 'Der Gastgeber hat den Raum geschlossen.';

  @override
  String get byeMisbehaved => 'Die Verbindung wurde beendet.';

  @override
  String get byeLost => 'Die Verbindung zum Gastgeber ist weg.';

  @override
  String get backToStart => 'Zurück zum Start';

  @override
  String get reconnecting => 'Verbindung weg, verbinde neu …';

  @override
  String get lobbyTitle => 'Lobby';

  @override
  String get lobbyJoinHint =>
      'Die anderen tippen auf „Raum beitreten“ und geben ein:';

  @override
  String players(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler',
      one: '1 Spieler',
    );
    return '$_temp0';
  }

  @override
  String get startGame => 'Rollen verteilen';

  @override
  String needPlayers(int count) {
    return 'Mindestens $count Spieler nötig.';
  }

  @override
  String get fewPlayersHint => 'Richtig Spaß macht es ab 5 Spielern.';

  @override
  String rolesInGame(String roles) {
    return 'Im Spiel: $roles';
  }

  @override
  String get waitingForOwner => 'Warte, bis der Gastgeber startet …';

  @override
  String get kick => 'Entfernen';

  @override
  String get you => 'du';

  @override
  String get owner => 'Gastgeber';

  @override
  String get leave => 'Verlassen';

  @override
  String get leaveTitle => 'Spiel verlassen?';

  @override
  String get leaveOwner => 'Du bist Gastgeber: Der Raum schließt für alle.';

  @override
  String get leavePlayer =>
      'Du kannst zurückkommen, solange die App offen bleibt.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get roleVillager => 'Dorfbewohner';

  @override
  String get roleWerewolf => 'Werwolf';

  @override
  String get roleSeer => 'Seherin';

  @override
  String get roleVillagerText =>
      'Keine besondere Gabe. Beobachte, hör zu und stimm die Werwölfe raus.';

  @override
  String get roleWerewolfText =>
      'Nachts wählst du mit deinem Rudel ein Opfer. Tagsüber siehst du aus wie alle anderen.';

  @override
  String get roleSeerText =>
      'Jede Nacht blickst du in einen Spieler und erfährst, wer er ist.';

  @override
  String get factionVillage => 'Dorf';

  @override
  String get factionWerewolves => 'Werwölfe';

  @override
  String get revealTitle => 'Deine Rolle';

  @override
  String get revealTap =>
      'Tippe, um deine Rolle zu sehen. Niemand darf mitschauen.';

  @override
  String pack(String names) {
    return 'Dein Rudel: $names';
  }

  @override
  String get confirmRole => 'Verstanden';

  @override
  String waitingFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Warte auf $count Spieler …',
      one: 'Warte auf 1 Spieler …',
      zero: 'Alle sind bereit.',
    );
    return '$_temp0';
  }

  @override
  String nightTitle(int round) {
    return 'Nacht $round';
  }

  @override
  String get nightHunt => 'Wen holt das Rudel heute Nacht?';

  @override
  String get nightInspect => 'In wessen Seele blickst du?';

  @override
  String get nightDecoy => 'Wem traust du am wenigsten?';

  @override
  String get nightHint => 'Nachts tippen alle, damit niemand auffällt.';

  @override
  String picked(String name) {
    return 'Du hast $name gewählt.';
  }

  @override
  String seerSaw(String name, String what) {
    return '$name ist: $what';
  }

  @override
  String packPick(String name) {
    return '→ $name';
  }

  @override
  String get youAreDead => 'Du bist tot. Schweig und schau zu.';

  @override
  String timeLeft(int seconds) {
    return 'noch $seconds s';
  }

  @override
  String dayTitle(int round) {
    return 'Tag $round';
  }

  @override
  String killedAtNight(String name) {
    return '$name ist nicht mehr aufgewacht.';
  }

  @override
  String get nobodyDied => 'Alle sind aufgewacht. Niemand ist gestorben.';

  @override
  String roleWas(String role) {
    return 'Rolle: $role';
  }

  @override
  String get discuss => 'Diskutiert am Tisch. Handys weg!';

  @override
  String get startVote => 'Abstimmung starten';

  @override
  String get ownerStartsVote =>
      'Der Gastgeber startet die Abstimmung, wenn ihr so weit seid.';

  @override
  String get voteTitle => 'Abstimmung';

  @override
  String get votePrompt => 'Wer ist ein Werwolf?';

  @override
  String get abstain => 'Enthalten';

  @override
  String votedFor(String name) {
    return 'Deine Stimme: $name';
  }

  @override
  String get abstained => 'Du enthältst dich.';

  @override
  String eliminated(String name) {
    return 'Das Dorf hat $name verbannt.';
  }

  @override
  String get nobodyEliminated => 'Niemand wurde verbannt.';

  @override
  String get villageWins => 'Das Dorf gewinnt!';

  @override
  String get werewolvesWin => 'Die Werwölfe gewinnen!';

  @override
  String get everyRole => 'Wer war wer';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get dead => 'tot';

  @override
  String get refused => 'Das geht gerade nicht.';

  @override
  String get scanQr => 'QR-Code scannen';

  @override
  String get scanTitle => 'Raumcode scannen';

  @override
  String get scanInvalid => 'Das ist kein Whowolf-Raumcode.';

  @override
  String joinConfirmTitle(String room) {
    return 'Raum $room beitreten?';
  }

  @override
  String joinConfirmLan(String address) {
    return 'Im WLAN: $address';
  }

  @override
  String joinConfirmOnline(String server) {
    return 'Online über $server';
  }

  @override
  String get joinLan => 'Im WLAN';

  @override
  String get joinOnline => 'Online';

  @override
  String get onlineCode => 'Online-Code';

  @override
  String get noRelayServer =>
      'Kein Server für Online-Spiele eingestellt. Trag in den Einstellungen einen ein.';

  @override
  String resume(String room) {
    return 'Zurück ins Spiel (Raum $room)';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get relayServer => 'Server für Online-Spieler';

  @override
  String get relayServerHelp =>
      'Leer lassen für den offiziellen Server, sobald es ihn gibt. Eigener Server: docker compose up -d, siehe Docs.';

  @override
  String get save => 'Speichern';

  @override
  String get invalidServer =>
      'Die Adresse muss mit ws:// oder wss:// beginnen.';

  @override
  String get scanHint => 'Oder scannt diesen Code mit der Whowolf-App:';

  @override
  String get relayFailed => 'Online-Server nicht erreichbar: nur WLAN.';
}
