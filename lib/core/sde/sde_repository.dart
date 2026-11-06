import 'package:drift/drift.dart';

import '../search/name_search.dart';
import 'sde_database.dart';
import 'sde_models.dart';

/// Dogma attribute ids used outside the fitting engine.
abstract final class AttrIds {
  static const charisma = 164;
  static const intelligence = 165;
  static const memory = 166;
  static const perception = 167;
  static const willpower = 168;
  static const primaryAttribute = 180;
  static const secondaryAttribute = 181;
  static const skillTimeConstant = 275;
  static const charismaBonus = 175;
  static const intelligenceBonus = 176;
  static const memoryBonus = 177;
  static const perceptionBonus = 178;
  static const willpowerBonus = 179;

  /// chargeGroup1..5 on a module: the item groups of the charges it loads. (602/603/2076-2078
  /// next to them are launcherGroupN, which charges use to name their launchers.)
  static const chargeGroups = [604, 605, 606, 609, 610];
  static const chargeSize = 128;

  /// implant attribute bonus attribute -> character attribute it raises
  static const implantBonusToAttribute = {
    charismaBonus: charisma,
    intelligenceBonus: intelligence,
    memoryBonus: memory,
    perceptionBonus: perception,
    willpowerBonus: willpower,
  };
}

/// Read-only queries against the SDE database. All lookups that take many ids are chunked so
/// the IN (...) lists stay below SQLite's variable limit.
class SdeRepository {
  SdeRepository(this.db);

  final SdeDatabase db;

  static const _typeColumns =
      'type_id, group_id, category_id, market_group_id, meta_group_id, name_en, name_zh, volume, packaged_volume, mass, capacity';

  Future<List<QueryRow>> _select(String sql, [List<Object?> args = const []]) =>
      db.customSelect(sql, variables: [for (final a in args) _variable(a)]).get();

  static Variable<Object> _variable(Object? value) => switch (value) {
        final int v => Variable.withInt(v),
        final double v => Variable.withReal(v),
        final String v => Variable.withString(v),
        final bool v => Variable.withBool(v),
        null => const Variable(null),
        _ => throw ArgumentError('unsupported SQL argument $value'),
      };

  static Iterable<List<int>> _chunks(Iterable<int> ids, [int size = 400]) sync* {
    final list = ids.toSet().toList();
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }

  static TypeInfo _type(QueryRow r) => TypeInfo(
        typeId: r.read<int>('type_id'),
        groupId: r.read<int>('group_id'),
        categoryId: r.read<int>('category_id'),
        name: LocalName(r.read<String>('name_en'), r.readNullable<String>('name_zh')),
        marketGroupId: r.readNullable<int>('market_group_id'),
        metaGroupId: r.readNullable<int>('meta_group_id'),
        volume: r.readNullable<double>('volume'),
        packagedVolume: r.readNullable<double>('packaged_volume'),
        mass: r.readNullable<double>('mass'),
        capacity: r.readNullable<double>('capacity'),
      );

  Future<SdeMeta> meta() async {
    final rows = await _select('SELECT key, value FROM meta');
    final m = {for (final r in rows) r.read<String>('key'): r.read<String>('value')};
    return SdeMeta(
      buildNumber: int.parse(m['buildNumber'] ?? '0'),
      releaseDate: m['releaseDate'] ?? '',
      schemaVersion: int.parse(m['schemaVersion'] ?? '0'),
    );
  }

  /// [_typeColumns] read from `inv_types t`.
  static final _tColumns = _typeColumns.split(', ').map((c) => 't.$c AS $c').join(', ');

  /// Rows of [from] that pass [where] and whose English or Chinese name matches [query], best
  /// match first (see [NameQuery]). Typos are only tried when the strict match finds fewer
  /// than [typoFallbackBelow] rows; their scores are lower, so they come after.
  Future<List<TypeInfo>> _searchByName({
    required String from,
    required List<String> where,
    List<Object?> args = const [],
    required String query,
    required int limit,
  }) async {
    Future<List<QueryRow>> run({required bool typos}) => _select(
          'SELECT * FROM (SELECT $_tColumns, ph_name_score(t.name_en, t.name_zh, ?, ?) AS score '
          'FROM $from${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}) '
          'WHERE score > 0 ORDER BY score DESC, type_id LIMIT $limit',
          [query, typos ? 1 : 0, ...args],
        );
    var rows = await run(typos: false);
    if (rows.length < typoFallbackBelow) rows = await run(typos: true);
    return rows.map(_type).toList();
  }

  /// Fuzzy name search in English and Chinese, best match first (see [NameQuery]).
  Future<List<TypeInfo>> searchTypes(
    String query, {
    bool marketOnly = false,
    Set<int>? categories,
    Set<int>? groups,
    int limit = 60,
  }) async {
    if (NameQuery(query).isEmpty) return const [];
    return _searchByName(
      from: 'inv_types t',
      where: [
        if (marketOnly) 't.market_group_id IS NOT NULL',
        if (categories != null && categories.isNotEmpty) 't.category_id IN (${categories.join(',')})',
        if (groups != null && groups.isNotEmpty) 't.group_id IN (${groups.join(',')})',
      ],
      query: query,
      limit: limit,
    );
  }

  Future<TypeInfo?> type(int typeId) async {
    final rows = await _select('SELECT $_typeColumns FROM inv_types WHERE type_id = ?', [typeId]);
    return rows.isEmpty ? null : _type(rows.first);
  }

  Future<Map<int, TypeInfo>> types(Iterable<int> typeIds) async {
    final out = <int, TypeInfo>{};
    for (final chunk in _chunks(typeIds)) {
      final rows = await _select('SELECT $_typeColumns FROM inv_types WHERE type_id IN (${chunk.join(',')})');
      for (final r in rows) {
        final t = _type(r);
        out[t.typeId] = t;
      }
    }
    return out;
  }

  /// Exact name lookup (English case-insensitive, or Chinese), used by the EFT importer.
  Future<TypeInfo?> typeByName(String name) async {
    final n = name.trim();
    if (n.isEmpty) return null;
    final rows = await _select(
      'SELECT $_typeColumns FROM inv_types WHERE name_en = ? COLLATE NOCASE OR name_zh = ? '
      'ORDER BY market_group_id IS NULL, type_id LIMIT 1',
      [n, n],
    );
    return rows.isEmpty ? null : _type(rows.first);
  }

  Future<Map<int, SolarSystemInfo>> solarSystems(Iterable<int> ids) async {
    final out = <int, SolarSystemInfo>{};
    for (final chunk in _chunks(ids)) {
      final rows = await _select(
        'SELECT s.solar_system_id, s.name_en, s.name_zh, s.security_status, s.region_id, '
        'r.name_en AS region_en, r.name_zh AS region_zh '
        'FROM map_solar_systems s JOIN map_regions r USING (region_id) '
        'WHERE s.solar_system_id IN (${chunk.join(',')})',
      );
      for (final r in rows) {
        final id = r.read<int>('solar_system_id');
        out[id] = SolarSystemInfo(
          solarSystemId: id,
          name: LocalName(r.read<String>('name_en'), r.readNullable<String>('name_zh')),
          regionId: r.read<int>('region_id'),
          regionName: LocalName(r.read<String>('region_en'), r.readNullable<String>('region_zh')),
          security: r.readNullable<double>('security_status') ?? 0,
        );
      }
    }
    return out;
  }

  Future<Map<int, StationInfo>> stations(Iterable<int> ids) async {
    final out = <int, StationInfo>{};
    for (final chunk in _chunks(ids)) {
      final rows = await _select(
        'SELECT station_id, solar_system_id, name_en, name_zh FROM sta_stations '
        'WHERE station_id IN (${chunk.join(',')})',
      );
      for (final r in rows) {
        final id = r.read<int>('station_id');
        out[id] = StationInfo(
          stationId: id,
          solarSystemId: r.read<int>('solar_system_id'),
          name: LocalName(r.read<String>('name_en'), r.readNullable<String>('name_zh')),
        );
      }
    }
    return out;
  }

  Future<LocalName?> regionName(int regionId) async {
    final rows = await _select('SELECT name_en, name_zh FROM map_regions WHERE region_id = ?', [regionId]);
    if (rows.isEmpty) return null;
    return LocalName(rows.first.read<String>('name_en'), rows.first.readNullable<String>('name_zh'));
  }

  Future<Map<int, SkillTypeInfo>> skillTypes([Iterable<int>? typeIds]) async {
    final filter = typeIds == null ? 'category_id = 16' : 'type_id IN (${typeIds.toSet().join(',')})';
    if (typeIds != null && typeIds.isEmpty) return const {};
    final rows = await _select(
      'SELECT t.type_id, t.group_id, t.name_en, t.name_zh, '
      '(SELECT value FROM dgm_type_attributes WHERE type_id = t.type_id AND attribute_id = 275) AS rank, '
      '(SELECT value FROM dgm_type_attributes WHERE type_id = t.type_id AND attribute_id = 180) AS primary_attr, '
      '(SELECT value FROM dgm_type_attributes WHERE type_id = t.type_id AND attribute_id = 181) AS secondary_attr '
      'FROM inv_types t WHERE $filter',
    );
    return {
      for (final r in rows)
        r.read<int>('type_id'): SkillTypeInfo(
          typeId: r.read<int>('type_id'),
          groupId: r.read<int>('group_id'),
          name: LocalName(r.read<String>('name_en'), r.readNullable<String>('name_zh')),
          rank: r.readNullable<double>('rank') ?? 1,
          primaryAttributeId: (r.readNullable<double>('primary_attr') ?? AttrIds.intelligence).round(),
          secondaryAttributeId: (r.readNullable<double>('secondary_attr') ?? AttrIds.memory).round(),
        ),
    };
  }

  Future<Map<int, Map<int, double>>> typeAttributes(Iterable<int> typeIds) async {
    final out = <int, Map<int, double>>{};
    for (final chunk in _chunks(typeIds)) {
      final rows = await _select(
        'SELECT type_id, attribute_id, value FROM dgm_type_attributes WHERE type_id IN (${chunk.join(',')})',
      );
      for (final r in rows) {
        (out[r.read<int>('type_id')] ??= {})[r.read<int>('attribute_id')] = r.read<double>('value');
      }
    }
    return out;
  }

  Future<Map<int, List<(int, bool)>>> typeEffects(Iterable<int> typeIds) async {
    final out = <int, List<(int, bool)>>{};
    for (final chunk in _chunks(typeIds)) {
      final rows = await _select(
        'SELECT type_id, effect_id, is_default FROM dgm_type_effects WHERE type_id IN (${chunk.join(',')})',
      );
      for (final r in rows) {
        (out[r.read<int>('type_id')] ??= []).add((r.read<int>('effect_id'), r.read<int>('is_default') == 1));
      }
    }
    return out;
  }

  Future<List<int>> allSkillTypeIds() async {
    final rows = await _select('SELECT type_id FROM inv_types WHERE category_id = 16');
    return [for (final r in rows) r.read<int>('type_id')];
  }

  Future<List<QueryRow>> attributeDefinitionRows() => _select(
        'SELECT attribute_id, name, display_name_en, display_name_zh, default_value, stackable, high_is_good, '
        'unit_id, max_attribute_id FROM dgm_attributes',
      );

  Future<List<QueryRow>> effectDefinitionRows() => _select(
        'SELECT effect_id, name, category_id, duration_attribute_id, discharge_attribute_id FROM dgm_effects',
      );

  Future<List<QueryRow>> effectModifierRows() => _select(
        'SELECT effect_id, position, func, domain, modified_attribute_id, modifying_attribute_id, operation, '
        'group_id, skill_type_id FROM dgm_effect_modifiers ORDER BY effect_id, position',
      );

  /// Modules (or subsystems / rigs) whose slot effect matches, by name when [query] is given
  /// (fuzzy, English and Chinese), otherwise all of them alphabetically.
  /// [rigSize] keeps rigs of the ship's size; [fitsToShipType] keeps subsystems of that hull.
  Future<List<TypeInfo>> fittableTypes({
    required int slotEffectId,
    String query = '',
    int? rigSize,
    int? fitsToShipType,
    int limit = 80,
  }) async {
    final from = 'inv_types t JOIN dgm_type_effects e ON e.type_id = t.type_id AND e.effect_id = $slotEffectId';
    final where = ['t.market_group_id IS NOT NULL'];
    final args = <Object?>[];
    for (final (attributeId, value) in [(1547, rigSize), (1380, fitsToShipType)]) {
      if (value == null) continue;
      where.add('EXISTS (SELECT 1 FROM dgm_type_attributes a WHERE a.type_id = t.type_id '
          'AND a.attribute_id = $attributeId AND a.value = ?)');
      args.add(value);
    }
    if (!NameQuery(query).isEmpty) {
      return _searchByName(from: from, where: where, args: args, query: query, limit: limit);
    }
    final rows = await _select(
      'SELECT $_tColumns FROM $from WHERE ${where.join(' AND ')} ORDER BY $_byName LIMIT $limit',
      args,
    );
    return rows.map(_type).toList();
  }

  /// Alphabetical, ignoring the quotes around named modules ('Basic' Capacitor Recharger), which
  /// would otherwise all sort before A.
  static const _byName = "ltrim(t.name_en, '''\"') COLLATE NOCASE, t.name_en";

  /// Charges that fit a module: group listed in the module's chargeGroupN attributes and, when
  /// the module has a chargeSize, the same size.
  Future<List<TypeInfo>> chargesFor(Map<int, double> moduleAttributes) async {
    final groups = <int>{
      for (final a in AttrIds.chargeGroups)
        if ((moduleAttributes[a] ?? 0) > 0) moduleAttributes[a]!.round(),
    };
    if (groups.isEmpty) return const [];
    final size = moduleAttributes[AttrIds.chargeSize];
    final rows = await _select(
      'SELECT $_tColumns FROM inv_types t '
      'WHERE t.group_id IN (${groups.join(',')}) AND t.market_group_id IS NOT NULL '
      '${size == null ? '' : 'AND EXISTS (SELECT 1 FROM dgm_type_attributes a WHERE a.type_id = t.type_id AND a.attribute_id = 128 AND a.value = ${size.round()})'} '
      'ORDER BY $_byName LIMIT 300',
    );
    return rows.map(_type).toList();
  }
}
