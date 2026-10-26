// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'Werewolf at the table. Everyone on their own phone.';

  @override
  String devStamp(String version) {
    return 'Test version · $version';
  }

  @override
  String get testNote =>
      'Early test version: play in your own Wi-Fi with people you trust.';

  @override
  String get nameLabel => 'Your name';

  @override
  String get createRoom => 'Open a room';

  @override
  String get joinRoom => 'Join a room';

  @override
  String get nameRequired => 'Enter your name first.';

  @override
  String get joinTitle => 'Join a room';

  @override
  String get hostAddress => 'Host address';

  @override
  String get roomCode => 'Room code';

  @override
  String get connect => 'Join';

  @override
  String get joinHelp =>
      'The phone that opened the room shows its address and code. Everyone must be in the same Wi-Fi.';

  @override
  String get connectFailed =>
      'Could not reach the host. Same Wi-Fi? Address right?';

  @override
  String get hostFailed => 'Could not open a room on this device.';

  @override
  String get byeWrongRoom => 'The room code is wrong.';

  @override
  String get byeGameRunning => 'This game has already started.';

  @override
  String get byeUnknownSession => 'The host no longer knows you.';

  @override
  String get byeRefused => 'The host refused: name taken or room full.';

  @override
  String get byeKicked => 'The host removed you from the room.';

  @override
  String get byeLeft => 'You left the room.';

  @override
  String get byeReplaced => 'You joined again from another device.';

  @override
  String get byeClosed => 'The host closed the room.';

  @override
  String get byeMisbehaved => 'The connection was ended.';

  @override
  String get byeLost => 'The connection to the host is lost.';

  @override
  String get backToStart => 'Back to start';

  @override
  String get lobbyTitle => 'Lobby';

  @override
  String get lobbyJoinHint => 'Others tap “Join a room” and enter:';

  @override
  String players(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String get startGame => 'Deal the roles';

  @override
  String needPlayers(int count) {
    return 'At least $count players needed.';
  }

  @override
  String get fewPlayersHint => 'It really gets fun from 5 players.';

  @override
  String rolesInGame(String roles) {
    return 'In this game: $roles';
  }

  @override
  String get waitingForOwner => 'Waiting for the host to start …';

  @override
  String get kick => 'Remove';

  @override
  String get you => 'you';

  @override
  String get owner => 'host';

  @override
  String get leave => 'Leave';

  @override
  String get leaveTitle => 'Leave the game?';

  @override
  String get leaveOwner =>
      'You are the host: another player takes over the table and the game goes on without you. If nobody can, the room closes for everyone.';

  @override
  String get leavePlayer => 'You can come back as long as the app stays open.';

  @override
  String get cancel => 'Cancel';

  @override
  String get roleVillager => 'Villager';

  @override
  String get roleWerewolf => 'Werewolf';

  @override
  String get roleSeer => 'Seer';

  @override
  String get roleVillagerText =>
      'No special gift. Watch, listen, and vote the werewolves out.';

  @override
  String get roleWerewolfText =>
      'At night you pick a victim with your pack. By day you look like everyone else.';

  @override
  String get roleSeerText =>
      'Each night you look into one player and learn who they are.';

  @override
  String get factionVillage => 'Village';

  @override
  String get factionWerewolves => 'Werewolves';

  @override
  String get revealTitle => 'Your role';

  @override
  String get revealTap => 'Tap to see your role. Nobody may look.';

  @override
  String pack(String names) {
    return 'Your pack: $names';
  }

  @override
  String get confirmRole => 'Got it';

  @override
  String waitingFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Waiting for $count players …',
      one: 'Waiting for 1 player …',
      zero: 'Everyone is ready.',
    );
    return '$_temp0';
  }

  @override
  String nightTitle(int round) {
    return 'Night $round';
  }

  @override
  String get nightHunt => 'Whom does the pack take tonight?';

  @override
  String get nightInspect => 'Whose soul do you look into?';

  @override
  String get nightDecoy => 'Whom do you trust the least?';

  @override
  String get nightHint => 'Everyone taps at night, so nobody stands out.';

  @override
  String picked(String name) {
    return 'You picked $name.';
  }

  @override
  String seerSaw(String name, String what) {
    return '$name is: $what';
  }

  @override
  String packPick(String name) {
    return '→ $name';
  }

  @override
  String get youAreDead => 'You are dead. Stay quiet and watch.';

  @override
  String timeLeft(int seconds) {
    return '$seconds s left';
  }

  @override
  String dayTitle(int round) {
    return 'Day $round';
  }

  @override
  String killedAtNight(String name) {
    return '$name did not wake up.';
  }

  @override
  String get nobodyDied => 'Everyone woke up. Nobody died tonight.';

  @override
  String roleWas(String role) {
    return 'Role: $role';
  }

  @override
  String get discuss => 'Talk it out at the table. Phones down!';

  @override
  String get startVote => 'Start the vote';

  @override
  String get ownerStartsVote => 'The host starts the vote when you are done.';

  @override
  String get voteTitle => 'Vote';

  @override
  String get votePrompt => 'Who is a werewolf?';

  @override
  String get abstain => 'Abstain';

  @override
  String votedFor(String name) {
    return 'Your vote: $name';
  }

  @override
  String get abstained => 'You abstain.';

  @override
  String eliminated(String name) {
    return 'The village voted out $name.';
  }

  @override
  String get nobodyEliminated => 'Nobody was voted out.';

  @override
  String get villageWins => 'The village wins!';

  @override
  String get werewolvesWin => 'The werewolves win!';

  @override
  String get everyRole => 'Who was who';

  @override
  String get playAgain => 'Play again';

  @override
  String get dead => 'dead';

  @override
  String get refused => 'That is not possible right now.';

  @override
  String get scanQr => 'Scan QR code';

  @override
  String get scanTitle => 'Scan the room code';

  @override
  String get scanInvalid => 'That is not a Whowolf room code.';

  @override
  String joinConfirmTitle(String room) {
    return 'Join room $room?';
  }

  @override
  String joinConfirmLan(String address) {
    return 'In the Wi-Fi: $address';
  }

  @override
  String joinConfirmOnline(String server) {
    return 'Online via $server';
  }

  @override
  String get joinLan => 'In the Wi-Fi';

  @override
  String get joinOnline => 'Online';

  @override
  String get onlineCode => 'Online code';

  @override
  String get noRelayServer =>
      'No server set up for online games. Add one in the settings.';

  @override
  String resume(String room) {
    return 'Back to the game (room $room)';
  }

  @override
  String get settings => 'Settings';

  @override
  String get relayServer => 'Server for online players';

  @override
  String get relayServerHelp =>
      'Leave empty for the official server (play.whowolf.de). It only forwards encrypted messages. Own server: see the docs.';

  @override
  String get save => 'Save';

  @override
  String get invalidServer => 'Use an address starting with ws:// or wss://.';

  @override
  String get scanHint => 'Or scan this code with the Whowolf app:';

  @override
  String get relayFailed => 'The online server is not reachable: Wi-Fi only.';

  @override
  String get nameTaken =>
      'This name is already taken at the table. Pick another one:';

  @override
  String get narrateReveal =>
      'The roles are dealt. Look at yours, and let nobody look over your shoulder.';

  @override
  String get narrateNight =>
      'Night falls over the village. Everyone close your eyes … and tap on your phone.';

  @override
  String get narrateMorning => 'The sun rises over the village.';

  @override
  String get narrateDiscuss => 'Now talk: who is the werewolf?';

  @override
  String get narrateVote => 'Enough talk. Cast your votes now.';

  @override
  String narrateRole(String role) {
    return 'They were: $role.';
  }

  @override
  String get mute => 'Narrator voice off';

  @override
  String get unmute => 'Narrator voice on';

  @override
  String get nightSheep =>
      'Count sheep until morning: tap the white ones, let the black ones jump.';

  @override
  String dreamPoints(int points) {
    return '$points dream points';
  }

  @override
  String get sheepWhileWaiting => 'Until morning: count sheep.';

  @override
  String get sleepTitle => 'How well did you sleep?';

  @override
  String sheepCount(int count) {
    return '$count sheep';
  }

  @override
  String bestDreamer(String name, int points) {
    return 'Best dreamer: $name ($points dream points)';
  }

  @override
  String get youAppearAs => 'You appear as';

  @override
  String get changePersona => 'Choose your figure';

  @override
  String get personaHint =>
      'Your figure is only your look. Your role stays secret and is dealt by chance.';

  @override
  String get inviteTitle => 'Get the others in';

  @override
  String get inviteHint =>
      'The others open Whowolf and tap “Join a room”: your room shows up by itself. Or they scan this code.';

  @override
  String get connectionDetails => 'Connection details';

  @override
  String get nearbyTitle => 'Rooms nearby';

  @override
  String get searching => 'Looking for rooms in your Wi-Fi …';

  @override
  String roomOf(String host) {
    return '$host’s room';
  }

  @override
  String get noDiscovery =>
      'Searching does not work on this device. Scan the QR code instead.';

  @override
  String get manualJoin => 'Connect by hand';

  @override
  String get tableHint =>
      'This is how you sit at the table, seen from your seat. Is the order right? The host can swap seats.';

  @override
  String get swapSeat => 'Swap seats';

  @override
  String swapHint(String name) {
    return 'Now tap the seat $name should swap with.';
  }

  @override
  String get helpTitle => 'Can’t find each other?';

  @override
  String get helpLink => 'Room not showing up? Help';

  @override
  String get helpSameWifi =>
      'Everyone in the same Wi-Fi: check that no phone is on mobile data or a different network.';

  @override
  String get helpGuest =>
      'Guest Wi-Fi or hotel networks often keep devices apart. Open a hotspot on the host phone and let everyone join it.';

  @override
  String get helpIos =>
      'iPhone/iPad: Settings › Privacy & Security › Local Network: switch Whowolf on.';

  @override
  String get helpAndroid =>
      'Android: turn off battery saving for Whowolf so it stays connected.';

  @override
  String get helpMac =>
      'Mac: when asked “Accept incoming network connections?”, choose Allow (System Settings › Network › Firewall).';

  @override
  String get helpWindows =>
      'Windows: when the firewall asks, allow Whowolf on private networks.';

  @override
  String get helpVpn =>
      'Switch off VPNs and ad blockers that filter the local network.';

  @override
  String get helpQr =>
      'Still nothing? Scan the QR code on the host phone instead.';

  @override
  String get restoreRoom => 'Restore your room';

  @override
  String get waitingForHost => 'Almost in! Show the host these symbols:';

  @override
  String get waitingHint =>
      'The host lets you in as soon as the symbols match.';

  @override
  String wantsToJoin(String name) {
    return '$name wants to join';
  }

  @override
  String get compareSymbols =>
      'Do these symbols match the ones on their phone?';

  @override
  String get letIn => 'Let in';

  @override
  String get refuse => 'Refuse';

  @override
  String get pauseTitle => 'A short pause';

  @override
  String get pauseText =>
      'The narrator is catching their breath … The game goes on in a moment, nothing is lost.';

  @override
  String get pauseLeave => 'Leave the game';

  @override
  String roomOpenNotice(String room) {
    return 'Room $room is open';
  }

  @override
  String get keepAppOpenHint =>
      'You are hosting this room: please keep Whowolf open while you play. If you switch apps for a moment, the game simply carries on when you come back.';

  @override
  String get roleWitch => 'Witch';

  @override
  String get roleHunter => 'Hunter';

  @override
  String get roleCupid => 'Cupid';

  @override
  String get roleWitchText =>
      'You have one healing potion and one poison, each for one use. At night you see whom the werewolves take, and decide after them.';

  @override
  String get roleHunterText =>
      'If you fall, at night or by the vote, you take someone with you at once.';

  @override
  String get roleCupidText =>
      'In the first night you bind two people as lovers. If one of them dies, so does the other.';

  @override
  String get factionLovers => 'Lovers';

  @override
  String get nightLink =>
      'Whom do you bind as lovers? Pick two (you may pick yourself).';

  @override
  String get linkConfirm => 'Bind them';

  @override
  String linked(String first, String second) {
    return '$first and $second are lovers now.';
  }

  @override
  String get nightBrew => 'The werewolves have chosen. What do you brew?';

  @override
  String brewVictim(String name) {
    return 'Tonight the werewolves take $name.';
  }

  @override
  String get brewNoVictim => 'Tonight the werewolves take nobody.';

  @override
  String brewHeal(String name) {
    return 'Healing potion for $name';
  }

  @override
  String get brewPoison => 'Poison: tap someone (tap again to take it back).';

  @override
  String get brewDone => 'Done';

  @override
  String get brewNothing => 'Brew nothing';

  @override
  String get brewEmpty => 'Your potions are used up.';

  @override
  String get brewSent => 'You have decided. Sheep until the morning?';

  @override
  String get hunterYou => 'You have fallen. Whom do you take with you?';

  @override
  String get hunterSpare => 'Nobody';

  @override
  String hunterWait(String name) {
    return '$name was the hunter and takes aim …';
  }

  @override
  String diedOfGrief(String name) {
    return '$name dies of grief.';
  }

  @override
  String shotByHunter(String name) {
    return 'The hunter takes $name along.';
  }

  @override
  String inLove(String name) {
    return 'You are in love with $name. If one of you dies, so does the other.';
  }

  @override
  String yourCouple(String first, String second) {
    return 'Your lovers: $first and $second.';
  }

  @override
  String get loversWin => 'The lovers win!';

  @override
  String get narrateHunter => 'The hunter has fallen and takes aim …';

  @override
  String get settingsButton => 'Game settings';

  @override
  String get settingsTitle => 'Game settings';

  @override
  String get presetClassic => 'Classic';

  @override
  String get presetClassicText =>
      'Werewolf as you know it: everyone closes their eyes, the narrator calls the roles, and only whoever is called picks up their phone. The app narrates aloud and counts the votes.';

  @override
  String get presetWhowolf => 'Whowolf';

  @override
  String get presetWhowolfText =>
      'Plus counting sheep with the morning score, and atmosphere.';

  @override
  String get presetFullStage => 'Full stage';

  @override
  String get presetFullStageText =>
      'Everything there is, with Cupid and the wolf trail.';

  @override
  String get presetCustom => 'Your own mix';

  @override
  String get settingsRoles => 'Roles';

  @override
  String get settingsWolves => 'Werewolves';

  @override
  String wolvesSuggested(int count) {
    return 'Suggested ($count)';
  }

  @override
  String get settingsTimes => 'Times';

  @override
  String get timeNight => 'Night';

  @override
  String get timeDay => 'Discussion';

  @override
  String get timeVote => 'Vote';

  @override
  String seconds(int count) {
    return '$count s';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get settingsRules => 'Rules';

  @override
  String get settingsRevealRoles => 'Reveal roles of the dead';

  @override
  String get settingsSeerRole => 'Seer sees the role (otherwise only the side)';

  @override
  String get settingsExtras => 'Whowolf extras';

  @override
  String get settingsSheep => 'Counting sheep at night';

  @override
  String get settingsSheepOff =>
      'Without sheep, everyone answers a plain question at night, so tapping gives nobody away.';

  @override
  String get settingsWolfTrail => 'Wolf trail (after the first release)';

  @override
  String get settingsAtmosphere => 'Night sounds and the morning yawn';

  @override
  String get settingsPersonas => 'Players choose their figure';

  @override
  String get settingsVoice => 'Narrator voice on the host device';

  @override
  String tooManyRoles(int count) {
    return 'For $count players these are too many roles.';
  }

  @override
  String get presetBasic => 'Basic game';

  @override
  String get nightTaskDone => 'Your night task is done.';

  @override
  String get nightTaskShow => 'Show';

  @override
  String get nightTaskHide => 'Fold away';

  @override
  String get nightNothingToDo =>
      'Nothing else to do tonight: count sheep until the morning.';

  @override
  String get ownCount => 'Set the number yourself';

  @override
  String get ownCountTitle => 'How many sheep did you count?';

  @override
  String get ownCountHint =>
      'Everyone may do this, so fibbing is allowed. In the morning everyone sees the numbers.';

  @override
  String get ownCountSet => 'Take it';

  @override
  String get persona_maid => 'Maid';

  @override
  String get persona_farmer => 'Farmer';

  @override
  String get persona_baker => 'Baker';

  @override
  String get persona_smith => 'Smith';

  @override
  String get persona_fisher => 'Fisher';

  @override
  String get persona_miller => 'Miller';

  @override
  String get persona_seamstress => 'Seamstress';

  @override
  String get persona_minstrel => 'Minstrel';

  @override
  String get persona_gooseGirl => 'Goose girl';

  @override
  String get persona_beekeeper => 'Beekeeper';

  @override
  String get persona_innkeeper => 'Innkeeper';

  @override
  String get persona_shepherd => 'Shepherd';

  @override
  String get persona_washerwoman => 'Washerwoman';

  @override
  String get persona_carpenter => 'Carpenter';

  @override
  String get persona_spinner => 'Spinner';

  @override
  String get persona_cobbler => 'Cobbler';

  @override
  String get persona_flowerGirl => 'Flower girl';

  @override
  String get persona_mayor => 'Mayor';

  @override
  String get persona_grandmother => 'Grandmother';

  @override
  String get persona_grandfather => 'Grandfather';

  @override
  String get doorSignTitle => 'Your door sign tonight';

  @override
  String get doorSignHint =>
      'Let nobody look at your screen: a werewolf who knows your sign has a chance to come for you tonight.';

  @override
  String get markTitle => 'Spotted a door sign?';

  @override
  String get markHint =>
      'Once a night the pack may try one. If it is right, that person may die tonight as well (about one in two).';

  @override
  String markSymbol(int number) {
    return 'Symbol $number';
  }

  @override
  String get markTry => 'Try the sign';

  @override
  String markRight(String name) {
    return 'The sign of $name was right. Maybe the pack gets them tonight.';
  }

  @override
  String markWrong(String name) {
    return 'The sign of $name was wrong. Next night brings new signs.';
  }

  @override
  String get settingsDoorSigns =>
      'Door signs (peeking at screens can cost a life)';

  @override
  String get codeConfirmHint =>
      'Does the host\'s screen ask about you with exactly these symbols? Only then is it really the host. If the host sees no request from you, do not confirm.';

  @override
  String get codeConfirm => 'The host sees the same symbols';

  @override
  String get narrateNightCalled =>
      'Night falls over the village. Everyone close your eyes.';

  @override
  String get narrateStepLink => 'Cupid wakes up and binds two people in love.';

  @override
  String get narrateStepHunt => 'The werewolves wake up and choose a victim.';

  @override
  String get narrateStepInspect =>
      'The seer wakes up and looks into someone\'s soul.';

  @override
  String get narrateStepBrew =>
      'The witch wakes up. She sees who is to die tonight and reaches for her potions.';

  @override
  String get narrateStepSleep => 'Eyes closed again.';

  @override
  String get nightEyesClosed => 'Eyes closed';

  @override
  String get nightEyesClosedHint =>
      'Put your phone down until the narrator wakes you.';

  @override
  String nightAwakeNow(String who) {
    return 'Awake now: $who';
  }

  @override
  String get nightWerewolves => 'the werewolves';

  @override
  String get nightYourTurn => 'Your turn. Eyes open!';

  @override
  String get settingsNight => 'The night';

  @override
  String get settingsNightCalled => 'The narrator calls the roles';

  @override
  String get settingsNightCalledHint =>
      'Werewolf as you know it: everyone closes their eyes, and only whoever is called picks up their phone. No sheep and no door signs then.';

  @override
  String get settingsNightTogether => 'Everyone taps at once';

  @override
  String get settingsNightTogetherHint =>
      'Whowolf\'s night: phones stay in hand, and the tapping gives nobody away.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyNoticeTitle => 'A word on privacy';

  @override
  String get privacyNotice =>
      'Whowolf has no accounts, no ads and no tracking. At the table, game data travels end-to-end encrypted between your devices only. So that players without a shared Wi-Fi can join, the host\'s device connects to the server play.whowolf.de; it only forwards encrypted data and, like any server, sees the IP addresses. You can switch it off in the settings.';

  @override
  String get privacyRead => 'Read the privacy notice';

  @override
  String get privacyOk => 'Got it';

  @override
  String get relayOff => 'No online server (Wi-Fi only)';

  @override
  String get relayOffHint =>
      'Then only devices in the same Wi-Fi can play, and nothing goes to a server.';

  @override
  String get relayCustomHint =>
      'With your own server, its operator is responsible for it and sees the IP addresses of the connected devices.';

  @override
  String get privacyTitle => 'Privacy in the app';

  @override
  String get privacyUpdated => 'Last updated: 26 October 2026';

  @override
  String get privacySummaryTitle => 'In short';

  @override
  String get privacySummary =>
      'No accounts, no ads, no tracking, no analytics. The app keeps nothing about you on a server.';

  @override
  String get privacyTableTitle => 'At the table';

  @override
  String get privacyTable =>
      'Game data travels only between the devices at the table, end-to-end encrypted. So that others find the room, the host\'s device announces it in the local network (room code, the host\'s name, a mark of its key); only devices in the same Wi-Fi see it.';

  @override
  String get privacyServerTitle => 'The online server';

  @override
  String get privacyServer =>
      'So that players without a shared Wi-Fi can join, the host\'s device connects to play.whowolf.de, run by the project owner (see the imprint on whowolf.de). The server only forwards end-to-end encrypted data and can read neither names nor roles nor moves. It necessarily processes the IP addresses of the connected devices, in memory only and only while connected, to forward messages and to limit abuse; they are neither stored nor logged. The legal basis is our legitimate interest in providing the game you asked for and protecting the server (Art. 6(1)(f) GDPR). In the settings you can switch the server off or enter your own; its operator is then responsible.';

  @override
  String get privacyDeviceTitle => 'On your device';

  @override
  String get privacyDevice =>
      'Your name and a session key for rejoining are kept in your device\'s protected storage (12 hours at most). The host\'s device keeps the game state until the room closes. None of it leaves your device except encrypted, for the game.';

  @override
  String get privacyRightsTitle => 'Your rights';

  @override
  String get privacyRights =>
      'You have the right to access, rectification, erasure and restriction of processing, to data portability and to object (Art. 15 to 21 GDPR), and you may complain to a data protection authority (Art. 77 GDPR). As the server stores nothing, there is no stored data about you. The full version is on whowolf.de.';

  @override
  String get lobbyNightCalled =>
      'At night the narrator calls the roles; everyone else keeps their eyes closed.';

  @override
  String get lobbyNightTogether =>
      'At night everyone taps at once, so nobody stands out.';

  @override
  String lobbyExtras(String list) {
    return 'Plus: $list';
  }

  @override
  String get extraVoice => 'narrator\'s voice';

  @override
  String get extraSheep => 'counting sheep';

  @override
  String get extraDoorSigns => 'door signs';

  @override
  String get extraAtmosphere => 'night sounds';

  @override
  String get extraPersonas => 'free choice of figures';

  @override
  String get webJoinTitle => 'Play in the browser';

  @override
  String get webJoinHint =>
      'No app needed: enter your name and take your seat at the table.';

  @override
  String get webJoinNoLink =>
      'Scan the QR code at the table with your phone\'s camera to continue here.';

  @override
  String get webJoinButton => 'Join';

  @override
  String get webJoinApp => 'The app can do even more: whowolf.de';

  @override
  String get inviteHintWeb =>
      'Scan the code with the Whowolf app, or without the app with your phone\'s camera to play in the browser.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Like the system';
}
