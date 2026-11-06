import '../../../core/sde/sde_models.dart';
import '../../../core/sde/sde_repository.dart';

/// Attribute ids the engine and the stats code read by name. All of them were checked against
/// dogmaAttributes.jsonl of SDE build 3670638 (test/dogma_ids_test.dart re-checks them).
abstract final class A {
  static const mass = 4;
  static const hp = 9;
  static const powerOutput = 11;
  static const lowSlots = 12;
  static const medSlots = 13;
  static const hiSlots = 14;
  static const speedFactor = 20;
  static const power = 30;
  static const maxVelocity = 37;
  static const capacity = 38;
  static const volume = 161;
  static const cpuOutput = 48;
  static const cpu = 50;
  static const rechargeRate = 55;
  static const capacitorBonus = 67;
  static const agility = 70;
  static const launcherSlotsLeft = 101;
  static const turretSlotsLeft = 102;
  static const emDamageResonance = 113;
  static const explosiveDamageResonance = 111;
  static const kineticDamageResonance = 109;
  static const thermalDamageResonance = 110;
  static const shieldCapacity = 263;
  static const armorHP = 265;
  static const armorEmDamageResonance = 267;
  static const armorExplosiveDamageResonance = 268;
  static const armorKineticDamageResonance = 269;
  static const armorThermalDamageResonance = 270;
  static const shieldEmDamageResonance = 271;
  static const shieldExplosiveDamageResonance = 272;
  static const shieldKineticDamageResonance = 273;
  static const shieldThermalDamageResonance = 274;
  static const skillLevel = 280;
  static const capacitorCapacity = 482;
  static const signatureRadius = 552;
  static const signatureRadiusBonus = 554;
  static const speedBoostFactor = 567;
  static const moduleReactivationDelay = 669;
  static const maxGroupActive = 763;
  static const massAddition = 796;
  static const upgradeCapacity = 1132;
  static const rigSlots = 1137;
  static const upgradeCost = 1153;
  static const subSystemSlot = 1366;
  static const maxSubSystems = 1367;
  static const turretHardPointModifier = 1368;
  static const launcherHardPointModifier = 1369;
  static const hiSlotModifier = 1374;
  static const medSlotModifier = 1375;
  static const lowSlotModifier = 1376;
  static const fitsToShipType = 1380;
  static const maxGroupFitted = 1544;
  static const rigSize = 1547;
  static const maxTypeFitted = 2431;

  static const requiredSkills = [182, 183, 184, 1285, 1289, 1290];
}

/// Effect ids that mark slots and hardpoints (no modifiers, they only describe the module).
abstract final class E {
  static const loPower = 11;
  static const hiPower = 12;
  static const medPower = 13;
  static const online = 16;
  static const launcherFitted = 40;
  static const turretFitted = 42;
  static const skillEffect = 132;
  static const rigSlot = 2663;
  static const subSystem = 3772;
}

/// Effect categories in dgm_effects.category_id.
abstract final class EffectCategory {
  static const passive = 0;
  static const active = 1;
  static const target = 2;
  static const area = 3;
  static const online = 4;
  static const overload = 5;
}

class AttributeDef {
  const AttributeDef({
    required this.id,
    required this.name,
    required this.defaultValue,
    required this.stackable,
    required this.highIsGood,
    this.maxAttributeId,
    this.unitId,
    this.displayName,
  });

  final int id;
  final String name;
  final double defaultValue;
  final bool stackable;
  final bool highIsGood;
  final int? maxAttributeId;
  final int? unitId;
  final LocalName? displayName;
}

enum ModifierFunc { item, location, locationGroup, locationRequiredSkill, ownerRequiredSkill, effectStopper, unknown }

enum ModifierDomain { itemID, shipID, charID, otherID, targetID, structureID, unknown }

class ModifierDef {
  const ModifierDef({
    required this.func,
    required this.domain,
    this.modifiedAttributeId,
    this.modifyingAttributeId,
    this.operation,
    this.groupId,
    this.skillTypeId,
  });

  final ModifierFunc func;
  final ModifierDomain domain;
  final int? modifiedAttributeId;
  final int? modifyingAttributeId;
  final int? operation;
  final int? groupId;
  final int? skillTypeId;

  static ModifierFunc parseFunc(String value) => switch (value) {
        'ItemModifier' => ModifierFunc.item,
        'LocationModifier' => ModifierFunc.location,
        'LocationGroupModifier' => ModifierFunc.locationGroup,
        'LocationRequiredSkillModifier' => ModifierFunc.locationRequiredSkill,
        'OwnerRequiredSkillModifier' => ModifierFunc.ownerRequiredSkill,
        'EffectStopper' => ModifierFunc.effectStopper,
        _ => ModifierFunc.unknown,
      };

  static ModifierDomain parseDomain(String? value) => switch (value) {
        'itemID' => ModifierDomain.itemID,
        'shipID' => ModifierDomain.shipID,
        'charID' => ModifierDomain.charID,
        'otherID' => ModifierDomain.otherID,
        'targetID' || 'target' => ModifierDomain.targetID,
        'structureID' => ModifierDomain.structureID,
        _ => ModifierDomain.unknown,
      };
}

class EffectDef {
  const EffectDef({
    required this.id,
    required this.name,
    required this.category,
    required this.modifiers,
    this.durationAttributeId,
    this.dischargeAttributeId,
  });

  final int id;
  final String name;
  final int category;
  final int? durationAttributeId;
  final int? dischargeAttributeId;
  final List<ModifierDef> modifiers;
}

class TypeDef {
  TypeDef({
    required this.typeId,
    required this.groupId,
    required this.categoryId,
    required this.name,
    required this.attributes,
    required this.effects,
  }) : requiredSkills = {
          for (final a in A.requiredSkills)
            if ((attributes[a] ?? 0) > 0) attributes[a]!.round(),
        };

  final int typeId;
  final int groupId;
  final int categoryId;
  final LocalName name;
  final Map<int, double> attributes;

  /// (effect id, is default effect)
  final List<(int, bool)> effects;
  final Set<int> requiredSkills;

  bool hasEffect(int effectId) => effects.any((e) => e.$1 == effectId);
}

/// Static dogma definitions plus a cache of the types a fit uses. Definitions are loaded once
/// (a few thousand rows); types are loaded on demand.
class DogmaData {
  DogmaData({required this.attributes, required this.effects, this.sde});

  final Map<int, AttributeDef> attributes;
  final Map<int, EffectDef> effects;
  final SdeRepository? sde;
  final _types = <int, TypeDef>{};
  List<int>? _skillIds;

  static Future<DogmaData> load(SdeRepository sde) async {
    final attributeRows = await sde.attributeDefinitionRows();
    final attributes = <int, AttributeDef>{
      for (final r in attributeRows)
        r.read<int>('attribute_id'): AttributeDef(
          id: r.read<int>('attribute_id'),
          name: r.read<String>('name'),
          defaultValue: r.read<double>('default_value'),
          stackable: r.read<int>('stackable') == 1,
          highIsGood: r.read<int>('high_is_good') == 1,
          maxAttributeId: r.readNullable<int>('max_attribute_id'),
          unitId: r.readNullable<int>('unit_id'),
          displayName: r.readNullable<String>('display_name_en') == null
              ? null
              : LocalName(r.read<String>('display_name_en'), r.readNullable<String>('display_name_zh')),
        ),
    };
    final modifiers = <int, List<ModifierDef>>{};
    for (final r in await sde.effectModifierRows()) {
      (modifiers[r.read<int>('effect_id')] ??= []).add(
        ModifierDef(
          func: ModifierDef.parseFunc(r.read<String>('func')),
          domain: ModifierDef.parseDomain(r.readNullable<String>('domain')),
          modifiedAttributeId: r.readNullable<int>('modified_attribute_id'),
          modifyingAttributeId: r.readNullable<int>('modifying_attribute_id'),
          operation: r.readNullable<int>('operation'),
          groupId: r.readNullable<int>('group_id'),
          skillTypeId: r.readNullable<int>('skill_type_id'),
        ),
      );
    }
    final effects = <int, EffectDef>{
      for (final r in await sde.effectDefinitionRows())
        r.read<int>('effect_id'): EffectDef(
          id: r.read<int>('effect_id'),
          name: r.read<String>('name'),
          category: r.read<int>('category_id'),
          durationAttributeId: r.readNullable<int>('duration_attribute_id'),
          dischargeAttributeId: r.readNullable<int>('discharge_attribute_id'),
          modifiers: modifiers[r.read<int>('effect_id')] ?? const [],
        ),
    };
    return DogmaData(attributes: attributes, effects: effects, sde: sde);
  }

  TypeDef? typeOrNull(int typeId) => _types[typeId];

  TypeDef type(int typeId) => _types[typeId] ?? (throw StateError('type $typeId not loaded'));

  void putType(TypeDef def) => _types[def.typeId] = def;

  /// Loads the given types (and nothing that is already cached) from the SDE.
  Future<void> ensureTypes(Iterable<int> typeIds) async {
    final missing = typeIds.where((id) => !_types.containsKey(id)).toSet();
    final repo = sde;
    if (missing.isEmpty || repo == null) return;
    final infos = await repo.types(missing);
    final attrs = await repo.typeAttributes(missing);
    final effects = await repo.typeEffects(missing);
    for (final id in missing) {
      final info = infos[id];
      if (info == null) continue;
      _types[id] = TypeDef(
        typeId: id,
        groupId: info.groupId,
        categoryId: info.categoryId,
        name: info.name,
        attributes: attrs[id] ?? const {},
        effects: effects[id] ?? const [],
      );
    }
  }

  Future<List<int>> skillIds() async {
    final cached = _skillIds;
    if (cached != null) return cached;
    final ids = await sde!.allSkillTypeIds();
    await ensureTypes(ids);
    return _skillIds = ids;
  }
}
