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
  String get reconnecting => 'Connection lost, reconnecting …';

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
  String get leaveOwner => 'You are the host: the room closes for everyone.';

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
      'Leave empty to use the official server once it exists. Own server: docker compose up -d, see the docs.';

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
  String yourDreamPoints(int points) {
    return 'Your dream points: $points';
  }
}
