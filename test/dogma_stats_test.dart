import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hangar/features/fitting/dogma/capacitor.dart';
import 'package:pocket_hangar/features/fitting/dogma/dogma_data.dart';
import 'package:pocket_hangar/features/fitting/dogma/dogma_engine.dart';
import 'package:pocket_hangar/features/fitting/fit.dart';
import 'package:pocket_hangar/features/fitting/fit_editing.dart';
import 'package:pocket_hangar/features/fitting/fitting_providers.dart';

import 'support/fixture.dart';

/// Reference values. The Rifter numbers are worked out by hand from the SDE base values and the
/// skill bonuses at level V (25 % from CPU Management, Power Grid Management, Shield Management,
/// Hull Upgrades, Mechanics, Capacitor Management, Navigation; -25 % recharge from Capacitor
/// Systems Operation; agility x0.75 Evasive Maneuvering, x0.9 Spaceship Command; +25 % AB speed
/// from Acceleration Control). They do not come from running this engine.
void main() {
  late FitBench bench;

  setUpAll(() async => bench = await FitBench.open());
  tearDownAll(() => bench.close());

  group('Rifter, all skills V, empty', () {
    late FitComputation c;
    setUpAll(() async => c = bench.compute(await bench.fit('Rifter', [])));

    test('fitting resources', () {
      expect(c.stats.cpu.total, closeTo(162.5, 1e-9));
      expect(c.stats.power.total, closeTo(51.25, 1e-9));
      expect(c.stats.calibration.total, closeTo(400, 1e-9));
    });

    test('slots and hardpoints match the SDE', () async {
      final rifter = await bench.id('Rifter');
      expect(c.stats.slots[SlotType.high]!.total, bench.raw(rifter, A.hiSlots));
      expect(c.stats.slots[SlotType.mid]!.total, bench.raw(rifter, A.medSlots));
      expect(c.stats.slots[SlotType.low]!.total, bench.raw(rifter, A.lowSlots));
      expect(c.stats.slots[SlotType.rig]!.total, bench.raw(rifter, A.rigSlots));
      expect(c.stats.turrets.total, bench.raw(rifter, A.turretSlotsLeft));
      expect(c.stats.launchers.total, bench.raw(rifter, A.launcherSlotsLeft));
    });

    test('hit points', () {
      expect(c.stats.shield.hp, closeTo(562.5, 1e-9));
      expect(c.stats.armor.hp, closeTo(562.5, 1e-9));
      expect(c.stats.hull.hp, closeTo(437.5, 1e-9));
    });

    test('capacitor', () {
      expect(c.stats.capacitor.capacity, closeTo(312.5, 1e-9));
      expect(c.stats.capacitor.rechargeSeconds, closeTo(93.75, 1e-9));
      expect(c.stats.capacitor.stable, isTrue);
      expect(c.stats.capacitor.stableFraction, 1);
    });

    test('navigation', () {
      expect(c.stats.maxVelocity, closeTo(456.25, 1e-9));
      expect(c.stats.agility, closeTo(2.16, 1e-9));
      expect(c.stats.mass, 1067000);
      expect(c.stats.alignTime, closeTo(-math.log(0.25) * 1067000 * 2.16 / 1e6, 1e-9));
      expect(c.stats.alignTime, closeTo(3.195, 0.001));
    });

    test('resists are the hull values (no skill changes them)', () async {
      final rifter = await bench.id('Rifter');
      expect(c.stats.shield.em, bench.raw(rifter, A.shieldEmDamageResonance));
      expect(c.stats.armor.explosive, bench.raw(rifter, A.armorExplosiveDamageResonance));
      expect(c.stats.hull.kinetic, bench.raw(rifter, A.kineticDamageResonance));
    });

    test('skills at 0 give the hull values', () async {
      final rifter = await bench.id('Rifter');
      final base = bench.compute(await bench.fit('Rifter', []), skills: const {});
      expect(base.stats.cpu.total, bench.raw(rifter, A.cpuOutput));
      expect(base.stats.shield.hp, bench.raw(rifter, A.shieldCapacity));
      expect(base.stats.maxVelocity, bench.raw(rifter, A.maxVelocity));
    });
  });

  group('propulsion', () {
    test('1MN Afterburner II active: mass +500 t, speed x(1 + 1.6875 * 1.5e6 / 1.567e6)', () async {
      final c = bench.compute(await bench.fit('Rifter', ['1MN Afterburner II']));
      expect(c.stats.mass, closeTo(1567000, 1e-6));
      expect(c.stats.maxVelocity, closeTo(456.25 * (1 + 1.6875 * 1500000 / 1567000), 1e-6));
      expect(c.stats.maxVelocity, closeTo(1193.25, 0.01));
    });

    test('an online (not active) afterburner changes nothing', () async {
      var fit = await bench.fit('Rifter', ['1MN Afterburner II']);
      fit = setModuleState(fit, 0, ModuleState.online, bench.data);
      final c = bench.compute(fit);
      expect(c.stats.maxVelocity, closeTo(456.25, 1e-9));
      expect(c.stats.mass, 1067000);
    });

    test('microwarpdrive blooms the signature radius', () async {
      final mwd = await bench.id('5MN Microwarpdrive II');
      final rifter = await bench.id('Rifter');
      final c = bench.compute(await bench.fit('Rifter', ['5MN Microwarpdrive II']));
      final bonus = bench.raw(mwd, A.signatureRadiusBonus);
      expect(c.stats.signatureRadius, closeTo(bench.raw(rifter, A.signatureRadius) * (1 + bonus / 100), 1e-6));
    });
  });

  group('modifier order and stacking', () {
    test('shield extender adds HP before the skill percentage', () async {
      final extender = await bench.id('Medium Shield Extender II');
      final c = bench.compute(await bench.fit('Merlin', ['Medium Shield Extender II']));
      final merlin = await bench.id('Merlin');
      // capacityBonus (72) is a modAdd on the ship; Shield Management V is a postPercent +25 %.
      expect(c.stats.shield.hp, closeTo((bench.raw(merlin, A.shieldCapacity) + bench.raw(extender, 72)) * 1.25, 1e-6));
    });

    test('penalty factors', () {
      expect(DogmaFit.penaltyFactor(0), 1);
      expect(DogmaFit.penaltyFactor(1), closeTo(0.869119, 1e-6));
      expect(DogmaFit.penaltyFactor(2), closeTo(0.570583, 1e-6));
      expect(DogmaFit.penaltyFactor(3), closeTo(0.282955, 1e-6));
      expect(DogmaFit.stackingPenalized([1.1, 1.1, 1.1]), closeTo(1.1 * 1.0869119 * 1.0570583, 1e-6));
      // Increases and decreases are separate chains.
      expect(DogmaFit.stackingPenalized([1.1, 0.9]), closeTo(1.1 * 0.9, 1e-12));
    });

    test('two shield hardeners: the second one is penalized', () async {
      final one = bench.compute(await bench.fit('Merlin', ['Multispectrum Shield Hardener II']));
      final two = bench.compute(
        await bench.fit('Merlin', ['Multispectrum Shield Hardener II', 'Multispectrum Shield Hardener II']),
      );
      final base = bench.compute(await bench.fit('Merlin', []));
      final m1 = one.stats.shield.em / base.stats.shield.em;
      expect(m1, lessThan(1));
      expect(two.stats.shield.em / base.stats.shield.em, closeTo(m1 * (1 + (m1 - 1) * DogmaFit.penaltyFactor(1)), 1e-9));
    });

    test('damage control multiplies hull resists (own preMul chain)', () async {
      final dc = await bench.id('Damage Control II');
      final rifter = await bench.id('Rifter');
      final c = bench.compute(await bench.fit('Rifter', ['Damage Control II']));
      // The module keeps its hull bonus in hullEmDamageResonance; shield and armor use the ship's names.
      final hullEm = bench.data.attributes.values.firstWhere((a) => a.name == 'hullEmDamageResonance').id;
      expect(bench.raw(dc, hullEm), lessThan(1));
      expect(c.stats.hull.em, closeTo(bench.raw(rifter, A.emDamageResonance) * bench.raw(dc, hullEm), 1e-9));
      expect(
        c.stats.armor.thermal,
        closeTo(bench.raw(rifter, A.armorThermalDamageResonance) * bench.raw(dc, A.armorThermalDamageResonance), 1e-9),
      );
    });

    test('effective HP against even damage', () async {
      final c = bench.compute(await bench.fit('Rifter', ['Damage Control II']));
      double layer(double hp, List<double> res) => hp / (res.reduce((a, b) => a + b) / 4);
      final s = c.stats;
      final expected = layer(s.shield.hp, [s.shield.em, s.shield.thermal, s.shield.kinetic, s.shield.explosive]) +
          layer(s.armor.hp, [s.armor.em, s.armor.thermal, s.armor.kinetic, s.armor.explosive]) +
          layer(s.hull.hp, [s.hull.em, s.hull.thermal, s.hull.kinetic, s.hull.explosive]);
      expect(s.ehpUniform, closeTo(expected, 1e-6));
    });

    test('a rig changes the powergrid by its own bonus', () async {
      final c = bench.compute(await bench.fit('Rifter', ['Small Ancillary Current Router I']));
      expect(c.stats.power.total, greaterThan(51.25));
      expect(c.stats.calibration.used, greaterThan(0));
    });
  });

  group('usage', () {
    test('CPU and powergrid of online modules add up', () async {
      final c = bench.compute(await bench.fit('Rifter', ['200mm AutoCannon II', '200mm AutoCannon II', 'Damage Control II']));
      final ac = c.dogma.modules.first;
      final dc = c.dogma.modules.last;
      expect(c.stats.cpu.used, closeTo(2 * c.dogma.attr(ac, A.cpu) + c.dogma.attr(dc, A.cpu), 1e-9));
      expect(c.stats.power.used, closeTo(2 * c.dogma.attr(ac, A.power) + c.dogma.attr(dc, A.power), 1e-9));
      expect(c.stats.turrets.used, 2);
    });

    test('offline modules use no CPU', () async {
      var fit = await bench.fit('Rifter', ['Damage Control II']);
      fit = setModuleState(fit, 0, ModuleState.offline, bench.data);
      expect(bench.compute(fit).stats.cpu.used, 0);
    });
  });

  group('strategic cruiser', () {
    test('subsystems give the Legion its slots and hardpoints', () async {
      final legion = await bench.id('Legion');
      final subs = await bench.sde.searchTypes('Legion ', categories: {32}, limit: 50);
      await bench.data.ensureTypes(subs.map((s) => s.typeId));
      // One subsystem per subsystem slot.
      final bySlot = <double, int>{};
      for (final s in subs) {
        bySlot.putIfAbsent(bench.raw(s.typeId, A.subSystemSlot), () => s.typeId);
      }
      expect(bySlot.length, 4);
      var fit = Fit(shipTypeId: legion, name: 't3');
      for (final id in bySlot.values) {
        fit = addModule(fit, bench.data.type(id), bench.data);
      }
      final c = bench.compute(fit);
      double sum(int attr) => bySlot.values.fold(0, (a, id) => a + bench.raw(id, attr));
      expect(c.stats.slots[SlotType.high]!.total, bench.raw(legion, A.hiSlots) + sum(A.hiSlotModifier));
      expect(c.stats.slots[SlotType.mid]!.total, bench.raw(legion, A.medSlots) + sum(A.medSlotModifier));
      expect(c.stats.slots[SlotType.low]!.total, bench.raw(legion, A.lowSlots) + sum(A.lowSlotModifier));
      expect(c.stats.turrets.total, bench.raw(legion, A.turretSlotsLeft) + sum(A.turretHardPointModifier));
      expect(c.stats.slots[SlotType.subsystem]!.used, 4);
    });
  });

  group('capacitor model', () {
    test('stable level from the closed form', () {
      // k = D * tau / (10 * C) = 4 * 93.75 / 3125 = 0.12; s = (1 + sqrt(1 - 0.48)) / 2
      final r = simulateCapacitor(capacity: 312.5, rechargeSeconds: 93.75, drainPerSecond: 4);
      final s = (1 + math.sqrt(1 - 4 * 0.12)) / 2;
      expect(r.stableFraction, closeTo(s * s, 1e-9));
      expect(r.peakRecharge, closeTo(2.5 * 312.5 / 93.75, 1e-9));
    });

    test('time to empty matches a fine Euler integration', () {
      const c = 312.5, tau = 93.75, d = 10.0;
      final r = simulateCapacitor(capacity: c, rechargeSeconds: tau, drainPerSecond: d);
      expect(r.stable, isFalse);
      var cap = c;
      var t = 0.0;
      const dt = 0.0005;
      while (cap > 0) {
        final x = cap / c;
        cap += (10 * c / tau * (math.sqrt(x) - x) - d) * dt;
        t += dt;
      }
      expect(r.secondsToEmpty, closeTo(t, 0.05));
    });

    test('an active afterburner drains the Rifter capacitor but stays stable', () async {
      final c = bench.compute(await bench.fit('Rifter', ['1MN Afterburner II']));
      expect(c.stats.capacitor.drainPerSecond, greaterThan(0));
      expect(c.stats.capacitor.stable, isTrue);
      expect(c.stats.capacitor.stableFraction, lessThan(1));
    });

    test('a capacitor booster injects charge', () async {
      final without = bench.compute(await bench.fit('Rifter', ['1MN Afterburner II', 'Small Capacitor Booster II']));
      final withCharge = bench.compute(
        await bench.fit('Rifter', ['1MN Afterburner II', 'Small Capacitor Booster II'],
            charges: {'Small Capacitor Booster II': 'Navy Cap Booster 100'}),
      );
      expect(withCharge.stats.capacitor.drainPerSecond, lessThan(without.stats.capacitor.drainPerSecond));
    });
  });
}
