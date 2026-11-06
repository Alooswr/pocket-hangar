/// A name in the two languages the database keeps.
class LocalName {
  const LocalName(this.en, this.zh);

  final String en;
  final String? zh;

  String of({required bool zh}) {
    final value = this.zh;
    return zh && value != null && value.isNotEmpty ? value : en;
  }

  @override
  String toString() => en;
}

class SdeMeta {
  const SdeMeta({required this.buildNumber, required this.releaseDate, required this.schemaVersion});

  final int buildNumber;
  final String releaseDate;
  final int schemaVersion;
}

/// Well-known category ids (inv_categories).
abstract final class Categories {
  static const ship = 6;
  static const module = 7;
  static const charge = 8;
  static const skill = 16;
  static const drone = 18;
  static const implant = 20;
  static const subsystem = 32;
  static const blueprint = 9;
  static const skin = 91;
}

class TypeInfo {
  const TypeInfo({
    required this.typeId,
    required this.groupId,
    required this.categoryId,
    required this.name,
    this.marketGroupId,
    this.metaGroupId,
    this.volume,
    this.packagedVolume,
    this.mass,
    this.capacity,
  });

  final int typeId;
  final int groupId;
  final int categoryId;
  final LocalName name;
  final int? marketGroupId;
  final int? metaGroupId;
  final double? volume;
  final double? packagedVolume;
  final double? mass;
  final double? capacity;

  bool get isShip => categoryId == Categories.ship;
}

class SolarSystemInfo {
  const SolarSystemInfo({
    required this.solarSystemId,
    required this.name,
    required this.regionId,
    required this.regionName,
    required this.security,
  });

  final int solarSystemId;
  final LocalName name;
  final int regionId;
  final LocalName regionName;
  final double security;
}

class StationInfo {
  const StationInfo({required this.stationId, required this.solarSystemId, required this.name});

  final int stationId;
  final int solarSystemId;
  final LocalName name;
}

class SkillTypeInfo {
  const SkillTypeInfo({
    required this.typeId,
    required this.groupId,
    required this.name,
    required this.rank,
    required this.primaryAttributeId,
    required this.secondaryAttributeId,
  });

  final int typeId;
  final int groupId;
  final LocalName name;
  final double rank;
  final int primaryAttributeId;
  final int secondaryAttributeId;
}

class MarketGroupInfo {
  const MarketGroupInfo({required this.marketGroupId, required this.parentId, required this.name, required this.hasTypes});

  final int marketGroupId;
  final int? parentId;
  final LocalName name;
  final bool hasTypes;
}
