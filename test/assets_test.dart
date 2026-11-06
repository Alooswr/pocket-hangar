import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/core/db/app_database.dart';
import 'package:pocket_hangar/core/esi/esi_client.dart';
import 'package:pocket_hangar/core/esi/eve_api.dart';
import 'package:pocket_hangar/core/esi/rate_limiter.dart';
import 'package:pocket_hangar/core/providers.dart';
import 'package:pocket_hangar/features/assets/assets_data.dart';
import 'package:pocket_hangar/features/update/sde_controller.dart';

import 'esi_client_test.dart' show FakeAdapter;
import 'support/fixture.dart';

const jita44 = 60003760;
const jita = 30000142;
const noAccess = 1035000000001;
const dockedHere = 1035000000002;

ResponseBody reply(Object? body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        'expires': [HttpDate.format(DateTime.now().toUtc().add(const Duration(minutes: 5)))],
        'x-pages': ['1'],
      },
    );

void main() {
  late FitBench bench;
  late AppDatabase db;
  late FakeAdapter adapter;
  late ProviderContainer container;
  late Map<String, dynamic> shipJson;
  late Map<String, dynamic> locationJson;

  setUp(() async {
    bench = await FitBench.open();
    db = AppDatabase(NativeDatabase.memory());
    final rifter = await bench.id('Rifter');
    final merlin = await bench.id('Merlin');
    final punisher = await bench.id('Punisher');
    final emp = await bench.id('EMP S');
    final assets = [
      {'item_id': 1001, 'type_id': rifter, 'location_id': jita44, 'location_type': 'station', 'location_flag': 'Hangar', 'is_singleton': true, 'quantity': 1},
      {'item_id': 1002, 'type_id': merlin, 'location_id': noAccess, 'location_type': 'item', 'location_flag': 'Hangar', 'is_singleton': false, 'quantity': 2},
      {'item_id': 1003, 'type_id': punisher, 'location_id': dockedHere, 'location_type': 'item', 'location_flag': 'Hangar', 'is_singleton': true, 'quantity': 1},
      // A packaged Rifter inside a named container in Jita 4-4 (the container type is not in the fixture).
      {'item_id': 2001, 'type_id': 3467, 'location_id': jita44, 'location_type': 'station', 'location_flag': 'Hangar', 'is_singleton': true, 'quantity': 1},
      {'item_id': 1004, 'type_id': rifter, 'location_id': 2001, 'location_type': 'item', 'location_flag': 'Unlocked', 'is_singleton': false, 'quantity': 1},
      // Not a ship.
      {'item_id': 3001, 'type_id': emp, 'location_id': jita44, 'location_type': 'station', 'location_flag': 'Hangar', 'is_singleton': false, 'quantity': 5000},
    ];
    shipJson = {'ship_item_id': 1003, 'ship_type_id': punisher, 'ship_name': 'Docked Punisher'};
    locationJson = {'solar_system_id': jita, 'structure_id': dockedHere};
    adapter = FakeAdapter((o) => switch ((o.method, o.path)) {
          ('GET', '/characters/1/assets') => reply(assets),
          ('GET', '/characters/1/ship') => reply(shipJson),
          ('GET', '/characters/1/location') => reply(locationJson),
          ('POST', '/characters/1/assets/names') => reply([
              {'item_id': 1001, 'name': 'Main Rifter'},
              {'item_id': 2001, 'name': 'My Box'},
              {'item_id': 1003, 'name': 'None'},
            ]),
          ('GET', final p) when p.startsWith('/universe/structures/') => reply({'error': 'Forbidden'}, status: 403),
          _ => reply({'error': 'unexpected ${o.method} ${o.path}'}, status: 400),
        });
    final client = EsiClient(
      dio: EsiClient.createDio()..httpClientAdapter = adapter,
      cache: MemoryEsiCacheStore(),
      limiter: EsiRateLimiter(),
      accessToken: (id, {forceRefresh = false}) async => 'token',
    );
    container = ProviderContainer(
      overrides: [
        sdeRepositoryProvider.overrideWithValue(bench.sde),
        eveApiProvider.overrideWithValue(EveApi(client)),
        appDatabaseProvider.overrideWithValue(db),
      ],
      retry: (_, _) => null,
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await bench.close();
  });

  Future<ShipsOverview> load() async {
    final sub = container.listen(shipsProvider(1), (_, _) {});
    try {
      return await container.read(shipsProvider(1).future);
    } finally {
      sub.close();
    }
  }

  test('ships with their stations, structures and containers', () async {
    final o = await load();
    final byId = {for (final s in o.ships) s.itemId: s};
    expect(byId.keys.toSet(), {1001, 1002, 1003, 1004}, reason: 'charges are not ships');

    final main = byId[1001]!;
    expect(main.customName, 'Main Rifter');
    expect(main.place.kind, PlaceKind.station);
    expect(main.place.name?.en, 'Jita IV - Moon 4 - Caldari Navy Assembly Plant');
    expect(main.place.system?.name.en, 'Jita');
    expect(main.packaged, isFalse);

    final packaged = byId[1002]!;
    expect(packaged.packaged, isTrue);
    expect(packaged.quantity, 2);
    expect(packaged.place.kind, PlaceKind.structure);
    expect(packaged.place.name, isNull, reason: 'no docking access: shown as unknown structure');
    expect(packaged.place.system, isNull);

    final docked = byId[1003]!;
    expect(docked.isCurrent, isTrue);
    expect(o.current?.itemId, 1003);
    expect(docked.customName, isNull, reason: '"None" is not a name');
    expect(docked.place.kind, PlaceKind.structure);
    expect(docked.place.system?.solarSystemId, jita, reason: 'learned from the current location');

    final boxed = byId[1004]!;
    expect(boxed.container, 'My Box');
    expect(boxed.place.id, jita44);
  });

  test('structure lookups are remembered for a week', () async {
    await load();
    final rows = {for (final r in await db.select(db.structureInfos).get()) r.structureId: r};
    expect(rows[noAccess]?.accessDenied, isTrue);
    expect(rows[dockedHere]?.solarSystemId, jita);
    final lookups = adapter.requests.where((r) => r.path.startsWith('/universe/structures/')).length;
    expect(lookups, 2);

    container.invalidate(shipsProvider(1));
    await load();
    expect(adapter.requests.where((r) => r.path.startsWith('/universe/structures/')).length, lookups);
  });

  test('the active ship is added when it is not in the asset list', () async {
    final rifter = await bench.id('Rifter');
    shipJson = {'ship_item_id': 9999, 'ship_type_id': rifter, 'ship_name': 'Out There'};
    locationJson = {'solar_system_id': jita};
    final o = await load();
    final current = o.current!;
    expect(current.itemId, 9999);
    expect(current.customName, 'Out There');
    expect(current.place.kind, PlaceKind.space);
    expect(current.place.system?.name.en, 'Jita');
    expect(o.ships.where((s) => s.isCurrent).length, 1);
  });
}
