import 'dart:math' as math;

import 'dogma/dogma_data.dart';
import 'eft.dart';
import 'fit.dart';

/// Editing rules for a fit. Pure functions over [Fit] so they can be tested without widgets.

enum FitProblemKind { noFreeSlot, wrongShip, groupLimit }

class FitProblem {
  const FitProblem(this.kind, {this.limit = 0});

  final FitProblemKind kind;

  /// For [FitProblemKind.groupLimit]: how many may be fitted.
  final int limit;
}

/// Whether the ship accepts [module] at all: canFitShipGroupNN / canFitShipTypeNN lists (read
/// by attribute name, so lists CCP adds later are covered), subsystem hull and rig size.
bool canFitShip(TypeDef module, TypeDef ship, DogmaData data) {
  final groups = <int>{};
  final types = <int>{};
  module.attributes.forEach((id, value) {
    if (value == 0) return;
    final name = data.attributes[id]?.name ?? '';
    if (name.startsWith('canFitShipGroup')) {
      groups.add(value.round());
    } else if (name.startsWith('canFitShipType')) {
      types.add(value.round());
    }
  });
  if ((groups.isNotEmpty || types.isNotEmpty) && !groups.contains(ship.groupId) && !types.contains(ship.typeId)) {
    return false;
  }
  final slot = slotOf(module);
  if (slot == SlotType.subsystem) {
    final hull = module.attributes[A.fitsToShipType];
    if (hull != null && hull.round() != ship.typeId) return false;
  }
  if (slot == SlotType.rig) {
    final size = module.attributes[A.rigSize];
    final shipSize = ship.attributes[A.rigSize];
    if (size != null && shipSize != null && size.round() != shipSize.round()) return false;
  }
  return true;
}

/// Null when [module] can be added to [fit]. [slotTotals] are the ship's slot counts after
/// modifiers (subsystems add slots on strategic cruisers).
FitProblem? fitProblem({
  required Fit fit,
  required TypeDef ship,
  required TypeDef module,
  required DogmaData data,
  required Map<SlotType, int> slotTotals,
}) {
  final slot = slotOf(module);
  if (slot == null || !canFitShip(module, ship, data)) return const FitProblem(FitProblemKind.wrongShip);
  // A subsystem replaces the one already in its slot, so only the other slots can run out.
  if (slot != SlotType.subsystem && fit.inSlot(slot).length >= (slotTotals[slot] ?? 0)) {
    return const FitProblem(FitProblemKind.noFreeSlot);
  }
  final groupLimit = (module.attributes[A.maxGroupFitted] ?? 0).round();
  if (groupLimit > 0) {
    final same = fit.modules.where((m) => data.typeOrNull(m.typeId)?.groupId == module.groupId).length;
    if (same >= groupLimit) return FitProblem(FitProblemKind.groupLimit, limit: groupLimit);
  }
  final typeLimit = (module.attributes[A.maxTypeFitted] ?? 0).round();
  if (typeLimit > 0 && fit.modules.where((m) => m.typeId == module.typeId).length >= typeLimit) {
    return FitProblem(FitProblemKind.groupLimit, limit: typeLimit);
  }
  return null;
}

/// Adds [module] in its own slot. Activatable modules start active unless their group already
/// has as many active as maxGroupActive allows (a second prop mod comes in online). A subsystem
/// replaces the subsystem in the same subsystem slot.
Fit addModule(Fit fit, TypeDef module, DogmaData data) {
  final slot = slotOf(module) ?? (throw ArgumentError('${module.name.en} is not fittable'));
  var modules = fit.modules;
  if (slot == SlotType.subsystem) {
    final kind = module.attributes[A.subSystemSlot];
    modules = [
      for (final m in modules)
        if (m.slot != SlotType.subsystem || data.typeOrNull(m.typeId)?.attributes[A.subSystemSlot] != kind) m,
    ];
  }
  final state = isActivatable(module, data) ? ModuleState.active : ModuleState.online;
  return fit.copyWith(
    modules: limitActive([...modules, FitModule(typeId: module.typeId, slot: slot, state: state)], data),
  );
}

Fit removeModule(Fit fit, int index) => fit.copyWith(modules: [...fit.modules]..removeAt(index));

Fit setCharge(Fit fit, int index, int? chargeTypeId) {
  final modules = [...fit.modules];
  modules[index] = modules[index].copyWith(chargeTypeId: chargeTypeId, clearCharge: chargeTypeId == null);
  return fit.copyWith(modules: modules);
}

/// The states a module can be put in. Rigs and subsystems are always on.
List<ModuleState> availableStates(TypeDef type, DogmaData data) {
  final slot = slotOf(type);
  if (slot == SlotType.rig || slot == SlotType.subsystem) return const [ModuleState.online];
  final active = isActivatable(type, data);
  final overload = active && type.effects.any((e) => data.effects[e.$1]?.category == EffectCategory.overload);
  return [
    ModuleState.offline,
    ModuleState.online,
    if (active) ModuleState.active,
    if (overload) ModuleState.overheated,
  ];
}

/// What one tap on the state button does: activatable modules switch between online and
/// active, passive ones between online and offline. The other states are in the module sheet.
ModuleState toggledState(ModuleState current, TypeDef type, DogmaData data) {
  final states = availableStates(type, data);
  if (!states.contains(ModuleState.active)) {
    return current == ModuleState.online ? ModuleState.offline : ModuleState.online;
  }
  return switch (current) {
    ModuleState.online => ModuleState.active,
    ModuleState.overheated => ModuleState.active,
    ModuleState.active || ModuleState.offline => ModuleState.online,
  };
}

/// Sets the state of module [index]. When it becomes active, other modules of its group that
/// would break maxGroupActive go back to online (the one the user touched wins).
Fit setModuleState(Fit fit, int index, ModuleState state, DogmaData data) {
  final modules = [...fit.modules];
  modules[index] = modules[index].copyWith(state: state);
  if (state.index >= ModuleState.active.index) {
    final type = data.type(modules[index].typeId);
    final limit = (type.attributes[A.maxGroupActive] ?? 0).round();
    if (limit > 0) {
      var active = 1;
      for (var i = 0; i < modules.length; i++) {
        final m = modules[i];
        if (i == index || m.state.index < ModuleState.active.index) continue;
        if (data.typeOrNull(m.typeId)?.groupId != type.groupId) continue;
        active++;
        if (active > limit) modules[i] = m.copyWith(state: ModuleState.online);
      }
    }
  }
  return fit.copyWith(modules: modules);
}

const _flagPrefix = {
  SlotType.high: 'HiSlot',
  SlotType.mid: 'MedSlot',
  SlotType.low: 'LoSlot',
  SlotType.rig: 'RigSlot',
  SlotType.subsystem: 'SubSystemSlot',
};

/// ESI's flag enum stops at HiSlot7 / MedSlot7 / LoSlot7 / RigSlot2 / SubSystemSlot3.
const _flagCount = {
  SlotType.high: 8,
  SlotType.mid: 8,
  SlotType.low: 8,
  SlotType.rig: 3,
  SlotType.subsystem: 4,
};

/// Body for POST /characters/{id}/fittings. Loaded charges go to the cargo, enough to fill
/// every module that uses them once (in-game fittings carry charges as cargo).
Map<String, Object?> toEsiFitting(Fit fit, DogmaData data, {required String name, String description = ''}) {
  final items = <Map<String, Object?>>[];
  final next = <SlotType, int>{};
  for (final m in fit.modules) {
    final i = next[m.slot] ?? 0;
    next[m.slot] = i + 1;
    if (i >= _flagCount[m.slot]!) continue;
    items.add({'type_id': m.typeId, 'flag': '${_flagPrefix[m.slot]}$i', 'quantity': 1});
  }
  final cargo = <int, int>{};
  for (final c in fit.cargo) {
    cargo[c.typeId] = (cargo[c.typeId] ?? 0) + c.quantity;
  }
  for (final m in fit.modules) {
    final charge = m.chargeTypeId;
    if (charge == null) continue;
    final capacity = data.typeOrNull(m.typeId)?.attributes[A.capacity] ?? 0;
    final volume = data.typeOrNull(charge)?.attributes[A.volume] ?? 0;
    final perModule = volume > 0 ? (capacity / volume).floor() : 1;
    cargo[charge] = (cargo[charge] ?? 0) + math.max(1, perModule);
  }
  for (final d in fit.drones) {
    items.add({'type_id': d.typeId, 'flag': 'DroneBay', 'quantity': d.quantity});
  }
  for (final e in cargo.entries) {
    items.add({'type_id': e.key, 'flag': 'Cargo', 'quantity': e.value});
  }
  final trimmed = name.trim();
  return {
    'name': trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed,
    'description': description.length > 500 ? description.substring(0, 500) : description,
    'ship_type_id': fit.shipTypeId,
    'items': items,
  };
}
