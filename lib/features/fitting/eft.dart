import 'dart:convert';

import '../../core/sde/sde_models.dart';
import 'dogma/dogma_data.dart';
import 'fit.dart';

enum EftError { empty, badHeader, unknownShip }

class EftFormatException implements Exception {
  const EftFormatException(this.kind, [this.detail = '']);

  final EftError kind;

  /// The ship name for [EftError.unknownShip].
  final String detail;

  @override
  String toString() => switch (kind) {
        EftError.empty => 'empty text',
        EftError.badHeader => 'the first line must look like [Ship, Fit name]',
        EftError.unknownShip => 'unknown ship "$detail"',
      };
}

class EftImport {
  const EftImport(this.fit, this.skipped);

  final Fit fit;

  /// Names that matched no item and were left out.
  final List<String> skipped;
}

typedef TypeLookup = Future<TypeInfo?> Function(String name);

const _emptyLabels = {
  SlotType.low: '[Empty Low slot]',
  SlotType.mid: '[Empty Med slot]',
  SlotType.high: '[Empty High slot]',
  SlotType.rig: '[Empty Rig slot]',
  SlotType.subsystem: '[Empty Subsystem slot]',
};

const _exportOrder = [SlotType.low, SlotType.mid, SlotType.high, SlotType.rig, SlotType.subsystem];

final _header = RegExp(r'^\[([^,\]]+)(?:,\s*(.*))?\]$');
final _quantity = RegExp(r'^(.*\S)\s+x(\d+)$');

/// Parses EFT text:
///   [Ship, Fit name]
///   Module[, Charge][ /OFFLINE]     one per line; low, mid, high, rig, subsystem blocks
///   [Empty Low slot]                ignored
///   Item xN                         drones and cargo
/// Each module goes to the slot its own data says, so out-of-order blocks still import.
Future<EftImport> parseEft(String text, {required TypeLookup lookup, required DogmaData data}) async {
  final lines = const LineSplitter().convert(text).map((l) => l.trim()).toList();
  final start = lines.indexWhere((l) => l.isNotEmpty);
  if (start < 0) throw const EftFormatException(EftError.empty);
  final header = _header.firstMatch(lines[start]);
  if (header == null) throw const EftFormatException(EftError.badHeader);
  final ship = await lookup(header.group(1)!.trim());
  if (ship == null || !ship.isShip) throw EftFormatException(EftError.unknownShip, header.group(1)!.trim());
  final name = (header.group(2) ?? '').trim();

  final skipped = <String>[];
  final modules = <FitModule>[];
  final drones = <int, int>{};
  final cargo = <int, int>{};
  final implants = <int>[];
  final cache = <String, TypeInfo?>{};
  Future<TypeInfo?> find(String n) async => cache.containsKey(n) ? cache[n] : cache[n] = await lookup(n);

  await data.ensureTypes([ship.typeId]);
  for (final line in lines.skip(start + 1)) {
    if (line.isEmpty || line.startsWith('[')) continue;
    var raw = line;
    var offline = false;
    if (raw.endsWith('/OFFLINE')) {
      offline = true;
      raw = raw.substring(0, raw.length - '/OFFLINE'.length).trim();
    }
    final qty = _quantity.firstMatch(raw);
    if (qty != null) {
      final item = await find(qty.group(1)!.trim());
      if (item == null) {
        skipped.add(qty.group(1)!.trim());
        continue;
      }
      final n = int.parse(qty.group(2)!);
      final bucket = item.categoryId == Categories.drone ? drones : cargo;
      bucket[item.typeId] = (bucket[item.typeId] ?? 0) + n;
      continue;
    }
    final parts = raw.split(',');
    final moduleName = parts.first.trim();
    final chargeName = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;
    final item = await find(moduleName);
    if (item == null) {
      skipped.add(moduleName);
      continue;
    }
    await data.ensureTypes([item.typeId]);
    final def = data.type(item.typeId);
    final slot = slotOf(def);
    if (slot == null) {
      if (item.categoryId == Categories.implant) {
        implants.add(item.typeId);
      } else if (item.categoryId == Categories.drone) {
        drones[item.typeId] = (drones[item.typeId] ?? 0) + 1;
      } else {
        cargo[item.typeId] = (cargo[item.typeId] ?? 0) + 1;
      }
      continue;
    }
    TypeInfo? charge;
    if (chargeName != null && chargeName.isNotEmpty) {
      charge = await find(chargeName);
      if (charge == null) skipped.add(chargeName);
    }
    if (charge != null) await data.ensureTypes([charge.typeId]);
    final state = offline
        ? ModuleState.offline
        : (isActivatable(def, data) ? ModuleState.active : ModuleState.online);
    modules.add(FitModule(typeId: item.typeId, slot: slot, state: state, chargeTypeId: charge?.typeId));
  }

  return EftImport(
    Fit(
      shipTypeId: ship.typeId,
      name: name,
      modules: limitActive(modules, data),
      drones: [for (final e in drones.entries) FitStack(e.key, e.value)],
      cargo: [for (final e in cargo.entries) FitStack(e.key, e.value)],
      implants: implants,
    ),
    skipped,
  );
}

/// Modules with maxGroupActive (one prop mod, one RAH...) beyond the limit are set to online.
List<FitModule> limitActive(List<FitModule> modules, DogmaData data) {
  final activeByGroup = <int, int>{};
  return [
    for (final m in modules)
      () {
        if (m.state.index < ModuleState.active.index) return m;
        final type = data.type(m.typeId);
        final limit = type.attributes[A.maxGroupActive];
        if (limit == null || limit <= 0) return m;
        final count = (activeByGroup[type.groupId] ?? 0) + 1;
        activeByGroup[type.groupId] = count;
        return count > limit ? m.copyWith(state: ModuleState.online) : m;
      }(),
  ];
}

/// EFT text with English names, empty slots written out when [slotTotals] is given.
String exportEft(Fit fit, DogmaData data, {Map<SlotType, int>? slotTotals, String defaultName = 'Pocket Hangar'}) {
  String nameOf(int typeId) => data.typeOrNull(typeId)?.name.en ?? 'Unknown $typeId';
  final out = StringBuffer('[${nameOf(fit.shipTypeId)}, ${fit.name.isEmpty ? defaultName : fit.name}]\n');
  var firstBlock = true;
  for (final slot in _exportOrder) {
    final mods = fit.inSlot(slot).toList();
    final total = slotTotals?[slot] ?? mods.length;
    if (mods.isEmpty && total == 0) continue;
    if (!firstBlock) out.writeln();
    firstBlock = false;
    for (final m in mods) {
      final charge = m.chargeTypeId;
      out.write(nameOf(m.typeId));
      if (charge != null) out.write(', ${nameOf(charge)}');
      if (m.state == ModuleState.offline) out.write(' /OFFLINE');
      out.writeln();
    }
    for (var i = mods.length; i < total; i++) {
      out.writeln(_emptyLabels[slot]);
    }
  }
  for (final stacks in [fit.drones, fit.cargo]) {
    if (stacks.isEmpty) continue;
    out.writeln();
    for (final s in stacks) {
      out.writeln('${nameOf(s.typeId)} x${s.quantity}');
    }
  }
  return out.toString().trimRight();
}
