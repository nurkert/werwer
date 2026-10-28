// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get tagline => 'Das Werwolfspiel für euren Tisch.';

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
  String get lobbyTitle => 'Der Tisch füllt sich';

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
  String get leaveOwner =>
      'Du bist Gastgeber: Ein anderer Spieler übernimmt den Tisch, und die Runde geht ohne dich weiter. Ist keiner bereit, schließt der Raum für alle.';

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
  String get introListening =>
      'Hört zu: Der Erzähler führt euch ins Dorf. Danach seht ihr eure Rollen.';

  @override
  String get introSkip => 'Intro überspringen';

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
  String get eyesClosingTogether =>
      'Kurz die Augen zu und das Handy an dich: Gleich geht die Nacht los.';

  @override
  String get settingsOpenVotes => 'Offene Abstimmung';

  @override
  String get settingsOpenVotesHint =>
      'Alle sehen live, wer wen wählt, und am nächsten Tag noch einmal.';

  @override
  String votesFor(String name, String voters) {
    return '$name: $voters';
  }

  @override
  String votesAbstained(String names) {
    return 'Enthalten: $names';
  }

  @override
  String get votesLive => 'Wer wen wählt';

  @override
  String get votesYesterday => 'So wurde gestern abgestimmt';

  @override
  String get chronicleTitle => 'Was wirklich geschah';

  @override
  String chronicleNight(int round) {
    return 'Nacht $round';
  }

  @override
  String chronicleDay(int round) {
    return 'Tag $round';
  }

  @override
  String chronicleHunt(String name) {
    return 'Die Werwölfe wählten $name.';
  }

  @override
  String get chronicleHuntNone => 'Die Werwölfe wurden sich nicht einig.';

  @override
  String chronicleLook(String seer, String name) {
    return '$seer blickte in ${name}s Seele.';
  }

  @override
  String chronicleHeal(String witch, String name) {
    return '$witch rettete $name mit dem Heiltrank.';
  }

  @override
  String chroniclePoison(String witch, String name) {
    return '$witch vergiftete $name.';
  }

  @override
  String chronicleLink(String cupid, String a, String b) {
    return '$cupid verband $a und $b.';
  }

  @override
  String get lastWordsTitle => 'Letzte Worte';

  @override
  String get lastWordsYou => 'Deine letzten Worte';

  @override
  String get lastWordsHint =>
      'Hört zu: Jetzt spricht nur, wer gerade gegangen ist.';

  @override
  String get lastWordsYouHint => 'Sag dem Dorf noch etwas, die Zeit läuft.';

  @override
  String get voteSoon => 'Gleich wird abgestimmt …';

  @override
  String readyCount(int ready, int alive) {
    return '$ready von $alive sind so weit.';
  }

  @override
  String get readyToVote => 'Wir sind so weit';

  @override
  String get readyUndo => 'Doch noch reden';

  @override
  String get offlineBadge => 'nicht verbunden';

  @override
  String get pausedByLeader => 'Der Spielleiter hat pausiert. Die Zeit steht.';

  @override
  String get leaderPause => 'Pause';

  @override
  String get leaderResume => 'Weiter';

  @override
  String get leaderExtend => '+30 s';

  @override
  String get leaderEnd => 'Abstimmung beenden';

  @override
  String timesForTable(int count) {
    return 'Passend für $count Spieler';
  }

  @override
  String updateTitle(String version) {
    return 'Version $version ist da';
  }

  @override
  String updateText(String current) {
    return 'Du spielst noch mit $current. Am besten aktualisieren alle am Tisch, denn nur gleiche Versionen spielen zusammen.';
  }

  @override
  String get updateLater => 'Später';

  @override
  String get updateGet => 'Zur Download-Seite';

  @override
  String get updateCheck => 'Nach neuen Versionen suchen';

  @override
  String get updateCheckHint =>
      'Fragt beim Start GitHub nach der neuesten Version. GitHub sieht dabei deine IP-Adresse.';

  @override
  String get privacyUpdatesTitle => 'Neue Versionen';

  @override
  String get privacyUpdates =>
      'Beim Start fragt die App die öffentliche Liste der Versionen auf GitHub ab (github.com, betrieben von GitHub Inc., USA), um dir eine neue Version zu zeigen. Dabei sieht GitHub die IP-Adresse deines Geräts, wie bei jedem Abruf einer Webseite. Es werden keine Daten über dich oder dein Spiel gesendet. In den Einstellungen kannst du das abschalten. Rechtsgrundlage ist unser berechtigtes Interesse, dich auf Fehlerbehebungen und zueinander passende Versionen hinzuweisen (Art. 6 Abs. 1 lit. f DSGVO).';

  @override
  String get handoverMenu => 'Platz an anderes Gerät geben';

  @override
  String get handoverPick => 'Wessen Platz geht an ein anderes Gerät?';

  @override
  String handoverTitle(String name) {
    return 'Platz von $name';
  }

  @override
  String handoverHint(String name) {
    return 'Auf dem neuen Gerät mit der Whowolf-App scannen. Der Code gilt einmal und nur kurz; das alte Gerät von $name wird abgemeldet.';
  }

  @override
  String get handoverDone => 'Fertig';

  @override
  String get webAppHint =>
      'Mit der App läuft es runder: Ton, der Bildschirm bleibt an, und du kommst leichter zurück.';

  @override
  String get webAppGet => 'App holen';

  @override
  String get inviteOpen => 'Mitspieler einladen';

  @override
  String get inviteFold => 'Einklappen';

  @override
  String get inviteInfoTitle => 'So kommen die anderen dazu';

  @override
  String get inviteInfo =>
      'Im selben WLAN öffnen die anderen Whowolf und tippen auf „Raum beitreten“: Euer Raum erscheint dort von selbst, ganz ohne Code.\n\nFür alle anderen (anderes WLAN, mobile Daten, ohne App im Browser) gibt es den QR-Code. Erst wenn du ihn aufklappst, geht der Raum auf den Online-Server; Runden im WLAN bleiben dem Server unbekannt.';

  @override
  String get seerVisionTitle => 'Deine Vision';

  @override
  String get seerVisionClose => 'Tippen zum Schließen';

  @override
  String get seerSeeAgain => 'Nochmal ansehen';

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
  String get scanHint => 'Oder scannt diesen Code mit der Whowolf-App:';

  @override
  String get scanLight => 'Licht';

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
      'Leer lassen für den offiziellen Server (play.whowolf.de). Er leitet nur verschlüsselte Nachrichten weiter. Eigener Server: siehe Docs.';

  @override
  String get save => 'Speichern';

  @override
  String get invalidServer =>
      'Die Adresse muss mit ws:// oder wss:// beginnen.';

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
      'Werwolf, wie man es kennt: Alle schließen die Augen, der Erzähler ruft die Rollen auf, und nur wer dran ist, nimmt sein Handy. Die App erzählt laut und zählt die Stimmen.';

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
  String get settingsQuick => 'Schnellwahl';

  @override
  String get quickClassicHint => 'Augen zu, der Erzähler ruft auf';

  @override
  String get quickWhowolfHint => 'Alle tippen, mit Schäfchen und Türzeichen';

  @override
  String get settingsQuickHint => 'Alles darunter stellst du selbst ein.';

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
  String get settingsSound => 'Erzähler & Ton';

  @override
  String get settingsNarrator => 'Erzähler';

  @override
  String get narratorOff => 'Aus';

  @override
  String get narratorEssential => 'Nötigstes';

  @override
  String get narratorEssentialHint =>
      'Die Stimme sagt nur, was ihr mit geschlossenen Augen braucht: einschlafen, wer aufwacht, wer wieder einschläft und wann das Dorf erwacht.';

  @override
  String get narratorMoments => 'Momente';

  @override
  String get narratorAlways => 'Alles';

  @override
  String get narratorOffHint =>
      'Die Geschichte steht nur auf den Bildschirmen.';

  @override
  String get narratorMomentsHint =>
      'Die Stimme erzählt das Wichtige: Nachtbeginn, die Nachricht am Morgen, die Abstimmung und das Ende. Den Rest zeigen die Bildschirme.';

  @override
  String get narratorAlwaysHint => 'Die Stimme erzählt jeden Satz.';

  @override
  String get settingsSoundWhere => 'Ton spielt auf';

  @override
  String get soundEveryone => 'Allen';

  @override
  String get soundMe => 'Nur mir';

  @override
  String get soundGroup => 'Gruppe';

  @override
  String get soundOne => 'Einem';

  @override
  String get soundEveryoneHint =>
      'Die Stimme wandert über alle Handys. Wer stumm ist, wird übersprungen.';

  @override
  String get soundChosenHint =>
      'Stimme und gemeinsame Klänge spielen nur auf diesen Handys. Alle anderen hören nur ihre eigenen Tipp-Klänge.';

  @override
  String get settingsExtras => 'Whowolf-Extras';

  @override
  String get settingsSheep => 'Schäfchen zählen in der Nacht';

  @override
  String get settingsSheepOff =>
      'Ohne Schäfchen beantworten nachts alle eine schlichte Frage, damit das Tippen niemanden verrät.';

  @override
  String get settingsWolfTrail => 'Wolfsspur (nach dem ersten Release)';

  @override
  String get settingsAtmosphere => 'Nachtgeräusche und Morgen-Gähnen';

  @override
  String get settingsVoice => 'Erzählstimme auf dem Gastgeber-Gerät';

  @override
  String rolesFitted(int count, String roles) {
    return 'Für $count Spieler ohne: $roles. Sie kommen zurück, sobald mehr mitspielen.';
  }

  @override
  String tooManyRoles(int count) {
    return 'Für $count Spieler sind das zu viele Rollen.';
  }

  @override
  String get presetBasic => 'Grundspiel';

  @override
  String get nightTaskDone => 'Deine Nachtaufgabe ist erledigt.';

  @override
  String get nightTaskShow => 'Ansehen';

  @override
  String get nightTaskHide => 'Zuklappen';

  @override
  String get nightNothingToDo =>
      'Heute Nacht hast du nichts weiter zu tun: Zähl Schäfchen bis zum Morgen.';

  @override
  String get ownCount => 'Zahl selbst festlegen';

  @override
  String get ownCountTitle => 'Wie viele Schäfchen hast du gezählt?';

  @override
  String get ownCountHint =>
      'Das darf jeder, also auch flunkern. Am Morgen sehen alle die Zahlen.';

  @override
  String get ownCountSet => 'Übernehmen';

  @override
  String get persona_maid => 'Magd';

  @override
  String get persona_farmer => 'Bauer';

  @override
  String get persona_baker => 'Bäckerin';

  @override
  String get persona_smith => 'Schmied';

  @override
  String get persona_fisher => 'Fischerin';

  @override
  String get persona_miller => 'Müller';

  @override
  String get persona_seamstress => 'Schneiderin';

  @override
  String get persona_minstrel => 'Spielmann';

  @override
  String get persona_gooseGirl => 'Gänsehirtin';

  @override
  String get persona_beekeeper => 'Imker';

  @override
  String get persona_innkeeper => 'Wirtin';

  @override
  String get persona_shepherd => 'Schäfer';

  @override
  String get persona_washerwoman => 'Wäscherin';

  @override
  String get persona_carpenter => 'Zimmermann';

  @override
  String get persona_spinner => 'Spinnerin';

  @override
  String get persona_cobbler => 'Schuster';

  @override
  String get persona_flowerGirl => 'Blumenmädchen';

  @override
  String get persona_mayor => 'Bürgermeister';

  @override
  String get persona_grandmother => 'Großmutter';

  @override
  String get persona_grandfather => 'Großvater';

  @override
  String get doorSignTitle => 'Dein Türzeichen heute Nacht';

  @override
  String get doorSignHint =>
      'Lass niemanden auf dein Display schauen: Ein Werwolf, der dein Zeichen kennt, hat heute Nacht eine Chance, dich zu holen.';

  @override
  String get markTitle => 'Ein Türzeichen erspäht?';

  @override
  String get markHint =>
      'Einmal pro Nacht darf das Rudel eines versuchen. Stimmt es, stirbt diese Person heute Nacht vielleicht zusätzlich (etwa jedes zweite Mal).';

  @override
  String markSymbol(int number) {
    return 'Symbol $number';
  }

  @override
  String get markTry => 'Zeichen versuchen';

  @override
  String markRight(String name) {
    return 'Das Zeichen von $name stimmte. Vielleicht erwischt das Rudel sie heute Nacht.';
  }

  @override
  String markWrong(String name) {
    return 'Das Zeichen von $name war falsch. Die nächste Nacht bringt neue Zeichen.';
  }

  @override
  String get settingsDoorSigns =>
      'Türzeichen (wer aufs Display schauen lässt, riskiert sein Leben)';

  @override
  String get codeAdmitted => 'Der Gastgeber hat dich reingelassen!';

  @override
  String get codeAdmittedHint =>
      'Siehst du auf seinem Bildschirm genau diese Zeichen? Dann bist du drin.';

  @override
  String get codeAdmittedGo => 'Stimmt, los geht’s';

  @override
  String get codeConfirmHint =>
      'Fragt der Bildschirm des Gastgebers mit genau diesen Zeichen nach dir? Nur dann ist es wirklich der Gastgeber. Sieht er keine Anfrage von dir, bestätige nicht.';

  @override
  String get codeConfirm => 'Der Gastgeber sieht dieselben Zeichen';

  @override
  String get narrateNightCalled =>
      'Die Nacht legt sich über das Dorf. Alle schließen die Augen.';

  @override
  String get narrateStepLink =>
      'Amor erwacht und verbindet zwei Menschen in Liebe.';

  @override
  String get narrateStepHunt =>
      'Die Werwölfe erwachen und suchen sich ein Opfer.';

  @override
  String get narrateStepInspect =>
      'Die Seherin erwacht und blickt in eine Seele.';

  @override
  String get narrateStepBrew =>
      'Die Hexe erwacht. Sie sieht, wen es heute Nacht treffen soll, und greift zu ihren Tränken.';

  @override
  String get narrateStepSleep => 'Augen wieder zu.';

  @override
  String get nightEyesClosed => 'Augen zu';

  @override
  String get nightEyesClosedHint =>
      'Leg das Handy weg, bis der Erzähler dich weckt.';

  @override
  String nightAwakeNow(String who) {
    return 'Gerade wach: $who';
  }

  @override
  String get nightWerewolves => 'die Werwölfe';

  @override
  String get nightYourTurn => 'Du bist dran. Augen auf!';

  @override
  String get settingsNight => 'Die Nacht';

  @override
  String get settingsNightCalled => 'Der Erzähler ruft die Rollen auf';

  @override
  String get settingsNightCalledHint =>
      'Wie man Werwolf kennt: Alle schließen die Augen, nur wer aufgerufen wird, nimmt sein Handy. Schäfchen und Türzeichen gibt es dann nicht.';

  @override
  String get settingsNightTogether => 'Alle tippen zugleich';

  @override
  String get settingsNightTogetherHint =>
      'Whowolf-Nacht: Alle haben ihr Handy in der Hand, und das Tippen verrät niemanden.';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get privacyNoticeTitle => 'Kurz zum Datenschutz';

  @override
  String get privacyNotice =>
      'Whowolf hat keine Konten, keine Werbung und kein Tracking. Am Tisch gehen die Spieldaten Ende-zu-Ende verschlüsselt nur zwischen euren Geräten hin und her. Damit auch Spieler ohne gemeinsames WLAN mitmachen können, verbindet sich das Gastgeber-Gerät mit dem Server play.whowolf.de, aber erst wenn es den QR-Code zeigt oder kein WLAN hat; der leitet nur Verschlüsseltes weiter und sieht dabei, wie jeder Server, die IP-Adressen. In den Einstellungen kannst du ihn abschalten.';

  @override
  String get privacyRead => 'Datenschutz lesen';

  @override
  String get privacyOk => 'Verstanden';

  @override
  String get relayOff => 'Kein Online-Server (nur WLAN)';

  @override
  String get relayOffHint =>
      'Dann können nur Geräte im selben WLAN mitspielen, und nichts geht an einen Server.';

  @override
  String get relayOnDemand => 'Server nur bei Bedarf';

  @override
  String get relayOnDemandHint =>
      'Im WLAN findet man deinen Raum ohne Server. Erst wenn du den QR-Code zeigst, öffnet sich der Raum auch auf dem Server, damit jeder mitspielen kann, auch ohne WLAN oder ohne App.';

  @override
  String get relayAlways => 'Server immer bereit';

  @override
  String get relayAlwaysHint =>
      'Dein Raum ist sofort auch auf dem Server, der QR-Code gilt von Anfang an für alle.';

  @override
  String get serveWebApp =>
      'Browser-Spieler im WLAN laden die Seite von meinem Handy';

  @override
  String get serveWebAppHint =>
      'Nur im selben WLAN, kostet also keine mobilen Daten. Aus: Ohne App kann dann nur jemand über den Server mitspielen.';

  @override
  String get relayCustomHint =>
      'Bei einem eigenen Server ist dessen Betreiber für ihn verantwortlich und sieht die IP-Adressen der verbundenen Geräte.';

  @override
  String get privacyTitle => 'Datenschutz in der App';

  @override
  String get privacyUpdated => 'Stand: 28. Oktober 2026';

  @override
  String get privacySummaryTitle => 'Das Wichtigste';

  @override
  String get privacySummary =>
      'Keine Konten, keine Werbung, kein Tracking, keine Analyse. Die App speichert nichts über dich auf einem Server.';

  @override
  String get privacyTableTitle => 'Am Tisch';

  @override
  String get privacyTable =>
      'Spieldaten gehen nur zwischen den Geräten am Tisch hin und her, Ende-zu-Ende verschlüsselt. Damit andere den Raum finden, kündigt das Gastgeber-Gerät ihn im lokalen Netz an (Raumcode, Name des Gastgebers, ein Kennzeichen seines Schlüssels); das sehen nur Geräte im selben WLAN.';

  @override
  String get privacyServerTitle => 'Der Online-Server';

  @override
  String get privacyServer =>
      'Damit Spieler ohne gemeinsames WLAN mitspielen können, verbindet sich das Gastgeber-Gerät mit play.whowolf.de, standardmäßig erst wenn es den QR-Code zeigt oder kein WLAN hat (Runden im WLAN bleiben dem Server unbekannt), betrieben vom Projektverantwortlichen (siehe Impressum auf whowolf.de). Der Server steht in Deutschland bei der ZAP-Hosting GmbH (Münster). Der Server leitet nur Ende-zu-Ende verschlüsselte Daten weiter und kann weder Namen noch Rollen noch Spielzüge lesen. Er verarbeitet dabei zwangsläufig die IP-Adressen der verbundenen Geräte, nur im Arbeitsspeicher und nur solange die Verbindung besteht, um Nachrichten weiterzuleiten und Missbrauch zu begrenzen; gespeichert oder protokolliert werden sie nicht. Rechtsgrundlage ist unser berechtigtes Interesse, das gewünschte Spiel bereitzustellen und den Server zu schützen (Art. 6 Abs. 1 lit. f DSGVO). In den Einstellungen kannst du den Server abschalten oder einen eigenen eintragen; dann ist dessen Betreiber verantwortlich.';

  @override
  String get privacyDeviceTitle => 'Auf deinem Gerät';

  @override
  String get privacyDevice =>
      'Dein Name und ein Sitzungsschlüssel für den Wiedereinstieg liegen im geschützten Speicher deines Geräts (höchstens 12 Stunden). Das Gastgeber-Gerät hält den Spielstand, bis der Raum geschlossen wird. Davon verlässt nichts dein Gerät, außer verschlüsselt zum Spiel.';

  @override
  String get privacyBrowserTitle => 'Im Browser';

  @override
  String get privacyBrowser =>
      'Wer ohne App im Browser mitspielt, lädt die Seite vom Gastgeber-Handy (im WLAN) oder vom Server, der den QR-Code ausgestellt hat. Dieser Server sieht dabei wie jeder Webserver die IP-Adresse und den Browser, speichert sie aber nicht. Es gibt keine Cookies und keine Inhalte von Dritten. Damit du nach dem Neuladen an deinen Platz zurückkommst, merkt sich der Browser den Link zur Runde und deinen Sitzungsschlüssel, höchstens 12 Stunden und nur auf diesem Gerät. Das ist für das Spiel nötig und braucht deshalb keine Einwilligung (§ 25 Abs. 2 TDDDG). Wer die Seite ausliefert, könnte mit einer veränderten Seite mitlesen. Mit der App gibt es diese Abhängigkeit nicht.';

  @override
  String get privacyRightsTitle => 'Deine Rechte';

  @override
  String get privacyRights =>
      'Du hast das Recht auf Auskunft, Berichtigung, Löschung und Einschränkung der Verarbeitung, auf Datenübertragbarkeit sowie auf Widerspruch (Art. 15 bis 21 DSGVO) und kannst dich bei einer Datenschutz-Aufsichtsbehörde beschweren (Art. 77 DSGVO). Da der Server nichts speichert, gibt es über dich keine gespeicherten Daten. Die ausführliche Fassung steht auf whowolf.de.';

  @override
  String get lobbyNightCalled =>
      'Nachts ruft der Erzähler die Rollen auf, alle anderen haben die Augen zu.';

  @override
  String get lobbyNightTogether =>
      'Nachts tippen alle zugleich, damit niemand auffällt.';

  @override
  String lobbyExtras(String list) {
    return 'Dazu: $list';
  }

  @override
  String get extraVoice => 'Erzählerstimme';

  @override
  String get extraSheep => 'Schäfchen zählen';

  @override
  String get extraDoorSigns => 'Türzeichen';

  @override
  String get extraAtmosphere => 'Nachtgeräusche';

  @override
  String get webJoinTitle => 'Mitspielen im Browser';

  @override
  String get webJoinHint =>
      'Ohne App: Gib deinen Namen ein, und du sitzt mit am Tisch.';

  @override
  String get webJoinNoLink =>
      'Scanne den QR-Code am Tisch mit der Kamera deines Handys, dann geht es hier weiter.';

  @override
  String get webJoinButton => 'Mitspielen';

  @override
  String get webJoinApp => 'Mit der App geht noch mehr: whowolf.de';

  @override
  String get webJoinBack => 'Du sitzt schon an diesem Tisch.';

  @override
  String webJoinContinue(String name) {
    return 'Weiter als $name';
  }

  @override
  String get webJoinSomeoneElse => 'Als jemand anderes beitreten';

  @override
  String get webJoinScreenOn =>
      'Lass den Bildschirm an und den Ton laut, solange ihr spielt.';

  @override
  String get webJoinPrivacy =>
      'Keine Cookies, kein Tracking: Dieser Browser merkt sich nur deinen Platz am Tisch, höchstens 12 Stunden.';

  @override
  String get inBrowser => 'im Browser';

  @override
  String get inviteHintWeb =>
      'Scannt den Code mit der Whowolf-App oder ohne App mit der Handykamera, dann geht es im Browser los.';

  @override
  String get inviteNoBrowser =>
      'Im Browser kann gerade niemand beitreten: Der Server hat diese Version der App noch nicht, und die Seite im WLAN ist in den Einstellungen aus. Mit der App geht es immer.';

  @override
  String get inviteWifiFirst =>
      'Im selben WLAN? Die anderen öffnen Whowolf und tippen auf „Raum beitreten“: Dein Raum erscheint dort von selbst.';

  @override
  String get inviteShowCode => 'QR-Code zeigen';

  @override
  String get inviteLocalCode =>
      'Nur WLAN-Code, ohne Server (nicht in vielen Hotel- und Gäste-WLANs)';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Wie das System';

  @override
  String get settingsNarratorLanguage => 'Sprache des Erzählers';

  @override
  String get runoffTitle => 'Stichwahl';

  @override
  String runoffPrompt(String names) {
    return 'Gleichstand! Stimmt noch einmal ab, nur zwischen: $names';
  }

  @override
  String get narrateRunoff => 'Gleichstand. Jetzt entscheidet eine Stichwahl.';

  @override
  String get ghostHold => 'Geisterblick: gedrückt halten';

  @override
  String get ghostHint =>
      'Als Geist siehst du mehr als die Lebenden. Verrate nichts.';

  @override
  String get ghostRoles => 'Wer ist wer';

  @override
  String ghostLovers(String a, String b) {
    return 'Verliebt: $a und $b';
  }

  @override
  String get ghostTonight => 'Heute Nacht';

  @override
  String ghostPick(String who, String whom) {
    return '$who → $whom';
  }

  @override
  String ghostVictim(String name) {
    return 'Opfer des Rudels: $name';
  }

  @override
  String ghostSeen(String name, String what) {
    return 'Die Seherin sah $name: $what';
  }

  @override
  String ghostPotions(String potions) {
    return 'Benutzte Tränke: $potions';
  }

  @override
  String get potionHeal => 'Heiltrank';

  @override
  String get potionPoison => 'Gift';

  @override
  String get ghostVotes => 'Stimmen';

  @override
  String get ghostNothingYet => 'Noch ist nichts passiert.';

  @override
  String get settingsGhosts => 'Was die Toten sehen';

  @override
  String get ghostsOff => 'Nichts';

  @override
  String get ghostsRoles => 'Rollen';

  @override
  String get ghostsEverything => 'Alles';

  @override
  String get settingsGhostsHint =>
      'Erst wenn sie nichts mehr zu tun haben, und nur solange ein Knopf gedrückt ist.';

  @override
  String get settingsRunoff => 'Stichwahl bei Gleichstand (sonst geht niemand)';

  @override
  String get extraGhosts => 'Geister schauen zu';

  @override
  String get extraRunoff => 'Stichwahl bei Gleichstand';

  @override
  String get eyebrowEvening => 'Spielabend';

  @override
  String get eyebrowYourRole => 'Nur für dich';

  @override
  String eyebrowNight(String round) {
    return 'Nacht $round';
  }

  @override
  String get eyebrowAwake => 'Nur du bist wach';

  @override
  String eyebrowDay(String round) {
    return 'Tag $round';
  }

  @override
  String get eyebrowVote => 'Die Abstimmung';

  @override
  String get eyebrowTie => 'Gleichstand';

  @override
  String get eyebrowLastShot => 'Der letzte Schuss';

  @override
  String get eyebrowEnd => 'Die Vorstellung ist aus';

  @override
  String get eyebrowNarrator => 'Der Erzähler';

  @override
  String get dayTalkTitle => 'Redet miteinander';

  @override
  String get voteQuestion => 'Wen verdächtigst du?';

  @override
  String get hunterQuestion => 'Wen nimmst du mit?';

  @override
  String get introTitle => 'Hört gut zu';

  @override
  String get eyesClosedTitle => 'Augen zu';

  @override
  String get comeJoinTitle => 'Komm dazu';

  @override
  String get howTitle => 'So geht\'s';

  @override
  String get howEyebrow => 'Vorhang auf';

  @override
  String get howLink => 'So geht\'s';

  @override
  String get how1Title => 'Raum öffnen';

  @override
  String get how1Text =>
      'Einer öffnet auf seinem Handy einen Raum. Die anderen scannen den QR-Code und sind dabei. Ihr sitzt zusammen am Tisch, im selben WLAN.';

  @override
  String get how2Title => 'Geheime Rolle';

  @override
  String get how2Text =>
      'Jeder sucht sich eine Figur aus und bekommt eine geheime Rolle. Die meisten sind Dorfbewohner, ein paar sind Werwölfe. Zeig dein Handy niemandem.';

  @override
  String get how3Title => 'Die Nacht';

  @override
  String get how3Text =>
      'Alle schließen die Augen. Der Erzähler weckt die Werwölfe: Sie sehen, wer noch zum Rudel gehört, und wählen auf dem Handy ein Opfer.';

  @override
  String get how4Title => 'Besondere Rollen';

  @override
  String get how4Text =>
      'Danach wacht die Seherin auf und erfährt die Rolle eines Mitspielers. Die Hexe kann mit ihren Tränken einmal retten und einmal vergiften.';

  @override
  String get how5Title => 'Der Morgen';

  @override
  String get how5Text =>
      'Alle öffnen die Augen, und die App verrät, wen es erwischt hat. Wer raus ist, redet nicht mehr mit, darf aber zuschauen.';

  @override
  String get how6Title => 'Reden';

  @override
  String get how6Text =>
      'Jetzt wird diskutiert: Wer war verdächtig? Die Werwölfe tun harmlos und lügen, das Dorf versucht, sie zu entlarven.';

  @override
  String get how7Title => 'Abstimmen';

  @override
  String get how7Text =>
      'Jeder stimmt geheim auf seinem Handy ab. Wer die meisten Stimmen hat, verlässt das Dorf. Dann kommt die nächste Nacht.';

  @override
  String get how8Title => 'Wer gewinnt';

  @override
  String get how8Text =>
      'Das Dorf gewinnt, sobald alle Werwölfe gefunden sind. Die Werwölfe gewinnen, wenn sie so viele sind wie alle anderen.';

  @override
  String get howPhaseSetup => 'Vorbereitung';

  @override
  String get howPhaseNight => 'Nacht';

  @override
  String get howPhaseMorning => 'Morgen';

  @override
  String get howPhaseDay => 'Tag';

  @override
  String get howPhaseEnd => 'Ende';

  @override
  String get howDone => 'Verstanden';

  @override
  String get pagePlay => 'Spielen';

  @override
  String get pageAbout => 'Über';

  @override
  String get pageTable => 'Tisch';

  @override
  String get pageInvite => 'Einladen';

  @override
  String get pageGame => 'Spiel';

  @override
  String get act1 => 'Vorspiel';

  @override
  String get act2 => 'Erster Akt';

  @override
  String get act3 => 'Zweiter Akt';

  @override
  String get act4 => 'Dritter Akt';

  @override
  String get act5 => 'Finale';

  @override
  String get pageSettings => 'Einstellungen';

  @override
  String get pageFigure => 'Figur';

  @override
  String get figureTitle => 'Wer bist du heute?';

  @override
  String get figureTaken => 'vergeben';

  @override
  String quickJoin(String name) {
    return 'Tisch von $name beitreten';
  }

  @override
  String get roomGone => 'Dieser Raum ist nicht mehr offen.';

  @override
  String get quickJoinLast => 'Dein letzter Tisch';

  @override
  String get settingsOnline => 'Online-Spiel';

  @override
  String get settingsAbout => 'Über Whowolf';

  @override
  String get settingsSaved => 'Gespeichert';

  @override
  String get settingsStage => 'Bühne & Akku';

  @override
  String get motionFull => 'Volle Bühne';

  @override
  String get motionFullHint =>
      'Flackernde Lichter, ziehender Nebel, eine Kulisse, die der Neigung des Handys folgt, wippende Figuren. Am schönsten, kostet aber am meisten Akku.';

  @override
  String get motionCalm => 'Akku sparen';

  @override
  String get motionCalmHint =>
      'Die Bühne steht still und bewegt sich nur, wenn etwas passiert: Karten drehen sich, der Vorhang fällt. Kein Neigungssensor. Gut für einen langen Abend.';

  @override
  String get motionStill => 'Ruhig';

  @override
  String get motionStillHint =>
      'Gar nichts bewegt sich, wie bei „Bewegung reduzieren“ im System. Braucht am wenigsten Akku.';

  @override
  String get motionMenu => 'Bühne & Akku';
}
