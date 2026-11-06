# Pocket Hangar

Pocket Hangar (口袋机库) is an open-source EVE Online companion app for Android and iOS. It has
an offline fitting simulator, shows the skill queue and where your ships are, and lists market
orders and price history. You can sign in with several characters and switch between them.

It is a fan project. CCP hf. does not endorse it and is not affiliated with it (see
[EVE Online data and trademarks](#eve-online-data-and-trademarks)).

## Features

- **Skills**: shows the training queue with the finish time of every skill and of the whole queue,
  and the attributes including implants. Training speed is primary + secondary / 2 SP per
  minute, and half that on an Alpha clone. Times come from the server queue, and the app
  estimates them locally when the queue is paused.
- **Ships**: lists every ship of the character with its type, custom name, solar system and
  station or structure, with the current ship first. If the character cannot dock at a
  structure, the app shows "unknown structure" and the system, when the system is known.
- **Market**: shows sell and buy orders in The Forge, filtered to Jita 4-4 by default, a price
  history chart (30 days, 90 days or a year), and favorites.
- **Fitting**, which works offline. It has its own attribute engine built from the static data
  (dogma attributes, effects and modifiers). It shows slots, CPU, powergrid, calibration,
  capacitor stability, resists and EHP, max velocity and align time.
  - Skills are all at V by default, or the signed-in character's trained levels.
  - Fits import from and export to EFT, and can be saved to the character's in-game fittings.
- **Search**: the market search and the ship, module and charge pickers take English or
  Chinese names, or both in one query, in any word order. Case, spaces, hyphens and
  full-width letters do not matter. Abbreviations work: initials (`lse`), letters in order
  (`mwd`, `加燃`), digits for Roman numerals (`dc2`). When little matches, names with a typo
  or two are shown after the rest.
- **Updates**: at startup the app compares its game data with the published manifest. It
  checks the SHA-256 of a new download and swaps the database in atomically. It also checks
  for a new app version: on Android against GitHub Releases, on iOS through an App Store link.
- English and Chinese interface, dark theme.

## How it fits together

```
developers.eveonline.com/static-data  --(daily GitHub Action, pipeline/)-->  GitHub Release
  tranquility/latest.jsonl (buildNumber)                                    sde-<build>: eve-sde-<build>.sqlite.gz
  eve-online-static-data-<build>-jsonl.zip                                   sde-latest:  manifest.json
                                                                                  |
ESI (esi.evetech.net) <---- app (Flutter) ----> images.evetech.net               |
login.eveonline.com   <---- OAuth2 + PKCE        cached on device                 v
                                                                    downloaded on first start
```

- **Data pipeline** (`pipeline/`, Python 3.12): a GitHub Actions job runs once a day. When the
  SDE `buildNumber` changes, it downloads the JSONL archive and checks that every file it needs
  is in it. It then builds a SQLite database of published types with English and Chinese names,
  plus dogma data, market groups, map and NPC stations. The database is gzipped and published
  as release `sde-<build>` with a `manifest.json`
  (`buildNumber, releaseDate, url, sha256, size, schemaVersion`). The rolling release
  `sde-latest` always holds the newest manifest.
- **App**: Flutter, Riverpod, drift (SQLite), dio, flutter_appauth, flutter_secure_storage.
  - **ESI**: every request carries `X-Compatibility-Date: 2026-08-18` and a User-Agent naming
    the app. Responses are cached until `Expires` and revalidated with `ETag`/`If-None-Match`.
    Paged resources are read through `X-Pages` with a `Last-Modified` consistency check.
  - **ESI limits**: the app respects both the error limit (`X-ESI-Error-Limit-*`, 420) and the
    bucket limits (`X-Ratelimit-*`, 429). Nothing retries in a loop.
  - **Sign-in**: authorization code with PKCE. The app holds no client secret. Access tokens
    are JWTs verified against the published JWKS (RS256 and ES256). Only refresh tokens are
    stored, in the platform keystore, and tokens never reach the log.

## Building the app

You need Flutter 3.47 (Dart 3.13), the Android SDK with a JDK 17 or newer (Android Studio's
bundled JDK works), and Xcode on a Mac for iOS.

1. Register an application at <https://developers.eveonline.com/applications>:
   - Connection type: Authentication & API Access
   - Callback URL: `eveauth-pockethangar://callback` (the portal only accepts custom schemes
     that start with `eveauth`)
   - Scopes:
     `esi-skills.read_skills.v1 esi-skills.read_skillqueue.v1 esi-clones.read_clones.v1
     esi-clones.read_implants.v1 esi-assets.read_assets.v1 esi-location.read_location.v1
     esi-location.read_ship_type.v1 esi-universe.read_structures.v1
     esi-wallet.read_character_wallet.v1 esi-markets.read_character_orders.v1
     esi-fittings.read_fittings.v1 esi-fittings.write_fittings.v1`

   The app uses only the client ID. The secret shown on that page is not needed and must not go
   into the app.
2. Run `flutter pub get`.
3. Build for Android:

   ```
   flutter build apk --release --dart-define=EVE_CLIENT_ID=<client id>
   ```

   On Windows, `scripts\build_apk.ps1 -ClientId <client id>` does the same and copies the APK to
   `dist\`.
4. Build for iOS on a Mac with `flutter build ios --release --dart-define=EVE_CLIENT_ID=<client id>`,
   then sign and upload it from Xcode.

Without `EVE_CLIENT_ID` the app still runs: market and fitting work, and sign-in says the client
ID is missing.

**Release signing (Android).** Create `android/key.properties`; git ignores it. It has four
keys:

```
storeFile=upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

`storeFile` is relative to `android/`. Without this file the release APK is signed with the
debug key, and such a build cannot be installed over one signed with the release key.

**SDK components.** On the first build Gradle installs what the project needs into the
Android SDK if it is missing. With Flutter 3.47 that is NDK 28.2.13676358 and Android SDK
Platform 35.

## Development

- After changing drift tables (`lib/core/db/app_database.dart`), run
  `dart run build_runner build`.
- Translations are in `lib/l10n/app_en.arb` and `app_zh.arb`. They are regenerated on
  `flutter pub get`, or with `flutter gen-l10n`.
- `flutter analyze` and `flutter test` run the app's checks. The tests use
  `test/fixtures/sde_test.sqlite`, a slice of SDE build 3670638 made by
  `pipeline/tools/make_test_fixture.py`.
- `cd pipeline && python -m pytest` runs the pipeline tests. The tests against real data run
  when `SDE_ZIP` (the SDE zip) and `SDE_DB` (a built database) are set.
- The fitting engine follows the published dogma rules: modifier operations in order
  preAssign, preMul, preDiv, modAdd, modSub, postMul, postDiv, postPercent, postAssign, and the
  stacking penalty exp(-(n / 2.67)²) per operation. Pyfa was a reference for these rules only;
  none of its code is used. Pyfa is GPL, which conflicts with App Store distribution.

### Running the pipeline by hand

```
cd pipeline
python -m sde_pipeline latest
python -m sde_pipeline download --build <N> --dest ../out
python -m sde_pipeline list --zip ../out/eve-online-static-data-<N>-jsonl.zip
python -m sde_pipeline build --zip ../out/eve-online-static-data-<N>-jsonl.zip --out-dir ../out
```

## Milestones

Each milestone's checks and tests are in [docs/ACCEPTANCE.md](docs/ACCEPTANCE.md).

| | Scope |
|---|---|
| M0 | Data pipeline and the release with the SQLite database and manifest |
| M1 | Sign-in, several characters, skill queue |
| M2 | Market |
| M3 | Ships and where they are |
| M4 | Fitting v1 (DPS, ranges, missiles and drones come in v2) |
| M5 | Update checks, Android APK, iOS test build |

## License

The source code is MIT-licensed, see [LICENSE](LICENSE).

## EVE Online data and trademarks

EVE Online data, images and trademarks belong to CCP hf. They are used under the
[CCP Developer License Agreement](https://developers.eveonline.com/license-agreement) and are
not covered by this project's license. This applies to the static data database published by
the pipeline and to the test fixture in `test/fixtures/`. The app downloads item images from
CCP's image server at runtime; none are bundled.

© 2014 CCP hf. All rights reserved. "EVE", "EVE Online", "CCP", and all related logos and images
are trademarks or registered trademarks of CCP hf.
