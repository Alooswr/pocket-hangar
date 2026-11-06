import 'dart:math' as math;

import '../../../core/sde/sde_models.dart';
import '../fit.dart';
import 'dogma_data.dart';

/// Attribute calculation for one fit, written from the published dogma rules (SDE modifierInfo,
/// operator order, stacking penalties). It does not reuse code from other fitting tools.
///
/// How a value is computed:
///   base (type attribute, or the attribute's default)
///   -> preAssign -> preMul -> preDiv -> modAdd -> modSub -> postMul -> postDiv -> postPercent
///   -> postAssign -> capped by the attribute's maxAttributeId (when it names one)
/// Multiplicative operations on a non-stackable attribute are stacking penalized when the
/// source is not a ship, charge, skill, implant or subsystem: per operation, increases and
/// decreases separately, strongest first, the n-th one (from 0) scaled by exp(-(n / 2.67)^2).
enum ItemKind { character, ship, module, charge, skill, implant }

class DogmaItem {
  DogmaItem(this.type, this.kind, {this.state = ModuleState.online, this.parent});

  final TypeDef type;
  final ItemKind kind;
  ModuleState state;

  /// Charge -> the module holding it.
  final DogmaItem? parent;

  /// Module -> its loaded charge.
  DogmaItem? charge;

  /// Values that replace the type attribute (skill levels).
  final overrides = <int, double>{};

  @override
  String toString() => '${type.name.en}(${kind.name})';
}

class _Modifier {
  const _Modifier(this.source, this.operation, this.value, {required this.penalized});

  final DogmaItem source;
  final int operation;
  final double Function() value;
  final bool penalized;
}

typedef _SpecialEffect = void Function(DogmaFit fit, DogmaItem item);

class DogmaFit {
  DogmaFit._(this.data, this.ship, this.character);

  /// Builds the item tree and registers every modifier that is live in the current module
  /// states. Types must already be loaded in [data] (see [DogmaData.ensureTypes]).
  factory DogmaFit.build({
    required DogmaData data,
    required Fit fit,
    required Map<int, int> skillLevels,
  }) {
    final character = DogmaItem(
      TypeDef(typeId: 0, groupId: 1, categoryId: 3, name: const LocalName('Character', null), attributes: const {}, effects: const []),
      ItemKind.character,
    );
    final ship = DogmaItem(data.type(fit.shipTypeId), ItemKind.ship);
    final result = DogmaFit._(data, ship, character);

    for (final entry in skillLevels.entries) {
      if (entry.value <= 0) continue;
      final type = data.typeOrNull(entry.key);
      if (type == null) continue;
      final skill = DogmaItem(type, ItemKind.skill)..overrides[A.skillLevel] = entry.value.toDouble();
      result.skills.add(skill);
    }
    for (final implantId in fit.implants) {
      final type = data.typeOrNull(implantId);
      if (type != null) result.implants.add(DogmaItem(type, ItemKind.implant));
    }
    for (final m in fit.modules) {
      final type = data.typeOrNull(m.typeId);
      if (type == null) continue;
      final module = DogmaItem(type, ItemKind.module, state: m.state);
      result.modules.add(module);
      result.moduleSlots[module] = m.slot;
      final chargeId = m.chargeTypeId;
      final chargeType = chargeId == null ? null : data.typeOrNull(chargeId);
      if (chargeType != null) {
        final charge = DogmaItem(chargeType, ItemKind.charge, parent: module);
        module.charge = charge;
        result.charges.add(charge);
      }
    }
    result._registerAll();
    return result;
  }

  final DogmaData data;
  final DogmaItem ship;
  final DogmaItem character;
  final skills = <DogmaItem>[];
  final implants = <DogmaItem>[];
  final modules = <DogmaItem>[];
  final charges = <DogmaItem>[];
  final moduleSlots = <DogmaItem, SlotType>{};

  final _incoming = <DogmaItem, Map<int, List<_Modifier>>>{};
  final _values = <DogmaItem, Map<int, double>>{};
  final _computing = <(DogmaItem, int)>{};

  /// Effects that have no modifierInfo in the SDE and are therefore implemented by hand.
  static final Map<String, _SpecialEffect> _special = {
    'moduleBonusAfterburner': (f, m) => f._propulsion(m, microwarp: false),
    'moduleBonusMicrowarpdrive': (f, m) => f._propulsion(m, microwarp: true),
    'adaptiveArmorHardener': (f, m) => f._reactiveArmorHardener(m),
    'slotModifier': (f, m) => f._subsystemSlots(m),
    'hardPointModifierEffect': (f, m) => f._subsystemHardpoints(m),
  };

  static const _penaltyExemptCategories = {
    Categories.ship,
    Categories.charge,
    Categories.skill,
    Categories.implant,
    Categories.subsystem,
  };

  Iterable<DogmaItem> get _allItems sync* {
    yield ship;
    yield* skills;
    yield* implants;
    yield* modules;
    yield* charges;
  }

  // ---------------------------------------------------------------- registration

  void _registerAll() {
    for (final item in _allItems) {
      for (final (effectId, _) in item.type.effects) {
        final effect = data.effects[effectId];
        if (effect == null || !_isLive(item, effect)) continue;
        final special = _special[effect.name];
        if (special != null) {
          special(this, item);
          continue;
        }
        for (final m in effect.modifiers) {
          _register(item, m);
        }
      }
    }
  }

  bool _isLive(DogmaItem item, EffectDef effect) {
    if (effect.id == E.skillEffect) return false; // derives skillLevel from SP; we set it directly
    switch (item.kind) {
      case ItemKind.module:
        return switch (effect.category) {
          EffectCategory.passive => true,
          EffectCategory.online => item.state.index >= ModuleState.online.index,
          EffectCategory.active => item.state.index >= ModuleState.active.index,
          EffectCategory.overload => item.state == ModuleState.overheated,
          _ => false, // target / area effects act on other ships
        };
      case ItemKind.charge:
        return effect.category == EffectCategory.passive;
      case ItemKind.ship || ItemKind.skill || ItemKind.implant || ItemKind.character:
        return effect.category == EffectCategory.passive;
    }
  }

  void _register(DogmaItem source, ModifierDef m) {
    final modified = m.modifiedAttributeId;
    final modifying = m.modifyingAttributeId;
    final op = m.operation;
    if (m.func == ModifierFunc.effectStopper || m.func == ModifierFunc.unknown) return;
    if (modified == null || modifying == null || op == null || op == 9) return;
    final def = data.attributes[modified];
    final penalized = def != null && !def.stackable && !_exempt(source);
    final modifier = _Modifier(source, op, () => attr(source, modifying), penalized: penalized);
    for (final target in _targets(source, m)) {
      _add(target, modified, modifier);
    }
  }

  bool _exempt(DogmaItem source) =>
      source.kind == ItemKind.character || _penaltyExemptCategories.contains(source.type.categoryId);

  void _add(DogmaItem target, int attributeId, _Modifier modifier) {
    ((_incoming[target] ??= {})[attributeId] ??= []).add(modifier);
  }

  Iterable<DogmaItem> _targets(DogmaItem source, ModifierDef m) {
    final domain = switch (m.domain) {
      ModifierDomain.itemID => source,
      ModifierDomain.shipID => ship,
      ModifierDomain.charID => character,
      ModifierDomain.otherID => source.kind == ItemKind.charge ? source.parent : source.charge,
      _ => null, // projected or structure effects do not touch our own fit
    };
    if (domain == null) return const [];
    final skill = m.skillTypeId == -1 ? source.type.typeId : m.skillTypeId;
    return switch (m.func) {
      ModifierFunc.item => [domain],
      ModifierFunc.location => _locatedIn(domain),
      ModifierFunc.locationGroup => _locatedIn(domain).where((i) => i.type.groupId == m.groupId),
      ModifierFunc.locationRequiredSkill => _locatedIn(domain).where((i) => i.type.requiredSkills.contains(skill)),
      ModifierFunc.ownerRequiredSkill => _owned().where((i) => i.type.requiredSkills.contains(skill)),
      _ => const [],
    };
  }

  /// Items "inside" a location: everything fitted to the ship, and a module's charge.
  Iterable<DogmaItem> _locatedIn(DogmaItem location) {
    if (identical(location, ship) || identical(location, character)) return [...modules, ...charges];
    final charge = location.charge;
    return charge == null ? const [] : [charge];
  }

  Iterable<DogmaItem> _owned() => [...modules, ...charges];

  // ---------------------------------------------------------------- special effects

  /// Afterburner / microwarpdrive: adds mass, then raises max velocity by
  /// speedFactor * speedBoostFactor / ship mass (percent). The MWD also blooms the signature.
  void _propulsion(DogmaItem module, {required bool microwarp}) {
    _add(ship, A.mass, _Modifier(module, 2, () => attr(module, A.massAddition), penalized: false));
    _add(
      ship,
      A.maxVelocity,
      _Modifier(
        module,
        6,
        () => attr(module, A.speedFactor) * attr(module, A.speedBoostFactor) / attr(ship, A.mass),
        penalized: false,
      ),
    );
    if (microwarp) {
      _add(ship, A.signatureRadius, _Modifier(module, 6, () => attr(module, A.signatureRadiusBonus), penalized: false));
    }
  }

  /// Reactive Armor Hardener at its starting split (no adaptation to incoming damage yet).
  void _reactiveArmorHardener(DogmaItem module) {
    for (final id in const [
      A.armorEmDamageResonance,
      A.armorThermalDamageResonance,
      A.armorKineticDamageResonance,
      A.armorExplosiveDamageResonance,
    ]) {
      _add(ship, id, _Modifier(module, 0, () => attr(module, id), penalized: true));
    }
  }

  void _subsystemSlots(DogmaItem subsystem) {
    _add(ship, A.hiSlots, _Modifier(subsystem, 2, () => attr(subsystem, A.hiSlotModifier), penalized: false));
    _add(ship, A.medSlots, _Modifier(subsystem, 2, () => attr(subsystem, A.medSlotModifier), penalized: false));
    _add(ship, A.lowSlots, _Modifier(subsystem, 2, () => attr(subsystem, A.lowSlotModifier), penalized: false));
  }

  void _subsystemHardpoints(DogmaItem subsystem) {
    _add(ship, A.turretSlotsLeft,
        _Modifier(subsystem, 2, () => attr(subsystem, A.turretHardPointModifier), penalized: false));
    _add(ship, A.launcherSlotsLeft,
        _Modifier(subsystem, 2, () => attr(subsystem, A.launcherHardPointModifier), penalized: false));
  }

  // ---------------------------------------------------------------- calculation

  double base(DogmaItem item, int attributeId) =>
      item.overrides[attributeId] ??
      item.type.attributes[attributeId] ??
      data.attributes[attributeId]?.defaultValue ??
      0;

  /// The modified value of [attributeId] on [item].
  double attr(DogmaItem item, int attributeId) {
    final cache = _values[item] ??= {};
    final cached = cache[attributeId];
    if (cached != null) return cached;
    final key = (item, attributeId);
    if (!_computing.add(key)) return base(item, attributeId); // dependency cycle: use the base value
    try {
      var value = base(item, attributeId);
      final mods = _incoming[item]?[attributeId];
      if (mods != null && mods.isNotEmpty) value = _apply(value, mods, data.attributes[attributeId]);
      final maxId = data.attributes[attributeId]?.maxAttributeId;
      if (maxId != null && maxId != attributeId) {
        final cap = attr(item, maxId);
        if (cap > 0 && value > cap) value = cap;
      }
      cache[attributeId] = value;
      return value;
    } finally {
      _computing.remove(key);
    }
  }

  double _apply(double base, List<_Modifier> mods, AttributeDef? def) {
    final byOp = <int, List<_Modifier>>{};
    for (final m in mods) {
      (byOp[m.operation] ??= []).add(m);
    }
    var v = base;
    final preAssign = byOp[-1];
    if (preAssign != null) v = _assign(preAssign, def);
    v *= _product(byOp[0], (x) => x);
    v *= _product(byOp[1], (x) => x == 0 ? 1 : 1 / x);
    for (final m in byOp[2] ?? const <_Modifier>[]) {
      v += m.value();
    }
    for (final m in byOp[3] ?? const <_Modifier>[]) {
      v -= m.value();
    }
    v *= _product(byOp[4], (x) => x);
    v *= _product(byOp[5], (x) => x == 0 ? 1 : 1 / x);
    v *= _product(byOp[6], (x) => 1 + x / 100);
    final postAssign = byOp[7];
    if (postAssign != null) v = _assign(postAssign, def);
    return v;
  }

  static double _assign(List<_Modifier> mods, AttributeDef? def) {
    final values = mods.map((m) => m.value());
    return (def?.highIsGood ?? true) ? values.reduce(math.max) : values.reduce(math.min);
  }

  static double _product(List<_Modifier>? mods, double Function(double) toMultiplier) {
    if (mods == null) return 1;
    var result = 1.0;
    final penalized = <double>[];
    for (final m in mods) {
      final x = toMultiplier(m.value());
      if (m.penalized) {
        penalized.add(x);
      } else {
        result *= x;
      }
    }
    return result * stackingPenalized(penalized);
  }

  /// Combines multipliers with EVE's stacking penalty.
  static double stackingPenalized(List<double> multipliers) {
    final up = multipliers.where((m) => m > 1).toList()..sort((a, b) => b.compareTo(a));
    final down = multipliers.where((m) => m < 1).toList()..sort();
    double chain(List<double> list) {
      var r = 1.0;
      for (var i = 0; i < list.length; i++) {
        r *= 1 + (list[i] - 1) * penaltyFactor(i);
      }
      return r;
    }

    return chain(up) * chain(down);
  }

  static double penaltyFactor(int n) => math.exp(-math.pow(n / 2.67, 2));
}
