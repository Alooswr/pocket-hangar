# Acceptance checklists

Each milestone lists what must be true, the automated tests that cover it, and what still needs
a device, an account or a published release.

Status on 2026-11-06, SDE build 3670638:

- `flutter analyze`: no issues.
- `flutter test`: 107 passed, 2 skipped (search speed, runs with `SDE_DB` set; the published
  release, runs with `LIVE_SDE=1`).
- `pipeline: python -m pytest`: 28 passed, real-data tests included.
- GitHub Actions on `a90b6a4`, the first push: every job passed (analyze, the same 107 tests,
  pipeline unit tests with the real-data ones skipped, Android APK, unsigned iOS build).

Legend: **[x]** verified (test or local run) · **[ ]** open, with the reason.

## M0: data pipeline and release

- [x] The latest build is read from `tranquility/latest.jsonl` (`buildNumber`, `releaseDate`).
  - Tests: `test_pipeline_unit.py::test_parse_latest_picks_sde_record`.
- [x] The build is skipped when `buildNumber` and the schema version match the published
  manifest, and can be forced.
  - Tests: `test_pipeline_unit.py::test_needs_build_decision`.
- [x] File names come from the archive itself. A missing file stops the build and lists what is
  there.
  - Tests: `test_pipeline_unit.py::test_missing_file_is_reported_with_real_listing`.
  - The real archive's file list was printed and checked (`python -m sde_pipeline list`).
- [x] Only published types are kept, with English and Chinese names.
  - Tests: `test_real_sde.py::test_only_published_types`,
    `test_pipeline_unit.py::test_names_keep_english_and_chinese`.
- [x] Rifter (587) and the other spot-checked ships have slots, CPU and PG equal to the raw SDE,
  and so does every published ship.
  - Tests: `test_real_sde.py`.
- [x] NPC station names are built the way ESI names them, for example
  "Jita IV - Moon 4 - Caldari Navy Assembly Plant". During development all 5210 stations were
  compared with ESI once, with 0 mismatches.
  - Tests: `test_real_sde.py::test_npc_stations`,
    `test_pipeline_unit.py::test_station_names_are_composed`.
- [x] `manifest.json` has `buildNumber, releaseDate, url, sha256, size`, plus
  `schemaVersion, compression`.
  - Tests: `test_pipeline_unit.py::test_manifest_hash_and_size_match_the_gz`.
- [x] Local run: the database is 9.3 MB (3.0 MB gzipped) and builds in about 5 s.
- [x] The first GitHub releases, `sde-3670638` and the rolling `sde-latest` manifest, published by
  the `SDE pipeline` workflow (run by hand on 2026-11-06, then daily at 13:17 UTC). On the runner
  the 28 pipeline tests passed against the real SDE before anything was published.
  - The app's installer fetched the manifest from its built-in URL, downloaded the 3.0 MB
    database, checked the SHA-256, installed it, and found the Rifter by `裂谷` and by `rfiter`.
  - Tests: `live_release_test.dart` (runs with `LIVE_SDE=1`).
  - Until the first app version is released, GitHub labels `sde-latest` as the repository's
    latest release. The app's update check reads the whole release list and only counts `vX.Y.Z`
    tags, so it is not affected.

## M1: sign-in, several characters, skill queue

- [x] Authorization code with PKCE through flutter_appauth. No client secret anywhere: the client
  ID is supplied at build time with `--dart-define`.
- [x] The access token (JWT) is verified against the JWKS, both RS256 and ES256:
  - issuer is one of the three accepted forms;
  - audience contains both the client ID and "EVE Online";
  - the token is not expired;
  - subject is `CHARACTER:EVE:<id>`;
  - a key rotation triggers one reload of the key set.
  - Tests: `auth_test.dart`.
- [x] Tokens never reach the log: bearer tokens, JWTs and token fields are redacted.
  - Tests: `auth_test.dart` log redaction.
- [x] Several characters: add, switch, remove, mark "sign in again" when a refresh is refused.
  Only refresh tokens are stored, in secure storage.
- [x] Training maths:
  - SP per level = 250 × rank × 32^((L−1)/2);
  - SP/min = primary + secondary/2, half for Alpha;
  - implants are added to the attributes;
  - Alpha is detected from the server rate.
  - Tests: `skills_test.dart`.
- [x] Finish time per skill and for the whole queue. A paused queue gets local estimates;
  skills that finished since ESI cached the queue are dropped.
  - Tests: `skills_test.dart`.
- [ ] Real sign-in on a phone. This needs the application registered at
  developers.eveonline.com (callback `pockethangar://sso-callback`, 12 scopes) and its client
  ID.

## M2: market

- [x] The default region is The Forge (10000002) and the default station Jita 4-4 (60003760).
- [x] Every page is read through `X-Pages`. Pages from different cache generations
  (`Last-Modified`) are fetched again.
  - Tests: `esi_client_test.dart` pagination.
- [x] `Expires`/`ETag` caching:
  - a 304 keeps the body;
  - stale data is shown when ESI is unreachable;
  - the error limit (420) and bucket limits (429) are respected.
  - Tests: `esi_client_test.dart`.
- [x] The price history line chart shows one series, a 30 days / 90 days / 1 year window, and
  the change over the window.
  - Tests: `widget_test.dart`.
- [x] Favorites are kept on the device.
- [x] Search takes English and Chinese names, mixed in one query, in any word order:
  - case, spaces, hyphens and full-width letters are ignored;
  - initials (`lse`), letters in order (`mwd`, `加燃`) and digits for Roman numerals (`dc2`)
    match;
  - typos (`rfiter`, `列谷级`) are tried only when the strict match finds fewer than 8 items,
    and rank after it.
  - Ranking: exact, then prefix, whole word, word start, initials, part of the name, letters
    in order.
  - Tests: `search_test.dart`.
  - SQLite drops most rows before the Dart scoring runs; a test checks that this prefilter
    returns exactly what the Dart ranking returns on the fixture.
  - On the full SDE (19,732 market types) a search takes 30 to 75 ms on a desktop, including
    the typo pass (`SDE_DB=... flutter test test/search_test.dart`).
- [x] Item images come from the image server: `icon` for most types, `bp` for blueprints,
  none for SKINs (the server has no SKIN images, a local icon is shown).
  - Tests: `eve_image_test.dart`.
- [x] Live check against ESI on the emulator: orders, station names, price history (see M5).
- [ ] The same on a real phone.

## M3: ships and where they are

- [x] Every ship is listed with type, custom name, solar system, and station or structure, and
  the current ship comes first.
  - Tests: `assets_test.dart`.
- [x] A ship in a container is placed where the container is, and the container's name is
  shown.
  - Tests: `assets_test.dart`.
- [x] Without docking access (403) the location shows as "unknown structure". The solar system
  is shown when it is known, for example while the character is docked there.
  - Tests: `assets_test.dart`.
- [x] Structure lookups are cached for a week and a 403 is remembered, so ESI is not asked again
  each time.
  - Tests: `assets_test.dart`.
- [x] The active ship is added from `/ship` and `/location` when it is not in the asset list,
  for example in space.
  - Tests: `assets_test.dart`.
- [ ] Live check with a real character.

## M4: fitting v1

- [x] The attribute engine works from the SDE's dogma attributes, effects and modifiers.
  Pyfa's rules were consulted; none of its code is used.
- [x] Reference values for a Rifter with all skills at V, worked out by hand from the SDE base
  values and the skill bonuses:

  | Stat | Value |
  |---|---|
  | CPU | 162.5 tf |
  | Powergrid | 51.25 MW |
  | Shield | 562.5 |
  | Armor | 562.5 |
  | Hull | 437.5 |
  | Capacitor | 312.5 GJ |
  | Recharge | 93.75 s |
  | Max velocity | 456.25 m/s |
  | Agility | 2.16 |
  | Align time | 3.195 s |
  | With 1MN Afterburner II active | 1,567,000 kg, 1193.25 m/s |

  - Tests: `dogma_stats_test.dart`.
- [x] Modifier order and stacking:
  - the extender adds HP before the skill percentage;
  - the second hardener is stacking-penalized;
  - the damage control has its own chain;
  - penalty factors 1, 0.8691, 0.5706, 0.2830.
  - Tests: `dogma_stats_test.dart`.
- [x] Capacitor: the stable level matches the closed form, and the time to empty matches a fine
  numerical integration; cap boosters are counted.
  - Tests: `dogma_stats_test.dart`.
- [x] Strategic cruiser slots and hardpoints come from the subsystems.
  - Tests: `dogma_stats_test.dart`.
- [x] Fitting rules:
  - slot limits;
  - one per group (maxGroupFitted), for example the damage control;
  - one active per group (maxGroupActive), for example prop modules;
  - rig size, subsystem hull and canFitShip lists.
  - Tests: `fit_editing_test.dart`.
- [x] The ship, module and charge pickers use the same search as the market, inside their
  filters (slot, rig size, subsystem hull, charge group and size).
  - Tests: `search_test.dart` module and ship picker cases.
- [x] Skills are at V by default; the signed-in character's skills can be chosen instead.
- [x] EFT import and export round-trip, including `/OFFLINE`, charges, drones, cargo and
  empty slots; bad text is reported.
  - Tests: `fit_editing_test.dart`.
- [x] Saved fits keep type IDs, so they survive item renames. They can be saved to the
  in-game fittings (ESI flags HiSlot0…, DroneBay, Cargo).
  - Tests: `fit_editing_test.dart`.
- [x] The editor renders the stats of an empty Rifter in English and Chinese.
  - Tests: `widget_test.dart`.
- [ ] Cross-check the reference values against Pyfa or the in-game fitting window. They are
  derived independently but not compared yet.
- [ ] v2: DPS, ranges, missiles, drones.

## M5: update checks and builds

- [x] Game data:
  - the manifest is read at startup;
  - SHA-256 is verified;
  - the schema version is checked;
  - the build number must match;
  - the database is swapped in atomically, and a failure leaves the installed data alone.
  - Tests: `updates_test.dart`; `live_release_test.dart` runs the same installer against the
    published release.
- [x] Android update check: the newest `vX.Y.Z` GitHub release with an APK. Data releases
  (`sde-<build>`) in the same repository are ignored.
  - Tests: `updates_test.dart`.
- [x] iOS shows a notice with an App Store link and never updates itself.
- [x] Android release APK built locally with `scripts/build_apk.ps1`:
  `dist\PocketHangar-0.1.0.apk`, 66 MB with arm, arm64 and x86_64 code. It is debug-signed
  until a release key exists.
- [x] Smoke test of the release APK on an Android 12 x86_64 emulator, with the SDE copied in
  by hand and no character signed in:
  - market search with typos and abbreviations (`rfiter`, `1mn ab`, `mwd`); item icons,
    blueprint images, and the local icon for SKINs;
  - the Rifter market page: Jita 4-4 orders with ESI's station names, and the 90-day price
    chart;
  - fitting: ship picker, module picker, a 5MN Microwarpdrive I fitted. The stats match the
    reference values, and the capacitor drops to 234.4 GJ (312.5 GJ x 0.75 MWD penalty).
  - Found and fixed during the test, each with a test:
    - item images never appeared, because the download cache never completed its future;
    - the result list shrank to two rows while the keyboard was open, because the keyboard
      height was taken off twice;
    - the chart's axis-end labels overlapped the grid labels.
  - Not checked on the emulator: Chinese input (adb cannot type it; covered by tests), sign-in
    and the character tabs (no client ID yet).
- [x] Unsigned iOS build: the `ios` job in `.github/workflows/app-ci.yml` built `Runner.app` on
  macOS in the first CI run. The Android job built the release APK there too; both are kept as
  workflow artifacts for 90 days.
- [ ] TestFlight needs an Apple Developer account, signing, and an App Store Connect entry.
- [ ] Release signing key for Android: create it and keep it safe. Without the same key,
  updates cannot be installed over earlier builds.
