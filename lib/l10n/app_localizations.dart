import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pocket Hangar'**
  String get appTitle;

  /// No description provided for @tabSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get tabSkills;

  /// No description provided for @tabMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get tabMarket;

  /// No description provided for @tabAssets.
  ///
  /// In en, this message translates to:
  /// **'Ships'**
  String get tabAssets;

  /// No description provided for @tabFitting.
  ///
  /// In en, this message translates to:
  /// **'Fitting'**
  String get tabFitting;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network request failed. Check the connection and retry.'**
  String get errorNetwork;

  /// No description provided for @errorEsiThrottled.
  ///
  /// In en, this message translates to:
  /// **'ESI is limiting requests. Try again in {seconds} s.'**
  String errorEsiThrottled(Object seconds);

  /// No description provided for @errorEsiServer.
  ///
  /// In en, this message translates to:
  /// **'ESI returned {status}. Try again later.'**
  String errorEsiServer(Object status);

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'The character did not grant access to this data.'**
  String get errorForbidden;

  /// No description provided for @errorReloginNeeded.
  ///
  /// In en, this message translates to:
  /// **'Access for {name} expired. Sign in again.'**
  String errorReloginNeeded(Object name);

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedAt(Object time);

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @addCharacter.
  ///
  /// In en, this message translates to:
  /// **'Add character'**
  String get addCharacter;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgain;

  /// No description provided for @switchCharacter.
  ///
  /// In en, this message translates to:
  /// **'Switch character'**
  String get switchCharacter;

  /// No description provided for @removeCharacter.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeCharacter(Object name);

  /// No description provided for @removeCharacterConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this device? You can add it again later.'**
  String removeCharacterConfirm(Object name);

  /// No description provided for @removeCharacterAction.
  ///
  /// In en, this message translates to:
  /// **'Remove character'**
  String get removeCharacterAction;

  /// No description provided for @noCharacterTitle.
  ///
  /// In en, this message translates to:
  /// **'No character yet'**
  String get noCharacterTitle;

  /// No description provided for @noCharacterBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in with EVE Online to see skills, ships and orders. Fitting and market work without a character.'**
  String get noCharacterBody;

  /// No description provided for @clientIdMissing.
  ///
  /// In en, this message translates to:
  /// **'This build has no EVE client ID. Build with --dart-define=EVE_CLIENT_ID=<your client id>.'**
  String get clientIdMissing;

  /// No description provided for @loginCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled.'**
  String get loginCancelled;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed: {message}'**
  String loginFailed(Object message);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Game data'**
  String get dataSection;

  /// No description provided for @dataBuild.
  ///
  /// In en, this message translates to:
  /// **'Build {build}, released {date}'**
  String dataBuild(Object build, Object date);

  /// No description provided for @dataNone.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get dataNone;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(Object version);

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code (MIT)'**
  String get sourceCode;

  /// No description provided for @ccpNotice.
  ///
  /// In en, this message translates to:
  /// **'EVE Online data, images and trademarks belong to CCP hf. and are used under the CCP Developer License Agreement. © 2014 CCP hf. All rights reserved. \"EVE\", \"EVE Online\", \"CCP\", and all related logos and images are trademarks or registered trademarks of CCP hf.'**
  String get ccpNotice;

  /// No description provided for @sdeOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Download game data'**
  String get sdeOnboardingTitle;

  /// No description provided for @sdeOnboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Items, skills and the star map, about {size}. Downloaded once; fitting then works offline.'**
  String sdeOnboardingBody(Object size);

  /// No description provided for @sdeDownload.
  ///
  /// In en, this message translates to:
  /// **'Download {size}'**
  String sdeDownload(Object size);

  /// No description provided for @sdeDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String sdeDownloading(Object percent);

  /// No description provided for @sdeInstalling.
  ///
  /// In en, this message translates to:
  /// **'Checking and installing…'**
  String get sdeInstalling;

  /// No description provided for @sdeUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Game data build {build} is available ({size}).'**
  String sdeUpdateAvailable(Object build, Object size);

  /// No description provided for @sdeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update data'**
  String get sdeUpdate;

  /// No description provided for @sdeUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Game data is up to date.'**
  String get sdeUpToDate;

  /// No description provided for @sdeChecksumFailed.
  ///
  /// In en, this message translates to:
  /// **'Download check failed (SHA-256 mismatch). Local data was not changed.'**
  String get sdeChecksumFailed;

  /// No description provided for @sdeSchemaTooNew.
  ///
  /// In en, this message translates to:
  /// **'This game data needs a newer app version. Update the app first.'**
  String get sdeSchemaTooNew;

  /// No description provided for @sdeInstalled.
  ///
  /// In en, this message translates to:
  /// **'Game data build {build} installed.'**
  String sdeInstalled(Object build);

  /// No description provided for @appUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.'**
  String appUpdateAvailable(Object version);

  /// No description provided for @appUpdateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get appUpdateDownload;

  /// No description provided for @appUpdateOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Open App Store'**
  String get appUpdateOpenStore;

  /// No description provided for @appUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version.'**
  String get appUpToDate;

  /// No description provided for @skillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsTitle;

  /// No description provided for @totalSp.
  ///
  /// In en, this message translates to:
  /// **'{sp} SP'**
  String totalSp(Object sp);

  /// No description provided for @unallocatedSp.
  ///
  /// In en, this message translates to:
  /// **'{sp} unallocated'**
  String unallocatedSp(Object sp);

  /// No description provided for @skillQueue.
  ///
  /// In en, this message translates to:
  /// **'Training queue'**
  String get skillQueue;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The training queue is empty.'**
  String get queueEmpty;

  /// No description provided for @queuePaused.
  ///
  /// In en, this message translates to:
  /// **'Queue paused'**
  String get queuePaused;

  /// No description provided for @trainingRate.
  ///
  /// In en, this message translates to:
  /// **'{rate} SP/min'**
  String trainingRate(Object rate);

  /// No description provided for @skillFinishes.
  ///
  /// In en, this message translates to:
  /// **'Done {time}'**
  String skillFinishes(Object time);

  /// No description provided for @skillLeft.
  ///
  /// In en, this message translates to:
  /// **'{duration} left'**
  String skillLeft(Object duration);

  /// No description provided for @queueFinishesIn.
  ///
  /// In en, this message translates to:
  /// **'Queue done in {duration}'**
  String queueFinishesIn(Object duration);

  /// No description provided for @queueFinishesAt.
  ///
  /// In en, this message translates to:
  /// **'Last skill done {time}'**
  String queueFinishesAt(Object time);

  /// No description provided for @alphaClone.
  ///
  /// In en, this message translates to:
  /// **'Alpha clone: training at half speed'**
  String get alphaClone;

  /// No description provided for @rateFromServer.
  ///
  /// In en, this message translates to:
  /// **'Times come from the server queue. The local estimate differs by {percent}% (boosters or remaps).'**
  String rateFromServer(Object percent);

  /// No description provided for @attributes.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get attributes;

  /// No description provided for @attrIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Intelligence'**
  String get attrIntelligence;

  /// No description provided for @attrMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get attrMemory;

  /// No description provided for @attrPerception.
  ///
  /// In en, this message translates to:
  /// **'Perception'**
  String get attrPerception;

  /// No description provided for @attrWillpower.
  ///
  /// In en, this message translates to:
  /// **'Willpower'**
  String get attrWillpower;

  /// No description provided for @attrCharisma.
  ///
  /// In en, this message translates to:
  /// **'Charisma'**
  String get attrCharisma;

  /// No description provided for @implantBonus.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} from implants'**
  String implantBonus(Object bonus);

  /// No description provided for @durationDHM.
  ///
  /// In en, this message translates to:
  /// **'{d}d {h}h {m}m'**
  String durationDHM(Object d, Object h, Object m);

  /// No description provided for @durationHM.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String durationHM(Object h, Object m);

  /// No description provided for @durationMS.
  ///
  /// In en, this message translates to:
  /// **'{m}m {s}s'**
  String durationMS(Object m, Object s);

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get marketTitle;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get searchItems;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Items you star show up here.'**
  String get favoritesEmpty;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No items match \"{query}\".'**
  String noResults(Object query);

  /// No description provided for @sellOrders.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellOrders;

  /// No description provided for @buyOrders.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyOrders;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @jitaOnly.
  ///
  /// In en, this message translates to:
  /// **'Jita 4-4 only'**
  String get jitaOnly;

  /// No description provided for @lowestSell.
  ///
  /// In en, this message translates to:
  /// **'Lowest sell'**
  String get lowestSell;

  /// No description provided for @highestBuy.
  ///
  /// In en, this message translates to:
  /// **'Highest buy'**
  String get highestBuy;

  /// No description provided for @ordersIn.
  ///
  /// In en, this message translates to:
  /// **'{count} orders in {region}'**
  String ordersIn(Object count, Object region);

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders.'**
  String get noOrders;

  /// No description provided for @priceHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Average price, last {days} days'**
  String priceHistoryTitle(Object days);

  /// No description provided for @priceChange.
  ///
  /// In en, this message translates to:
  /// **'{change} over {days} days'**
  String priceChange(Object change, Object days);

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No trades recorded.'**
  String get noHistory;

  /// No description provided for @columnPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get columnPrice;

  /// No description provided for @columnQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get columnQuantity;

  /// No description provided for @columnLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get columnLocation;

  /// No description provided for @playerStructure.
  ///
  /// In en, this message translates to:
  /// **'Player structure'**
  String get playerStructure;

  /// No description provided for @assetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ships'**
  String get assetsTitle;

  /// No description provided for @currentShip.
  ///
  /// In en, this message translates to:
  /// **'Current ship'**
  String get currentShip;

  /// No description provided for @inSpace.
  ///
  /// In en, this message translates to:
  /// **'In space'**
  String get inSpace;

  /// No description provided for @unknownStructure.
  ///
  /// In en, this message translates to:
  /// **'Unknown structure'**
  String get unknownStructure;

  /// No description provided for @unknownSystem.
  ///
  /// In en, this message translates to:
  /// **'system unknown'**
  String get unknownSystem;

  /// No description provided for @noShips.
  ///
  /// In en, this message translates to:
  /// **'No ships found.'**
  String get noShips;

  /// No description provided for @packaged.
  ///
  /// In en, this message translates to:
  /// **'Packaged'**
  String get packaged;

  /// No description provided for @shipCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ships'**
  String shipCount(Object count);

  /// No description provided for @insideContainer.
  ///
  /// In en, this message translates to:
  /// **'Inside {name}'**
  String insideContainer(Object name);

  /// No description provided for @fittingTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitting'**
  String get fittingTitle;

  /// No description provided for @newFit.
  ///
  /// In en, this message translates to:
  /// **'New fit'**
  String get newFit;

  /// No description provided for @chooseShip.
  ///
  /// In en, this message translates to:
  /// **'Choose ship'**
  String get chooseShip;

  /// No description provided for @searchShips.
  ///
  /// In en, this message translates to:
  /// **'Search ships'**
  String get searchShips;

  /// No description provided for @importEft.
  ///
  /// In en, this message translates to:
  /// **'Import EFT'**
  String get importEft;

  /// No description provided for @exportEft.
  ///
  /// In en, this message translates to:
  /// **'Copy as EFT'**
  String get exportEft;

  /// No description provided for @eftPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a fit in EFT format'**
  String get eftPasteHint;

  /// No description provided for @eftImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get eftImport;

  /// No description provided for @eftImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read this EFT text: {reason}'**
  String eftImportFailed(Object reason);

  /// No description provided for @eftSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped items that were not found: {names}'**
  String eftSkipped(Object names);

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard.'**
  String get copied;

  /// No description provided for @savedFits.
  ///
  /// In en, this message translates to:
  /// **'Saved fits'**
  String get savedFits;

  /// No description provided for @savedFitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Fits you save show up here.'**
  String get savedFitsEmpty;

  /// No description provided for @deleteFit.
  ///
  /// In en, this message translates to:
  /// **'Delete fit'**
  String get deleteFit;

  /// No description provided for @deleteFitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteFitConfirm(Object name);

  /// No description provided for @fitName.
  ///
  /// In en, this message translates to:
  /// **'Fit name'**
  String get fitName;

  /// No description provided for @slotHigh.
  ///
  /// In en, this message translates to:
  /// **'High slots'**
  String get slotHigh;

  /// No description provided for @slotMid.
  ///
  /// In en, this message translates to:
  /// **'Mid slots'**
  String get slotMid;

  /// No description provided for @slotLow.
  ///
  /// In en, this message translates to:
  /// **'Low slots'**
  String get slotLow;

  /// No description provided for @slotRig.
  ///
  /// In en, this message translates to:
  /// **'Rigs'**
  String get slotRig;

  /// No description provided for @slotSubsystem.
  ///
  /// In en, this message translates to:
  /// **'Subsystems'**
  String get slotSubsystem;

  /// No description provided for @emptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty slot'**
  String get emptySlot;

  /// No description provided for @addModule.
  ///
  /// In en, this message translates to:
  /// **'Add module'**
  String get addModule;

  /// No description provided for @chooseModule.
  ///
  /// In en, this message translates to:
  /// **'Choose module'**
  String get chooseModule;

  /// No description provided for @chooseCharge.
  ///
  /// In en, this message translates to:
  /// **'Choose charge'**
  String get chooseCharge;

  /// No description provided for @removeModule.
  ///
  /// In en, this message translates to:
  /// **'Remove module'**
  String get removeModule;

  /// No description provided for @removeCharge.
  ///
  /// In en, this message translates to:
  /// **'Unload charge'**
  String get removeCharge;

  /// No description provided for @moduleState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get moduleState;

  /// No description provided for @stateOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get stateOffline;

  /// No description provided for @stateOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get stateOnline;

  /// No description provided for @stateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stateActive;

  /// No description provided for @stateOverheated.
  ///
  /// In en, this message translates to:
  /// **'Overheated'**
  String get stateOverheated;

  /// No description provided for @skillsAllV.
  ///
  /// In en, this message translates to:
  /// **'All skills V'**
  String get skillsAllV;

  /// No description provided for @skillsOf.
  ///
  /// In en, this message translates to:
  /// **'Skills of {name}'**
  String skillsOf(Object name);

  /// No description provided for @statFitting.
  ///
  /// In en, this message translates to:
  /// **'Fitting'**
  String get statFitting;

  /// No description provided for @statCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get statCpu;

  /// No description provided for @statPowergrid.
  ///
  /// In en, this message translates to:
  /// **'Powergrid'**
  String get statPowergrid;

  /// No description provided for @statCalibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration'**
  String get statCalibration;

  /// No description provided for @statTurrets.
  ///
  /// In en, this message translates to:
  /// **'Turrets'**
  String get statTurrets;

  /// No description provided for @statLaunchers.
  ///
  /// In en, this message translates to:
  /// **'Launchers'**
  String get statLaunchers;

  /// No description provided for @statCapacitor.
  ///
  /// In en, this message translates to:
  /// **'Capacitor'**
  String get statCapacitor;

  /// No description provided for @capStable.
  ///
  /// In en, this message translates to:
  /// **'Stable at {percent}%'**
  String capStable(Object percent);

  /// No description provided for @capLasts.
  ///
  /// In en, this message translates to:
  /// **'Runs out after {duration}'**
  String capLasts(Object duration);

  /// No description provided for @capRecharge.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s recharge'**
  String capRecharge(Object seconds);

  /// No description provided for @capDelta.
  ///
  /// In en, this message translates to:
  /// **'{use} GJ/s used, {peak} GJ/s peak recharge'**
  String capDelta(Object use, Object peak);

  /// No description provided for @statDefense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get statDefense;

  /// No description provided for @layerShield.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get layerShield;

  /// No description provided for @layerArmor.
  ///
  /// In en, this message translates to:
  /// **'Armor'**
  String get layerArmor;

  /// No description provided for @layerHull.
  ///
  /// In en, this message translates to:
  /// **'Hull'**
  String get layerHull;

  /// No description provided for @damageEm.
  ///
  /// In en, this message translates to:
  /// **'EM'**
  String get damageEm;

  /// No description provided for @damageThermal.
  ///
  /// In en, this message translates to:
  /// **'Thermal'**
  String get damageThermal;

  /// No description provided for @damageKinetic.
  ///
  /// In en, this message translates to:
  /// **'Kinetic'**
  String get damageKinetic;

  /// No description provided for @damageExplosive.
  ///
  /// In en, this message translates to:
  /// **'Explosive'**
  String get damageExplosive;

  /// No description provided for @ehp.
  ///
  /// In en, this message translates to:
  /// **'Effective HP'**
  String get ehp;

  /// No description provided for @ehpUniform.
  ///
  /// In en, this message translates to:
  /// **'Effective HP against even damage'**
  String get ehpUniform;

  /// No description provided for @statNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get statNavigation;

  /// No description provided for @maxVelocity.
  ///
  /// In en, this message translates to:
  /// **'Max velocity'**
  String get maxVelocity;

  /// No description provided for @alignTime.
  ///
  /// In en, this message translates to:
  /// **'Align time'**
  String get alignTime;

  /// No description provided for @signatureRadius.
  ///
  /// In en, this message translates to:
  /// **'Signature radius'**
  String get signatureRadius;

  /// No description provided for @mass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get mass;

  /// No description provided for @fitTooMuchCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU over by {amount} tf'**
  String fitTooMuchCpu(Object amount);

  /// No description provided for @fitTooMuchPower.
  ///
  /// In en, this message translates to:
  /// **'Powergrid over by {amount} MW'**
  String fitTooMuchPower(Object amount);

  /// No description provided for @fitTooMuchCalibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration over by {amount}'**
  String fitTooMuchCalibration(Object amount);

  /// No description provided for @fitNoFreeSlot.
  ///
  /// In en, this message translates to:
  /// **'No free slot for {name}'**
  String fitNoFreeSlot(Object name);

  /// No description provided for @fitWrongShip.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot be fitted to this ship'**
  String fitWrongShip(Object name);

  /// No description provided for @uploadFitToGame.
  ///
  /// In en, this message translates to:
  /// **'Save to in-game fittings'**
  String get uploadFitToGame;

  /// No description provided for @tabModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get tabModules;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @drones.
  ///
  /// In en, this message translates to:
  /// **'Drones'**
  String get drones;

  /// No description provided for @cargo.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get cargo;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard the changes to this fit?'**
  String get unsavedChanges;

  /// No description provided for @fitSaved.
  ///
  /// In en, this message translates to:
  /// **'Fit saved.'**
  String get fitSaved;

  /// No description provided for @fitUploaded.
  ///
  /// In en, this message translates to:
  /// **'Saved to the in-game fittings of {name}.'**
  String fitUploaded(Object name);

  /// No description provided for @uploadNeedsCharacter.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a character first.'**
  String get uploadNeedsCharacter;

  /// No description provided for @fitEmptyCannotUpload.
  ///
  /// In en, this message translates to:
  /// **'Fit at least one module first.'**
  String get fitEmptyCannotUpload;

  /// No description provided for @fitGroupLimit.
  ///
  /// In en, this message translates to:
  /// **'At most {count} of {name} can be fitted.'**
  String fitGroupLimit(Object count, Object name);

  /// No description provided for @secondsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String secondsValue(Object value);

  /// No description provided for @skillsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the skills of {name}, so all skills V are used.'**
  String skillsLoadFailed(Object name);

  /// No description provided for @shipSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Type a ship name in English or Chinese. Part of it, or a small typo, is enough.'**
  String get shipSearchHint;

  /// No description provided for @capCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capCapacity;

  /// No description provided for @capRechargeTime.
  ///
  /// In en, this message translates to:
  /// **'Recharge time'**
  String get capRechargeTime;

  /// No description provided for @capStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get capStatus;

  /// No description provided for @hpColumn.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get hpColumn;

  /// No description provided for @fillSlots.
  ///
  /// In en, this message translates to:
  /// **'Fit to every empty slot'**
  String get fillSlots;

  /// No description provided for @unknownShip.
  ///
  /// In en, this message translates to:
  /// **'This ship is not in the installed game data.'**
  String get unknownShip;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing to choose here.'**
  String get noItems;

  /// No description provided for @eftErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'the text is empty'**
  String get eftErrorEmpty;

  /// No description provided for @eftErrorHeader.
  ///
  /// In en, this message translates to:
  /// **'the first line must look like [Ship, Fit name]'**
  String get eftErrorHeader;

  /// No description provided for @eftErrorShip.
  ///
  /// In en, this message translates to:
  /// **'no ship is called \"{name}\"'**
  String eftErrorShip(Object name);

  /// No description provided for @damageEmShort.
  ///
  /// In en, this message translates to:
  /// **'EM'**
  String get damageEmShort;

  /// No description provided for @damageThermalShort.
  ///
  /// In en, this message translates to:
  /// **'Therm'**
  String get damageThermalShort;

  /// No description provided for @damageKineticShort.
  ///
  /// In en, this message translates to:
  /// **'Kin'**
  String get damageKineticShort;

  /// No description provided for @damageExplosiveShort.
  ///
  /// In en, this message translates to:
  /// **'Exp'**
  String get damageExplosiveShort;

  /// No description provided for @errorHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'The server answered {status}. Try again later.'**
  String errorHttpStatus(Object status);

  /// No description provided for @sdeNotPublished.
  ///
  /// In en, this message translates to:
  /// **'No game data has been published yet. Try again later.'**
  String get sdeNotPublished;

  /// No description provided for @ordersAtJita.
  ///
  /// In en, this message translates to:
  /// **'{count} orders at Jita 4-4'**
  String ordersAtJita(Object count);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
