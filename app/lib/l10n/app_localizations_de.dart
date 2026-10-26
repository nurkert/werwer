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

  @override
  String get nameTaken =>
      'Diesen Namen gibt es am Tisch schon. Nimm einen anderen:';

  @override
  String get narrateReveal =>
      'Die Rollen sind verteilt. Schaut euch eure Rolle an, und lasst niemanden mitschauen.';

  @override
  String get narrateNight =>
      'Die Nacht legt sich über das Dorf. Alle schließen die Augen … und tippen auf ihrem Handy.';

  @override
  String get narrateMorning => 'Die Sonne geht über dem Dorf auf.';

  @override
  String get narrateDiscuss => 'Jetzt redet: Wer ist der Werwolf?';

  @override
  String get narrateVote => 'Genug geredet. Stimmt jetzt ab.';

  @override
  String narrateRole(String role) {
    return 'Die Rolle war: $role.';
  }

  @override
  String get mute => 'Erzählerstimme aus';

  @override
  String get unmute => 'Erzählerstimme an';

  @override
  String get nightSheep =>
      'Zähl Schäfchen bis zum Morgen: Tipp die weißen an, lass die schwarzen springen.';

  @override
  String dreamPoints(int points) {
    return '$points Traumpunkte';
  }

  @override
  String get sheepWhileWaiting => 'Bis zum Morgen: Schäfchen zählen.';

  @override
  String get sleepTitle => 'Wie gut habt ihr geschlafen?';

  @override
  String sheepCount(int count) {
    return '$count Schäfchen';
  }

  @override
  String bestDreamer(String name, int points) {
    return 'Bester Träumer: $name ($points Traumpunkte)';
  }

  @override
  String get youAppearAs => 'Du erscheinst als';

  @override
  String get changePersona => 'Figur wählen';

  @override
  String get personaHint =>
      'Deine Figur ist nur dein Aussehen. Deine Rolle bleibt geheim und wird zufällig verteilt.';

  @override
  String get persona_maid => 'Magd';

  @override
  String get persona_lanternBearer => 'Laternenträgerin';

  @override
  String get persona_greyWolf => 'Grauwolf';

  @override
  String get persona_farmer => 'Bauer';

  @override
  String get persona_hunter => 'Jäger';

  @override
  String get persona_herbWitch => 'Kräuterhexe';

  @override
  String get persona_cupid => 'Amor';

  @override
  String get persona_guard => 'Wächter';

  @override
  String get persona_tracker => 'Fährtenleger';

  @override
  String get persona_listener => 'Lauscherin';

  @override
  String get persona_quietPaw => 'Stille Pfote';

  @override
  String get inviteTitle => 'Holt die anderen dazu';

  @override
  String get inviteHint =>
      'Die anderen öffnen Whowolf und tippen auf „Raum beitreten“: Dein Raum erscheint dort von selbst. Oder sie scannen diesen Code.';

  @override
  String get connectionDetails => 'Verbindungsdetails';

  @override
  String get nearbyTitle => 'Räume in der Nähe';

  @override
  String get searching => 'Suche nach Räumen in deinem WLAN …';

  @override
  String roomOf(String host) {
    return 'Raum von $host';
  }

  @override
  String get noDiscovery =>
      'Die Suche geht auf diesem Gerät nicht. Scanne stattdessen den QR-Code.';

  @override
  String get manualJoin => 'Von Hand verbinden';

  @override
  String get tableHint =>
      'So sitzt ihr am Tisch, von deinem Platz aus gesehen. Stimmt die Reihenfolge? Der Gastgeber kann Plätze tauschen.';

  @override
  String get swapSeat => 'Platz tauschen';

  @override
  String swapHint(String name) {
    return 'Tippe jetzt auf den Platz, mit dem $name tauschen soll.';
  }

  @override
  String get helpTitle => 'Ihr findet euch nicht?';

  @override
  String get helpLink => 'Raum nicht dabei? Hilfe';

  @override
  String get helpSameWifi =>
      'Alle im selben WLAN: Prüft, dass kein Handy im Mobilfunk oder in einem anderen Netz hängt.';

  @override
  String get helpGuest =>
      'Gäste- oder Hotel-WLANs halten Geräte oft voneinander fern. Öffnet einen Hotspot auf dem Gastgeber-Handy und verbindet euch alle damit.';

  @override
  String get helpIos =>
      'iPhone/iPad: Einstellungen › Datenschutz & Sicherheit › Lokales Netzwerk: Whowolf einschalten.';

  @override
  String get helpAndroid =>
      'Android: Akku-Sparmodus für Whowolf ausschalten, damit die Verbindung bleibt.';

  @override
  String get helpMac =>
      'Mac: Bei „Eingehende Netzwerkverbindungen akzeptieren?“ auf Erlauben tippen (Systemeinstellungen › Netzwerk › Firewall).';

  @override
  String get helpWindows =>
      'Windows: Wenn die Firewall fragt, Whowolf in privaten Netzwerken erlauben.';

  @override
  String get helpVpn =>
      'VPNs und Werbeblocker ausschalten, die das lokale Netz filtern.';

  @override
  String get helpQr =>
      'Immer noch nichts? Scannt stattdessen den QR-Code am Gastgeber-Handy.';

  @override
  String get restoreRoom => 'Deinen Raum wiederherstellen';

  @override
  String get waitingForHost =>
      'Gleich bist du drin! Zeig dem Gastgeber diese Zeichen:';

  @override
  String get waitingHint =>
      'Der Gastgeber lässt dich rein, sobald die Zeichen übereinstimmen.';

  @override
  String wantsToJoin(String name) {
    return '$name möchte mitspielen';
  }

  @override
  String get compareSymbols =>
      'Stimmen diese Zeichen mit denen auf dem anderen Handy überein?';

  @override
  String get letIn => 'Reinlassen';

  @override
  String get refuse => 'Ablehnen';

  @override
  String get pauseTitle => 'Kurze Pause';

  @override
  String get pauseText =>
      'Der Erzähler holt kurz Luft … Gleich geht es weiter, nichts geht verloren.';

  @override
  String get pauseLeave => 'Spiel verlassen';

  @override
  String roomOpenNotice(String room) {
    return 'Raum $room ist offen';
  }

  @override
  String get keepAppOpenHint =>
      'Du bist Gastgeber: Lass Whowolf bitte offen, solange ihr spielt. Wechselst du kurz in eine andere App, geht es weiter, sobald du zurück bist.';

  @override
  String get roleWitch => 'Hexe';

  @override
  String get roleHunter => 'Jäger';

  @override
  String get roleCupid => 'Amor';

  @override
  String get roleWitchText =>
      'Du hast einen Heiltrank und einen Gifttrank, jeden für einmal. Nachts siehst du, wen die Werwölfe holen, und entscheidest nach ihnen.';

  @override
  String get roleHunterText =>
      'Fällst du, ob nachts oder bei der Abstimmung, nimmst du sofort jemanden mit.';

  @override
  String get roleCupidText =>
      'In der ersten Nacht verbindest du zwei Menschen als Liebespaar. Stirbt einer, stirbt auch der andere.';

  @override
  String get factionLovers => 'Liebespaar';

  @override
  String get nightLink =>
      'Wen verbindest du als Liebespaar? Wähl zwei (auch dich selbst).';

  @override
  String get linkConfirm => 'Verbinden';

  @override
  String linked(String first, String second) {
    return '$first und $second sind jetzt ein Liebespaar.';
  }

  @override
  String get nightBrew => 'Die Werwölfe haben gewählt. Was braust du?';

  @override
  String brewVictim(String name) {
    return 'Heute holen die Werwölfe $name.';
  }

  @override
  String get brewNoVictim => 'Heute holen die Werwölfe niemanden.';

  @override
  String brewHeal(String name) {
    return 'Heiltrank für $name';
  }

  @override
  String get brewPoison =>
      'Gift: Tipp jemanden an (noch einmal tippen nimmt es zurück).';

  @override
  String get brewDone => 'Fertig';

  @override
  String get brewNothing => 'Nichts brauen';

  @override
  String get brewEmpty => 'Deine Tränke sind aufgebraucht.';

  @override
  String get brewSent =>
      'Du hast entschieden. Noch ein paar Schäfchen bis zum Morgen?';

  @override
  String get hunterYou => 'Du bist gefallen. Wen nimmst du mit?';

  @override
  String get hunterSpare => 'Niemanden';

  @override
  String hunterWait(String name) {
    return '$name war der Jäger und legt an …';
  }

  @override
  String diedOfGrief(String name) {
    return '$name stirbt vor Kummer.';
  }

  @override
  String shotByHunter(String name) {
    return 'Der Jäger nimmt $name mit.';
  }

  @override
  String inLove(String name) {
    return 'Du bist verliebt in $name. Stirbt einer von euch, stirbt auch der andere.';
  }

  @override
  String yourCouple(String first, String second) {
    return 'Dein Liebespaar: $first und $second.';
  }

  @override
  String get loversWin => 'Das Liebespaar gewinnt!';

  @override
  String get narrateHunter => 'Der Jäger ist gefallen und legt an …';

  @override
  String get settingsButton => 'Spiel einstellen';

  @override
  String get settingsTitle => 'Spiel einstellen';

  @override
  String get presetClassic => 'Klassisch';

  @override
  String get presetClassicText =>
      'Wie das Kartenspiel: nur die Rollen. Die App erzählt und zählt die Stimmen.';

  @override
  String get presetWhowolf => 'Whowolf';

  @override
  String get presetWhowolfText =>
      'Dazu Schäfchen zählen mit Morgenwertung und Atmosphäre.';

  @override
  String get presetFullStage => 'Volle Bühne';

  @override
  String get presetFullStageText =>
      'Alles, was es gibt, mit Amor und Wolfsspur.';

  @override
  String get presetCustom => 'Eigene Mischung';

  @override
  String get settingsRoles => 'Rollen';

  @override
  String get settingsWolves => 'Werwölfe';

  @override
  String wolvesSuggested(int count) {
    return 'Passend ($count)';
  }

  @override
  String get settingsTimes => 'Zeiten';

  @override
  String get timeNight => 'Nacht';

  @override
  String get timeDay => 'Diskussion';

  @override
  String get timeVote => 'Abstimmung';

  @override
  String seconds(int count) {
    return '$count s';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get settingsRules => 'Regeln';

  @override
  String get settingsRevealRoles => 'Rollen der Toten aufdecken';

  @override
  String get settingsSeerRole =>
      'Seherin sieht die Rolle (sonst nur das Lager)';

  @override
  String get settingsExtras => 'Whowolf-Extras';

  @override
  String get settingsSheep => 'Schäfchen zählen in der Nacht';

  @override
  String get settingsSheepOff =>
      'Ohne Schäfchen beantworten nachts alle eine schlichte Frage, damit das Tippen niemanden verrät.';

  @override
  String get settingsWolfTrail => 'Wolfsspur light';

  @override
  String get settingsAtmosphere => 'Nacht-Atmosphäre';

  @override
  String get settingsPersonas => 'Figuren selbst wählen';

  @override
  String get settingsVoice => 'Erzählstimme auf dem Gastgeber-Gerät';

  @override
  String tooManyRoles(int count) {
    return 'Für $count Spieler sind das zu viele Rollen.';
  }

  @override
  String get presetBasic => 'Grundspiel';
}
