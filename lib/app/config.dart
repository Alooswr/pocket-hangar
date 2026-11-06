/// Everything that names a server, an app identity or a URL lives here, so a fork only edits
/// this file (plus the Android applicationId / iOS bundle id).
///
/// Sources, checked 2026-11-06:
/// - ESI headers, compatibility dates, rate limits: developers.eveonline.com/docs/services/esi/
///   (latest compatibility date at that time: 2026-08-18, from esi.evetech.net/meta/compatibility-dates)
/// - SSO endpoints: login.eveonline.com/.well-known/oauth-authorization-server
/// - Image server: developers.eveonline.com/docs/services/image-server/
abstract final class AppConfig {
  static const appName = 'Pocket Hangar';
  static const appNameZh = '口袋机库';
  static const version = '0.1.0';

  static const repo = 'Alooswr/pocket-hangar';
  static const sourceUrl = 'https://github.com/$repo';

  /// Rolling release written by .github/workflows/sde-pipeline.yml.
  static const sdeManifestUrl =
      'https://github.com/$repo/releases/download/sde-latest/manifest.json';

  /// Highest database schema this build understands (pipeline/sde_pipeline/__init__.py).
  static const supportedSdeSchema = 1;

  /// Release list (Android update check); app releases are tagged `v1.2.3`, data releases
  /// `sde-<build>`, so the app picks its own from the list instead of trusting "latest".
  static const githubReleasesApi = 'https://api.github.com/repos/$repo/releases';
  static const githubReleasesPage = 'https://github.com/$repo/releases';

  /// iOS update check: App Store lookup by bundle id. Returns no result until the app is listed.
  static const iosBundleId = 'io.github.alooswr.pocketHangar';
  static const appStoreLookup = 'https://itunes.apple.com/lookup?bundleId=$iosBundleId';

  // ---- ESI ----
  static const esiBaseUrl = 'https://esi.evetech.net';

  /// "This app's ESI usage was reviewed against the API as of this date." Bump after re-checking
  /// the response shapes we parse against the newer spec.
  static const esiCompatibilityDate = '2026-08-18';

  static const userAgent = 'PocketHangar/$version (+$sourceUrl)';

  // ---- SSO (OAuth2 authorization code + PKCE, no client secret in the app) ----
  static const ssoIssuer = 'https://login.eveonline.com';
  static const ssoMetadataUrl = 'https://login.eveonline.com/.well-known/oauth-authorization-server';
  static const ssoAuthorizeUrl = 'https://login.eveonline.com/v2/oauth/authorize';
  static const ssoTokenUrl = 'https://login.eveonline.com/v2/oauth/token';
  static const ssoRevokeUrl = 'https://login.eveonline.com/v2/oauth/revoke';

  /// Public client id of the application registered on developers.eveonline.com.
  /// Pass it at build time: flutter build apk --dart-define=EVE_CLIENT_ID=xxxxxxxx
  static const ssoClientId = String.fromEnvironment('EVE_CLIENT_ID');

  /// Must match the callback URL registered for the application, and the scheme in
  /// android/app/build.gradle.kts (appAuthRedirectScheme) and ios/Runner/Info.plist.
  static const ssoRedirectScheme = 'pockethangar';
  static const ssoRedirectUrl = '$ssoRedirectScheme://sso-callback';

  static const ssoScopes = <String>[
    'esi-skills.read_skills.v1',
    'esi-skills.read_skillqueue.v1',
    'esi-clones.read_clones.v1',
    'esi-clones.read_implants.v1',
    'esi-assets.read_assets.v1',
    'esi-location.read_location.v1',
    'esi-location.read_ship_type.v1',
    'esi-universe.read_structures.v1',
    'esi-wallet.read_character_wallet.v1',
    'esi-markets.read_character_orders.v1',
    'esi-fittings.read_fittings.v1',
    'esi-fittings.write_fittings.v1',
  ];

  // ---- Images ----
  static const imageBaseUrl = 'https://images.evetech.net';

  // ---- Market defaults ----
  static const theForgeRegionId = 10000002;
  static const jita44StationId = 60003760;
}
