import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Werewolf at the table. Everyone on their own phone.'**
  String get tagline;

  /// No description provided for @devStamp.
  ///
  /// In en, this message translates to:
  /// **'Test version · {version}'**
  String devStamp(String version);

  /// No description provided for @testNote.
  ///
  /// In en, this message translates to:
  /// **'Early test version: play in your own Wi-Fi with people you trust.'**
  String get testNote;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Open a room'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join a room'**
  String get joinRoom;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name first.'**
  String get nameRequired;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a room'**
  String get joinTitle;

  /// No description provided for @hostAddress.
  ///
  /// In en, this message translates to:
  /// **'Host address'**
  String get hostAddress;

  /// No description provided for @roomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get roomCode;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get connect;

  /// No description provided for @joinHelp.
  ///
  /// In en, this message translates to:
  /// **'The phone that opened the room shows its address and code. Everyone must be in the same Wi-Fi.'**
  String get joinHelp;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the host. Same Wi-Fi? Address right?'**
  String get connectFailed;

  /// No description provided for @hostFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open a room on this device.'**
  String get hostFailed;

  /// No description provided for @byeWrongRoom.
  ///
  /// In en, this message translates to:
  /// **'The room code is wrong.'**
  String get byeWrongRoom;

  /// No description provided for @byeGameRunning.
  ///
  /// In en, this message translates to:
  /// **'This game has already started.'**
  String get byeGameRunning;

  /// No description provided for @byeUnknownSession.
  ///
  /// In en, this message translates to:
  /// **'The host no longer knows you.'**
  String get byeUnknownSession;

  /// No description provided for @byeRefused.
  ///
  /// In en, this message translates to:
  /// **'The host refused: name taken or room full.'**
  String get byeRefused;

  /// No description provided for @byeKicked.
  ///
  /// In en, this message translates to:
  /// **'The host removed you from the room.'**
  String get byeKicked;

  /// No description provided for @byeLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the room.'**
  String get byeLeft;

  /// No description provided for @byeReplaced.
  ///
  /// In en, this message translates to:
  /// **'You joined again from another device.'**
  String get byeReplaced;

  /// No description provided for @byeClosed.
  ///
  /// In en, this message translates to:
  /// **'The host closed the room.'**
  String get byeClosed;

  /// No description provided for @byeMisbehaved.
  ///
  /// In en, this message translates to:
  /// **'The connection was ended.'**
  String get byeMisbehaved;

  /// No description provided for @byeLost.
  ///
  /// In en, this message translates to:
  /// **'The connection to the host is lost.'**
  String get byeLost;

  /// No description provided for @backToStart.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get backToStart;

  /// No description provided for @lobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'The table fills up'**
  String get lobbyTitle;

  /// No description provided for @lobbyJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Others tap “Join a room” and enter:'**
  String get lobbyJoinHint;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 player} other{{count} players}}'**
  String players(int count);

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Deal the roles'**
  String get startGame;

  /// No description provided for @needPlayers.
  ///
  /// In en, this message translates to:
  /// **'At least {count} players needed.'**
  String needPlayers(int count);

  /// No description provided for @fewPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'It really gets fun from 5 players.'**
  String get fewPlayersHint;

  /// No description provided for @rolesInGame.
  ///
  /// In en, this message translates to:
  /// **'In this game: {roles}'**
  String rolesInGame(String roles);

  /// No description provided for @waitingForOwner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start …'**
  String get waitingForOwner;

  /// No description provided for @kick.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get kick;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get you;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'host'**
  String get owner;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the game?'**
  String get leaveTitle;

  /// No description provided for @leaveOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the host: another player takes over the table and the game goes on without you. If nobody can, the room closes for everyone.'**
  String get leaveOwner;

  /// No description provided for @leavePlayer.
  ///
  /// In en, this message translates to:
  /// **'You can come back as long as the app stays open.'**
  String get leavePlayer;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @roleVillager.
  ///
  /// In en, this message translates to:
  /// **'Villager'**
  String get roleVillager;

  /// No description provided for @roleWerewolf.
  ///
  /// In en, this message translates to:
  /// **'Werewolf'**
  String get roleWerewolf;

  /// No description provided for @roleSeer.
  ///
  /// In en, this message translates to:
  /// **'Seer'**
  String get roleSeer;

  /// No description provided for @roleVillagerText.
  ///
  /// In en, this message translates to:
  /// **'No special gift. Watch, listen, and vote the werewolves out.'**
  String get roleVillagerText;

  /// No description provided for @roleWerewolfText.
  ///
  /// In en, this message translates to:
  /// **'At night you pick a victim with your pack. By day you look like everyone else.'**
  String get roleWerewolfText;

  /// No description provided for @roleSeerText.
  ///
  /// In en, this message translates to:
  /// **'Each night you look into one player and learn who they are.'**
  String get roleSeerText;

  /// No description provided for @factionVillage.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get factionVillage;

  /// No description provided for @factionWerewolves.
  ///
  /// In en, this message translates to:
  /// **'Werewolves'**
  String get factionWerewolves;

  /// No description provided for @revealTitle.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get revealTitle;

  /// No description provided for @revealTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to see your role. Nobody may look.'**
  String get revealTap;

  /// No description provided for @introListening.
  ///
  /// In en, this message translates to:
  /// **'Listen: the narrator takes you into the village. Then you will see your roles.'**
  String get introListening;

  /// No description provided for @introSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip the intro'**
  String get introSkip;

  /// No description provided for @pack.
  ///
  /// In en, this message translates to:
  /// **'Your pack: {names}'**
  String pack(String names);

  /// No description provided for @confirmRole.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get confirmRole;

  /// No description provided for @waitingFor.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everyone is ready.} =1{Waiting for 1 player …} other{Waiting for {count} players …}}'**
  String waitingFor(int count);

  /// No description provided for @nightTitle.
  ///
  /// In en, this message translates to:
  /// **'Night {round}'**
  String nightTitle(int round);

  /// No description provided for @nightHunt.
  ///
  /// In en, this message translates to:
  /// **'Whom does the pack take tonight?'**
  String get nightHunt;

  /// No description provided for @nightInspect.
  ///
  /// In en, this message translates to:
  /// **'Whose soul do you look into?'**
  String get nightInspect;

  /// No description provided for @nightDecoy.
  ///
  /// In en, this message translates to:
  /// **'Whom do you trust the least?'**
  String get nightDecoy;

  /// No description provided for @nightHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone taps at night, so nobody stands out.'**
  String get nightHint;

  /// No description provided for @picked.
  ///
  /// In en, this message translates to:
  /// **'You picked {name}.'**
  String picked(String name);

  /// No description provided for @seerSaw.
  ///
  /// In en, this message translates to:
  /// **'{name} is: {what}'**
  String seerSaw(String name, String what);

  /// No description provided for @packPick.
  ///
  /// In en, this message translates to:
  /// **'→ {name}'**
  String packPick(String name);

  /// No description provided for @youAreDead.
  ///
  /// In en, this message translates to:
  /// **'You are dead. Stay quiet and watch.'**
  String get youAreDead;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left'**
  String timeLeft(int seconds);

  /// No description provided for @dayTitle.
  ///
  /// In en, this message translates to:
  /// **'Day {round}'**
  String dayTitle(int round);

  /// No description provided for @killedAtNight.
  ///
  /// In en, this message translates to:
  /// **'{name} did not wake up.'**
  String killedAtNight(String name);

  /// No description provided for @nobodyDied.
  ///
  /// In en, this message translates to:
  /// **'Everyone woke up. Nobody died tonight.'**
  String get nobodyDied;

  /// No description provided for @roleWas.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String roleWas(String role);

  /// No description provided for @discuss.
  ///
  /// In en, this message translates to:
  /// **'Talk it out at the table. Phones down!'**
  String get discuss;

  /// No description provided for @startVote.
  ///
  /// In en, this message translates to:
  /// **'Start the vote'**
  String get startVote;

  /// No description provided for @ownerStartsVote.
  ///
  /// In en, this message translates to:
  /// **'The host starts the vote when you are done.'**
  String get ownerStartsVote;

  /// No description provided for @voteTitle.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get voteTitle;

  /// No description provided for @votePrompt.
  ///
  /// In en, this message translates to:
  /// **'Who is a werewolf?'**
  String get votePrompt;

  /// No description provided for @abstain.
  ///
  /// In en, this message translates to:
  /// **'Abstain'**
  String get abstain;

  /// No description provided for @votedFor.
  ///
  /// In en, this message translates to:
  /// **'Your vote: {name}'**
  String votedFor(String name);

  /// No description provided for @abstained.
  ///
  /// In en, this message translates to:
  /// **'You abstain.'**
  String get abstained;

  /// No description provided for @eliminated.
  ///
  /// In en, this message translates to:
  /// **'The village voted out {name}.'**
  String eliminated(String name);

  /// No description provided for @nobodyEliminated.
  ///
  /// In en, this message translates to:
  /// **'Nobody was voted out.'**
  String get nobodyEliminated;

  /// No description provided for @villageWins.
  ///
  /// In en, this message translates to:
  /// **'The village wins!'**
  String get villageWins;

  /// No description provided for @werewolvesWin.
  ///
  /// In en, this message translates to:
  /// **'The werewolves win!'**
  String get werewolvesWin;

  /// No description provided for @everyRole.
  ///
  /// In en, this message translates to:
  /// **'Who was who'**
  String get everyRole;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @dead.
  ///
  /// In en, this message translates to:
  /// **'dead'**
  String get dead;

  /// No description provided for @refused.
  ///
  /// In en, this message translates to:
  /// **'That is not possible right now.'**
  String get refused;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQr;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the room code'**
  String get scanTitle;

  /// No description provided for @scanInvalid.
  ///
  /// In en, this message translates to:
  /// **'That is not a Whowolf room code.'**
  String get scanInvalid;

  /// No description provided for @joinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Join room {room}?'**
  String joinConfirmTitle(String room);

  /// No description provided for @joinConfirmLan.
  ///
  /// In en, this message translates to:
  /// **'In the Wi-Fi: {address}'**
  String joinConfirmLan(String address);

  /// No description provided for @joinConfirmOnline.
  ///
  /// In en, this message translates to:
  /// **'Online via {server}'**
  String joinConfirmOnline(String server);

  /// No description provided for @joinLan.
  ///
  /// In en, this message translates to:
  /// **'In the Wi-Fi'**
  String get joinLan;

  /// No description provided for @joinOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get joinOnline;

  /// No description provided for @onlineCode.
  ///
  /// In en, this message translates to:
  /// **'Online code'**
  String get onlineCode;

  /// No description provided for @noRelayServer.
  ///
  /// In en, this message translates to:
  /// **'No server set up for online games. Add one in the settings.'**
  String get noRelayServer;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Back to the game (room {room})'**
  String resume(String room);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @relayServer.
  ///
  /// In en, this message translates to:
  /// **'Server for online players'**
  String get relayServer;

  /// No description provided for @relayServerHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for the official server (play.whowolf.de). It only forwards encrypted messages. Own server: see the docs.'**
  String get relayServerHelp;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @invalidServer.
  ///
  /// In en, this message translates to:
  /// **'Use an address starting with ws:// or wss://.'**
  String get invalidServer;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Or scan this code with the Whowolf app:'**
  String get scanHint;

  /// No description provided for @relayFailed.
  ///
  /// In en, this message translates to:
  /// **'The online server is not reachable: Wi-Fi only.'**
  String get relayFailed;

  /// No description provided for @nameTaken.
  ///
  /// In en, this message translates to:
  /// **'This name is already taken at the table. Pick another one:'**
  String get nameTaken;

  /// No description provided for @narrateReveal.
  ///
  /// In en, this message translates to:
  /// **'The roles are dealt. Look at yours, and let nobody look over your shoulder.'**
  String get narrateReveal;

  /// No description provided for @narrateNight.
  ///
  /// In en, this message translates to:
  /// **'Night falls over the village. Everyone close your eyes … and tap on your phone.'**
  String get narrateNight;

  /// No description provided for @narrateMorning.
  ///
  /// In en, this message translates to:
  /// **'The sun rises over the village.'**
  String get narrateMorning;

  /// No description provided for @narrateDiscuss.
  ///
  /// In en, this message translates to:
  /// **'Now talk: who is the werewolf?'**
  String get narrateDiscuss;

  /// No description provided for @narrateVote.
  ///
  /// In en, this message translates to:
  /// **'Enough talk. Cast your votes now.'**
  String get narrateVote;

  /// No description provided for @narrateRole.
  ///
  /// In en, this message translates to:
  /// **'They were: {role}.'**
  String narrateRole(String role);

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Narrator voice off'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Narrator voice on'**
  String get unmute;

  /// No description provided for @nightSheep.
  ///
  /// In en, this message translates to:
  /// **'Count sheep until morning: tap the white ones, let the black ones jump.'**
  String get nightSheep;

  /// No description provided for @dreamPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} dream points'**
  String dreamPoints(int points);

  /// No description provided for @sheepWhileWaiting.
  ///
  /// In en, this message translates to:
  /// **'Until morning: count sheep.'**
  String get sheepWhileWaiting;

  /// No description provided for @sleepTitle.
  ///
  /// In en, this message translates to:
  /// **'How well did you sleep?'**
  String get sleepTitle;

  /// No description provided for @sheepCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sheep'**
  String sheepCount(int count);

  /// No description provided for @bestDreamer.
  ///
  /// In en, this message translates to:
  /// **'Best dreamer: {name} ({points} dream points)'**
  String bestDreamer(String name, int points);

  /// No description provided for @youAppearAs.
  ///
  /// In en, this message translates to:
  /// **'You appear as'**
  String get youAppearAs;

  /// No description provided for @changePersona.
  ///
  /// In en, this message translates to:
  /// **'Choose your figure'**
  String get changePersona;

  /// No description provided for @personaHint.
  ///
  /// In en, this message translates to:
  /// **'Your figure is only your look. Your role stays secret and is dealt by chance.'**
  String get personaHint;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Get the others in'**
  String get inviteTitle;

  /// No description provided for @inviteHint.
  ///
  /// In en, this message translates to:
  /// **'The others open Whowolf and tap “Join a room”: your room shows up by itself. Or they scan this code.'**
  String get inviteHint;

  /// No description provided for @connectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Connection details'**
  String get connectionDetails;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms nearby'**
  String get nearbyTitle;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Looking for rooms in your Wi-Fi …'**
  String get searching;

  /// No description provided for @roomOf.
  ///
  /// In en, this message translates to:
  /// **'{host}’s room'**
  String roomOf(String host);

  /// No description provided for @noDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Searching does not work on this device. Scan the QR code instead.'**
  String get noDiscovery;

  /// No description provided for @manualJoin.
  ///
  /// In en, this message translates to:
  /// **'Connect by hand'**
  String get manualJoin;

  /// No description provided for @tableHint.
  ///
  /// In en, this message translates to:
  /// **'This is how you sit at the table, seen from your seat. Is the order right? The host can swap seats.'**
  String get tableHint;

  /// No description provided for @swapSeat.
  ///
  /// In en, this message translates to:
  /// **'Swap seats'**
  String get swapSeat;

  /// No description provided for @swapHint.
  ///
  /// In en, this message translates to:
  /// **'Now tap the seat {name} should swap with.'**
  String swapHint(String name);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Can’t find each other?'**
  String get helpTitle;

  /// No description provided for @helpLink.
  ///
  /// In en, this message translates to:
  /// **'Room not showing up? Help'**
  String get helpLink;

  /// No description provided for @helpSameWifi.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the same Wi-Fi: check that no phone is on mobile data or a different network.'**
  String get helpSameWifi;

  /// No description provided for @helpGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest Wi-Fi or hotel networks often keep devices apart. Open a hotspot on the host phone and let everyone join it.'**
  String get helpGuest;

  /// No description provided for @helpIos.
  ///
  /// In en, this message translates to:
  /// **'iPhone/iPad: Settings › Privacy & Security › Local Network: switch Whowolf on.'**
  String get helpIos;

  /// No description provided for @helpAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android: turn off battery saving for Whowolf so it stays connected.'**
  String get helpAndroid;

  /// No description provided for @helpMac.
  ///
  /// In en, this message translates to:
  /// **'Mac: when asked “Accept incoming network connections?”, choose Allow (System Settings › Network › Firewall).'**
  String get helpMac;

  /// No description provided for @helpWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows: when the firewall asks, allow Whowolf on private networks.'**
  String get helpWindows;

  /// No description provided for @helpVpn.
  ///
  /// In en, this message translates to:
  /// **'Switch off VPNs and ad blockers that filter the local network.'**
  String get helpVpn;

  /// No description provided for @helpQr.
  ///
  /// In en, this message translates to:
  /// **'Still nothing? Scan the QR code on the host phone instead.'**
  String get helpQr;

  /// No description provided for @restoreRoom.
  ///
  /// In en, this message translates to:
  /// **'Restore your room'**
  String get restoreRoom;

  /// No description provided for @waitingForHost.
  ///
  /// In en, this message translates to:
  /// **'Almost in! Show the host these symbols:'**
  String get waitingForHost;

  /// No description provided for @waitingHint.
  ///
  /// In en, this message translates to:
  /// **'The host lets you in as soon as the symbols match.'**
  String get waitingHint;

  /// No description provided for @wantsToJoin.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to join'**
  String wantsToJoin(String name);

  /// No description provided for @compareSymbols.
  ///
  /// In en, this message translates to:
  /// **'Do these symbols match the ones on their phone?'**
  String get compareSymbols;

  /// No description provided for @letIn.
  ///
  /// In en, this message translates to:
  /// **'Let in'**
  String get letIn;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @pauseTitle.
  ///
  /// In en, this message translates to:
  /// **'A short pause'**
  String get pauseTitle;

  /// No description provided for @pauseText.
  ///
  /// In en, this message translates to:
  /// **'The narrator is catching their breath … The game goes on in a moment, nothing is lost.'**
  String get pauseText;

  /// Quiet button that appears after a long pause, in case the room is gone.
  ///
  /// In en, this message translates to:
  /// **'Leave the game'**
  String get pauseLeave;

  /// Silent Android notification while this device hosts a room.
  ///
  /// In en, this message translates to:
  /// **'Room {room} is open'**
  String roomOpenNotice(String room);

  /// No description provided for @keepAppOpenHint.
  ///
  /// In en, this message translates to:
  /// **'You are hosting this room: please keep Whowolf open while you play. If you switch apps for a moment, the game simply carries on when you come back.'**
  String get keepAppOpenHint;

  /// No description provided for @roleWitch.
  ///
  /// In en, this message translates to:
  /// **'Witch'**
  String get roleWitch;

  /// No description provided for @roleHunter.
  ///
  /// In en, this message translates to:
  /// **'Hunter'**
  String get roleHunter;

  /// No description provided for @roleCupid.
  ///
  /// In en, this message translates to:
  /// **'Cupid'**
  String get roleCupid;

  /// No description provided for @roleWitchText.
  ///
  /// In en, this message translates to:
  /// **'You have one healing potion and one poison, each for one use. At night you see whom the werewolves take, and decide after them.'**
  String get roleWitchText;

  /// No description provided for @roleHunterText.
  ///
  /// In en, this message translates to:
  /// **'If you fall, at night or by the vote, you take someone with you at once.'**
  String get roleHunterText;

  /// No description provided for @roleCupidText.
  ///
  /// In en, this message translates to:
  /// **'In the first night you bind two people as lovers. If one of them dies, so does the other.'**
  String get roleCupidText;

  /// No description provided for @factionLovers.
  ///
  /// In en, this message translates to:
  /// **'Lovers'**
  String get factionLovers;

  /// No description provided for @nightLink.
  ///
  /// In en, this message translates to:
  /// **'Whom do you bind as lovers? Pick two (you may pick yourself).'**
  String get nightLink;

  /// No description provided for @linkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Bind them'**
  String get linkConfirm;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second} are lovers now.'**
  String linked(String first, String second);

  /// No description provided for @nightBrew.
  ///
  /// In en, this message translates to:
  /// **'The werewolves have chosen. What do you brew?'**
  String get nightBrew;

  /// No description provided for @brewVictim.
  ///
  /// In en, this message translates to:
  /// **'Tonight the werewolves take {name}.'**
  String brewVictim(String name);

  /// No description provided for @brewNoVictim.
  ///
  /// In en, this message translates to:
  /// **'Tonight the werewolves take nobody.'**
  String get brewNoVictim;

  /// No description provided for @brewHeal.
  ///
  /// In en, this message translates to:
  /// **'Healing potion for {name}'**
  String brewHeal(String name);

  /// No description provided for @brewPoison.
  ///
  /// In en, this message translates to:
  /// **'Poison: tap someone (tap again to take it back).'**
  String get brewPoison;

  /// No description provided for @brewDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get brewDone;

  /// No description provided for @brewNothing.
  ///
  /// In en, this message translates to:
  /// **'Brew nothing'**
  String get brewNothing;

  /// No description provided for @brewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your potions are used up.'**
  String get brewEmpty;

  /// No description provided for @brewSent.
  ///
  /// In en, this message translates to:
  /// **'You have decided. Sheep until the morning?'**
  String get brewSent;

  /// No description provided for @hunterYou.
  ///
  /// In en, this message translates to:
  /// **'You have fallen. Whom do you take with you?'**
  String get hunterYou;

  /// No description provided for @hunterSpare.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get hunterSpare;

  /// No description provided for @hunterWait.
  ///
  /// In en, this message translates to:
  /// **'{name} was the hunter and takes aim …'**
  String hunterWait(String name);

  /// No description provided for @diedOfGrief.
  ///
  /// In en, this message translates to:
  /// **'{name} dies of grief.'**
  String diedOfGrief(String name);

  /// No description provided for @shotByHunter.
  ///
  /// In en, this message translates to:
  /// **'The hunter takes {name} along.'**
  String shotByHunter(String name);

  /// No description provided for @inLove.
  ///
  /// In en, this message translates to:
  /// **'You are in love with {name}. If one of you dies, so does the other.'**
  String inLove(String name);

  /// No description provided for @yourCouple.
  ///
  /// In en, this message translates to:
  /// **'Your lovers: {first} and {second}.'**
  String yourCouple(String first, String second);

  /// No description provided for @loversWin.
  ///
  /// In en, this message translates to:
  /// **'The lovers win!'**
  String get loversWin;

  /// No description provided for @narrateHunter.
  ///
  /// In en, this message translates to:
  /// **'The hunter has fallen and takes aim …'**
  String get narrateHunter;

  /// No description provided for @settingsButton.
  ///
  /// In en, this message translates to:
  /// **'Game settings'**
  String get settingsButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Game settings'**
  String get settingsTitle;

  /// No description provided for @presetClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get presetClassic;

  /// No description provided for @presetClassicText.
  ///
  /// In en, this message translates to:
  /// **'Werewolf as you know it: everyone closes their eyes, the narrator calls the roles, and only whoever is called picks up their phone. The app narrates aloud and counts the votes.'**
  String get presetClassicText;

  /// No description provided for @presetWhowolf.
  ///
  /// In en, this message translates to:
  /// **'Whowolf'**
  String get presetWhowolf;

  /// No description provided for @presetWhowolfText.
  ///
  /// In en, this message translates to:
  /// **'Plus counting sheep with the morning score, and atmosphere.'**
  String get presetWhowolfText;

  /// No description provided for @presetFullStage.
  ///
  /// In en, this message translates to:
  /// **'Full stage'**
  String get presetFullStage;

  /// No description provided for @presetFullStageText.
  ///
  /// In en, this message translates to:
  /// **'Everything there is, with Cupid and the wolf trail.'**
  String get presetFullStageText;

  /// No description provided for @presetCustom.
  ///
  /// In en, this message translates to:
  /// **'Your own mix'**
  String get presetCustom;

  /// No description provided for @settingsRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get settingsRoles;

  /// No description provided for @settingsWolves.
  ///
  /// In en, this message translates to:
  /// **'Werewolves'**
  String get settingsWolves;

  /// No description provided for @wolvesSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested ({count})'**
  String wolvesSuggested(int count);

  /// No description provided for @settingsTimes.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get settingsTimes;

  /// No description provided for @timeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get timeNight;

  /// No description provided for @timeDay.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get timeDay;

  /// No description provided for @timeVote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get timeVote;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{count} s'**
  String seconds(int count);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @settingsRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get settingsRules;

  /// No description provided for @settingsRevealRoles.
  ///
  /// In en, this message translates to:
  /// **'Reveal roles of the dead'**
  String get settingsRevealRoles;

  /// No description provided for @settingsSeerRole.
  ///
  /// In en, this message translates to:
  /// **'Seer sees the role (otherwise only the side)'**
  String get settingsSeerRole;

  /// No description provided for @settingsExtras.
  ///
  /// In en, this message translates to:
  /// **'Whowolf extras'**
  String get settingsExtras;

  /// No description provided for @settingsSheep.
  ///
  /// In en, this message translates to:
  /// **'Counting sheep at night'**
  String get settingsSheep;

  /// No description provided for @settingsSheepOff.
  ///
  /// In en, this message translates to:
  /// **'Without sheep, everyone answers a plain question at night, so tapping gives nobody away.'**
  String get settingsSheepOff;

  /// No description provided for @settingsWolfTrail.
  ///
  /// In en, this message translates to:
  /// **'Wolf trail (after the first release)'**
  String get settingsWolfTrail;

  /// No description provided for @settingsAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'Night sounds and the morning yawn'**
  String get settingsAtmosphere;

  /// No description provided for @settingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Narrator voice on the host device'**
  String get settingsVoice;

  /// No description provided for @tooManyRoles.
  ///
  /// In en, this message translates to:
  /// **'For {count} players these are too many roles.'**
  String tooManyRoles(int count);

  /// No description provided for @presetBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic game'**
  String get presetBasic;

  /// No description provided for @nightTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Your night task is done.'**
  String get nightTaskDone;

  /// No description provided for @nightTaskShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get nightTaskShow;

  /// No description provided for @nightTaskHide.
  ///
  /// In en, this message translates to:
  /// **'Fold away'**
  String get nightTaskHide;

  /// No description provided for @nightNothingToDo.
  ///
  /// In en, this message translates to:
  /// **'Nothing else to do tonight: count sheep until the morning.'**
  String get nightNothingToDo;

  /// No description provided for @ownCount.
  ///
  /// In en, this message translates to:
  /// **'Set the number yourself'**
  String get ownCount;

  /// No description provided for @ownCountTitle.
  ///
  /// In en, this message translates to:
  /// **'How many sheep did you count?'**
  String get ownCountTitle;

  /// No description provided for @ownCountHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone may do this, so fibbing is allowed. In the morning everyone sees the numbers.'**
  String get ownCountHint;

  /// No description provided for @ownCountSet.
  ///
  /// In en, this message translates to:
  /// **'Take it'**
  String get ownCountSet;

  /// No description provided for @persona_maid.
  ///
  /// In en, this message translates to:
  /// **'Maid'**
  String get persona_maid;

  /// No description provided for @persona_farmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get persona_farmer;

  /// No description provided for @persona_baker.
  ///
  /// In en, this message translates to:
  /// **'Baker'**
  String get persona_baker;

  /// No description provided for @persona_smith.
  ///
  /// In en, this message translates to:
  /// **'Smith'**
  String get persona_smith;

  /// No description provided for @persona_fisher.
  ///
  /// In en, this message translates to:
  /// **'Fisher'**
  String get persona_fisher;

  /// No description provided for @persona_miller.
  ///
  /// In en, this message translates to:
  /// **'Miller'**
  String get persona_miller;

  /// No description provided for @persona_seamstress.
  ///
  /// In en, this message translates to:
  /// **'Seamstress'**
  String get persona_seamstress;

  /// No description provided for @persona_minstrel.
  ///
  /// In en, this message translates to:
  /// **'Minstrel'**
  String get persona_minstrel;

  /// No description provided for @persona_gooseGirl.
  ///
  /// In en, this message translates to:
  /// **'Goose girl'**
  String get persona_gooseGirl;

  /// No description provided for @persona_beekeeper.
  ///
  /// In en, this message translates to:
  /// **'Beekeeper'**
  String get persona_beekeeper;

  /// No description provided for @persona_innkeeper.
  ///
  /// In en, this message translates to:
  /// **'Innkeeper'**
  String get persona_innkeeper;

  /// No description provided for @persona_shepherd.
  ///
  /// In en, this message translates to:
  /// **'Shepherd'**
  String get persona_shepherd;

  /// No description provided for @persona_washerwoman.
  ///
  /// In en, this message translates to:
  /// **'Washerwoman'**
  String get persona_washerwoman;

  /// No description provided for @persona_carpenter.
  ///
  /// In en, this message translates to:
  /// **'Carpenter'**
  String get persona_carpenter;

  /// No description provided for @persona_spinner.
  ///
  /// In en, this message translates to:
  /// **'Spinner'**
  String get persona_spinner;

  /// No description provided for @persona_cobbler.
  ///
  /// In en, this message translates to:
  /// **'Cobbler'**
  String get persona_cobbler;

  /// No description provided for @persona_flowerGirl.
  ///
  /// In en, this message translates to:
  /// **'Flower girl'**
  String get persona_flowerGirl;

  /// No description provided for @persona_mayor.
  ///
  /// In en, this message translates to:
  /// **'Mayor'**
  String get persona_mayor;

  /// No description provided for @persona_grandmother.
  ///
  /// In en, this message translates to:
  /// **'Grandmother'**
  String get persona_grandmother;

  /// No description provided for @persona_grandfather.
  ///
  /// In en, this message translates to:
  /// **'Grandfather'**
  String get persona_grandfather;

  /// No description provided for @doorSignTitle.
  ///
  /// In en, this message translates to:
  /// **'Your door sign tonight'**
  String get doorSignTitle;

  /// No description provided for @doorSignHint.
  ///
  /// In en, this message translates to:
  /// **'Let nobody look at your screen: a werewolf who knows your sign has a chance to come for you tonight.'**
  String get doorSignHint;

  /// No description provided for @markTitle.
  ///
  /// In en, this message translates to:
  /// **'Spotted a door sign?'**
  String get markTitle;

  /// No description provided for @markHint.
  ///
  /// In en, this message translates to:
  /// **'Once a night the pack may try one. If it is right, that person may die tonight as well (about one in two).'**
  String get markHint;

  /// No description provided for @markSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol {number}'**
  String markSymbol(int number);

  /// No description provided for @markTry.
  ///
  /// In en, this message translates to:
  /// **'Try the sign'**
  String get markTry;

  /// No description provided for @markRight.
  ///
  /// In en, this message translates to:
  /// **'The sign of {name} was right. Maybe the pack gets them tonight.'**
  String markRight(String name);

  /// No description provided for @markWrong.
  ///
  /// In en, this message translates to:
  /// **'The sign of {name} was wrong. Next night brings new signs.'**
  String markWrong(String name);

  /// No description provided for @settingsDoorSigns.
  ///
  /// In en, this message translates to:
  /// **'Door signs (peeking at screens can cost a life)'**
  String get settingsDoorSigns;

  /// No description provided for @codeConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Does the host\'s screen ask about you with exactly these symbols? Only then is it really the host. If the host sees no request from you, do not confirm.'**
  String get codeConfirmHint;

  /// No description provided for @codeConfirm.
  ///
  /// In en, this message translates to:
  /// **'The host sees the same symbols'**
  String get codeConfirm;

  /// No description provided for @narrateNightCalled.
  ///
  /// In en, this message translates to:
  /// **'Night falls over the village. Everyone close your eyes.'**
  String get narrateNightCalled;

  /// No description provided for @narrateStepLink.
  ///
  /// In en, this message translates to:
  /// **'Cupid wakes up and binds two people in love.'**
  String get narrateStepLink;

  /// No description provided for @narrateStepHunt.
  ///
  /// In en, this message translates to:
  /// **'The werewolves wake up and choose a victim.'**
  String get narrateStepHunt;

  /// No description provided for @narrateStepInspect.
  ///
  /// In en, this message translates to:
  /// **'The seer wakes up and looks into someone\'s soul.'**
  String get narrateStepInspect;

  /// No description provided for @narrateStepBrew.
  ///
  /// In en, this message translates to:
  /// **'The witch wakes up. She sees who is to die tonight and reaches for her potions.'**
  String get narrateStepBrew;

  /// No description provided for @narrateStepSleep.
  ///
  /// In en, this message translates to:
  /// **'Eyes closed again.'**
  String get narrateStepSleep;

  /// No description provided for @nightEyesClosed.
  ///
  /// In en, this message translates to:
  /// **'Eyes closed'**
  String get nightEyesClosed;

  /// No description provided for @nightEyesClosedHint.
  ///
  /// In en, this message translates to:
  /// **'Put your phone down until the narrator wakes you.'**
  String get nightEyesClosedHint;

  /// No description provided for @nightAwakeNow.
  ///
  /// In en, this message translates to:
  /// **'Awake now: {who}'**
  String nightAwakeNow(String who);

  /// No description provided for @nightWerewolves.
  ///
  /// In en, this message translates to:
  /// **'the werewolves'**
  String get nightWerewolves;

  /// No description provided for @nightYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn. Eyes open!'**
  String get nightYourTurn;

  /// No description provided for @settingsNight.
  ///
  /// In en, this message translates to:
  /// **'The night'**
  String get settingsNight;

  /// No description provided for @settingsNightCalled.
  ///
  /// In en, this message translates to:
  /// **'The narrator calls the roles'**
  String get settingsNightCalled;

  /// No description provided for @settingsNightCalledHint.
  ///
  /// In en, this message translates to:
  /// **'Werewolf as you know it: everyone closes their eyes, and only whoever is called picks up their phone. No sheep and no door signs then.'**
  String get settingsNightCalledHint;

  /// No description provided for @settingsNightTogether.
  ///
  /// In en, this message translates to:
  /// **'Everyone taps at once'**
  String get settingsNightTogether;

  /// No description provided for @settingsNightTogetherHint.
  ///
  /// In en, this message translates to:
  /// **'Whowolf\'s night: phones stay in hand, and the tapping gives nobody away.'**
  String get settingsNightTogetherHint;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'A word on privacy'**
  String get privacyNoticeTitle;

  /// No description provided for @privacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Whowolf has no accounts, no ads and no tracking. At the table, game data travels end-to-end encrypted between your devices only. So that players without a shared Wi-Fi can join, the host\'s device connects to the server play.whowolf.de; it only forwards encrypted data and, like any server, sees the IP addresses. You can switch it off in the settings.'**
  String get privacyNotice;

  /// No description provided for @privacyRead.
  ///
  /// In en, this message translates to:
  /// **'Read the privacy notice'**
  String get privacyRead;

  /// No description provided for @privacyOk.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get privacyOk;

  /// No description provided for @relayOff.
  ///
  /// In en, this message translates to:
  /// **'No online server (Wi-Fi only)'**
  String get relayOff;

  /// No description provided for @relayOffHint.
  ///
  /// In en, this message translates to:
  /// **'Then only devices in the same Wi-Fi can play, and nothing goes to a server.'**
  String get relayOffHint;

  /// No description provided for @relayCustomHint.
  ///
  /// In en, this message translates to:
  /// **'With your own server, its operator is responsible for it and sees the IP addresses of the connected devices.'**
  String get relayCustomHint;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy in the app'**
  String get privacyTitle;

  /// No description provided for @privacyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 27 October 2026'**
  String get privacyUpdated;

  /// No description provided for @privacySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'In short'**
  String get privacySummaryTitle;

  /// No description provided for @privacySummary.
  ///
  /// In en, this message translates to:
  /// **'No accounts, no ads, no tracking, no analytics. The app keeps nothing about you on a server.'**
  String get privacySummary;

  /// No description provided for @privacyTableTitle.
  ///
  /// In en, this message translates to:
  /// **'At the table'**
  String get privacyTableTitle;

  /// No description provided for @privacyTable.
  ///
  /// In en, this message translates to:
  /// **'Game data travels only between the devices at the table, end-to-end encrypted. So that others find the room, the host\'s device announces it in the local network (room code, the host\'s name, a mark of its key); only devices in the same Wi-Fi see it.'**
  String get privacyTable;

  /// No description provided for @privacyServerTitle.
  ///
  /// In en, this message translates to:
  /// **'The online server'**
  String get privacyServerTitle;

  /// No description provided for @privacyServer.
  ///
  /// In en, this message translates to:
  /// **'So that players without a shared Wi-Fi can join, the host\'s device connects to play.whowolf.de, run by the project owner (see the imprint on whowolf.de). The server is located in Germany, hosted by ZAP-Hosting GmbH (Münster). The server only forwards end-to-end encrypted data and can read neither names nor roles nor moves. It necessarily processes the IP addresses of the connected devices, in memory only and only while connected, to forward messages and to limit abuse; they are neither stored nor logged. The legal basis is our legitimate interest in providing the game you asked for and protecting the server (Art. 6(1)(f) GDPR). In the settings you can switch the server off or enter your own; its operator is then responsible.'**
  String get privacyServer;

  /// No description provided for @privacyDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'On your device'**
  String get privacyDeviceTitle;

  /// No description provided for @privacyDevice.
  ///
  /// In en, this message translates to:
  /// **'Your name and a session key for rejoining are kept in your device\'s protected storage (12 hours at most). The host\'s device keeps the game state until the room closes. None of it leaves your device except encrypted, for the game.'**
  String get privacyDevice;

  /// No description provided for @privacyRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your rights'**
  String get privacyRightsTitle;

  /// No description provided for @privacyRights.
  ///
  /// In en, this message translates to:
  /// **'You have the right to access, rectification, erasure and restriction of processing, to data portability and to object (Art. 15 to 21 GDPR), and you may complain to a data protection authority (Art. 77 GDPR). As the server stores nothing, there is no stored data about you. The full version is on whowolf.de.'**
  String get privacyRights;

  /// No description provided for @lobbyNightCalled.
  ///
  /// In en, this message translates to:
  /// **'At night the narrator calls the roles; everyone else keeps their eyes closed.'**
  String get lobbyNightCalled;

  /// No description provided for @lobbyNightTogether.
  ///
  /// In en, this message translates to:
  /// **'At night everyone taps at once, so nobody stands out.'**
  String get lobbyNightTogether;

  /// No description provided for @lobbyExtras.
  ///
  /// In en, this message translates to:
  /// **'Plus: {list}'**
  String lobbyExtras(String list);

  /// No description provided for @extraVoice.
  ///
  /// In en, this message translates to:
  /// **'narrator\'s voice'**
  String get extraVoice;

  /// No description provided for @extraSheep.
  ///
  /// In en, this message translates to:
  /// **'counting sheep'**
  String get extraSheep;

  /// No description provided for @extraDoorSigns.
  ///
  /// In en, this message translates to:
  /// **'door signs'**
  String get extraDoorSigns;

  /// No description provided for @extraAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'night sounds'**
  String get extraAtmosphere;

  /// No description provided for @webJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Play in the browser'**
  String get webJoinTitle;

  /// No description provided for @webJoinHint.
  ///
  /// In en, this message translates to:
  /// **'No app needed: enter your name and take your seat at the table.'**
  String get webJoinHint;

  /// No description provided for @webJoinNoLink.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code at the table with your phone\'s camera to continue here.'**
  String get webJoinNoLink;

  /// No description provided for @webJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get webJoinButton;

  /// No description provided for @webJoinApp.
  ///
  /// In en, this message translates to:
  /// **'The app can do even more: whowolf.de'**
  String get webJoinApp;

  /// No description provided for @inviteHintWeb.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with the Whowolf app, or without the app with your phone\'s camera to play in the browser.'**
  String get inviteHintWeb;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Like the system'**
  String get languageSystem;

  /// No description provided for @settingsNarratorLanguage.
  ///
  /// In en, this message translates to:
  /// **'Narrator\'s language'**
  String get settingsNarratorLanguage;

  /// No description provided for @runoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Runoff'**
  String get runoffTitle;

  /// No description provided for @runoffPrompt.
  ///
  /// In en, this message translates to:
  /// **'A tie! Vote once more, only between these: {names}'**
  String runoffPrompt(String names);

  /// No description provided for @narrateRunoff.
  ///
  /// In en, this message translates to:
  /// **'A tie. A runoff decides now.'**
  String get narrateRunoff;

  /// No description provided for @ghostHold.
  ///
  /// In en, this message translates to:
  /// **'Ghost sight: press and hold'**
  String get ghostHold;

  /// No description provided for @ghostHint.
  ///
  /// In en, this message translates to:
  /// **'As a ghost you see more than the living. Give nothing away.'**
  String get ghostHint;

  /// No description provided for @ghostRoles.
  ///
  /// In en, this message translates to:
  /// **'Who is who'**
  String get ghostRoles;

  /// No description provided for @ghostLovers.
  ///
  /// In en, this message translates to:
  /// **'In love: {a} and {b}'**
  String ghostLovers(String a, String b);

  /// No description provided for @ghostTonight.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get ghostTonight;

  /// No description provided for @ghostPick.
  ///
  /// In en, this message translates to:
  /// **'{who} → {whom}'**
  String ghostPick(String who, String whom);

  /// No description provided for @ghostVictim.
  ///
  /// In en, this message translates to:
  /// **'The pack\'s victim: {name}'**
  String ghostVictim(String name);

  /// No description provided for @ghostSeen.
  ///
  /// In en, this message translates to:
  /// **'The seer saw {name}: {what}'**
  String ghostSeen(String name, String what);

  /// No description provided for @ghostPotions.
  ///
  /// In en, this message translates to:
  /// **'Potions used: {potions}'**
  String ghostPotions(String potions);

  /// No description provided for @potionHeal.
  ///
  /// In en, this message translates to:
  /// **'healing potion'**
  String get potionHeal;

  /// No description provided for @potionPoison.
  ///
  /// In en, this message translates to:
  /// **'poison'**
  String get potionPoison;

  /// No description provided for @ghostVotes.
  ///
  /// In en, this message translates to:
  /// **'Votes'**
  String get ghostVotes;

  /// No description provided for @ghostNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened yet.'**
  String get ghostNothingYet;

  /// No description provided for @settingsGhosts.
  ///
  /// In en, this message translates to:
  /// **'What the dead see'**
  String get settingsGhosts;

  /// No description provided for @ghostsOff.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get ghostsOff;

  /// No description provided for @ghostsRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get ghostsRoles;

  /// No description provided for @ghostsEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get ghostsEverything;

  /// No description provided for @settingsGhostsHint.
  ///
  /// In en, this message translates to:
  /// **'Only once they have nothing left to do, and only while holding a button.'**
  String get settingsGhostsHint;

  /// No description provided for @settingsRunoff.
  ///
  /// In en, this message translates to:
  /// **'Runoff on a tie (otherwise nobody goes)'**
  String get settingsRunoff;

  /// No description provided for @extraGhosts.
  ///
  /// In en, this message translates to:
  /// **'ghosts watch'**
  String get extraGhosts;

  /// No description provided for @extraRunoff.
  ///
  /// In en, this message translates to:
  /// **'runoff on a tie'**
  String get extraRunoff;

  /// No description provided for @eyebrowEvening.
  ///
  /// In en, this message translates to:
  /// **'Game night'**
  String get eyebrowEvening;

  /// No description provided for @eyebrowYourRole.
  ///
  /// In en, this message translates to:
  /// **'Only for you'**
  String get eyebrowYourRole;

  /// No description provided for @eyebrowNight.
  ///
  /// In en, this message translates to:
  /// **'Night {round}'**
  String eyebrowNight(String round);

  /// No description provided for @eyebrowAwake.
  ///
  /// In en, this message translates to:
  /// **'Only you are awake'**
  String get eyebrowAwake;

  /// No description provided for @eyebrowDay.
  ///
  /// In en, this message translates to:
  /// **'Day {round}'**
  String eyebrowDay(String round);

  /// No description provided for @eyebrowVote.
  ///
  /// In en, this message translates to:
  /// **'The vote'**
  String get eyebrowVote;

  /// No description provided for @eyebrowTie.
  ///
  /// In en, this message translates to:
  /// **'A tie'**
  String get eyebrowTie;

  /// No description provided for @eyebrowLastShot.
  ///
  /// In en, this message translates to:
  /// **'The last shot'**
  String get eyebrowLastShot;

  /// No description provided for @eyebrowEnd.
  ///
  /// In en, this message translates to:
  /// **'The show is over'**
  String get eyebrowEnd;

  /// No description provided for @eyebrowNarrator.
  ///
  /// In en, this message translates to:
  /// **'The narrator'**
  String get eyebrowNarrator;

  /// No description provided for @dayTalkTitle.
  ///
  /// In en, this message translates to:
  /// **'Talk to each other'**
  String get dayTalkTitle;

  /// No description provided for @voteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Whom do you suspect?'**
  String get voteQuestion;

  /// No description provided for @hunterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Whom do you take with you?'**
  String get hunterQuestion;

  /// No description provided for @introTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen closely'**
  String get introTitle;

  /// No description provided for @eyesClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Eyes closed'**
  String get eyesClosedTitle;

  /// No description provided for @comeJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Come and join'**
  String get comeJoinTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
