import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/core/sde/sde_repository.dart';
import 'package:pocket_hangar/features/fitting/dogma/dogma_data.dart';

import 'support/fixture.dart';

/// The engine refers to attributes and effects by id. Ids are stable in EVE, but a typo would
/// silently read the wrong value, so every constant is checked against its name in the SDE.
void main() {
  late FitBench bench;
  setUpAll(() async => bench = await FitBench.open());
  tearDownAll(() => bench.close());

  test('attribute ids', () {
    const expected = {
      A.mass: 'mass',
      A.hp: 'hp',
      A.powerOutput: 'powerOutput',
      A.lowSlots: 'lowSlots',
      A.medSlots: 'medSlots',
      A.hiSlots: 'hiSlots',
      A.speedFactor: 'speedFactor',
      A.power: 'power',
      A.maxVelocity: 'maxVelocity',
      A.capacity: 'capacity',
      A.cpuOutput: 'cpuOutput',
      A.cpu: 'cpu',
      A.rechargeRate: 'rechargeRate',
      A.capacitorBonus: 'capacitorBonus',
      A.agility: 'agility',
      A.launcherSlotsLeft: 'launcherSlotsLeft',
      A.turretSlotsLeft: 'turretSlotsLeft',
      A.emDamageResonance: 'emDamageResonance',
      A.explosiveDamageResonance: 'explosiveDamageResonance',
      A.kineticDamageResonance: 'kineticDamageResonance',
      A.thermalDamageResonance: 'thermalDamageResonance',
      A.volume: 'volume',
      A.shieldCapacity: 'shieldCapacity',
      A.armorHP: 'armorHP',
      A.armorEmDamageResonance: 'armorEmDamageResonance',
      A.armorExplosiveDamageResonance: 'armorExplosiveDamageResonance',
      A.armorKineticDamageResonance: 'armorKineticDamageResonance',
      A.armorThermalDamageResonance: 'armorThermalDamageResonance',
      A.shieldEmDamageResonance: 'shieldEmDamageResonance',
      A.shieldExplosiveDamageResonance: 'shieldExplosiveDamageResonance',
      A.shieldKineticDamageResonance: 'shieldKineticDamageResonance',
      A.shieldThermalDamageResonance: 'shieldThermalDamageResonance',
      A.skillLevel: 'skillLevel',
      A.capacitorCapacity: 'capacitorCapacity',
      A.signatureRadius: 'signatureRadius',
      A.signatureRadiusBonus: 'signatureRadiusBonus',
      A.speedBoostFactor: 'speedBoostFactor',
      A.moduleReactivationDelay: 'moduleReactivationDelay',
      A.maxGroupActive: 'maxGroupActive',
      A.massAddition: 'massAddition',
      A.upgradeCapacity: 'upgradeCapacity',
      A.rigSlots: 'rigSlots',
      A.upgradeCost: 'upgradeCost',
      A.subSystemSlot: 'subSystemSlot',
      A.maxSubSystems: 'maxSubSystems',
      A.turretHardPointModifier: 'turretHardPointModifier',
      A.launcherHardPointModifier: 'launcherHardPointModifier',
      A.hiSlotModifier: 'hiSlotModifier',
      A.medSlotModifier: 'medSlotModifier',
      A.lowSlotModifier: 'lowSlotModifier',
      A.fitsToShipType: 'fitsToShipType',
      A.maxGroupFitted: 'maxGroupFitted',
      A.rigSize: 'rigSize',
      A.maxTypeFitted: 'maxTypeFitted',
      // character attributes and skill training
      AttrIds.charisma: 'charisma',
      AttrIds.intelligence: 'intelligence',
      AttrIds.memory: 'memory',
      AttrIds.perception: 'perception',
      AttrIds.willpower: 'willpower',
      AttrIds.primaryAttribute: 'primaryAttribute',
      AttrIds.secondaryAttribute: 'secondaryAttribute',
      AttrIds.skillTimeConstant: 'skillTimeConstant',
      AttrIds.charismaBonus: 'charismaBonus',
      AttrIds.intelligenceBonus: 'intelligenceBonus',
      AttrIds.memoryBonus: 'memoryBonus',
      AttrIds.perceptionBonus: 'perceptionBonus',
      AttrIds.willpowerBonus: 'willpowerBonus',
    };
    for (final e in expected.entries) {
      expect(bench.data.attributes[e.key]?.name, e.value, reason: 'attribute ${e.key}');
    }
  });

  test('required skill and charge group attributes', () {
    final names = [for (final id in A.requiredSkills) bench.data.attributes[id]?.name];
    expect(names, ['requiredSkill1', 'requiredSkill2', 'requiredSkill3', 'requiredSkill4', 'requiredSkill5', 'requiredSkill6']);
    expect([for (final id in AttrIds.chargeGroups) bench.data.attributes[id]?.name],
        ['chargeGroup1', 'chargeGroup2', 'chargeGroup3', 'chargeGroup4', 'chargeGroup5']);
    expect(bench.data.attributes[AttrIds.chargeSize]?.name, 'chargeSize');
    expect(bench.data.attributes[72]?.name, 'capacityBonus');
  });

  test('effect ids', () {
    const expected = {
      E.loPower: 'loPower',
      E.hiPower: 'hiPower',
      E.medPower: 'medPower',
      E.online: 'online',
      E.launcherFitted: 'launcherFitted',
      E.turretFitted: 'turretFitted',
      E.skillEffect: 'skillEffect',
      E.rigSlot: 'rigSlot',
      E.subSystem: 'subSystem',
    };
    for (final e in expected.entries) {
      expect(bench.data.effects[e.key]?.name, e.value, reason: 'effect ${e.key}');
    }
  });

  test('implant bonus attributes map to the right character attribute', () {
    final names = {
      for (final e in AttrIds.implantBonusToAttribute.entries)
        bench.data.attributes[e.key]?.name: bench.data.attributes[e.value]?.name,
    };
    expect(names, {
      'charismaBonus': 'charisma',
      'intelligenceBonus': 'intelligence',
      'memoryBonus': 'memory',
      'perceptionBonus': 'perception',
      'willpowerBonus': 'willpower',
    });
  });
}
