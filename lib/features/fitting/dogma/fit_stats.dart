import 'dart:math' as math;

import '../fit.dart';
import 'capacitor.dart';
import 'dogma_data.dart';
import 'dogma_engine.dart';

class Usage {
  const Usage(this.used, this.total);

  final double used;
  final double total;

  double get left => total - used;
  bool get over => used > total + 1e-9;
  double get fraction => total <= 0 ? (used > 0 ? 1 : 0) : (used / total).clamp(0.0, 1.0);
}

class DefenseLayer {
  const DefenseLayer({
    required this.hp,
    required this.em,
    required this.thermal,
    required this.kinetic,
    required this.explosive,
  });

  final double hp;

  /// Resonances (damage taken multipliers). Resist = 1 - resonance.
  final double em;
  final double thermal;
  final double kinetic;
  final double explosive;

  /// Effective HP against a damage profile given as weights (they need not sum to 1).
  double ehp({double emW = 1, double thermalW = 1, double kineticW = 1, double explosiveW = 1}) {
    final total = emW + thermalW + kineticW + explosiveW;
    final taken = (em * emW + thermal * thermalW + kinetic * kineticW + explosive * explosiveW) / total;
    return taken <= 0 ? double.infinity : hp / taken;
  }
}

class FitStats {
  const FitStats({
    required this.slots,
    required this.cpu,
    required this.power,
    required this.calibration,
    required this.turrets,
    required this.launchers,
    required this.capacitor,
    required this.shield,
    required this.armor,
    required this.hull,
    required this.maxVelocity,
    required this.mass,
    required this.agility,
    required this.signatureRadius,
  });

  final Map<SlotType, Usage> slots;
  final Usage cpu;
  final Usage power;
  final Usage calibration;
  final Usage turrets;
  final Usage launchers;
  final CapacitorResult capacitor;
  final DefenseLayer shield;
  final DefenseLayer armor;
  final DefenseLayer hull;
  final double maxVelocity;
  final double mass;
  final double agility;
  final double signatureRadius;

  /// Seconds to reach 75 % of max velocity in the warp direction: -ln(0.25) * mass * agility / 10^6.
  double get alignTime => -math.log(0.25) * mass * agility / 1e6;

  double get ehpUniform => shield.ehp() + armor.ehp() + hull.ehp();
}

FitStats computeStats(DogmaFit f) {
  final data = f.data;
  final ship = f.ship;
  double s(int id) => f.attr(ship, id);

  final online = f.modules.where((m) => m.state.index >= ModuleState.online.index).toList();
  final cpuUsed = online.fold<double>(0, (sum, m) => sum + f.attr(m, A.cpu));
  final powerUsed = online.fold<double>(0, (sum, m) => sum + f.attr(m, A.power));
  final rigs = f.modules.where((m) => f.moduleSlots[m] == SlotType.rig);
  final calibrationUsed = rigs.fold<double>(0, (sum, m) => sum + f.attr(m, A.upgradeCost));

  int countSlot(SlotType t) => f.modules.where((m) => f.moduleSlots[m] == t).length;
  final slots = {
    SlotType.high: Usage(countSlot(SlotType.high).toDouble(), s(A.hiSlots)),
    SlotType.mid: Usage(countSlot(SlotType.mid).toDouble(), s(A.medSlots)),
    SlotType.low: Usage(countSlot(SlotType.low).toDouble(), s(A.lowSlots)),
    SlotType.rig: Usage(countSlot(SlotType.rig).toDouble(), s(A.rigSlots)),
    SlotType.subsystem: Usage(countSlot(SlotType.subsystem).toDouble(), s(A.maxSubSystems)),
  };
  final turrets = f.modules.where((m) => m.type.hasEffect(E.turretFitted)).length;
  final launchers = f.modules.where((m) => m.type.hasEffect(E.launcherFitted)).length;

  // Capacitor: average use of every active module, minus cap booster injection.
  var drain = 0.0;
  for (final m in f.modules.where((m) => m.state.index >= ModuleState.active.index)) {
    final activation = _activationEffect(m, data);
    if (activation == null) continue;
    final durationId = activation.durationAttributeId;
    if (durationId == null) continue;
    final cycle = f.attr(m, durationId) + f.attr(m, A.moduleReactivationDelay);
    if (cycle <= 0) continue;
    final seconds = cycle / 1000;
    final dischargeId = activation.dischargeAttributeId;
    if (dischargeId != null) drain += f.attr(m, dischargeId) / seconds;
    final charge = m.charge;
    if (activation.name == 'powerBooster' && charge != null) {
      drain -= f.attr(charge, A.capacitorBonus) / seconds;
    }
  }
  final capacitor = simulateCapacitor(
    capacity: s(A.capacitorCapacity),
    rechargeSeconds: s(A.rechargeRate) / 1000,
    drainPerSecond: drain,
  );

  DefenseLayer layer(int hpId, int em, int th, int ki, int ex) =>
      DefenseLayer(hp: s(hpId), em: s(em), thermal: s(th), kinetic: s(ki), explosive: s(ex));

  return FitStats(
    slots: slots,
    cpu: Usage(cpuUsed, s(A.cpuOutput)),
    power: Usage(powerUsed, s(A.powerOutput)),
    calibration: Usage(calibrationUsed, s(A.upgradeCapacity)),
    turrets: Usage(turrets.toDouble(), s(A.turretSlotsLeft)),
    launchers: Usage(launchers.toDouble(), s(A.launcherSlotsLeft)),
    capacitor: capacitor,
    shield: layer(A.shieldCapacity, A.shieldEmDamageResonance, A.shieldThermalDamageResonance,
        A.shieldKineticDamageResonance, A.shieldExplosiveDamageResonance),
    armor: layer(A.armorHP, A.armorEmDamageResonance, A.armorThermalDamageResonance, A.armorKineticDamageResonance,
        A.armorExplosiveDamageResonance),
    hull: layer(A.hp, A.emDamageResonance, A.thermalDamageResonance, A.kineticDamageResonance,
        A.explosiveDamageResonance),
    maxVelocity: s(A.maxVelocity),
    mass: s(A.mass),
    agility: s(A.agility),
    signatureRadius: s(A.signatureRadius),
  );
}

/// The effect that runs when the module cycles: its default effect if that is an activation
/// effect, otherwise the first active/target effect with a duration.
EffectDef? _activationEffect(DogmaItem module, DogmaData data) {
  EffectDef? fallback;
  for (final (id, isDefault) in module.type.effects) {
    final e = data.effects[id];
    if (e == null || e.id == E.online) continue;
    if (e.category != EffectCategory.active && e.category != EffectCategory.target) continue;
    if (isDefault) return e;
    if (e.durationAttributeId != null) fallback ??= e;
  }
  return fallback;
}
