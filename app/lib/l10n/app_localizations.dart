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

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connection lost, reconnecting …'**
  String get reconnecting;

  /// No description provided for @lobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
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
  /// **'You are the host: the room closes for everyone.'**
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
  /// **'Leave empty to use the official server once it exists. Own server: docker compose up -d, see the docs.'**
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
