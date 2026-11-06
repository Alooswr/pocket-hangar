import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/esi/esi_errors.dart';
import '../../core/esi/eve_api.dart';
import '../../core/log.dart';
import '../../core/providers.dart';
import '../../core/sde/sde_models.dart';
import '../update/sde_controller.dart';

enum PlaceKind { station, structure, space, unknown }

/// Where something is: the station or structure (or space) and the solar system.
class Place {
  const Place({required this.kind, required this.id, this.name, this.system});

  final PlaceKind kind;
  final int id;

  /// Station or structure name; null for space and for structures we may not see.
  final LocalName? name;
  final SolarSystemInfo? system;

  String get groupKey => '${kind.name}:$id';
}

class ShipEntry {
  const ShipEntry({
    required this.itemId,
    required this.type,
    required this.place,
    required this.packaged,
    required this.quantity,
    required this.locationFlag,
    this.customName,
    this.container,
    this.isCurrent = false,
  });

  final int itemId;
  final TypeInfo type;
  final Place place;
  final bool packaged;
  final int quantity;
  final String locationFlag;
  final String? customName;

  /// Name of the container / carrier the ship sits in, when not directly in a hangar.
  final String? container;
  final bool isCurrent;
}

class ShipsOverview {
  const ShipsOverview({required this.ships, required this.fetchedAt, required this.stale});

  final List<ShipEntry> ships;
  final DateTime fetchedAt;
  final bool stale;

  ShipEntry? get current => ships.where((s) => s.isCurrent).firstOrNull;
}

const _structureRecheck = Duration(days: 7);

bool _isStation(int id) => id >= 60000000 && id < 64000000;

bool _isSolarSystem(int id) => id >= 30000000 && id < 33000000;

/// Lists every ship of the character with its location.
///
/// Assets reference their parent by location_id: a station, a solar system, a structure, or
/// another item (container, carrier). We walk up the item chain to the root. Player structure
/// names need esi-universe.read_structures.v1 and docking access; without access ESI answers 403
/// and the ship is shown as "unknown structure" with the solar system if we learned it before
/// (an earlier successful lookup, or the character being docked there now).
final shipsProvider = FutureProvider.autoDispose.family<ShipsOverview, int>((ref, characterId) async {
  final sde = requireSde(ref);
  final api = ref.watch(eveApiProvider);
  final db = ref.watch(appDatabaseProvider);

  final assetsResp = await api.assets(characterId);
  final assets = [for (final a in assetsResp.data) a as Map<String, dynamic>];
  final byId = {for (final a in assets) (a['item_id'] as num).toInt(): a};
  final types = await sde.types(assets.map((a) => (a['type_id'] as num).toInt()));
  final ships = assets.where((a) => types[(a['type_id'] as num).toInt()]?.isShip ?? false).toList();

  // Current ship and location (best effort: missing scopes should not break the list).
  int? currentShipId;
  Map<String, dynamic>? currentLocation;
  Map<String, dynamic>? currentShip;
  try {
    currentShip = (await api.ship(characterId)).data as Map<String, dynamic>?;
    currentShipId = (currentShip?['ship_item_id'] as num?)?.toInt();
    currentLocation = (await api.location(characterId)).data as Map<String, dynamic>?;
  } on EsiException catch (e) {
    appLog('current ship/location unavailable: $e');
  }

  // Walk up to the root location, remembering the first container on the way.
  (int, String, int?) root(Map<String, dynamic> asset) {
    var current = asset;
    int? container;
    for (var depth = 0; depth < 12; depth++) {
      final locationId = (current['location_id'] as num).toInt();
      final parent = byId[locationId];
      if (current['location_type'] != 'item' || parent == null) {
        return (locationId, current['location_type'] as String, container);
      }
      container ??= locationId;
      current = parent;
    }
    return ((current['location_id'] as num).toInt(), current['location_type'] as String, container);
  }

  final roots = {for (final s in ships) (s['item_id'] as num).toInt(): root(s)};

  // Custom names: assembled ships and the containers they sit in.
  final nameIds = <int>{
    for (final s in ships)
      if (s['is_singleton'] == true) (s['item_id'] as num).toInt(),
    for (final r in roots.values) ?r.$3,
  }.toList();
  final names = <int, String>{};
  for (var i = 0; i < nameIds.length; i += 1000) {
    final chunk = nameIds.sublist(i, i + 1000 > nameIds.length ? nameIds.length : i + 1000);
    try {
      final result = await api.assetNames(characterId, chunk) as List<dynamic>? ?? const [];
      for (final n in result) {
        final m = n as Map<String, dynamic>;
        final name = (m['name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty && name != 'None') names[(m['item_id'] as num).toInt()] = name;
      }
    } on EsiException catch (e) {
      appLog('asset names failed: $e');
    }
  }

  // Structures: cached lookups, refreshed weekly; 403 is remembered as "no access".
  final structureIds = {
    for (final r in roots.values)
      if (!_isStation(r.$1) && !_isSolarSystem(r.$1) && r.$2 != 'other') r.$1,
  };
  final structures = await _resolveStructures(db, api, characterId, structureIds, currentLocation);

  final systemIds = <int>{
    for (final r in roots.values)
      if (_isSolarSystem(r.$1)) r.$1,
    for (final s in structures.values) ?s.solarSystemId,
  };
  final stations = await sde.stations({for (final r in roots.values) if (_isStation(r.$1)) r.$1});
  systemIds.addAll(stations.values.map((s) => s.solarSystemId));
  final systems = await sde.solarSystems(systemIds);

  Place placeFor((int, String, int?) r) {
    final id = r.$1;
    if (_isStation(id)) {
      final st = stations[id];
      return Place(kind: PlaceKind.station, id: id, name: st?.name, system: st == null ? null : systems[st.solarSystemId]);
    }
    if (_isSolarSystem(id)) return Place(kind: PlaceKind.space, id: id, system: systems[id]);
    final info = structures[id];
    if (info != null) {
      final name = info.name;
      return Place(
        kind: PlaceKind.structure,
        id: id,
        name: name == null ? null : LocalName(name, null),
        system: info.solarSystemId == null ? null : systems[info.solarSystemId],
      );
    }
    return Place(kind: r.$2 == 'other' ? PlaceKind.unknown : PlaceKind.structure, id: id);
  }

  final entries = <ShipEntry>[
    for (final s in ships)
      () {
        final itemId = (s['item_id'] as num).toInt();
        final r = roots[itemId]!;
        final containerId = r.$3;
        final containerType = containerId == null ? null : types[(byId[containerId]!['type_id'] as num).toInt()];
        return ShipEntry(
          itemId: itemId,
          type: types[(s['type_id'] as num).toInt()]!,
          place: placeFor(r),
          packaged: s['is_singleton'] != true,
          quantity: (s['quantity'] as num?)?.toInt() ?? 1,
          locationFlag: s['location_flag'] as String? ?? '',
          customName: names[itemId],
          container: containerId == null ? null : (names[containerId] ?? containerType?.name.en),
          isCurrent: itemId == currentShipId,
        );
      }(),
  ];

  // The active ship is not always in the asset list (e.g. in space); add it from /ship + /location.
  if (currentShipId != null && !entries.any((e) => e.isCurrent) && currentShip != null) {
    final type = (await sde.types([(currentShip['ship_type_id'] as num).toInt()])).values.firstOrNull;
    final loc = currentLocation;
    if (type != null && loc != null) {
      final stationId = (loc['station_id'] as num?)?.toInt();
      final structureId = (loc['structure_id'] as num?)?.toInt();
      final systemId = (loc['solar_system_id'] as num).toInt();
      final rootTuple = stationId != null
          ? (stationId, 'station', null)
          : structureId != null
              ? (structureId, 'item', null)
              : (systemId, 'solar_system', null);
      systems.addAll(await sde.solarSystems([systemId]));
      if (stationId != null) stations.addAll(await sde.stations([stationId]));
      entries.add(ShipEntry(
        itemId: currentShipId,
        type: type,
        place: placeFor(rootTuple),
        packaged: false,
        quantity: 1,
        locationFlag: '',
        customName: currentShip['ship_name'] as String?,
        isCurrent: true,
      ));
    }
  }

  return ShipsOverview(ships: entries, fetchedAt: assetsResp.fetchedAt, stale: assetsResp.isStale);
});

Future<Map<int, StructureInfo>> _resolveStructures(
  AppDatabase db,
  EveApi api,
  int characterId,
  Set<int> ids,
  Map<String, dynamic>? currentLocation,
) async {
  if (ids.isEmpty) return {};
  final cached = {
    for (final row in await (db.select(db.structureInfos)..where((t) => t.structureId.isIn(ids))).get())
      row.structureId: row,
  };
  final now = DateTime.now();
  for (final id in ids) {
    final row = cached[id];
    if (row != null && now.difference(row.fetchedAt) < _structureRecheck) continue;
    try {
      final data = (await api.structure(characterId, id)).data as Map<String, dynamic>;
      final companion = StructureInfosCompanion.insert(
        structureId: Value(id),
        name: Value(data['name'] as String?),
        solarSystemId: Value((data['solar_system_id'] as num?)?.toInt()),
        typeId: Value((data['type_id'] as num?)?.toInt()),
        accessDenied: const Value(false),
        fetchedAt: now,
      );
      await db.into(db.structureInfos).insertOnConflictUpdate(companion);
    } on EsiForbidden {
      await db.into(db.structureInfos).insertOnConflictUpdate(StructureInfosCompanion.insert(
            structureId: Value(id),
            name: Value(row?.name),
            solarSystemId: Value(row?.solarSystemId),
            accessDenied: const Value(true),
            fetchedAt: now,
          ));
    } on EsiException catch (e) {
      appLog('structure $id lookup failed: $e');
    }
  }
  // Docked in a structure right now: that tells us its system even without access.
  final dockedStructure = (currentLocation?['structure_id'] as num?)?.toInt();
  final dockedSystem = (currentLocation?['solar_system_id'] as num?)?.toInt();
  if (dockedStructure != null && dockedSystem != null && ids.contains(dockedStructure)) {
    final existing = await (db.select(db.structureInfos)..where((t) => t.structureId.equals(dockedStructure)))
        .getSingleOrNull();
    if (existing == null || existing.solarSystemId == null) {
      await db.into(db.structureInfos).insertOnConflictUpdate(StructureInfosCompanion.insert(
            structureId: Value(dockedStructure),
            name: Value(existing?.name),
            solarSystemId: Value(dockedSystem),
            accessDenied: Value(existing?.accessDenied ?? true),
            fetchedAt: existing?.fetchedAt ?? now,
          ));
    }
  }
  return {
    for (final row in await (db.select(db.structureInfos)..where((t) => t.structureId.isIn(ids))).get())
      row.structureId: row,
  };
}
