// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pocket Hangar';

  @override
  String get tabSkills => 'Skills';

  @override
  String get tabMarket => 'Market';

  @override
  String get tabAssets => 'Ships';

  @override
  String get tabFitting => 'Fitting';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading…';

  @override
  String errorWithMessage(Object message) {
    return 'Something went wrong: $message';
  }

  @override
  String get errorNetwork =>
      'Network request failed. Check the connection and retry.';

  @override
  String errorEsiThrottled(Object seconds) {
    return 'ESI is limiting requests. Try again in $seconds s.';
  }

  @override
  String errorEsiServer(Object status) {
    return 'ESI returned $status. Try again later.';
  }

  @override
  String get errorForbidden =>
      'The character did not grant access to this data.';

  @override
  String errorReloginNeeded(Object name) {
    return 'Access for $name expired. Sign in again.';
  }

  @override
  String updatedAt(Object time) {
    return 'Updated $time';
  }

  @override
  String get characters => 'Characters';

  @override
  String get addCharacter => 'Add character';

  @override
  String get signInAgain => 'Sign in again';

  @override
  String get switchCharacter => 'Switch character';

  @override
  String removeCharacter(Object name) {
    return 'Remove $name';
  }

  @override
  String removeCharacterConfirm(Object name) {
    return 'Remove $name from this device? You can add it again later.';
  }

  @override
  String get removeCharacterAction => 'Remove character';

  @override
  String get noCharacterTitle => 'No character yet';

  @override
  String get noCharacterBody =>
      'Sign in with EVE Online to see skills, ships and orders. Fitting and market work without a character.';

  @override
  String get clientIdMissing =>
      'This build has no EVE client ID. Build with --dart-define=EVE_CLIENT_ID=<your client id>.';

  @override
  String get loginCancelled => 'Sign-in cancelled.';

  @override
  String loginFailed(Object message) {
    return 'Sign-in failed: $message';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get dataSection => 'Game data';

  @override
  String dataBuild(Object build, Object date) {
    return 'Build $build, released $date';
  }

  @override
  String get dataNone => 'Not downloaded';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get aboutSection => 'About';

  @override
  String appVersion(Object version) {
    return 'Version $version';
  }

  @override
  String get sourceCode => 'Source code (MIT)';

  @override
  String get ccpNotice =>
      'EVE Online data, images and trademarks belong to CCP hf. and are used under the CCP Developer License Agreement. © 2014 CCP hf. All rights reserved. \"EVE\", \"EVE Online\", \"CCP\", and all related logos and images are trademarks or registered trademarks of CCP hf.';

  @override
  String get sdeOnboardingTitle => 'Download game data';

  @override
  String sdeOnboardingBody(Object size) {
    return 'Items, skills and the star map, about $size. Downloaded once; fitting then works offline.';
  }

  @override
  String sdeDownload(Object size) {
    return 'Download $size';
  }

  @override
  String sdeDownloading(Object percent) {
    return 'Downloading $percent%';
  }

  @override
  String get sdeInstalling => 'Checking and installing…';

  @override
  String sdeUpdateAvailable(Object build, Object size) {
    return 'Game data build $build is available ($size).';
  }

  @override
  String get sdeUpdate => 'Update data';

  @override
  String get sdeUpToDate => 'Game data is up to date.';

  @override
  String get sdeChecksumFailed =>
      'Download check failed (SHA-256 mismatch). Local data was not changed.';

  @override
  String get sdeSchemaTooNew =>
      'This game data needs a newer app version. Update the app first.';

  @override
  String sdeInstalled(Object build) {
    return 'Game data build $build installed.';
  }

  @override
  String appUpdateAvailable(Object version) {
    return 'Version $version is available.';
  }

  @override
  String get appUpdateDownload => 'Download';

  @override
  String get appUpdateOpenStore => 'Open App Store';

  @override
  String get appUpToDate => 'You have the latest version.';

  @override
  String get skillsTitle => 'Skills';

  @override
  String totalSp(Object sp) {
    return '$sp SP';
  }

  @override
  String unallocatedSp(Object sp) {
    return '$sp unallocated';
  }

  @override
  String get skillQueue => 'Training queue';

  @override
  String get queueEmpty => 'The training queue is empty.';

  @override
  String get queuePaused => 'Queue paused';

  @override
  String trainingRate(Object rate) {
    return '$rate SP/min';
  }

  @override
  String skillFinishes(Object time) {
    return 'Done $time';
  }

  @override
  String skillLeft(Object duration) {
    return '$duration left';
  }

  @override
  String queueFinishesIn(Object duration) {
    return 'Queue done in $duration';
  }

  @override
  String queueFinishesAt(Object time) {
    return 'Last skill done $time';
  }

  @override
  String get alphaClone => 'Alpha clone: training at half speed';

  @override
  String rateFromServer(Object percent) {
    return 'Times come from the server queue. The local estimate differs by $percent% (boosters or remaps).';
  }

  @override
  String get attributes => 'Attributes';

  @override
  String get attrIntelligence => 'Intelligence';

  @override
  String get attrMemory => 'Memory';

  @override
  String get attrPerception => 'Perception';

  @override
  String get attrWillpower => 'Willpower';

  @override
  String get attrCharisma => 'Charisma';

  @override
  String implantBonus(Object bonus) {
    return '+$bonus from implants';
  }

  @override
  String durationDHM(Object d, Object h, Object m) {
    return '${d}d ${h}h ${m}m';
  }

  @override
  String durationHM(Object h, Object m) {
    return '${h}h ${m}m';
  }

  @override
  String durationMS(Object m, Object s) {
    return '${m}m ${s}s';
  }

  @override
  String get marketTitle => 'Market';

  @override
  String get searchItems => 'Search items';

  @override
  String get favorites => 'Favorites';

  @override
  String get favoritesEmpty => 'Items you star show up here.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String noResults(Object query) {
    return 'No items match \"$query\".';
  }

  @override
  String get sellOrders => 'Sell';

  @override
  String get buyOrders => 'Buy';

  @override
  String get history => 'History';

  @override
  String get jitaOnly => 'Jita 4-4 only';

  @override
  String get lowestSell => 'Lowest sell';

  @override
  String get highestBuy => 'Highest buy';

  @override
  String ordersIn(Object count, Object region) {
    return '$count orders in $region';
  }

  @override
  String get noOrders => 'No orders.';

  @override
  String priceHistoryTitle(Object days) {
    return 'Average price, last $days days';
  }

  @override
  String priceChange(Object change, Object days) {
    return '$change over $days days';
  }

  @override
  String get noHistory => 'No trades recorded.';

  @override
  String get columnPrice => 'Price';

  @override
  String get columnQuantity => 'Qty';

  @override
  String get columnLocation => 'Location';

  @override
  String get playerStructure => 'Player structure';

  @override
  String get assetsTitle => 'Ships';

  @override
  String get currentShip => 'Current ship';

  @override
  String get inSpace => 'In space';

  @override
  String get unknownStructure => 'Unknown structure';

  @override
  String get unknownSystem => 'system unknown';

  @override
  String get noShips => 'No ships found.';

  @override
  String get packaged => 'Packaged';

  @override
  String shipCount(Object count) {
    return '$count ships';
  }

  @override
  String insideContainer(Object name) {
    return 'Inside $name';
  }

  @override
  String get fittingTitle => 'Fitting';

  @override
  String get newFit => 'New fit';

  @override
  String get chooseShip => 'Choose ship';

  @override
  String get searchShips => 'Search ships';

  @override
  String get importEft => 'Import EFT';

  @override
  String get exportEft => 'Copy as EFT';

  @override
  String get eftPasteHint => 'Paste a fit in EFT format';

  @override
  String get eftImport => 'Import';

  @override
  String eftImportFailed(Object reason) {
    return 'Could not read this EFT text: $reason';
  }

  @override
  String eftSkipped(Object names) {
    return 'Skipped items that were not found: $names';
  }

  @override
  String get copied => 'Copied to the clipboard.';

  @override
  String get savedFits => 'Saved fits';

  @override
  String get savedFitsEmpty => 'Fits you save show up here.';

  @override
  String get deleteFit => 'Delete fit';

  @override
  String deleteFitConfirm(Object name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get fitName => 'Fit name';

  @override
  String get slotHigh => 'High slots';

  @override
  String get slotMid => 'Mid slots';

  @override
  String get slotLow => 'Low slots';

  @override
  String get slotRig => 'Rigs';

  @override
  String get slotSubsystem => 'Subsystems';

  @override
  String get emptySlot => 'Empty slot';

  @override
  String get addModule => 'Add module';

  @override
  String get chooseModule => 'Choose module';

  @override
  String get chooseCharge => 'Choose charge';

  @override
  String get removeModule => 'Remove module';

  @override
  String get removeCharge => 'Unload charge';

  @override
  String get moduleState => 'State';

  @override
  String get stateOffline => 'Offline';

  @override
  String get stateOnline => 'Online';

  @override
  String get stateActive => 'Active';

  @override
  String get stateOverheated => 'Overheated';

  @override
  String get skillsAllV => 'All skills V';

  @override
  String skillsOf(Object name) {
    return 'Skills of $name';
  }

  @override
  String get statFitting => 'Fitting';

  @override
  String get statCpu => 'CPU';

  @override
  String get statPowergrid => 'Powergrid';

  @override
  String get statCalibration => 'Calibration';

  @override
  String get statTurrets => 'Turrets';

  @override
  String get statLaunchers => 'Launchers';

  @override
  String get statCapacitor => 'Capacitor';

  @override
  String capStable(Object percent) {
    return 'Stable at $percent%';
  }

  @override
  String capLasts(Object duration) {
    return 'Runs out after $duration';
  }

  @override
  String capRecharge(Object seconds) {
    return '$seconds s recharge';
  }

  @override
  String capDelta(Object use, Object peak) {
    return '$use GJ/s used, $peak GJ/s peak recharge';
  }

  @override
  String get statDefense => 'Defense';

  @override
  String get layerShield => 'Shield';

  @override
  String get layerArmor => 'Armor';

  @override
  String get layerHull => 'Hull';

  @override
  String get damageEm => 'EM';

  @override
  String get damageThermal => 'Thermal';

  @override
  String get damageKinetic => 'Kinetic';

  @override
  String get damageExplosive => 'Explosive';

  @override
  String get ehp => 'Effective HP';

  @override
  String get ehpUniform => 'Effective HP against even damage';

  @override
  String get statNavigation => 'Navigation';

  @override
  String get maxVelocity => 'Max velocity';

  @override
  String get alignTime => 'Align time';

  @override
  String get signatureRadius => 'Signature radius';

  @override
  String get mass => 'Mass';

  @override
  String fitTooMuchCpu(Object amount) {
    return 'CPU over by $amount tf';
  }

  @override
  String fitTooMuchPower(Object amount) {
    return 'Powergrid over by $amount MW';
  }

  @override
  String fitTooMuchCalibration(Object amount) {
    return 'Calibration over by $amount';
  }

  @override
  String fitNoFreeSlot(Object name) {
    return 'No free slot for $name';
  }

  @override
  String fitWrongShip(Object name) {
    return '$name cannot be fitted to this ship';
  }

  @override
  String get uploadFitToGame => 'Save to in-game fittings';

  @override
  String get tabModules => 'Modules';

  @override
  String get tabStats => 'Stats';

  @override
  String get drones => 'Drones';

  @override
  String get cargo => 'Cargo';

  @override
  String get paste => 'Paste';

  @override
  String get rename => 'Rename';

  @override
  String get discard => 'Discard';

  @override
  String get unsavedChanges => 'Discard the changes to this fit?';

  @override
  String get fitSaved => 'Fit saved.';

  @override
  String fitUploaded(Object name) {
    return 'Saved to the in-game fittings of $name.';
  }

  @override
  String get uploadNeedsCharacter => 'Sign in with a character first.';

  @override
  String get fitEmptyCannotUpload => 'Fit at least one module first.';

  @override
  String fitGroupLimit(Object count, Object name) {
    return 'At most $count of $name can be fitted.';
  }

  @override
  String secondsValue(Object value) {
    return '$value s';
  }

  @override
  String skillsLoadFailed(Object name) {
    return 'Could not load the skills of $name, so all skills V are used.';
  }

  @override
  String get shipSearchHint =>
      'Type a ship name in English or Chinese. Part of it, or a small typo, is enough.';

  @override
  String get capCapacity => 'Capacity';

  @override
  String get capRechargeTime => 'Recharge time';

  @override
  String get capStatus => 'Status';

  @override
  String get hpColumn => 'HP';

  @override
  String get fillSlots => 'Fit to every empty slot';

  @override
  String get unknownShip => 'This ship is not in the installed game data.';

  @override
  String get noItems => 'Nothing to choose here.';

  @override
  String get eftErrorEmpty => 'the text is empty';

  @override
  String get eftErrorHeader => 'the first line must look like [Ship, Fit name]';

  @override
  String eftErrorShip(Object name) {
    return 'no ship is called \"$name\"';
  }

  @override
  String get damageEmShort => 'EM';

  @override
  String get damageThermalShort => 'Therm';

  @override
  String get damageKineticShort => 'Kin';

  @override
  String get damageExplosiveShort => 'Exp';

  @override
  String errorHttpStatus(Object status) {
    return 'The server answered $status. Try again later.';
  }

  @override
  String get sdeNotPublished =>
      'No game data has been published yet. Try again later.';

  @override
  String ordersAtJita(Object count) {
    return '$count orders at Jita 4-4';
  }
}
