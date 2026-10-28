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
  /// **'The werewolf game for your table.'**
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

  /// No description provided for @byeVersionNewer.
  ///
  /// In en, this message translates to:
  /// **'The game leader has a newer version of Whowolf. Update your Whowolf, then it fits.'**
  String get byeVersionNewer;

  /// No description provided for @byeVersionOlder.
  ///
  /// In en, this message translates to:
  /// **'The game leader has an older version of Whowolf. Everyone at the table needs the same version: they should update Whowolf.'**
  String get byeVersionOlder;

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

  /// No description provided for @eyesClosingTogether.
  ///
  /// In en, this message translates to:
  /// **'Close your eyes for a moment and hold your phone close: the night begins in a second.'**
  String get eyesClosingTogether;

  /// No description provided for @settingsOpenVotes.
  ///
  /// In en, this message translates to:
  /// **'Open voting'**
  String get settingsOpenVotes;

  /// No description provided for @settingsOpenVotesHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone sees who votes for whom as it happens, and again the next day.'**
  String get settingsOpenVotesHint;

  /// No description provided for @votesFor.
  ///
  /// In en, this message translates to:
  /// **'{name}: {voters}'**
  String votesFor(String name, String voters);

  /// No description provided for @votesAbstained.
  ///
  /// In en, this message translates to:
  /// **'Abstained: {names}'**
  String votesAbstained(String names);

  /// No description provided for @votesLive.
  ///
  /// In en, this message translates to:
  /// **'Who votes for whom'**
  String get votesLive;

  /// No description provided for @votesYesterday.
  ///
  /// In en, this message translates to:
  /// **'How yesterday\'s vote went'**
  String get votesYesterday;

  /// No description provided for @chronicleTitle.
  ///
  /// In en, this message translates to:
  /// **'What really happened'**
  String get chronicleTitle;

  /// No description provided for @chronicleNight.
  ///
  /// In en, this message translates to:
  /// **'Night {round}'**
  String chronicleNight(int round);

  /// No description provided for @chronicleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {round}'**
  String chronicleDay(int round);

  /// No description provided for @chronicleHunt.
  ///
  /// In en, this message translates to:
  /// **'The werewolves chose {name}.'**
  String chronicleHunt(String name);

  /// No description provided for @chronicleHuntNone.
  ///
  /// In en, this message translates to:
  /// **'The werewolves did not agree.'**
  String get chronicleHuntNone;

  /// No description provided for @chronicleLook.
  ///
  /// In en, this message translates to:
  /// **'{seer} looked into {name}\'s soul.'**
  String chronicleLook(String seer, String name);

  /// No description provided for @chronicleHeal.
  ///
  /// In en, this message translates to:
  /// **'{witch} saved {name} with the healing potion.'**
  String chronicleHeal(String witch, String name);

  /// No description provided for @chroniclePoison.
  ///
  /// In en, this message translates to:
  /// **'{witch} poisoned {name}.'**
  String chroniclePoison(String witch, String name);

  /// No description provided for @chronicleLink.
  ///
  /// In en, this message translates to:
  /// **'{cupid} linked {a} and {b}.'**
  String chronicleLink(String cupid, String a, String b);

  /// No description provided for @lastWordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Last words'**
  String get lastWordsTitle;

  /// No description provided for @lastWordsYou.
  ///
  /// In en, this message translates to:
  /// **'Your last words'**
  String get lastWordsYou;

  /// No description provided for @lastWordsHint.
  ///
  /// In en, this message translates to:
  /// **'Listen: only the one who just left speaks now.'**
  String get lastWordsHint;

  /// No description provided for @lastWordsYouHint.
  ///
  /// In en, this message translates to:
  /// **'Tell the village one more thing, the clock is running.'**
  String get lastWordsYouHint;

  /// No description provided for @voteSoon.
  ///
  /// In en, this message translates to:
  /// **'The vote is coming …'**
  String get voteSoon;

  /// No description provided for @readyCount.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {alive} are ready.'**
  String readyCount(int ready, int alive);

  /// No description provided for @readyToVote.
  ///
  /// In en, this message translates to:
  /// **'We\'re ready'**
  String get readyToVote;

  /// No description provided for @readyUndo.
  ///
  /// In en, this message translates to:
  /// **'Keep talking'**
  String get readyUndo;

  /// No description provided for @offlineBadge.
  ///
  /// In en, this message translates to:
  /// **'not connected'**
  String get offlineBadge;

  /// No description provided for @pausedByLeader.
  ///
  /// In en, this message translates to:
  /// **'The game leader paused. The clock stands still.'**
  String get pausedByLeader;

  /// No description provided for @leaderPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get leaderPause;

  /// No description provided for @leaderResume.
  ///
  /// In en, this message translates to:
  /// **'Go on'**
  String get leaderResume;

  /// No description provided for @leaderExtend.
  ///
  /// In en, this message translates to:
  /// **'+30 s'**
  String get leaderExtend;

  /// No description provided for @leaderEndAsk.
  ///
  /// In en, this message translates to:
  /// **'End it now? Whoever has not voted yet cannot do so any more.'**
  String get leaderEndAsk;

  /// No description provided for @notChoosable.
  ///
  /// In en, this message translates to:
  /// **'Cannot be chosen'**
  String get notChoosable;

  /// No description provided for @leaderEnd.
  ///
  /// In en, this message translates to:
  /// **'End the vote'**
  String get leaderEnd;

  /// No description provided for @timesForTable.
  ///
  /// In en, this message translates to:
  /// **'Suited to {count} players'**
  String timesForTable(int count);

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is out'**
  String updateTitle(String version);

  /// No description provided for @updateText.
  ///
  /// In en, this message translates to:
  /// **'You are still playing {current}. Best update everyone at the table: only the same versions play together.'**
  String updateText(String current);

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateGet.
  ///
  /// In en, this message translates to:
  /// **'Go to downloads'**
  String get updateGet;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Look for new versions'**
  String get updateCheck;

  /// No description provided for @updateCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Asks GitHub for the newest version when the app starts. GitHub sees your IP address.'**
  String get updateCheckHint;

  /// No description provided for @privacyUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'New versions'**
  String get privacyUpdatesTitle;

  /// No description provided for @privacyUpdates.
  ///
  /// In en, this message translates to:
  /// **'When it starts, the app reads the public list of versions on GitHub (github.com, run by GitHub Inc., USA) to tell you about a new version. GitHub sees your device\'s IP address, as with any web page. Nothing about you or your game is sent. You can switch this off in the settings. The legal basis is our legitimate interest in pointing you to fixes and matching versions (Art. 6(1)(f) GDPR).'**
  String get privacyUpdates;

  /// No description provided for @handoverMenu.
  ///
  /// In en, this message translates to:
  /// **'Give a seat to another device'**
  String get handoverMenu;

  /// No description provided for @handoverPick.
  ///
  /// In en, this message translates to:
  /// **'Whose seat goes to another device?'**
  String get handoverPick;

  /// No description provided for @handoverTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s seat'**
  String handoverTitle(String name);

  /// No description provided for @handoverHint.
  ///
  /// In en, this message translates to:
  /// **'Scan it on the new device with the Whowolf app. The code works once and only briefly; {name}\'s old device is signed out.'**
  String handoverHint(String name);

  /// No description provided for @handoverDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get handoverDone;

  /// No description provided for @webAppHint.
  ///
  /// In en, this message translates to:
  /// **'The app runs smoother: sound, the screen stays on, and coming back is easier.'**
  String get webAppHint;

  /// No description provided for @webAppGet.
  ///
  /// In en, this message translates to:
  /// **'Get the app'**
  String get webAppGet;

  /// No description provided for @inviteOpen.
  ///
  /// In en, this message translates to:
  /// **'Invite players'**
  String get inviteOpen;

  /// No description provided for @inviteFold.
  ///
  /// In en, this message translates to:
  /// **'Fold away'**
  String get inviteFold;

  /// No description provided for @inviteInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'How the others get in'**
  String get inviteInfoTitle;

  /// No description provided for @inviteInfo.
  ///
  /// In en, this message translates to:
  /// **'On the same Wi-Fi the others open Whowolf and tap “Join a room”: your room shows up there by itself, no code needed.\n\nFor everyone else (another Wi-Fi, mobile data, the browser without the app) there is the QR code. Only when you unfold it does the room go onto the online server; games on the Wi-Fi stay unknown to it.'**
  String get inviteInfo;

  /// No description provided for @seerVisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vision'**
  String get seerVisionTitle;

  /// No description provided for @seerVisionClose.
  ///
  /// In en, this message translates to:
  /// **'Tap to close'**
  String get seerVisionClose;

  /// No description provided for @seerSeeAgain.
  ///
  /// In en, this message translates to:
  /// **'See again'**
  String get seerSeeAgain;

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

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Or scan this code with the Whowolf app:'**
  String get scanHint;

  /// No description provided for @scanLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get scanLight;

  /// No description provided for @joinConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Join room {room}?'**
  String joinConfirmTitle(String room);

  /// No description provided for @joinConfirmWifi.
  ///
  /// In en, this message translates to:
  /// **'Over your Wi-Fi'**
  String get joinConfirmWifi;

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

  /// No description provided for @settingsQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick pick'**
  String get settingsQuick;

  /// No description provided for @quickClassicHint.
  ///
  /// In en, this message translates to:
  /// **'Eyes closed, the narrator calls'**
  String get quickClassicHint;

  /// No description provided for @quickWhowolfHint.
  ///
  /// In en, this message translates to:
  /// **'Everyone taps, with sheep and door signs'**
  String get quickWhowolfHint;

  /// No description provided for @settingsQuickHint.
  ///
  /// In en, this message translates to:
  /// **'Everything below is yours to set.'**
  String get settingsQuickHint;

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

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Narrator & sound'**
  String get settingsSound;

  /// No description provided for @settingsNarrator.
  ///
  /// In en, this message translates to:
  /// **'Narrator'**
  String get settingsNarrator;

  /// No description provided for @narratorOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get narratorOff;

  /// No description provided for @narratorEssential.
  ///
  /// In en, this message translates to:
  /// **'Essentials'**
  String get narratorEssential;

  /// No description provided for @narratorEssentialHint.
  ///
  /// In en, this message translates to:
  /// **'The voice only says what you need with your eyes closed: falling asleep, who wakes up, who goes back to sleep and when the village wakes.'**
  String get narratorEssentialHint;

  /// No description provided for @narratorMoments.
  ///
  /// In en, this message translates to:
  /// **'Moments'**
  String get narratorMoments;

  /// No description provided for @narratorAlways.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get narratorAlways;

  /// No description provided for @narratorOffHint.
  ///
  /// In en, this message translates to:
  /// **'The story is told on the screens only.'**
  String get narratorOffHint;

  /// No description provided for @narratorMomentsHint.
  ///
  /// In en, this message translates to:
  /// **'The voice tells what matters: nightfall, the news in the morning, the vote and the end. The screens show the rest.'**
  String get narratorMomentsHint;

  /// No description provided for @narratorAlwaysHint.
  ///
  /// In en, this message translates to:
  /// **'The voice tells every line.'**
  String get narratorAlwaysHint;

  /// No description provided for @settingsSoundWhere.
  ///
  /// In en, this message translates to:
  /// **'Sound plays on'**
  String get settingsSoundWhere;

  /// No description provided for @soundEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get soundEveryone;

  /// No description provided for @soundMe.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get soundMe;

  /// No description provided for @soundGroup.
  ///
  /// In en, this message translates to:
  /// **'A group'**
  String get soundGroup;

  /// No description provided for @soundOne.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get soundOne;

  /// No description provided for @soundEveryoneHint.
  ///
  /// In en, this message translates to:
  /// **'The voice walks across all phones. Muted ones are skipped.'**
  String get soundEveryoneHint;

  /// No description provided for @soundChosenHint.
  ///
  /// In en, this message translates to:
  /// **'The voice and the shared sounds play only on these phones. Everyone else hears only their own taps.'**
  String get soundChosenHint;

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

  /// No description provided for @rolesFitted.
  ///
  /// In en, this message translates to:
  /// **'For {count} players without: {roles}. They come back as soon as more people join.'**
  String rolesFitted(int count, String roles);

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
  /// **'All quiet. Eyes closed until the village wakes.'**
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

  /// No description provided for @codeAdmitted.
  ///
  /// In en, this message translates to:
  /// **'The host let you in!'**
  String get codeAdmitted;

  /// No description provided for @codeAdmittedHint.
  ///
  /// In en, this message translates to:
  /// **'Does the host’s screen show exactly these symbols? Then you are in.'**
  String get codeAdmittedHint;

  /// No description provided for @codeAdmittedGo.
  ///
  /// In en, this message translates to:
  /// **'They match, let’s go'**
  String get codeAdmittedGo;

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
  /// **'Whowolf has no accounts, no ads and no tracking. At the table, game data travels end-to-end encrypted between your devices only. So that players without a shared Wi-Fi can join, the host\'s device connects to the server play.whowolf.de, but only once it shows the QR code or has no Wi-Fi; it only forwards encrypted data and, like any server, sees the IP addresses. You can switch it off in the settings.'**
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

  /// No description provided for @relayOnDemand.
  ///
  /// In en, this message translates to:
  /// **'Server only when needed'**
  String get relayOnDemand;

  /// No description provided for @relayOnDemandHint.
  ///
  /// In en, this message translates to:
  /// **'On the same Wi-Fi your room is found without the server. Only when you show the QR code does the room open on the server too, so anyone can join, even without Wi-Fi or the app.'**
  String get relayOnDemandHint;

  /// No description provided for @relayAlways.
  ///
  /// In en, this message translates to:
  /// **'Server always ready'**
  String get relayAlways;

  /// No description provided for @relayAlwaysHint.
  ///
  /// In en, this message translates to:
  /// **'Your room is on the server right away; the QR code works for everyone from the start.'**
  String get relayAlwaysHint;

  /// No description provided for @serveWebApp.
  ///
  /// In en, this message translates to:
  /// **'Browser players on my Wi-Fi load the page from my phone'**
  String get serveWebApp;

  /// No description provided for @serveWebAppHint.
  ///
  /// In en, this message translates to:
  /// **'Only on the same Wi-Fi, so it costs no mobile data. Off: without the app, people can only join through the server.'**
  String get serveWebAppHint;

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
  /// **'Last updated: 28 October 2026'**
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
  /// **'So that players without a shared Wi-Fi can join, the host\'s device connects to play.whowolf.de, by default only once it shows the QR code or has no Wi-Fi (games on the Wi-Fi stay unknown to the server), run by the project owner (see the imprint on whowolf.de). The server is located in Germany, hosted by ZAP-Hosting GmbH (Münster). The server only forwards end-to-end encrypted data and can read neither names nor roles nor moves. It necessarily processes the IP addresses of the connected devices, in memory only and only while connected, to forward messages and to limit abuse; they are neither stored nor logged. The legal basis is our legitimate interest in providing the game you asked for and protecting the server (Art. 6(1)(f) GDPR). In the settings you can switch the server off or enter your own; its operator is then responsible.'**
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

  /// No description provided for @privacyBrowserTitle.
  ///
  /// In en, this message translates to:
  /// **'In the browser'**
  String get privacyBrowserTitle;

  /// No description provided for @privacyBrowser.
  ///
  /// In en, this message translates to:
  /// **'If you play in the browser without the app, the page comes from the host\'s phone (on the same Wi-Fi) or from the server that issued the QR code. Like any web server, that server sees your IP address and browser, but it does not store them. There are no cookies and nothing from third parties. So that you get back to your seat after a reload, the browser keeps the link to the game and your session key, for at most 12 hours and only on this device. The game needs this, so it does not require consent (§ 25(2) TDDDG). Whoever delivers the page could read along with a modified page. The app does not depend on this.'**
  String get privacyBrowser;

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

  /// No description provided for @webJoinBack.
  ///
  /// In en, this message translates to:
  /// **'You already have a seat at this table.'**
  String get webJoinBack;

  /// No description provided for @webJoinContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue as {name}'**
  String webJoinContinue(String name);

  /// No description provided for @webJoinSomeoneElse.
  ///
  /// In en, this message translates to:
  /// **'Join as someone else'**
  String get webJoinSomeoneElse;

  /// No description provided for @webJoinScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on and the sound up while you play.'**
  String get webJoinScreenOn;

  /// No description provided for @webJoinPrivacy.
  ///
  /// In en, this message translates to:
  /// **'No cookies, no tracking: this browser only remembers your seat at the table, for at most 12 hours.'**
  String get webJoinPrivacy;

  /// No description provided for @inBrowser.
  ///
  /// In en, this message translates to:
  /// **'in the browser'**
  String get inBrowser;

  /// No description provided for @inviteHintWeb.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with the Whowolf app, or without the app with your phone\'s camera to play in the browser.'**
  String get inviteHintWeb;

  /// No description provided for @inviteNoBrowser.
  ///
  /// In en, this message translates to:
  /// **'Nobody can join in the browser right now: the server does not have this version of the app yet, and serving the page on the Wi-Fi is off in the settings. The app always works.'**
  String get inviteNoBrowser;

  /// No description provided for @inviteWifiFirst.
  ///
  /// In en, this message translates to:
  /// **'On the same Wi-Fi? The others open Whowolf and tap “Join a room”: your room shows up there by itself.'**
  String get inviteWifiFirst;

  /// No description provided for @inviteShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get inviteShowCode;

  /// No description provided for @inviteLocalCode.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi code only, no server (not in many hotel and guest networks)'**
  String get inviteLocalCode;

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

  /// No description provided for @howTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howTitle;

  /// No description provided for @howEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Curtain up'**
  String get howEyebrow;

  /// No description provided for @howLink.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howLink;

  /// No description provided for @how1Title.
  ///
  /// In en, this message translates to:
  /// **'Open a room'**
  String get how1Title;

  /// No description provided for @how1Text.
  ///
  /// In en, this message translates to:
  /// **'One of you opens a room on their phone. The others scan the QR code and they are in. You sit together at the table, on the same Wi-Fi.'**
  String get how1Text;

  /// No description provided for @how2Title.
  ///
  /// In en, this message translates to:
  /// **'A secret role'**
  String get how2Title;

  /// No description provided for @how2Text.
  ///
  /// In en, this message translates to:
  /// **'Everyone picks a figure and gets a secret role. Most are villagers, a few are werewolves. Don’t show your phone to anyone.'**
  String get how2Text;

  /// No description provided for @how3Title.
  ///
  /// In en, this message translates to:
  /// **'The night'**
  String get how3Title;

  /// No description provided for @how3Text.
  ///
  /// In en, this message translates to:
  /// **'Everyone closes their eyes. The narrator wakes the werewolves: they see who else is in the pack and pick a victim on their phones.'**
  String get how3Text;

  /// No description provided for @how4Title.
  ///
  /// In en, this message translates to:
  /// **'Special roles'**
  String get how4Title;

  /// No description provided for @how4Text.
  ///
  /// In en, this message translates to:
  /// **'Then the seer wakes up and learns one player’s role. The witch can save someone once and poison someone once with her potions.'**
  String get how4Text;

  /// No description provided for @how5Title.
  ///
  /// In en, this message translates to:
  /// **'The morning'**
  String get how5Title;

  /// No description provided for @how5Text.
  ///
  /// In en, this message translates to:
  /// **'Everyone opens their eyes, and the app tells you who was caught. Whoever is out stops talking but may watch.'**
  String get how5Text;

  /// No description provided for @how6Title.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get how6Title;

  /// No description provided for @how6Text.
  ///
  /// In en, this message translates to:
  /// **'Now you argue: who acted suspicious? The werewolves play innocent and lie, the village tries to unmask them.'**
  String get how6Text;

  /// No description provided for @how7Title.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get how7Title;

  /// No description provided for @how7Text.
  ///
  /// In en, this message translates to:
  /// **'Everyone votes in secret on their phone. Whoever gets the most votes leaves the village. Then the next night falls.'**
  String get how7Text;

  /// No description provided for @how8Title.
  ///
  /// In en, this message translates to:
  /// **'Who wins'**
  String get how8Title;

  /// No description provided for @how8Text.
  ///
  /// In en, this message translates to:
  /// **'The village wins as soon as every werewolf is found. The werewolves win once they are as many as everyone else.'**
  String get how8Text;

  /// No description provided for @howPhaseSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get howPhaseSetup;

  /// No description provided for @howPhaseNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get howPhaseNight;

  /// No description provided for @howPhaseMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get howPhaseMorning;

  /// No description provided for @howPhaseDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get howPhaseDay;

  /// No description provided for @howPhaseEnd.
  ///
  /// In en, this message translates to:
  /// **'The end'**
  String get howPhaseEnd;

  /// No description provided for @howDone.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get howDone;

  /// No description provided for @pagePlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get pagePlay;

  /// No description provided for @pageAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get pageAbout;

  /// No description provided for @pageTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get pageTable;

  /// No description provided for @pageInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get pageInvite;

  /// No description provided for @pageGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get pageGame;

  /// No description provided for @act1.
  ///
  /// In en, this message translates to:
  /// **'Prologue'**
  String get act1;

  /// No description provided for @act2.
  ///
  /// In en, this message translates to:
  /// **'Act one'**
  String get act2;

  /// No description provided for @act3.
  ///
  /// In en, this message translates to:
  /// **'Act two'**
  String get act3;

  /// No description provided for @act4.
  ///
  /// In en, this message translates to:
  /// **'Act three'**
  String get act4;

  /// No description provided for @act5.
  ///
  /// In en, this message translates to:
  /// **'Finale'**
  String get act5;

  /// No description provided for @pageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pageSettings;

  /// No description provided for @pageFigure.
  ///
  /// In en, this message translates to:
  /// **'Figure'**
  String get pageFigure;

  /// No description provided for @figureTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are you tonight?'**
  String get figureTitle;

  /// No description provided for @figureTaken.
  ///
  /// In en, this message translates to:
  /// **'taken'**
  String get figureTaken;

  /// No description provided for @quickJoin.
  ///
  /// In en, this message translates to:
  /// **'Join {name}\'s table'**
  String quickJoin(String name);

  /// No description provided for @roomGone.
  ///
  /// In en, this message translates to:
  /// **'This room is no longer open.'**
  String get roomGone;

  /// No description provided for @quickJoinLast.
  ///
  /// In en, this message translates to:
  /// **'Your last table'**
  String get quickJoinLast;

  /// Settings page: Online play.
  ///
  /// In en, this message translates to:
  /// **'Online play'**
  String get settingsOnline;

  /// Settings page: About Whowolf.
  ///
  /// In en, this message translates to:
  /// **'About Whowolf'**
  String get settingsAbout;

  /// Settings page: Saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsSaved;

  /// Settings page: group for how much the stage moves.
  ///
  /// In en, this message translates to:
  /// **'Stage & battery'**
  String get settingsStage;

  /// Stage motion option: everything moves.
  ///
  /// In en, this message translates to:
  /// **'Full stage'**
  String get motionFull;

  /// Hint under the full stage option.
  ///
  /// In en, this message translates to:
  /// **'Flickering lights, drifting mist, a set that follows the tilt of your phone, figures that rock. The prettiest, and it costs the most battery.'**
  String get motionFullHint;

  /// Stage motion option: only moves in answer to the game.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get motionCalm;

  /// Hint under the battery saver option.
  ///
  /// In en, this message translates to:
  /// **'The stage stands still and only moves when something happens: cards turn, the curtain falls. No tilt sensor. Good for a long evening.'**
  String get motionCalmHint;

  /// Stage motion option: nothing moves.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get motionStill;

  /// Hint under the still option.
  ///
  /// In en, this message translates to:
  /// **'Nothing moves at all, like the system\'s reduce motion. Uses the least battery.'**
  String get motionStillHint;

  /// Tooltip of the in-game button to pick how much the stage moves.
  ///
  /// In en, this message translates to:
  /// **'Stage & battery'**
  String get motionMenu;
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
