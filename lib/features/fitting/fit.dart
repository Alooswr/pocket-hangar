import 'dogma/dogma_data.dart';

enum SlotType { high, mid, low, rig, subsystem }

enum ModuleState { offline, online, active, overheated }

class FitModule {
  const FitModule({required this.typeId, required this.slot, this.state = ModuleState.online, this.chargeTypeId});

  final int typeId;
  final SlotType slot;
  final ModuleState state;
  final int? chargeTypeId;

  FitModule copyWith({ModuleState? state, int? chargeTypeId, bool clearCharge = false}) => FitModule(
        typeId: typeId,
        slot: slot,
        state: state ?? this.state,
        chargeTypeId: clearCharge ? null : (chargeTypeId ?? this.chargeTypeId),
      );
}

class FitStack {
  const FitStack(this.typeId, this.quantity);

  final int typeId;
  final int quantity;
}

class Fit {
  const Fit({
    required this.shipTypeId,
    required this.name,
    this.modules = const [],
    this.drones = const [],
    this.cargo = const [],
    this.implants = const [],
  });

  final int shipTypeId;
  final String name;
  final List<FitModule> modules;
  final List<FitStack> drones;
  final List<FitStack> cargo;
  final List<int> implants;

  Iterable<FitModule> inSlot(SlotType slot) => modules.where((m) => m.slot == slot);

  Set<int> get typeIds => {
        shipTypeId,
        for (final m in modules) ...[m.typeId, ?m.chargeTypeId],
        for (final d in drones) d.typeId,
        for (final c in cargo) c.typeId,
        ...implants,
      };

  Fit copyWith({String? name, List<FitModule>? modules, List<FitStack>? drones, List<FitStack>? cargo}) => Fit(
        shipTypeId: shipTypeId,
        name: name ?? this.name,
        modules: modules ?? this.modules,
        drones: drones ?? this.drones,
        cargo: cargo ?? this.cargo,
        implants: implants,
      );

  /// Stored form of a fit: type ids only, so renamed items still load.
  Map<String, Object?> toJson() => {
        'v': 1,
        'ship': shipTypeId,
        'name': name,
        'modules': [
          for (final m in modules)
            {'type': m.typeId, 'slot': m.slot.name, 'state': m.state.name, 'charge': ?m.chargeTypeId},
        ],
        'drones': [for (final d in drones) [d.typeId, d.quantity]],
        'cargo': [for (final c in cargo) [c.typeId, c.quantity]],
        'implants': implants,
      };

  static Fit fromJson(Map<String, Object?> json) {
    int asInt(Object? v) => (v as num).toInt();
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    List<FitStack> stacks(Object? list) => [
          for (final e in (list as List<Object?>?) ?? const [])
            FitStack(asInt((e as List<Object?>)[0]), asInt(e[1])),
        ];
    return Fit(
      shipTypeId: asInt(json['ship']),
      name: json['name'] as String? ?? '',
      modules: [
        for (final m in (json['modules'] as List<Object?>?) ?? const [])
          if (m is Map<String, Object?>)
            FitModule(
              typeId: asInt(m['type']),
              slot: byName(SlotType.values, m['slot'], SlotType.high),
              state: byName(ModuleState.values, m['state'], ModuleState.online),
              chargeTypeId: m['charge'] == null ? null : asInt(m['charge']),
            ),
      ],
      drones: stacks(json['drones']),
      cargo: stacks(json['cargo']),
      implants: [for (final i in (json['implants'] as List<Object?>?) ?? const []) asInt(i)],
    );
  }
}

/// Which slot a module goes in, from its slot effect. Null for anything that is not fitted.
SlotType? slotOf(TypeDef type) {
  for (final (id, _) in type.effects) {
    switch (id) {
      case E.hiPower:
        return SlotType.high;
      case E.medPower:
        return SlotType.mid;
      case E.loPower:
        return SlotType.low;
      case E.rigSlot:
        return SlotType.rig;
      case E.subSystem:
        return SlotType.subsystem;
    }
  }
  return null;
}

int slotEffectFor(SlotType slot) => switch (slot) {
      SlotType.high => E.hiPower,
      SlotType.mid => E.medPower,
      SlotType.low => E.loPower,
      SlotType.rig => E.rigSlot,
      SlotType.subsystem => E.subSystem,
    };

/// A module that has an activation effect (hardeners, prop mods, weapons, repairers).
bool isActivatable(TypeDef type, DogmaData data) => type.effects.any((e) {
      final def = data.effects[e.$1];
      return def != null &&
          (def.category == EffectCategory.active || def.category == EffectCategory.target) &&
          def.id != E.online;
    });
